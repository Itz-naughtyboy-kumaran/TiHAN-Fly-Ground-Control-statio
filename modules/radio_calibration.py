from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QTimer
from pymavlink import mavutil
import time
import math

class RadioCalibrationModel(QObject):
    calibrationStatusChanged = pyqtSignal()
    calibrationProgressChanged = pyqtSignal()
    radioChannelsChanged = pyqtSignal()
    statusMessageChanged = pyqtSignal()
    
    def __init__(self, drone_model):
        super().__init__()
        self._drone_model = drone_model
        self._calibration_active = False
        self._calibration_step = 0  # 0: not started, 1: move to extremes, 2: center sticks, 3: complete
        self._calibration_progress = 0
        self._status_message = "Ready for radio calibration"
        
        # Radio channel data (PWM values) - support up to 18 channels
        # Initialize with standard RC values (1500 center, except throttle at 1000)
        self._radio_channels = [1500] * 18  
        self._radio_channels[2] = 1000  # Throttle starts at minimum
        
        # Calibration values
        self._channel_min = [1500] * 18      # Start with center values
        self._channel_max = [1500] * 18      # Start with center values
        self._channel_trim = [1500] * 18     # Center/trim values
        
        # Initialize throttle properly
        self._channel_min[2] = 1000    # Throttle minimum
        self._channel_trim[2] = 1000   # Throttle trim at minimum
        
        # Calibration parameters
        self._calibration_timeout = 60  # 60 seconds timeout for each step
        self._samples_collected = 0
        self._required_samples = 50      # Samples needed for each step
        self._step1_samples = 0          # Samples for extreme positions
        self._step2_samples = 0          # Samples for center positions
        
        # Min/max tracking for step 1 (extreme positions)
        self._step1_min = [2000] * 18    # Track minimum values seen
        self._step1_max = [1000] * 18    # Track maximum values seen
        
        # Channel mapping - this is crucial for proper calibration
        # ArduPilot standard channel mapping:
        # Channel 1: Roll (Aileron)
        # Channel 2: Pitch (Elevator) 
        # Channel 3: Throttle
        # Channel 4: Yaw (Rudder)
        self._channel_names = [
            "Roll (Ch1)", "Pitch (Ch2)", "Throttle (Ch3)", "Yaw (Ch4)",
            "Channel 5", "Channel 6", "Channel 7", "Channel 8",
            "Channel 9", "Channel 10", "Channel 11", "Channel 12",
            "Channel 13", "Channel 14", "Channel 15", "Channel 16",
            "Channel 17", "Channel 18"
        ]
        
        # Timer for updating radio channel data
        self._update_timer = QTimer()
        self._update_timer.timeout.connect(self._update_radio_channels)
        
        # Timer for calibration timeout
        self._calibration_timer = QTimer()
        self._calibration_timer.timeout.connect(self._calibration_timeout_handler)
        
        # Timer for automatic step progression
        self._step_timer = QTimer()
        self._step_timer.timeout.connect(self._check_step_completion)
        
        print("[RadioCalibrationModel] Initialized with proper channel mapping")
    
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def calibrationActive(self):
        return self._calibration_active
    
    @pyqtProperty(int, notify=calibrationProgressChanged)
    def calibrationProgress(self):
        return self._calibration_progress
    
    @pyqtProperty(int, notify=calibrationStatusChanged)
    def calibrationStep(self):
        return self._calibration_step
    
    @pyqtProperty(str, notify=statusMessageChanged)
    def statusMessage(self):
        return self._status_message
    
    @pyqtProperty('QVariantList', notify=radioChannelsChanged)
    def radioChannels(self):
        return self._radio_channels[:12]  # Return first 12 channels for UI
    
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def isDroneConnected(self):
        return self._drone_model.isConnected if self._drone_model else False
    
    def _set_status_message(self, message):
        if self._status_message != message:
            self._status_message = message
            print(f"[RadioCalibration] {message}")
            self.statusMessageChanged.emit()
    
    def _set_calibration_progress(self, progress):
        if self._calibration_progress != progress:
            self._calibration_progress = max(0, min(100, progress))
            self.calibrationProgressChanged.emit()
    
    @pyqtSlot()
    def startCalibration(self):
        """Start radio calibration process following Mission Planner workflow"""
        if not self.isDroneConnected:
            self._set_status_message("Cannot start calibration - drone not connected")
            return False
        
        if self._calibration_active:
            self._set_status_message("Calibration already in progress")
            return False
        
        print("[RadioCalibration] Starting Mission Planner style radio calibration...")
        
        # Reset calibration state
        self._calibration_active = True
        self._calibration_step = 1
        self._calibration_progress = 0
        self._samples_collected = 0
        self._step1_samples = 0
        self._step2_samples = 0
        
        # Initialize calibration values from current readings
        current_values = self._get_current_radio_values()
        for i in range(18):
            current_value = current_values[i] if current_values[i] > 0 else (1000 if i == 2 else 1500)
            self._channel_min[i] = current_value
            self._channel_max[i] = current_value
            self._channel_trim[i] = current_value
            self._step1_min[i] = current_value
            self._step1_max[i] = current_value
        
        # Special handling for throttle (channel 3, index 2)
        self._channel_min[2] = min(self._channel_min[2], 1000)
        self._channel_trim[2] = self._channel_min[2]
        
        self._set_status_message("Step 1: Move all sticks, knobs and switches to their extreme positions")
        
        # Start the calibration process
        self._start_rc_calibration_mavlink()
        
        # Start timers
        self._update_timer.start(20)  # Update every 20ms for responsive UI
        self._calibration_timer.start(self._calibration_timeout * 1000)
        self._step_timer.start(100)  # Check step completion every 100ms
        
        self.calibrationStatusChanged.emit()
        return True
    
    @pyqtSlot()
    def stopCalibration(self):
        """Stop radio calibration process"""
        print("[RadioCalibration] Stopping radio calibration...")
        
        if self._calibration_active:
            self._stop_rc_calibration_mavlink()
        
        self._calibration_active = False
        self._calibration_step = 0
        self._calibration_progress = 0
        
        # Stop all timers
        self._update_timer.stop()
        self._calibration_timer.stop()
        self._step_timer.stop()
        
        self._set_status_message("Radio calibration stopped")
        self.calibrationStatusChanged.emit()
    
    @pyqtSlot()
    def nextCalibrationStep(self):
        """Advance to next calibration step - called from UI dialogs"""
        if not self._calibration_active:
            return
        
        if self._calibration_step == 1:
            # Step 1 complete: Moving from extreme positions to center positions
            print("[RadioCalibration] Step 1 complete - captured extreme positions")
            
            # Save the extreme values captured in step 1
            for i in range(18):
                self._channel_min[i] = self._step1_min[i]
                self._channel_max[i] = self._step1_max[i]
                
                # Validate ranges
                if abs(self._channel_max[i] - self._channel_min[i]) < 100:
                    print(f"[RadioCalibration WARNING] Channel {i+1} ({self._channel_names[i]}) has small range: {abs(self._channel_max[i] - self._channel_min[i])}us")
            
            # Move to step 2: Center sticks
            self._calibration_step = 2
            self._step2_samples = 0
            self._set_calibration_progress(66)
            self._set_status_message("Step 2: Center all sticks and set throttle to minimum")
            
            # Reset calibration timer for next step
            self._calibration_timer.stop()
            self._calibration_timer.start(self._calibration_timeout * 1000)
        
        elif self._calibration_step == 2:
            # Step 2 complete: Center positions captured
            print("[RadioCalibration] Step 2 complete - captured center positions")
            
            # Calculate trim values from center positions
            for i in range(18):
                # For throttle channel (channel 3, index 2), trim should be at minimum
                if i == 2:  # Throttle channel
                    self._channel_trim[i] = self._channel_min[i]
                    print(f"[RadioCalibration] Throttle trim set to minimum: {self._channel_trim[i]}")
                else:
                    # For other channels, trim is current center position
                    self._channel_trim[i] = self._radio_channels[i]
                    print(f"[RadioCalibration] {self._channel_names[i]} trim set to: {self._channel_trim[i]}")
            
            # Complete calibration
            self._calibration_step = 3
            self._set_calibration_progress(100)
            self._set_status_message("Calibration complete - Review values and save settings")
            self._complete_calibration()
        
        self.calibrationStatusChanged.emit()
    
    def _get_current_radio_values(self):
        """Get current radio channel values from drone"""
        current_values = [0] * 18
        
        if not self._drone_model.drone_connection:
            return current_values
        
        try:
            connection = self._drone_model.drone_connection
            
            # Try to get latest RC_CHANNELS message
            msg = connection.recv_match(type='RC_CHANNELS', blocking=False, timeout=0.1)
            
            if msg:
                current_values = [
                    msg.chan1_raw, msg.chan2_raw, msg.chan3_raw, msg.chan4_raw,
                    msg.chan5_raw, msg.chan6_raw, msg.chan7_raw, msg.chan8_raw,
                    msg.chan9_raw, msg.chan10_raw, msg.chan11_raw, msg.chan12_raw,
                    msg.chan13_raw, msg.chan14_raw, msg.chan15_raw, msg.chan16_raw,
                    msg.chan17_raw, msg.chan18_raw
                ]
                
                print(f"[RadioCalibration] Current values - Ch1:{current_values[0]}, Ch2:{current_values[1]}, Ch3:{current_values[2]}, Ch4:{current_values[3]}")
        
        except Exception as e:
            print(f"[RadioCalibration] Could not get current radio values: {e}")
        
        return current_values
    
    @pyqtSlot()
    def saveCalibration(self):
        """Save radio calibration parameters to drone"""
        if not self.isDroneConnected:
            self._set_status_message("Cannot save - drone not connected")
            return False
        
        if self._calibration_step != 3:
            self._set_status_message("Complete calibration process first")
            return False
        
        print("[RadioCalibration] Saving radio calibration parameters...")
        self._set_status_message("Saving radio calibration parameters...")
        
        try:
            # Validate calibration data before saving
            if not self._validate_calibration_data():
                self._set_status_message("Invalid calibration data - please recalibrate")
                return False
            
            # Save RC parameters to drone using MAVLink parameter protocol
            self._save_rc_parameters()
            
            # Display calibration summary (like Mission Planner)
            self._display_calibration_summary()
            
            # Stop calibration
            self.stopCalibration()
            self._set_status_message("Radio calibration saved successfully")
            return True
            
        except Exception as e:
            print(f"[RadioCalibration ERROR] Failed to save calibration: {e}")
            self._set_status_message(f"Failed to save calibration: {e}")
            return False
    
    def _validate_calibration_data(self):
        """Validate calibration data similar to Mission Planner checks"""
        valid = True
        
        for i in range(8):  # Check first 8 channels
            min_val = self._channel_min[i]
            max_val = self._channel_max[i]
            trim_val = self._channel_trim[i]
            channel_name = self._channel_names[i]
            
            # Check if we have reasonable range (at least 200us difference)
            range_us = abs(max_val - min_val)
            if range_us < 200:
                print(f"[RadioCalibration WARNING] {channel_name} has insufficient range: {range_us}us")
                if range_us < 100:  # Really bad
                    valid = False
            
            # Check if values are in reasonable PWM range (800-2200us)
            if min_val < 800 or max_val > 2200:
                print(f"[RadioCalibration WARNING] {channel_name} values out of range: min={min_val}, max={max_val}")
                if min_val < 700 or max_val > 2300:  # Really out of range
                    valid = False
            
            # Check if trim is within min/max range
            if trim_val < min_val or trim_val > max_val:
                print(f"[RadioCalibration WARNING] {channel_name} trim out of range: trim={trim_val}, min={min_val}, max={max_val}")
                # Fix trim value
                self._channel_trim[i] = (min_val + max_val) // 2
                if i == 2:  # Throttle should be at minimum
                    self._channel_trim[i] = min_val
        
        return valid
    
    def _display_calibration_summary(self):
        """Display calibration summary like Mission Planner"""
        print("\n[RadioCalibration] ===== CALIBRATION SUMMARY =====")
        
        for i in range(8):
            min_val = self._channel_min[i]
            max_val = self._channel_max[i]
            trim_val = self._channel_trim[i]
            range_val = max_val - min_val
            channel_name = self._channel_names[i]
            
            print(f"  {channel_name:15}: Min={min_val:4d}  Max={max_val:4d}  Trim={trim_val:4d}  Range={range_val:3d}us")
        
        print("=============================================\n")
    
    def _check_step_completion(self):
        """Check if current calibration step has enough samples"""
        if not self._calibration_active:
            return
        
        if self._calibration_step == 1:
            # Step 1: Check if we have good range data from moving sticks
            ranges_detected = 0
            total_range = 0
            
            for i in range(4):  # Check first 4 main channels
                range_detected = abs(self._step1_max[i] - self._step1_min[i])
                total_range += range_detected
                if range_detected > 300:  # Good range detected (>300us)
                    ranges_detected += 1
                    print(f"[RadioCalibration] {self._channel_names[i]} range: {range_detected}us (Min: {self._step1_min[i]}, Max: {self._step1_max[i]})")
            
            # Update progress based on ranges detected
            progress = min(60, (ranges_detected / 4.0) * 60)
            self._set_calibration_progress(int(progress))
            
            # Update status with range info
            if ranges_detected > 0:
                self._set_status_message(f"Step 1: {ranges_detected}/4 channels have good range - Continue moving sticks!")
            
        elif self._calibration_step == 2:
            # Step 2: Just collect samples for center positions
            self._step2_samples += 1
            if self._step2_samples >= self._required_samples:
                # Enough center samples collected
                progress = 66 + min(33, (self._step2_samples / self._required_samples) * 33)
                self._set_calibration_progress(int(progress))
    
    def _start_rc_calibration_mavlink(self):
        """Start RC calibration using MAVLink commands"""
        if not self._drone_model.drone_connection:
            return
        
        try:
            connection = self._drone_model.drone_connection
            
            # Request RC_CHANNELS messages at higher rate during calibration (50Hz)
            connection.mav.command_long_send(
                connection.target_system,
                connection.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0,
                mavutil.mavlink.MAVLINK_MSG_ID_RC_CHANNELS,  # RC_CHANNELS message
                20000,  # 20ms interval (50Hz)
                0, 0, 0, 0, 0
            )
            
            print("[RadioCalibration] Started RC calibration mode - requesting 50Hz RC_CHANNELS")
            
        except Exception as e:
            print(f"[RadioCalibration ERROR] Failed to start RC calibration: {e}")
    
    def _stop_rc_calibration_mavlink(self):
        """Stop RC calibration using MAVLink commands"""
        if not self._drone_model.drone_connection:
            return
        
        try:
            connection = self._drone_model.drone_connection
            
            # Reset RC_CHANNELS message rate to normal (5Hz)
            connection.mav.command_long_send(
                connection.target_system,
                connection.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0,
                mavutil.mavlink.MAVLINK_MSG_ID_RC_CHANNELS,  # RC_CHANNELS message
                200000,  # 200ms interval (5Hz) - normal rate
                0, 0, 0, 0, 0
            )
            
            print("[RadioCalibration] Stopped RC calibration mode - reset to 5Hz RC_CHANNELS")
            
        except Exception as e:
            print(f"[RadioCalibration ERROR] Failed to stop RC calibration: {e}")
    
    def _update_radio_channels(self):
        """Update radio channel values from drone with proper channel mapping"""
        if not self._calibration_active or not self._drone_model.drone_connection:
            return
        
        try:
            connection = self._drone_model.drone_connection
            
            # Get latest RC_CHANNELS message
            msg = connection.recv_match(type='RC_CHANNELS', blocking=False, timeout=0.01)
            
            if msg:
                # Extract channel values in correct order
                # IMPORTANT: These correspond directly to RC channels 1-18
                new_channels = [
                    msg.chan1_raw,   # Channel 1: Roll
                    msg.chan2_raw,   # Channel 2: Pitch  
                    msg.chan3_raw,   # Channel 3: Throttle
                    msg.chan4_raw,   # Channel 4: Yaw
                    msg.chan5_raw,   # Channel 5
                    msg.chan6_raw,   # Channel 6
                    msg.chan7_raw,   # Channel 7
                    msg.chan8_raw,   # Channel 8
                    msg.chan9_raw,   # Channel 9
                    msg.chan10_raw,  # Channel 10
                    msg.chan11_raw,  # Channel 11
                    msg.chan12_raw,  # Channel 12
                    msg.chan13_raw,  # Channel 13
                    msg.chan14_raw,  # Channel 14
                    msg.chan15_raw,  # Channel 15
                    msg.chan16_raw,  # Channel 16
                    msg.chan17_raw,  # Channel 17
                    msg.chan18_raw   # Channel 18
                ]
                
                # Update channel values and calibration data
                channels_updated = 0
                for i, value in enumerate(new_channels):
                    if value > 0 and value != 65535:  # Valid channel data (65535 = no signal)
                        self._radio_channels[i] = value
                        channels_updated += 1
                        print(i,value)
                        # Update calibration data based on current step
                        if self._calibration_step == 1:
                            # Step 1: Track extreme positions
                            if value < self._step1_min[i]:
                                self._step1_min[i] = value
                                print(f"[RadioCalibration] {self._channel_names[i]} new minimum: {value}")
                            if value > self._step1_max[i]:
                                self._step1_max[i] = value
                                print(f"[RadioCalibration] {self._channel_names[i]} new maximum: {value}")
                
                # Only count as valid update if we got reasonable number of channels
                if channels_updated >= 4:
                    self._samples_collected += 1
                    if self._calibration_step == 1:
                        self._step1_samples += 1
                    elif self._calibration_step == 2:
                        self._step2_samples += 1
                    
                    # Emit signal to update UI
                    self.radioChannelsChanged.emit()
                
        except Exception as e:
            print(f"[RadioCalibration ERROR] Failed to update radio channels: {e}")
    
    def _complete_calibration(self):
        """Complete the calibration process"""
        print("[RadioCalibration] Completing calibration...")
        
        # Stop data collection but keep calibration active for saving
        self._step_timer.stop()
        self._calibration_timer.stop()
        
        # Final validation and adjustments
        for i in range(18):
            # Ensure min < max
            if self._channel_min[i] > self._channel_max[i]:
                self._channel_min[i], self._channel_max[i] = self._channel_max[i], self._channel_min[i]
            
            # Ensure trim is within range
            if self._channel_trim[i] < self._channel_min[i]:
                self._channel_trim[i] = self._channel_min[i]
            elif self._channel_trim[i] > self._channel_max[i]:
                self._channel_trim[i] = self._channel_max[i]
            
            # Special case for throttle: ensure trim is at minimum
            if i == 2:  # Throttle channel
                self._channel_trim[i] = self._channel_min[i]
        
        # Display results
        self._display_calibration_summary()
    
    def _save_rc_parameters(self):
        """Save RC calibration parameters to drone using MAVLink parameter protocol"""
        if not self._drone_model.drone_connection:
            raise Exception("No drone connection available")
        
        connection = self._drone_model.drone_connection
        
        # ArduPilot RC parameter names (first 8 channels)
        rc_params = {}
        for i in range(8):
            channel_num = i + 1  # RC parameters are 1-indexed
            rc_params[f'RC{channel_num}_MIN'] = self._channel_min[i]
            rc_params[f'RC{channel_num}_MAX'] = self._channel_max[i]
            rc_params[f'RC{channel_num}_TRIM'] = self._channel_trim[i]
        
        # Send parameter set commands
        saved_count = 0
        for param_name, param_value in rc_params.items():
            if param_value > 0:  # Only set valid parameters
                try:
                    # Send parameter set command
                    connection.mav.param_set_send(
                        connection.target_system,
                        connection.target_component,
                        param_name.encode('utf-8')[:16],  # MAVLink param names are max 16 chars
                        float(param_value),
                        mavutil.mavlink.MAV_PARAM_TYPE_INT16
                    )
                    
                    print(f"[RadioCalibration] Set {param_name} = {param_value}")
                    saved_count += 1
                    time.sleep(0.05)  # Small delay between parameter sets
                    
                except Exception as e:
                    print(f"[RadioCalibration ERROR] Failed to set parameter {param_name}: {e}")
        
        print(f"[RadioCalibration] Saved {saved_count} RC parameters to drone")
        
        # Send parameter save command to write to EEPROM
        try:
            connection.mav.command_long_send(
                connection.target_system,
                connection.target_component,
                mavutil.mavlink.MAV_CMD_PREFLIGHT_STORAGE,
                0,
                1,  # Save parameters to EEPROM
                0, 0, 0, 0, 0, 0
            )
            print("[RadioCalibration] Sent command to save parameters to EEPROM")
        except Exception as e:
            print(f"[RadioCalibration ERROR] Failed to save parameters to EEPROM: {e}")
    
    def _calibration_timeout_handler(self):
        """Handle calibration timeout"""
        print(f"[RadioCalibration] Step {self._calibration_step} timeout reached")
        self._set_status_message(f"Step {self._calibration_step} timeout - please try again")
        # Don't auto-stop, let user decide
        self._calibration_timer.stop()
    
    @pyqtSlot(str)
    def bindSpectrum(self, bind_type):
        """Initiate Spektrum receiver binding"""
        if not self.isDroneConnected:
            self._set_status_message("Cannot bind - drone not connected")
            return
        
        if self._calibration_active:
            self._set_status_message("Cannot bind during calibration - stop calibration first")
            return
        
        print(f"[RadioCalibration] Starting Spektrum {bind_type} bind process")
        self._set_status_message(f"Binding {bind_type} - Put receiver in bind mode now")
        
        try:
            connection = self._drone_model.drone_connection
            
            # Spektrum bind command mapping
            bind_commands = {
                'DSM2': 0,  # DSM2 bind
                'DSMX': 1,  # DSMX bind  
                'DSME': 2   # DSM2/DSMX auto-detect
            }
            
            bind_value = bind_commands.get(bind_type, 1)
            
            # Send bind command using MAVLink START_RX_PAIR command
            connection.mav.command_long_send(
                connection.target_system,
                connection.target_component,
                mavutil.mavlink.MAV_CMD_START_RX_PAIR,  # Receiver pairing command
                0,
                bind_value,  # Bind type parameter
                0, 0, 0, 0, 0, 0
            )
            
            print(f"[RadioCalibration] Spektrum {bind_type} bind command sent")
            
            # Set a timer to update status after bind attempt
            QTimer.singleShot(8000, lambda: self._set_status_message(f"{bind_type} bind complete - Check receiver LED status"))
            
        except Exception as e:
            print(f"[RadioCalibration ERROR] Failed to initiate {bind_type} bind: {e}")
            self._set_status_message(f"Failed to initiate {bind_type} bind: {e}")
    
    @pyqtSlot(result='QVariantList')
    def getChannelInfo(self):
        """Get detailed channel information for UI with proper channel mapping"""
        channel_info = []
        
        for i in range(12):
            # Determine min/max values based on calibration step
            if self._calibration_step >= 1 and self._calibration_active:
                min_val = self._step1_min[i] if self._step1_min[i] < 1900 else self._channel_min[i]
                max_val = self._step1_max[i] if self._step1_max[i] > 1100 else self._channel_max[i]
            else:
                min_val = self._channel_min[i]
                max_val = self._channel_max[i]
            
            info = {
                'name': self._channel_names[i],
                'current': self._radio_channels[i],
                'min': min_val,
                'max': max_val,
                'trim': self._channel_trim[i],
                'active': self._radio_channels[i] > 900 and self._radio_channels[i] < 2200  # Active if reasonable PWM signal
            }
            channel_info.append(info)
        
        return channel_info
    
    def cleanup(self):
        """Clean up resources"""
        print("[RadioCalibrationModel] Cleaning up resources...")
        
        if self._calibration_active:
            self.stopCalibration()
        
        # Stop all timers
        for timer in [self._update_timer, self._calibration_timer, self._step_timer]:
            if timer:
                timer.stop()
        
        print("[RadioCalibrationModel] Cleanup completed")