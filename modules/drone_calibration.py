# Enhanced drone_calibration.py - Added GPS/altitude functionality and fixed nose positions
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QTimer
from pymavlink import mavutil
import time
import math

class CalibrationModel(QObject):
    # Signals for QML
    calibrationStatusChanged = pyqtSignal()
    feedbackMessageChanged = pyqtSignal()
    levelCalibrationProgressChanged = pyqtSignal()
    accelCalibrationProgressChanged = pyqtSignal()
    positionCheckChanged = pyqtSignal()
    altitudeDataChanged = pyqtSignal()  # New signal for altitude updates
    gpsDataChanged = pyqtSignal()       # New signal for GPS updates
    
    def __init__(self, drone_model):
        super().__init__()
        self._drone_model = drone_model
        
        # Connect to drone model signals to monitor connection status
        if self._drone_model:
            self._drone_model.droneConnectedChanged.connect(self._on_drone_connection_changed)
        
        # Level calibration properties
        self._level_calibration_active = False
        self._level_calibration_complete = False
        
        # Accelerometer calibration properties
        self._accel_calibration_active = False
        self._accel_calibration_complete = False
        self._current_step = 0
        self._completed_steps = [False] * 6  # 6 positions: Level → Left → Right → Nose Down → Nose Up → Back
        self._all_positions_completed = False
        
        # Position names for feedback (corrected sequence)
        self._position_names = ["Level", "Left", "Right", "Nose Down", "Nose Up", "Back"]
        
        # Position checking properties
        self._current_roll = 0.0
        self._current_pitch = 0.0
        self._current_yaw = 0.0
        self._position_tolerance = 15.0  # degrees tolerance for position checking
        self._is_position_correct = False
        self._position_check_message = ""
        self._position_check_active = False
        
        # GPS and Altitude properties
        self._current_altitude = 0.0
        self._correct_altitude = 0.0  # Target/reference altitude
        self._gps_latitude = 0.0
        self._gps_longitude = 0.0
        self._gps_fix_type = 0
        self._satellites_visible = 0
        self._hdop = 99.99
        self._vdop = 99.99
        
        # Additional calibration states
        self._compass_calibration_active = False
        self._compass_calibration_complete = False
        self._radio_calibration_active = False
        self._radio_calibration_complete = False
        self._esc_calibration_active = False
        self._esc_calibration_complete = False
        self._servo_calibration_active = False
        self._servo_calibration_complete = False
        
        # General properties
        self._feedback_message = ""
        self._all_calibrations_complete = False
        
        # Enhanced auto-reconnection properties
        self._is_rebooting = False
        self._last_connection_string = ""
        self._last_connection_id = ""
        self._reconnection_attempts = 0
        self._max_reconnection_attempts = 10
        self._auto_reconnect_enabled = True
        self._connection_lost_time = None
        
        # Timers
        self._level_timer = QTimer()
        self._level_timer.setSingleShot(True)
        self._level_timer.timeout.connect(self._complete_level_calibration)
        
        self._feedback_timer = QTimer()
        self._feedback_timer.setSingleShot(True)
        self._feedback_timer.timeout.connect(self._clear_feedback)
        
        # Position monitoring timer
        self._position_timer = QTimer()
        self._position_timer.timeout.connect(self._update_telemetry_data)
        self._position_timer.start(100)  # Update telemetry every 100ms
        
        # Position check timer for stability
        self._position_stability_timer = QTimer()
        self._position_stability_timer.setSingleShot(True)
        self._position_stability_timer.timeout.connect(self._on_position_stable)
        
        # Enhanced auto-reconnection timer
        self._reconnect_timer = QTimer()
        self._reconnect_timer.setSingleShot(False)
        self._reconnect_timer.timeout.connect(self._attempt_reconnection)
        
        # Heartbeat monitor timer
        self._heartbeat_timer = QTimer()
        self._heartbeat_timer.timeout.connect(self._check_connection_health)
        self._heartbeat_timer.start(2000)
        
        # Connection stability timer
        self._stability_timer = QTimer()
        self._stability_timer.setSingleShot(True)
        self._stability_timer.timeout.connect(self._on_connection_stable)
        
        print("[CalibrationModel] Initialized with GPS/altitude support and position checking system")
    
    # GPS and Altitude properties
    @pyqtProperty(float, notify=altitudeDataChanged)
    def currentAltitude(self):
        return self._current_altitude
    
    @pyqtProperty(float, notify=altitudeDataChanged)
    def correctAltitude(self):
        return self._correct_altitude
    
    @pyqtProperty(float, notify=gpsDataChanged)
    def gpsLatitude(self):
        return self._gps_latitude
    
    @pyqtProperty(float, notify=gpsDataChanged)
    def gpsLongitude(self):
        return self._gps_longitude
    
    @pyqtProperty(int, notify=gpsDataChanged)
    def gpsFixType(self):
        return self._gps_fix_type
    
    @pyqtProperty(int, notify=gpsDataChanged)
    def satellitesVisible(self):
        return self._satellites_visible
    
    @pyqtProperty(float, notify=gpsDataChanged)
    def hdop(self):
        return self._hdop
    
    @pyqtProperty(float, notify=gpsDataChanged)
    def vdop(self):
        return self._vdop
    
    # Position checking properties
    @pyqtProperty(float, notify=positionCheckChanged)
    def currentRoll(self):
        return self._current_roll
    
    @pyqtProperty(float, notify=positionCheckChanged)
    def currentPitch(self):
        return self._current_pitch
    
    @pyqtProperty(float, notify=positionCheckChanged)
    def currentYaw(self):
        return self._current_yaw
    
    @pyqtProperty(bool, notify=positionCheckChanged)
    def isPositionCorrect(self):
        return self._is_position_correct
    
    @pyqtProperty(str, notify=positionCheckChanged)
    def positionCheckMessage(self):
        return self._position_check_message
    
    @pyqtProperty(bool, notify=positionCheckChanged)
    def positionCheckActive(self):
        return self._position_check_active
    
    # Additional calibration properties
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def compassCalibrationActive(self):
        return self._compass_calibration_active
    
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def compassCalibrationComplete(self):
        return self._compass_calibration_complete
    
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def radioCalibrationActive(self):
        return self._radio_calibration_active
    
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def radioCalibrationComplete(self):
        return self._radio_calibration_complete
    
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def escCalibrationActive(self):
        return self._esc_calibration_active
    
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def escCalibrationComplete(self):
        return self._esc_calibration_complete
    
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def servoCalibrationActive(self):
        return self._servo_calibration_active
    
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def servoCalibrationComplete(self):
        return self._servo_calibration_complete
    
    @pyqtSlot()
    def _update_telemetry_data(self):
        """Update current drone telemetry data including attitude, GPS, and altitude"""
        if not self.isDroneConnected or not self._drone_model.drone_connection:
            return
            
        try:
            # Get attitude data
            attitude_msg = self._drone_model.drone_connection.recv_match(
                type='ATTITUDE', blocking=False, timeout=0.1
            )
            
            if attitude_msg:
                # Convert from radians to degrees
                self._current_roll = math.degrees(attitude_msg.roll)
                self._current_pitch = math.degrees(attitude_msg.pitch)
                self._current_yaw = math.degrees(attitude_msg.yaw)
                
                # Update position check if active
                if self._position_check_active:
                    self._check_current_position()
                
                self.positionCheckChanged.emit()
            
            # Get GPS data
            gps_msg = self._drone_model.drone_connection.recv_match(
                type='GPS_RAW_INT', blocking=False, timeout=0.1
            )
            
            if gps_msg:
                self._gps_latitude = gps_msg.lat / 1e7  # Convert from 1e7 degrees
                self._gps_longitude = gps_msg.lon / 1e7
                self._gps_fix_type = gps_msg.fix_type
                self._satellites_visible = gps_msg.satellites_visible
                self._hdop = gps_msg.eph / 100.0 if gps_msg.eph != 65535 else 99.99
                self._vdop = gps_msg.epv / 100.0 if gps_msg.epv != 65535 else 99.99
                self.gpsDataChanged.emit()
            
            # Get altitude data
            global_pos_msg = self._drone_model.drone_connection.recv_match(
                type='GLOBAL_POSITION_INT', blocking=False, timeout=0.1
            )
            
            if global_pos_msg:
                self._current_altitude = global_pos_msg.relative_alt / 1000.0  # Convert from mm to m
                
                # Set correct altitude based on GPS and current position
                if self._gps_fix_type >= 3:  # 3D fix
                    # Use current altitude as reference for "correct" altitude
                    if self._correct_altitude == 0.0:
                        self._correct_altitude = self._current_altitude
                
                self.altitudeDataChanged.emit()
                
        except Exception as e:
            print(f"[CalibrationModel] Error reading telemetry: {e}")
    
    @pyqtSlot()
    def setCorrectAltitude(self):
        """Set current altitude as the correct/reference altitude"""
        self._correct_altitude = self._current_altitude
        self.altitudeDataChanged.emit()
        self._set_feedback(f"✅ Reference altitude set to {self._correct_altitude:.2f}m")
    
    def _check_current_position(self):
        """Check if drone is in the required position with GPS-based orientation correction"""
        if not self._position_check_active:
            return
            
        required_position = None
        
        # Determine required position based on calibration state
        if self._level_calibration_active:
            required_position = "Level"
        elif self._accel_calibration_active:
            required_position = self._position_names[self._current_step]
        else:
            return
        
        # Check position based on required orientation with GPS correction
        is_correct, message = self._is_in_required_position(required_position)
        
        if is_correct != self._is_position_correct:
            self._is_position_correct = is_correct
            self._position_check_message = message
            self.positionCheckChanged.emit()
            
            # If position becomes correct, start stability timer
            if is_correct:
                self._position_stability_timer.start(2000)  # Wait 2 seconds for stability
            else:
                self._position_stability_timer.stop()
    
    def _is_in_required_position(self, position_name):
        """Check if drone is in the specified position with GPS-corrected nose directions"""
        tolerance = self._position_tolerance
        
        # Get GPS heading correction if available
        gps_heading_offset = 0.0
        if self._gps_fix_type >= 3:  # 3D fix available
            # Use yaw as GPS-corrected heading
            gps_heading_offset = self._current_yaw
        
        if position_name == "Level":
            # Level: Roll and Pitch should be close to 0
            if abs(self._current_roll) <= tolerance and abs(self._current_pitch) <= tolerance:
                return True, f"✅ Drone is level (Roll: {self._current_roll:.1f}°, Pitch: {self._current_pitch:.1f}°)"
            else:
                return False, f"⚠️ Place drone level - Current: Roll {self._current_roll:.1f}°, Pitch {self._current_pitch:.1f}°"
                
        elif position_name == "Left":
            # Left side: Roll should be around -90°
            target_roll = -90
            if abs(self._current_roll - target_roll) <= tolerance and abs(self._current_pitch) <= tolerance:
                return True, f"✅ Drone is on left side (Roll: {self._current_roll:.1f}°)"
            else:
                return False, f"⚠️ Place drone on LEFT side - Current: Roll {self._current_roll:.1f}° (need ~-90°)"
                
        elif position_name == "Right":
            # Right side: Roll should be around +90°
            target_roll = 90
            if abs(self._current_roll - target_roll) <= tolerance and abs(self._current_pitch) <= tolerance:
                return True, f"✅ Drone is on right side (Roll: {self._current_roll:.1f}°)"
            else:
                return False, f"⚠️ Place drone on RIGHT side - Current: Roll {self._current_roll:.1f}° (need ~+90°)"
                
        elif position_name == "Nose Down":
            # CORRECTED: Nose down based on GPS direction - Pitch should be around -90° (nose pointing down)
            target_pitch = -90
            if abs(self._current_pitch - target_pitch) <= tolerance and abs(self._current_roll) <= tolerance:
                return True, f"✅ Drone nose is down (Pitch: {self._current_pitch:.1f}°, GPS heading: {gps_heading_offset:.1f}°)"
            else:
                return False, f"⚠️ Place drone NOSE DOWN (towards GPS direction) - Current: Pitch {self._current_pitch:.1f}° (need ~-90°)"
                
        elif position_name == "Nose Up":
            # CORRECTED: Nose up (tail down) based on GPS direction - Pitch should be around +90° (nose pointing up)
            target_pitch = 90
            if abs(self._current_pitch - target_pitch) <= tolerance and abs(self._current_roll) <= tolerance:
                return True, f"✅ Drone nose is up (Pitch: {self._current_pitch:.1f}°, GPS heading: {gps_heading_offset:.1f}°)"
            else:
                return False, f"⚠️ Place drone NOSE UP (away from GPS direction, tail down) - Current: Pitch {self._current_pitch:.1f}° (need ~+90°)"
                
        elif position_name == "Back":
            # Upside down: Roll should be around ±180°
            if (abs(abs(self._current_roll) - 180) <= tolerance and 
                abs(self._current_pitch) <= tolerance):
                return True, f"✅ Drone is upside down (Roll: {self._current_roll:.1f}°)"
            else:
                return False, f"⚠️ Place drone UPSIDE DOWN - Current: Roll {self._current_roll:.1f}° (need ~±180°)"
        
        return False, f"Unknown position: {position_name}"
    
    # Additional calibration methods
    @pyqtSlot()
    def startCompassCalibration(self):
        """Start compass calibration"""
        if not self.isDroneConnected:
            self._set_feedback("Error: Drone not connected")
            return False
            
        if self._accel_calibration_active or self._level_calibration_active:
            self._set_feedback("Error: Cannot start compass calibration while other calibration is active")
            return False
        
        print("[CalibrationModel] Starting compass calibration")
        self._compass_calibration_active = True
        self._compass_calibration_complete = False
        self.calibrationStatusChanged.emit()
        
        # Send MAVLink command for compass calibration
        if self._drone_model and self._drone_model.drone_connection:
            try:
                self._drone_model.drone_connection.mav.command_long_send(
                    self._drone_model.drone_connection.target_system,
                    self._drone_model.drone_connection.target_component,
                    mavutil.mavlink.MAV_CMD_PREFLIGHT_CALIBRATION,
                    0, 0, 1, 0, 0, 0, 0, 0  # Compass calibration
                )
                print("[CalibrationModel] Sent compass calibration command")
                self._set_feedback("🧭 Compass calibration started - Rotate drone slowly in all directions...")
                return True
            except Exception as e:
                print(f"[CalibrationModel] Error sending compass calibration command: {e}")
                self._compass_calibration_active = False
                self.calibrationStatusChanged.emit()
                return False
        return False
    
    @pyqtSlot()
    def stopCompassCalibration(self):
        """Stop compass calibration"""
        self._compass_calibration_active = False
        self.calibrationStatusChanged.emit()
        self._set_feedback("Compass calibration cancelled")
    
    @pyqtSlot()
    def completeCompassCalibration(self):
        """Complete compass calibration"""
        self._compass_calibration_active = False
        self._compass_calibration_complete = True
        self.calibrationStatusChanged.emit()
        self._update_all_calibrations_status()
        self._set_feedback("✅ Compass calibration completed successfully!")
    
    @pyqtSlot()
    def startRadioCalibration(self):
        """Start radio calibration"""
        if not self.isDroneConnected:
            self._set_feedback("Error: Drone not connected")
            return False
            
        print("[CalibrationModel] Starting radio calibration")
        self._radio_calibration_active = True
        self._radio_calibration_complete = False
        self.calibrationStatusChanged.emit()
        
        # Send MAVLink command for RC calibration
        if self._drone_model and self._drone_model.drone_connection:
            try:
                self._drone_model.drone_connection.mav.command_long_send(
                    self._drone_model.drone_connection.target_system,
                    self._drone_model.drone_connection.target_component,
                    mavutil.mavlink.MAV_CMD_PREFLIGHT_CALIBRATION,
                    0, 0, 0, 1, 0, 0, 0, 0  # RC calibration
                )
                print("[CalibrationModel] Sent radio calibration command")
                self._set_feedback("📻 Radio calibration started - Move all sticks and switches through full range...")
                return True
            except Exception as e:
                print(f"[CalibrationModel] Error sending radio calibration command: {e}")
                self._radio_calibration_active = False
                self.calibrationStatusChanged.emit()
                return False
        return False
    
    @pyqtSlot()
    def stopRadioCalibration(self):
        """Stop radio calibration"""
        self._radio_calibration_active = False
        self.calibrationStatusChanged.emit()
        self._set_feedback("Radio calibration cancelled")
    
    @pyqtSlot()
    def completeRadioCalibration(self):
        """Complete radio calibration"""
        self._radio_calibration_active = False
        self._radio_calibration_complete = True
        self.calibrationStatusChanged.emit()
        self._update_all_calibrations_status()
        self._set_feedback("✅ Radio calibration completed successfully!")
    
    @pyqtSlot()
    def startEscCalibration(self):
        """Start ESC calibration"""
        if not self.isDroneConnected:
            self._set_feedback("Error: Drone not connected")
            return False
            
        print("[CalibrationModel] Starting ESC calibration")
        self._esc_calibration_active = True
        self._esc_calibration_complete = False
        self.calibrationStatusChanged.emit()
        
        # Send MAVLink command for ESC calibration
        if self._drone_model and self._drone_model.drone_connection:
            try:
                # ESC calibration typically involves motor test commands
                self._drone_model.drone_connection.mav.command_long_send(
                    self._drone_model.drone_connection.target_system,
                    self._drone_model.drone_connection.target_component,
                    mavutil.mavlink.MAV_CMD_PREFLIGHT_CALIBRATION,
                    0, 0, 0, 0, 1, 0, 0, 0  # ESC calibration
                )
                print("[CalibrationModel] Sent ESC calibration command")
                self._set_feedback("⚡ ESC calibration started - Keep propellers OFF! Follow ESC beep sequence...")
                return True
            except Exception as e:
                print(f"[CalibrationModel] Error sending ESC calibration command: {e}")
                self._esc_calibration_active = False
                self.calibrationStatusChanged.emit()
                return False
        return False
    
    @pyqtSlot()
    def stopEscCalibration(self):
        """Stop ESC calibration"""
        self._esc_calibration_active = False
        self.calibrationStatusChanged.emit()
        self._set_feedback("ESC calibration cancelled")
    
    @pyqtSlot()
    def completeEscCalibration(self):
        """Complete ESC calibration"""
        self._esc_calibration_active = False
        self._esc_calibration_complete = True
        self.calibrationStatusChanged.emit()
        self._update_all_calibrations_status()
        self._set_feedback("✅ ESC calibration completed successfully!")
    
    @pyqtSlot()
    def startServoCalibration(self):
        """Start servo output calibration"""
        if not self.isDroneConnected:
            self._set_feedback("Error: Drone not connected")
            return False
            
        print("[CalibrationModel] Starting servo calibration")
        self._servo_calibration_active = True
        self._servo_calibration_complete = False
        self.calibrationStatusChanged.emit()
        
        # Send MAVLink command for servo calibration
        if self._drone_model and self._drone_model.drone_connection:
            try:
                self._drone_model.drone_connection.mav.command_long_send(
                    self._drone_model.drone_connection.target_system,
                    self._drone_model.drone_connection.target_component,
                    mavutil.mavlink.MAV_CMD_PREFLIGHT_CALIBRATION,
                    0, 0, 0, 0, 0, 1, 0, 0  # Servo calibration
                )
                print("[CalibrationModel] Sent servo calibration command")
                self._set_feedback("🎛️ Servo calibration started - Move control sticks to set servo ranges...")
                return True
            except Exception as e:
                print(f"[CalibrationModel] Error sending servo calibration command: {e}")
                self._servo_calibration_active = False
                self.calibrationStatusChanged.emit()
                return False
        return False
    
    @pyqtSlot()
    def stopServoCalibration(self):
        """Stop servo calibration"""
        self._servo_calibration_active = False
        self.calibrationStatusChanged.emit()
        self._set_feedback("Servo calibration cancelled")
    
    @pyqtSlot()
    def completeServoCalibration(self):
        """Complete servo calibration"""
        self._servo_calibration_active = False
        self._servo_calibration_complete = True
        self.calibrationStatusChanged.emit()
        self._update_all_calibrations_status()
        self._set_feedback("✅ Servo calibration completed successfully!")
    
    # Rest of the existing methods remain the same...
    @pyqtSlot()
    def _on_position_stable(self):
        """Called when drone has been in correct position for required time"""
        if self._is_position_correct:
            self._set_feedback("✅ Position confirmed! Drone is stable and ready for calibration.")
    
    @pyqtSlot()
    def startPositionCheck(self):
        """Start checking drone position"""
        if not self.isDroneConnected:
            self._set_feedback("Error: Drone not connected")
            return False
            
        self._position_check_active = True
        self._is_position_correct = False
        self._position_check_message = "Checking drone position..."
        self.positionCheckChanged.emit()
        self._set_feedback("📍 Position checking active - Move drone to required position")
        return True
    
    @pyqtSlot()
    def stopPositionCheck(self):
        """Stop checking drone position"""
        self._position_check_active = False
        self._is_position_correct = False
        self._position_check_message = ""
        self._position_stability_timer.stop()
        self.positionCheckChanged.emit()
    
    @pyqtSlot()
    def _on_drone_connection_changed(self):
        """Handle drone connection state changes with enhanced auto-reconnection"""
        current_time = time.time()
        
        if not self.isDroneConnected:
            # Connection lost - stop position checking
            self.stopPositionCheck()
            
            if not self._connection_lost_time:
                self._connection_lost_time = current_time
                print(f"[CalibrationModel] Connection lost at {current_time}")
            
            # If drone disconnects during calibration (not during reboot), cancel calibrations
            if not self._is_rebooting:
                self.cancelCalibration()
                self._set_feedback("⚠️ Connection lost - Attempting to reconnect...")
            
            # Start auto-reconnection if enabled and we have connection info
            if (self._auto_reconnect_enabled and 
                self._last_connection_string and 
                not self._reconnect_timer.isActive()):
                
                print("[CalibrationModel] Starting auto-reconnection sequence")
                self._reconnection_attempts = 0
                self._reconnect_timer.start(3000)
                
        else:
            # Connection established/restored
            self._connection_lost_time = None
            
            # Stop reconnection timer if it's running
            if self._reconnect_timer.isActive():
                self._reconnect_timer.stop()
                print("[CalibrationModel] Auto-reconnection successful, stopping timer")
            
            # Reset reconnection attempts
            self._reconnection_attempts = 0
            
            # If drone reconnects after reboot, reset reboot flag
            if self._is_rebooting:
                self._is_rebooting = False
                self._set_feedback("✅ Drone reconnected successfully after reboot!")
                self._stability_timer.start(2000)
            else:
                self._set_feedback("✅ Drone connected successfully!")
        
        # Emit status change to update UI
        self.calibrationStatusChanged.emit()

    @pyqtSlot(result=bool)
    def isCalibrating(self):
        return (self._level_calibration_active or self._accel_calibration_active or 
                self._compass_calibration_active or self._radio_calibration_active or
                self._esc_calibration_active or self._servo_calibration_active)

    # Level Calibration Properties
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def levelCalibrationActive(self):
        return self._level_calibration_active
    
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def levelCalibrationComplete(self):
        return self._level_calibration_complete

    # Accelerometer Calibration Properties
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def accelCalibrationActive(self):
        return self._accel_calibration_active
    
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def accelCalibrationComplete(self):
        return self._accel_calibration_complete
    
    @pyqtProperty(int, notify=accelCalibrationProgressChanged)
    def currentStep(self):
        return self._current_step
    
    @pyqtProperty('QVariantList', notify=accelCalibrationProgressChanged)
    def completedSteps(self):
        return self._completed_steps
    
    @pyqtProperty(bool, notify=accelCalibrationProgressChanged)
    def allPositionsCompleted(self):
        return self._all_positions_completed

    # General Properties
    @pyqtProperty(str, notify=feedbackMessageChanged)
    def feedbackMessage(self):
        return self._feedback_message
    
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def allCalibrationsComplete(self):
        return self._all_calibrations_complete

    # Connection status (from drone model)
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def isDroneConnected(self):
        return self._drone_model.isConnected if self._drone_model else False

    # Enhanced Level Calibration Methods with Position Checking
    @pyqtSlot()
    def startLevelCalibration(self):
        if not self.isDroneConnected:
            self._set_feedback("Error: Drone not connected")
            return False
            
        if self._accel_calibration_active:
            self._set_feedback("Error: Cannot start level calibration while accelerometer calibration is active")
            return False
        
        # Store connection info for auto-reconnection
        self._store_connection_info()
        
        # Start position checking first
        self.startPositionCheck()
        
        # Check if drone is level
        is_level, message = self._is_in_required_position("Level")
        
        if not is_level:
            self._set_feedback(message + " - Level calibration requires drone to be level!")
            return False
            
        print("[CalibrationModel] Starting level calibration - drone position verified")
        self._level_calibration_active = True
        self._level_calibration_complete = False
        self._update_all_calibrations_status()
        
        # Send MAVLink command for level calibration
        if self._drone_model and self._drone_model.drone_connection:
            try:
                self._drone_model.drone_connection.mav.command_long_send(
                    self._drone_model.drone_connection.target_system,
                    self._drone_model.drone_connection.target_component,
                    mavutil.mavlink.MAV_CMD_PREFLIGHT_CALIBRATION,
                    0, 1, 0, 0, 0, 0, 0, 0
                )
                print("[CalibrationModel] Sent level calibration command")
            except Exception as e:
                print(f"[CalibrationModel] Error sending level calibration command: {e}")
                self._set_feedback(f"Error: Failed to send calibration command - {e}")
                self._level_calibration_active = False
                self.stopPositionCheck()
                self.calibrationStatusChanged.emit()
                return False
        
        self._set_feedback("✅ Level calibration started - Keep drone level and still...")
        self._level_timer.start(5000)  # 5 second calibration
        return True

    @pyqtSlot()
    def stopLevelCalibration(self):
        print("[CalibrationModel] Stopping level calibration")
        self._level_calibration_active = False
        self._level_timer.stop()
        self.stopPositionCheck()
        self._update_all_calibrations_status()
        self._set_feedback("Level calibration cancelled")

    def _complete_level_calibration(self):
        print("[CalibrationModel] Level calibration completed")
        self._level_calibration_active = False
        self._level_calibration_complete = True
        self.stopPositionCheck()
        self._update_all_calibrations_status()
        self._set_feedback("✅ Level calibration completed successfully!")

    # Enhanced Accelerometer Calibration Methods with Position Checking
    @pyqtSlot()
    def startAccelCalibration(self):
        if not self.isDroneConnected:
            self._set_feedback("Error: Drone not connected")
            return False
            
        if self._level_calibration_active:
            self._set_feedback("Error: Cannot start accelerometer calibration while level calibration is active")
            return False
        
        # Store connection info for auto-reconnection
        self._store_connection_info()
        
        print("[CalibrationModel] Starting accelerometer calibration")
        self._accel_calibration_active = True
        self._accel_calibration_complete = False
        self._current_step = 0
        self._completed_steps = [False] * 6
        self._all_positions_completed = False
        self._update_all_calibrations_status()
        
        # Start position checking for first position
        self.startPositionCheck()
        
        # Send MAVLink command for accelerometer calibration
        if self._drone_model and self._drone_model.drone_connection:
            try:
                self._drone_model.drone_connection.mav.command_long_send(
                    self._drone_model.drone_connection.target_system,
                    self._drone_model.drone_connection.target_component,
                    mavutil.mavlink.MAV_CMD_PREFLIGHT_CALIBRATION,
                    0, 0, 0, 0, 0, 1, 0, 0
                )
                print("[CalibrationModel] Sent accelerometer calibration command")
            except Exception as e:
                print(f"[CalibrationModel] Error sending accel calibration command: {e}")
                self._set_feedback(f"Error: Failed to send calibration command - {e}")
                self._accel_calibration_active = False
                self.stopPositionCheck()
                self.calibrationStatusChanged.emit()
                return False
        
        # Check initial position
        required_position = self._position_names[self._current_step]
        is_correct, message = self._is_in_required_position(required_position)
        
        if is_correct:
            self._set_feedback(f"✅ Accelerometer calibration started - Drone is in correct position: {required_position}")
        else:
            self._set_feedback(f"⚠️ {message} - Move to position: {required_position}")
        
        return True

    @pyqtSlot()
    def stopAccelCalibration(self):
        print("[CalibrationModel] Stopping accelerometer calibration")
        self._accel_calibration_active = False
        self._accel_calibration_complete = False
        self._current_step = 0
        self._completed_steps = [False] * 6
        self._all_positions_completed = False
        self.stopPositionCheck()
        self._update_all_calibrations_status()
        self._set_feedback("Accelerometer calibration cancelled")

    @pyqtSlot()
    def nextPosition(self):
        if not self._accel_calibration_active or not self.isDroneConnected:
            return
        
        # Check if current position is correct before proceeding
        current_position = self._position_names[self._current_step]
        is_correct, message = self._is_in_required_position(current_position)
        
        if not is_correct:
            self._set_feedback(f"❌ {message} - Cannot proceed until drone is in correct position!")
            return
            
        # Mark current position as completed
        self._completed_steps[self._current_step] = True
        
        # Send position completion to the connected drone
        if self._drone_model and self._drone_model.drone_connection:
            try:
                print(f"[CalibrationModel] Position {self._current_step + 1} ({current_position}) completed and verified")
            except Exception as e:
                print(f"[CalibrationModel] Error processing position: {e}")
        
        if self._current_step < 5:  # 0-5 = 6 positions
            self._current_step += 1
            next_position = self._position_names[self._current_step]
            
            # Check if drone is already in next position
            is_next_correct, next_message = self._is_in_required_position(next_position)
            
            if is_next_correct:
                self._set_feedback(f"✅ Position {self._current_step} completed. Drone is already in correct position: {next_position}")
            else:
                self._set_feedback(f"✅ Position {self._current_step} completed. {next_message}")
        else:
            self._all_positions_completed = True
            self.stopPositionCheck()
            self._set_feedback("🎉 All positions completed and verified! Click 'Done' to finish.")
        
        self.accelCalibrationProgressChanged.emit()

    @pyqtSlot()
    def completeAccelCalibration(self):
        if not self.isDroneConnected:
            self._set_feedback("Error: Drone not connected")
            return
            
        print("[CalibrationModel] Completing accelerometer calibration")
        self._accel_calibration_active = False
        self._accel_calibration_complete = True
        self.stopPositionCheck()
        self._update_all_calibrations_status()
        
        # Send final calibration completion to the connected drone
        if self._drone_model and self._drone_model.drone_connection:
            try:
                print("[CalibrationModel] Sending final calibration completion")
            except Exception as e:
                print(f"[CalibrationModel] Error completing calibration: {e}")
        
        self._set_feedback("✅ Accelerometer calibration completed successfully with position verification!")

    # Position verification methods for UI
    @pyqtSlot(result=bool)
    def canStartLevelCalibration(self):
        """Check if level calibration can be started (drone must be level)"""
        if not self.isDroneConnected:
            return False
        is_level, _ = self._is_in_required_position("Level")
        return is_level
    
    @pyqtSlot(result=bool)
    def canProceedToNextPosition(self):
        """Check if can proceed to next position in accel calibration"""
        if not self._accel_calibration_active:
            return False
        current_position = self._position_names[self._current_step]
        is_correct, _ = self._is_in_required_position(current_position)
        return is_correct

    # Rest of the existing methods...
    @pyqtSlot()
    def _check_connection_health(self):
        """Monitor connection health and trigger reconnection if needed"""
        if not self.isDroneConnected and self._last_connection_string:
            if not self._reconnect_timer.isActive() and self._auto_reconnect_enabled:
                current_time = time.time()
                if (self._connection_lost_time and 
                    current_time - self._connection_lost_time > 5.0):
                    print("[CalibrationModel] Connection health check: Starting reconnection")
                    self._reconnection_attempts = 0
                    self._reconnect_timer.start(3000)

    @pyqtSlot()
    def _on_connection_stable(self):
        """Called when connection has been stable for a while after reconnection"""
        print("[CalibrationModel] Connection stabilized")

    def _store_connection_info(self):
        """Store current connection info for auto-reconnection"""
        if self._drone_model:
            connection_string = getattr(self._drone_model, 'current_connection_string', None)
            connection_id = getattr(self._drone_model, 'current_connection_id', None)
            
            if not connection_string and hasattr(self._drone_model, 'drone_connection'):
                if hasattr(self._drone_model.drone_connection, 'device'):
                    connection_string = str(self._drone_model.drone_connection.device)
            
            if connection_string:
                self._last_connection_string = connection_string
                if connection_id:
                    self._last_connection_id = connection_id
                else:
                    self._last_connection_id = "auto-reconnect-" + str(int(time.time()))
                print(f"[CalibrationModel] Stored connection info: {self._last_connection_string}")
            else:
                print("[CalibrationModel] Warning: Could not store connection info")

    @pyqtSlot()
    def rebootDrone(self):
        if not self.isDroneConnected:
            self._set_feedback("Error: Drone not connected")
            return False
        
        self._store_connection_info()
        self._is_rebooting = True
        self._reconnection_attempts = 0
        self.stopPositionCheck()  # Stop position checking during reboot
            
        print("[CalibrationModel] Sending reboot command")
        
        if self._drone_model and self._drone_model.drone_connection:
            try:
                self._drone_model.drone_connection.mav.command_long_send(
                    self._drone_model.drone_connection.target_system,
                    self._drone_model.drone_connection.target_component,
                    mavutil.mavlink.MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN,
                    0, 1, 0, 0, 0, 0, 0, 0
                )
                self._set_feedback("🔄 Rebooting drone... Auto-reconnection will start in 8 seconds...")
                print("[CalibrationModel] Reboot command sent successfully")
                self._reconnect_timer.start(8000)
                return True
            except Exception as e:
                print(f"[CalibrationModel] Error sending reboot command: {e}")
                self._set_feedback(f"Error: Failed to reboot drone - {e}")
                self._is_rebooting = False
                return False
        return False

    @pyqtSlot()
    def _attempt_reconnection(self):
        """Enhanced auto-reconnection with multiple attempts and better feedback"""
        if self.isDroneConnected:
            self._reconnect_timer.stop()
            return
            
        if not self._last_connection_string:
            print("[CalibrationModel] No connection string stored for reconnection")
            self._reconnect_timer.stop()
            return
            
        if self._reconnection_attempts >= self._max_reconnection_attempts:
            print(f"[CalibrationModel] Max reconnection attempts reached")
            self._reconnect_timer.stop()
            self._set_feedback(f"❌ Auto-reconnection failed after {self._max_reconnection_attempts} attempts")
            return
        
        self._reconnection_attempts += 1
        attempt_text = f"(Attempt {self._reconnection_attempts}/{self._max_reconnection_attempts})"
        
        print(f"[CalibrationModel] Auto-reconnection attempt {self._reconnection_attempts}")
        
        try:
            if self._drone_model:
                try:
                    self._drone_model.disconnectDrone()
                except:
                    pass
                
                time.sleep(0.5)
                
                success = self._drone_model.connectToDrone(
                    self._last_connection_id,
                    self._last_connection_string,
                    57600
                )
                
                if self._is_rebooting:
                    self._set_feedback(f"🔄 Reconnecting after reboot... {attempt_text}")
                else:
                    self._set_feedback(f"📡 Auto-reconnecting... {attempt_text}")
                    
                if self._reconnection_attempts <= 3:
                    interval = 3000
                elif self._reconnection_attempts <= 6:
                    interval = 5000
                else:
                    interval = 10000
                
                self._reconnect_timer.setInterval(interval)
                
        except Exception as e:
            print(f"[CalibrationModel] Auto-reconnection attempt failed: {e}")
            self._set_feedback(f"📡 Reconnection failed {attempt_text}")

    @pyqtSlot()
    def cancelCalibration(self):
        """Cancel any active calibration - called when drone disconnects"""
        if self._level_calibration_active:
            self.stopLevelCalibration()
        if self._accel_calibration_active:
            self.stopAccelCalibration()
        if self._compass_calibration_active:
            self.stopCompassCalibration()
        if self._radio_calibration_active:
            self.stopRadioCalibration()
        if self._esc_calibration_active:
            self.stopEscCalibration()
        if self._servo_calibration_active:
            self.stopServoCalibration()
        self.stopPositionCheck()
        if not self._is_rebooting:
            self._set_feedback("⚠️ Calibration cancelled - Connection lost")

    def _set_feedback(self, message):
        self._feedback_message = message
        self.feedbackMessageChanged.emit()
        print(f"[CalibrationModel] Feedback: {message}")
        if message:
            self._feedback_timer.start(8000)

    def _clear_feedback(self):
        self._feedback_message = ""
        self.feedbackMessageChanged.emit()

    def _update_all_calibrations_status(self):
        self._all_calibrations_complete = (self._level_calibration_complete and 
                                          self._accel_calibration_complete and
                                          self._compass_calibration_complete and
                                          self._radio_calibration_complete and
                                          self._esc_calibration_complete and
                                          self._servo_calibration_complete)
        self.calibrationStatusChanged.emit()

    # Enhanced auto-reconnection properties
    @pyqtProperty(str, notify=calibrationStatusChanged)
    def lastConnectionString(self):
        return self._last_connection_string
    
    @pyqtProperty(str, notify=calibrationStatusChanged)
    def lastConnectionId(self):
        return self._last_connection_id
        
    @pyqtProperty(bool, notify=calibrationStatusChanged)
    def autoReconnectEnabled(self):
        return self._auto_reconnect_enabled
        
    @pyqtProperty(int, notify=calibrationStatusChanged)
    def reconnectionAttempts(self):
        return self._reconnection_attempts

    @pyqtSlot()
    def enableAutoReconnect(self):
        """Enable auto-reconnection feature"""
        self._auto_reconnect_enabled = True
        print("[CalibrationModel] Auto-reconnection enabled")
        self.calibrationStatusChanged.emit()

    @pyqtSlot()
    def disableAutoReconnect(self):
        """Disable auto-reconnection feature"""
        self._auto_reconnect_enabled = False
        if self._reconnect_timer.isActive():
            self._reconnect_timer.stop()
        print("[CalibrationModel] Auto-reconnection disabled")
        self.calibrationStatusChanged.emit()

    @pyqtSlot()
    def forceReconnect(self):
        """Force an immediate reconnection attempt"""
        if self._last_connection_string:
            print("[CalibrationModel] Forcing reconnection attempt")
            self._reconnection_attempts = 0
            if not self._reconnect_timer.isActive():
                self._reconnect_timer.start(1000)
            self._attempt_reconnection()
        else:
            self._set_feedback("No previous connection to reconnect to")

    @pyqtSlot()
    def resetCalibrations(self):
        """Reset all calibration states"""
        print("[CalibrationModel] Resetting all calibrations")
        
        if self._level_calibration_active:
            self.stopLevelCalibration()
        if self._accel_calibration_active:
            self.stopAccelCalibration()
        if self._compass_calibration_active:
            self.stopCompassCalibration()
        if self._radio_calibration_active:
            self.stopRadioCalibration()
        if self._esc_calibration_active:
            self.stopEscCalibration()
        if self._servo_calibration_active:
            self.stopServoCalibration()
        
        self.stopPositionCheck()
        
        self._level_calibration_complete = False
        self._accel_calibration_complete = False
        self._compass_calibration_complete = False
        self._radio_calibration_complete = False
        self._esc_calibration_complete = False
        self._servo_calibration_complete = False
        self._current_step = 0
        self._completed_steps = [False] * 6
        self._all_positions_completed = False
        self._all_calibrations_complete = False
        self._is_rebooting = False
        self._reconnection_attempts = 0
        
        # Reset GPS and altitude data
        self._current_altitude = 0.0
        self._correct_altitude = 0.0
        
        self.calibrationStatusChanged.emit()
        self.accelCalibrationProgressChanged.emit()
        self.positionCheckChanged.emit()
        self.altitudeDataChanged.emit()
        self.gpsDataChanged.emit()
        self._set_feedback("All calibrations reset")

    def cleanup(self):
        """Clean up resources"""
        print("[CalibrationModel] Cleaning up calibration resources")
        
        self._auto_reconnect_enabled = False
        
        if self._drone_model:
            try:
                self._drone_model.droneConnectedChanged.disconnect(self._on_drone_connection_changed)
            except:
                pass
        
        # Stop all timers
        timers = [self._level_timer, self._feedback_timer, self._reconnect_timer, 
                 self._heartbeat_timer, self._stability_timer, self._position_timer,
                 self._position_stability_timer]
        for timer in timers:
            if timer.isActive():
                timer.stop()
        
        self.stopPositionCheck()
        self._level_calibration_active = False
        self._accel_calibration_active = False
        self._compass_calibration_active = False
        self._radio_calibration_active = False
        self._esc_calibration_active = False
        self._servo_calibration_active = False