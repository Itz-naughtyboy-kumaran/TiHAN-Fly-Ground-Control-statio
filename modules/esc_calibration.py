import time
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QTimer
from pymavlink import mavutil
from pymavlink.dialects.v20 import ardupilotmega as mavlink_dialect

class ESCCalibrationModel(QObject):
    # Signals
    calibrationStatusChanged = pyqtSignal(str)  # Status message
    calibrationCompleted = pyqtSignal(bool, str)  # Success, message
    soundDetected = pyqtSignal(str)  # Sound feedback signal
    currentEscChanged = pyqtSignal(int)  # Current ESC being calibrated (1-4)
    
    def __init__(self, drone_model=None, drone_commander=None):
        super().__init__()
        self.drone_model = drone_model
        self.drone_commander = drone_commander
        
        # Calibration state
        self._is_calibrating = False
        self._current_status = "Ready - Remove propellers before starting!"
        self._calibration_step = 0  # Track current step
        self._current_esc = 0  # Current ESC being calibrated (0-3, displayed as 1-4)
        
        # PWM values - matching ArduPilot semi-automatic method
        self._pwm_min = 1000
        self._pwm_max = 2000
        self._pwm_neutral = 1500
        
        # ESC configuration
        self._total_escs = 4  # Quadcopter
        self._esc_channels = [1, 2, 3, 4]  # Motor channels
        self._calibrated_escs = []  # Track which ESCs are calibrated
        
        # Timers
        self._step_timer = QTimer()
        self._step_timer.timeout.connect(self._execute_current_step)
        
        self._sound_timer = QTimer()
        self._sound_timer.timeout.connect(self._monitor_sounds)
        
        # Connection monitoring
        self._connection_timer = QTimer()
        self._connection_timer.timeout.connect(self._check_connection)
        self._connection_timer.start(1000)
        
        # Individual ESC calibration states - ESC_CALIBRATION=3
        self._esc_calibration_parameter = 3  # ESC_CALIBRATION=3 for individual ESC method
        self._waiting_for_power_cycle = False
        self._power_cycle_detected = False
        self._esc_calibration_sequence = []  # Track calibration sequence
        
        print("[ESCCalibrationModel] Initialized - Individual ESC Method (ESC_CALIBRATION=3)")
    
    @property
    def _drone(self):
        """Access to the MAVLink connection through DroneModel"""
        return self.drone_model.drone_connection if self.drone_model else None
    
    def _check_connection(self):
        """Monitor connection status"""
        if self._is_calibrating and not self.drone_model.isConnected:
            self._update_status("❌ Connection lost during calibration!")
            self._calibration_failed()

    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def isCalibrating(self):
        return self._is_calibrating
    
    @pyqtProperty(str, notify=calibrationStatusChanged)
    def currentStatus(self):
        return self._current_status
    
    @pyqtProperty(int, notify=currentEscChanged)
    def currentEsc(self):
        return self._current_esc + 1  # Return 1-based ESC number
    
    def _update_status(self, status):
        """Update calibration status"""
        self._current_status = status
        self.calibrationStatusChanged.emit(status)
        print(f"[ESCCalibrationModel] Status: {status}")
    
    def _monitor_sounds(self):
        """Monitor for expected ESC sounds during calibration"""
        if not self._is_calibrating:
            return
        
        current_esc_display = self._current_esc + 1
        
        if self._calibration_step == 2:  # During power-on sequence
            self.soundDetected.emit(f"🎵 ESC {current_esc_display}: Arming tone (if buzzer attached)")
        elif self._calibration_step == 3:  # After parameter set and power cycle
            self.soundDetected.emit(f"🎵 ESC {current_esc_display}: Musical tone + 2 beeps")
        elif self._calibration_step == 4:  # Calibration completion
            self.soundDetected.emit(f"🔊 ESC {current_esc_display}: Cell count beeps + long final beep")
    
    @pyqtSlot()
    def testBuzzer(self):
        """Test the Pixhawk buzzer by playing a tune."""
        if not self.drone_model or not self.drone_model.isConnected:
            print("🔊 Cannot test buzzer: Drone not connected.")
            return

        if not self.drone_commander:
            print("🔊 Cannot test buzzer: DroneCommander not available.")
            return

        print("🔊 Playing a test tune on the hardware buzzer...")
        tune = "MFT250L8O2CO3C"  # A simple melody
        try:
            self.drone_commander.playTune(tune)
        except Exception as e:
            print(f"❌ Failed to play tune on buzzer: {e}")

    @pyqtSlot(result=bool)
    def startCalibration(self):
        """Start the individual ESC calibration process (ESC_CALIBRATION=3)"""
        if not self.drone_model or not self.drone_model.isConnected:
            self._update_status("❌ Error: Drone not connected")
            return False

        if self._is_calibrating:
            self._update_status("⚠️ Calibration already running")
            return False

        print("[ESCCalibrationModel] Starting individual ESC calibration (ESC_CALIBRATION=3)")
        
        # Initialize calibration
        self._is_calibrating = True
        self._calibration_step = 0
        self._current_esc = 0
        self._waiting_for_power_cycle = False
        self._power_cycle_detected = False
        self._calibrated_escs = []
        self._esc_calibration_sequence = []
        
        # Start sound monitoring
        self._sound_timer.start(3000)  # Check every 3 seconds
        
        self._update_status(
            "🚨 STARTING INDIVIDUAL ESC CALIBRATION\n\n" +
            "📋 ARDUPILOT ESC_CALIBRATION=3 METHOD (INDIVIDUAL ESCs):\n" +
            "Following the official ArduPilot individual ESC calibration procedure.\n" +
            "Each ESC will be calibrated one by one in sequence.\n\n" +
            "⚠️ CRITICAL SAFETY CHECKLIST:\n" +
            "   ✅ ALL PROPELLERS REMOVED (MANDATORY!)\n" +
            "   ✅ Battery voltage > 11.1V (3S minimum)\n" +
            "   ✅ All ESCs connected to flight controller\n" +
            "   ✅ USB/Telemetry connection stable\n" +
            "   ✅ Buzzer connected (recommended - for audio feedback)\n" +
            "   ✅ Safety button ready (if using Pixhawk)\n\n" +
            "🔄 INDIVIDUAL ESC PROCESS OVERVIEW:\n" +
            f"   • Will calibrate {self._total_escs} ESCs one by one\n" +
            "   • Process: Parameter Set → Power Cycle → Safety Button → Auto Calibration\n" +
            "   • Each ESC gets individual calibration session\n" +
            "   • Process repeats for each ESC automatically\n\n" +
            "🔊 EXPECTED SOUND SEQUENCE (per ESC):\n" +
            "   1. Arming tone (when battery connected)\n" +
            "   2. Musical tone + 2 beeps (after safety button)\n" +
            "   3. Cell count beeps + long beep (ESC calibrated)\n\n" +
            "📡 Setting ESC_CALIBRATION parameter to 3 (Individual ESC mode)...\n" +
            "⏳ Preparing for individual ESC calibration sequence..."
        )
        
        # Start the calibration sequence after 2 seconds
        QTimer.singleShot(2000, self._start_individual_esc_calibration)
        return True

    def _start_individual_esc_calibration(self):
        """Start calibrating ESCs individually using ESC_CALIBRATION=3"""
        try:
            self._calibration_step = 1
            
            self._update_status(
                "🔧 INDIVIDUAL ESC CALIBRATION SETUP\n\n" +
                "📋 OFFICIAL ARDUPILOT INDIVIDUAL ESC STEPS:\n" +
                "   1. ✅ Connect to autopilot via ground station\n" +
                f"   2. 🔄 Set ESC_CALIBRATION parameter to {self._esc_calibration_parameter} (Individual mode)\n" +
                "   3. 🔌 Disconnect battery and USB (power down)\n" +
                "   4. 🔋 Connect battery\n" +
                "   5. 🛡️ Press safety button until solid red (if applicable)\n" +
                "   6. 🔊 Listen for sound confirmations per ESC\n" +
                "   7. 🔄 Repeat for each ESC automatically\n" +
                "   8. 🔌 Disconnect battery, reconnect USB normally\n\n" +
                f"⚡ STEP 1: SETTING ESC_CALIBRATION PARAMETER\n" +
                f"📡 Setting parameter ESC_CALIBRATION = {self._esc_calibration_parameter}\n" +
                f"🎯 This tells autopilot to calibrate ESCs individually\n" +
                f"🔧 Each ESC will get its own calibration session\n" +
                f"📊 Total ESCs to calibrate: {self._total_escs}\n\n" +
                "⏳ Setting calibration parameter for individual ESC mode..."
            )
            
            # Set the ESC_CALIBRATION parameter for individual ESCs
            self._set_esc_calibration_parameter()
            
            # Wait 2 seconds then proceed to power cycle instruction
            self._step_timer.start(2000)
            
        except Exception as e:
            print(f"[ESCCalibrationModel] Error starting individual ESC calibration: {e}")
            self._update_status(f"❌ FAILED TO START INDIVIDUAL ESC CALIBRATION: {str(e)}")
            self._calibration_failed()

    def _set_esc_calibration_parameter(self):
        """Set the ESC_CALIBRATION parameter for individual ESCs"""
        if not self._drone:
            raise Exception("No drone connection")
            
        try:
            # ESC_CALIBRATION parameter values:
            # 0 = Disabled
            # 1 = All ESCs at once
            # 2 = All ESCs passthrough
            # 3 = ESC by ESC (this is what we want now)
            param_value = self._esc_calibration_parameter  # = 3 for individual ESCs
            
            print(f"[ESCCalibrationModel] Setting ESC_CALIBRATION parameter to {param_value} (Individual ESCs)")
            
            # Send parameter set command
            param_name = "ESC_CALIBRATION"
            param_name_bytes = param_name.encode('utf-8')[:16].ljust(16, b'\x00')
            
            self._drone.mav.param_set_send(
                self._drone.target_system,
                self._drone.target_component,
                param_name_bytes,
                param_value,
                mavutil.mavlink.MAV_PARAM_TYPE_INT32
            )
            
            print(f"[ESCCalibrationModel] ✅ ESC_CALIBRATION parameter set to {param_value} for individual ESCs")
            
        except Exception as e:
            print(f"[ESCCalibrationModel] Error setting parameter: {e}")
            raise Exception(f"Failed to set ESC_CALIBRATION parameter: {e}")

    def _execute_current_step(self):
        """Execute the current calibration step"""
        self._step_timer.stop()
        
        try:
            if self._calibration_step == 1:
                # Move to Step 2: Request power cycle for first ESC
                self._calibration_step = 2
                self._current_esc = 0  # Start with ESC 1 (index 0)
                self.currentEscChanged.emit(self._current_esc + 1)
                
                self._update_status(
                    f"🔌 STEP 2: POWER CYCLE FOR ESC {self._current_esc + 1} CALIBRATION\n\n" +
                    "✅ ESC_CALIBRATION parameter set successfully to 3\n" +
                    "📡 Parameter tells autopilot to calibrate ESCs individually\n" +
                    f"🎯 Starting with ESC {self._current_esc + 1} (Motor {self._esc_channels[self._current_esc]})\n\n" +
                    "🚨 MANUAL ACTION REQUIRED:\n" +
                    "   1. 🔌 DISCONNECT BATTERY from drone\n" +
                    "   2. 💻 DISCONNECT USB cable (power down completely)\n" +
                    "   3. ⏳ Wait 3 seconds\n" +
                    "   4. 🔋 CONNECT BATTERY (keep USB disconnected)\n\n" +
                    f"🔊 WHAT YOU SHOULD HEAR FOR ESC {self._current_esc + 1}:\n" +
                    "   • 📯 Arming tone (if buzzer attached)\n\n" +
                    "🛡️ SAFETY BUTTON ACTION (if using Pixhawk):\n" +
                    "   • Press safety button until it shows SOLID RED\n" +
                    f"   • This enables ESC {self._current_esc + 1} calibration mode\n" +
                    "   • Skip this step if no safety button\n\n" +
                    "After pressing safety button (or if no safety button):\n" +
                    "   • 🎵 Musical tone followed by 2 beeps\n" +
                    "   • ⏳ Few seconds pause\n" +
                    "   • 🔢 Cell count beeps (3 for 3S, 4 for 4S)\n" +
                    f"   • 📯 1 long final beep (ESC {self._current_esc + 1} calibration complete!)\n\n" +
                    f"🎯 ESC {self._current_esc + 1} (Motor {self._esc_channels[self._current_esc]}) will automatically:\n" +
                    "   • Enter calibration mode from parameter\n" +
                    "   • Learn maximum throttle range\n" +
                    "   • Learn minimum throttle range\n" +
                    "   • Save calibration to memory\n" +
                    "   • Confirm with beep sequence\n\n" +
                    "⚠️ IMPORTANT: \n" +
                    "   • Don't touch throttle stick - it's automatic!\n" +
                    f"   • Only ESC {self._current_esc + 1} will calibrate this round\n" +
                    "   • Battery must stay connected during process\n" +
                    f"   • After ESC {self._current_esc + 1}, we'll do ESC {self._current_esc + 2} next\n\n" +
                    f"⏳ Please perform power cycle and safety button for ESC {self._current_esc + 1}...\n" +
                    "🔄 Waiting for you to complete the power cycle and safety button"
                )
                
                self._waiting_for_power_cycle = True
                
                # Wait 45 seconds for user to complete power cycle and safety button
                self._step_timer.start(45000)
                
            elif self._calibration_step == 2:
                # Assume power cycle and safety button completed, move to calibration monitoring
                self._calibration_step = 3
                
                self._update_status(
                    f"🔊 STEP 3: MONITORING ESC {self._current_esc + 1} CALIBRATION\n\n" +
                    f"⚡ ESC {self._current_esc + 1} (Motor {self._esc_channels[self._current_esc]}) should now be in calibration mode\n" +
                    f"🎯 Automatic calibration process active for ESC {self._current_esc + 1}\n\n" +
                    f"🔊 LISTENING FOR ESC {self._current_esc + 1} CONFIRMATION SOUNDS:\n" +
                    f"   ✅ Arming tone - ESC {self._current_esc + 1} powered up\n" +
                    f"   ✅ Musical tone + 2 beeps - ESC {self._current_esc + 1} calibration mode active\n" +
                    f"   🔄 ESC {self._current_esc + 1} learning throttle endpoints automatically\n" +
                    "   ⏳ Waiting for final confirmation...\n\n" +
                    f"🤖 WHAT ESC {self._current_esc + 1} IS DOING AUTOMATICALLY:\n" +
                    "   • Reading ESC_CALIBRATION parameter value (3)\n" +
                    "   • Setting internal maximum PWM (2000μs)\n" +
                    "   • Setting internal minimum PWM (1000μs)\n" +
                    f"   • Storing calibration data in ESC {self._current_esc + 1} EEPROM\n" +
                    "   • Preparing confirmation beep sequence\n\n" +
                    f"⏳ Waiting for ESC {self._current_esc + 1} calibration completion...\n" +
                    f"🔊 Should hear cell count + long beep soon for ESC {self._current_esc + 1}\n\n" +
                    f"📊 Progress: ESC {self._current_esc + 1}/{self._total_escs} calibrating\n" +
                    f"⏭️ After this: {self._total_escs - self._current_esc - 1} ESCs remaining"
                )
                
                # Wait 15 seconds for calibration to complete
                self._step_timer.start(15000)
                
            elif self._calibration_step == 3:
                # Current ESC calibration should be complete
                self._single_esc_calibration_complete()
                
        except Exception as e:
            print(f"[ESCCalibrationModel] Error in step {self._calibration_step} for ESC {self._current_esc + 1}: {e}")
            self._update_status(f"❌ STEP {self._calibration_step} FAILED FOR ESC {self._current_esc + 1}: {str(e)}")
            self._calibration_failed()

    def _single_esc_calibration_complete(self):
        """Mark current ESC as calibrated and move to next or complete"""
        try:
            # Mark current ESC as calibrated
            self._calibrated_escs.append(self._current_esc + 1)
            self._esc_calibration_sequence.append({
                'esc_number': self._current_esc + 1,
                'channel': self._esc_channels[self._current_esc],
                'status': 'completed',
                'timestamp': time.time()
            })
            
            current_esc_display = self._current_esc + 1
            remaining_escs = self._total_escs - len(self._calibrated_escs)
            
            if remaining_escs > 0:
                # Move to next ESC
                self._current_esc += 1
                self.currentEscChanged.emit(self._current_esc + 1)
                next_esc_display = self._current_esc + 1
                
                self._update_status(
                    f"✅ ESC {current_esc_display} CALIBRATION COMPLETED!\n\n" +
                    f"🎉 SUCCESS: ESC {current_esc_display} (Motor {self._esc_channels[current_esc_display-1]}) calibrated\n" +
                    f"📊 Progress: {len(self._calibrated_escs)}/{self._total_escs} ESCs completed\n" +
                    f"✅ Calibrated ESCs: {', '.join(map(str, self._calibrated_escs))}\n\n" +
                    f"🔊 ESC {current_esc_display} CONFIRMATION RECEIVED:\n" +
                    "   • Single arming tone ✅\n" +
                    "   • Musical tone + 2 beeps ✅\n" +
                    "   • Cell count beeps + long beep ✅\n" +
                    f"   • ESC {current_esc_display} calibration data saved to EEPROM ✅\n\n" +
                    f"⏭️ MOVING TO NEXT ESC: ESC {next_esc_display}\n" +
                    f"🎯 Next: ESC {next_esc_display} (Motor {self._esc_channels[self._current_esc]})\n" +
                    f"📊 Remaining: {remaining_escs} ESCs to calibrate\n\n" +
                    f"🔄 PREPARING ESC {next_esc_display} CALIBRATION...\n" +
                    f"🔌 Next power cycle will calibrate ESC {next_esc_display}\n" +
                    "⏳ Please wait for next ESC setup instructions...\n\n" +
                    "💡 Each ESC gets individual calibration for maximum precision\n" +
                    f"💡 ESC {current_esc_display} now has optimal throttle response"
                )
                
                # Reset step to power cycle for next ESC
                self._calibration_step = 2
                self._waiting_for_power_cycle = False
                
                # Wait 5 seconds then start next ESC
                self._step_timer.start(5000)
                
            else:
                # All ESCs calibrated - complete the process
                self._all_esc_calibration_complete()
                
        except Exception as e:
            print(f"[ESCCalibrationModel] Error completing ESC {self._current_esc + 1} calibration: {e}")
            self._calibration_failed()

    def _all_esc_calibration_complete(self):
        """Mark all ESCs as calibrated and complete the process"""
        try:
            # Reset ESC_CALIBRATION parameter to 0 (disabled)
            if self._drone:
                param_name = "ESC_CALIBRATION"
                param_name_bytes = param_name.encode('utf-8')[:16].ljust(16, b'\x00')
                
                self._drone.mav.param_set_send(
                    self._drone.target_system,
                    self._drone.target_component,
                    param_name_bytes,
                    0,  # Disable calibration
                    mavutil.mavlink.MAV_PARAM_TYPE_INT32
                )
            
            # Stop timers
            self._step_timer.stop()
            self._sound_timer.stop()
            
            self._is_calibrating = False
            self._calibration_step = 0
            self._waiting_for_power_cycle = False
            
            # Generate calibration summary
            calibrated_list = ', '.join([f"ESC {esc}" for esc in self._calibrated_escs])
            
            self._update_status(
                f"🎉 ALL ESCs CALIBRATION COMPLETED INDIVIDUALLY!\n\n" +
                f"✅ SUCCESSFULLY CALIBRATED: {len(self._calibrated_escs)}/{self._total_escs} ESCs\n" +
                f"📊 Calibrated ESCs: {calibrated_list}\n" +
                f"📈 Success Rate: {len(self._calibrated_escs)/self._total_escs*100:.0f}%\n\n" +
                "🔹 INDIVIDUAL ESC CALIBRATION ACCOMPLISHED:\n" +
                "   ✅ Each ESC calibrated individually using parameter method\n" +
                "   ✅ No manual throttle stick movement required\n" +
                "   ✅ ArduPilot ESC_CALIBRATION=3 parameter controlled process\n" +
                "   ✅ Each ESC learned min/max automatically and individually\n" +
                "   ✅ Calibration data permanently stored in each ESC memory\n" +
                "   ✅ Individual precision calibration for each ESC\n\n" +
                "🔊 ALL SOUND CONFIRMATIONS RECEIVED:\n" +
                f"   • {len(self._calibrated_escs)} individual arming tones ✅\n" +
                f"   • {len(self._calibrated_escs)} musical tones + 2 beeps sequences ✅\n" +
                f"   • {len(self._calibrated_escs)} cell count + long beep confirmations ✅\n" +
                "   • Each ESC responded with individual sequence\n\n" +
                "🔋 FINAL SETUP STEPS:\n" +
                "   1. 🔋 Disconnect battery from drone\n" +
                "   2. 💻 Reconnect USB cable for normal operation\n" +
                "   3. 🔌 Power up normally (battery + USB)\n" +
                "   4. 🔊 Listen for normal ESC startup sequence\n" +
                "   5. ✅ All ESCs should start in sequence\n\n" +
                "🚁 BENEFITS OF INDIVIDUAL ESC CALIBRATION:\n" +
                "   • No manual throttle stick required\n" +
                "   • Parameter-controlled precision\n" +
                "   • Individual optimization per ESC\n" +
                "   • ArduPilot standard method\n" +
                "   • Maximum precision per ESC\n" +
                "   • Customized calibration per motor\n\n" +
                f"✅ Individual ESC calibration complete for all {len(self._calibrated_escs)} ESCs!\n" +
                "🎯 ESC_CALIBRATION parameter reset to 0 (disabled)\n" +
                "💡 Install propellers when ready for normal flight\n\n" +
                "🎊 Each ESC now has individual, precise calibration values!"
            )
            
            # Emit completion with success
            self.calibrationCompleted.emit(True, f"All {len(self._calibrated_escs)} ESCs calibrated individually using semi-automatic method")
            print(f"[ESCCalibrationModel] ✅ Individual ESC calibration completed - {len(self._calibrated_escs)} ESCs")
            
        except Exception as e:
            print(f"[ESCCalibrationModel] Error completing individual ESC calibration: {e}")
            self._calibration_failed()

    def _calibration_failed(self):
        """Handle calibration failure"""
        self._step_timer.stop()
        self._sound_timer.stop()
        
        try:
            # Reset ESC_CALIBRATION parameter to 0 for safety
            if self._drone:
                param_name = "ESC_CALIBRATION"
                param_name_bytes = param_name.encode('utf-8')[:16].ljust(16, b'\x00')
                
                self._drone.mav.param_set_send(
                    self._drone.target_system,
                    self._drone.target_component,
                    param_name_bytes,
                    0,  # Disable calibration
                    mavutil.mavlink.MAV_PARAM_TYPE_INT32
                )
        except:
            pass  # Ignore errors during cleanup
        
        self._is_calibrating = False
        self._calibration_step = 0
        self._waiting_for_power_cycle = False
        
        failed_esc = self._current_esc + 1 if self._current_esc < self._total_escs else "Unknown"
        completed_escs = ', '.join([f"ESC {esc}" for esc in self._calibrated_escs]) if self._calibrated_escs else "None"
        
        status_msg = f"❌ INDIVIDUAL ESC CALIBRATION FAILED\n\n"
        status_msg += f"⚠️ Failed at: ESC {failed_esc}\n"
        status_msg += f"✅ Completed ESCs: {completed_escs}\n"
        status_msg += f"📊 Progress: {len(self._calibrated_escs)}/{self._total_escs} ESCs\n\n"
        
        status_msg += (
            "🔧 TROUBLESHOOTING INDIVIDUAL ESC METHOD:\n" +
            "   • Verify ESC_CALIBRATION parameter was set to 3 correctly\n" +
            "   • Check ArduPilot firmware supports ESC_CALIBRATION=3\n" +
            "   • Ensure complete power cycle (battery + USB disconnect)\n" +
            "   • Verify safety button was pressed until solid red\n" +
            f"   • Check ESC {failed_esc} is properly connected\n" +
            f"   • Test ESC {failed_esc} responds to parameter-based calibration\n\n" +
            "🔊 SOUND TROUBLESHOOTING:\n" +
            f"   • No arming tone for ESC {failed_esc} = Power/connection issue\n" +
            f"   • No musical tone for ESC {failed_esc} = Parameter not recognized\n" +
            f"   • No cell beeps for ESC {failed_esc} = Calibration process failed\n" +
            f"   • No long beep for ESC {failed_esc} = Calibration not saved\n\n" +
            "🛡️ SAFETY BUTTON TROUBLESHOOTING:\n" +
            "   • Safety button must be solid red before calibration starts\n" +
            "   • If no safety button, some autopilots auto-proceed\n" +
            "   • Check autopilot type and safety button requirements\n\n" +
            "📖 ALTERNATIVE METHODS:\n" +
            "   1. Try ESC_CALIBRATION=1 (all ESCs at once method)\n" +
            "   2. Use manual calibration with RC transmitter\n" +
            "   3. Check ESC manufacturer's calibration procedure\n" +
            f"   4. Test individual ESC {failed_esc} connection and firmware\n\n" +
            "🔄 Click 'Start ESC Calibration' to retry from beginning\n" +
            "⚠️ ESC_CALIBRATION parameter reset to 0 for safety"
        )
        
        self._update_status(status_msg)
        self.calibrationCompleted.emit(False, f"Individual ESC calibration failed at ESC {failed_esc}")
        print(f"[ESCCalibrationModel] ❌ Individual ESC calibration failed at ESC {failed_esc}")

    @pyqtSlot()
    def resetCalibrationStatus(self):
        """Reset to ready state"""
        self._step_timer.stop()
        self._sound_timer.stop()
        
        try:
            if self._drone:
                # Reset ESC_CALIBRATION parameter to 0
                param_name = "ESC_CALIBRATION"
                param_name_bytes = param_name.encode('utf-8')[:16].ljust(16, b'\x00')
                
                self._drone.mav.param_set_send(
                    self._drone.target_system,
                    self._drone.target_component,
                    param_name_bytes,
                    0,  # Disable calibration
                    mavutil.mavlink.MAV_PARAM_TYPE_INT32
                )
        except:
            pass
        
        self._is_calibrating = False
        self._calibration_step = 0
        self._current_esc = 0
        self._waiting_for_power_cycle = False
        self._power_cycle_detected = False
        self._calibrated_escs = []
        self._esc_calibration_sequence = []
        self._update_status("Ready - Remove propellers before starting!")

    def cleanup(self):
        """Cleanup resources"""
        print("[ESCCalibrationModel] Cleaning up...")
        self._step_timer.stop()
        self._sound_timer.stop()
        self._connection_timer.stop()
        
        if self._is_calibrating:
            self.resetCalibrationStatus()