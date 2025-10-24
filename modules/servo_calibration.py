from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QTimer
from pymavlink import mavutil
import time
import threading

class ServoCalibrationModel(QObject):
    # Signals for QML UI updates
    calibrationStatusChanged = pyqtSignal(str)
    calibrationProgress = pyqtSignal(int)
    servoValueChanged = pyqtSignal(int, int)  # servo_num, value
    connectionStatusChanged = pyqtSignal(bool)
    errorOccurred = pyqtSignal(str)
    realTimeServoUpdate = pyqtSignal(int, int)  # servo_num, current_pwm_value
    servoConfigurationLoaded = pyqtSignal()  # Emitted when configuration is loaded
    servoParameterUpdated = pyqtSignal(int, str, 'QVariant')  # servo_num, param_type, value
    
    def __init__(self, drone_model=None):
        super().__init__()
        self._drone_model = drone_model
        self._drone_connection = None
        self._is_connected = False
        self._calibration_status = "Ready"
        self._servo_positions = [1500] * 16  # Default neutral positions
        self._real_servo_values = [1500] * 16  # Actual values from flight controller
        self._servo_functions = ["Disabled"] * 16
        self._servo_reversed = [False] * 16
        self._servo_min = [1100] * 16
        self._servo_max = [1900] * 16
        self._servo_trim = [1500] * 16
        # Dynamic motor detection
        self._detected_motors = []  # List of physical outputs that are motors
        self._motor_count = 0
        self._motor_display_mapping = {}  # Maps physical output to display number (1,2,3,4...)
        self._detection_complete = False


        # Motor/servo function mapping (similar to Mission Planner)
        self._function_map = {
            0: "Disabled",
            1: "RCPassThru",
            2: "Flap",
            3: "FlapAuto",
            4: "Aileron",
            5: "Mount1Yaw",
            6: "Mount1Pitch",
            7: "Mount1Roll",
            8: "CameraTrigger",
            9: "CameraShutter",
            33: "Motor1",
            34: "Motor2", 
            35: "Motor3",
            36: "Motor4",
            37: "Motor5",
            38: "Motor6",
            39: "Motor7",
            40: "Motor8"
        }
        
        # Reverse function map for setting parameters
        self._reverse_function_map = {v: k for k, v in self._function_map.items()}
        
        # Parameter names for each servo output (ArduPilot standard)
        self._param_names = {
            'function': 'SERVO{}_FUNCTION',
            'min': 'SERVO{}_MIN',
            'max': 'SERVO{}_MAX',
            'trim': 'SERVO{}_TRIM',
            'reversed': 'SERVO{}_REVERSED'
        }
        
        # Status update timer
        self._status_timer = QTimer()
        self._status_timer.timeout.connect(self._update_connection_status)
        self._status_timer.start(1000)  # Check every second
        
        # Real-time servo monitoring timer
        self._servo_monitor_timer = QTimer()
        self._servo_monitor_timer.timeout.connect(self._request_servo_outputs)
        
        print("[ServoCalibration] Model initialized with real-time servo monitoring")
        
    def _update_connection_status(self):
        """Monitor drone connection status"""
        if self._drone_model:
            current_connected = self._drone_model.isConnected
            if current_connected != self._is_connected:
                self._is_connected = current_connected
                if current_connected:
                    self._drone_connection = self._drone_model.drone_connection
                    print("[ServoCalibration] Drone connected - starting real-time monitoring")
                    self._receive_parameters()
                    self._start_servo_monitoring()
                else:
                    self._drone_connection = None
                    print("[ServoCalibration] Drone disconnected - stopping monitoring")
                    self._stop_servo_monitoring()
                
                self.connectionStatusChanged.emit(current_connected)
    
    def _start_servo_monitoring(self):
        """Start real-time servo output monitoring"""
        if self._is_connected and self._drone_connection:
            # Start monitoring servo outputs at 2Hz (reduced frequency)
            self._servo_monitor_timer.start(500)  # Every 500ms
            
            # Start background thread for receiving servo output data
            self._monitoring_active = True
            threading.Thread(target=self._monitor_servo_outputs, daemon=True).start()
            print("[ServoCalibration] Real-time servo monitoring started at 2Hz")
    
    def _stop_servo_monitoring(self):
        """Stop real-time servo monitoring"""
        self._monitoring_active = False
        self._servo_monitor_timer.stop()
        print("[ServoCalibration] Real-time servo monitoring stopped")
    
    def _request_servo_outputs(self):
        """Request current servo output values from flight controller"""
        if not self._is_connected or not self._drone_connection:
            return
            
        try:
            # Request SERVO_OUTPUT_RAW message for real-time servo positions
            # Use a lower rate to prevent spam
            self._drone_connection.mav.request_data_stream_send(
                self._drone_connection.target_system,
                self._drone_connection.target_component,
                mavutil.mavlink.MAV_DATA_STREAM_RC_CHANNELS,
                2,  # 2Hz rate (reduced from 10Hz)
                1   # start streaming
            )
            
        except Exception as e:
            print(f"[ServoCalibration] Error requesting servo outputs: {e}")
    
    def _monitor_servo_outputs(self):
     """Background thread to monitor real-time servo output values with motor mapping"""
     last_values = [0] * 16
    
     while self._monitoring_active and self._is_connected and self._drone_connection:
        try:
            msg = self._drone_connection.recv_match(
                type=['SERVO_OUTPUT_RAW', 'RC_CHANNELS'], 
                blocking=True, 
                timeout=1
            )
            
            if msg:
                servo_values = None
                
                if msg.get_type() == 'SERVO_OUTPUT_RAW':
                    servo_values = [
                        msg.servo1_raw, msg.servo2_raw, msg.servo3_raw, msg.servo4_raw,
                        msg.servo5_raw, msg.servo6_raw, msg.servo7_raw, msg.servo8_raw,
                        msg.servo9_raw, msg.servo10_raw, msg.servo11_raw, msg.servo12_raw,
                        msg.servo13_raw, msg.servo14_raw, msg.servo15_raw, msg.servo16_raw
                    ]
                elif msg.get_type() == 'RC_CHANNELS':
                    servo_values = [
                        msg.chan1_raw, msg.chan2_raw, msg.chan3_raw, msg.chan4_raw,
                        msg.chan5_raw, msg.chan6_raw, msg.chan7_raw, msg.chan8_raw,
                        msg.chan9_raw, msg.chan10_raw, msg.chan11_raw, msg.chan12_raw,
                        msg.chan13_raw, msg.chan14_raw, msg.chan15_raw, msg.chan16_raw
                    ]
                
                if servo_values:
                    for i, value in enumerate(servo_values):
                        if i < 16 and value > 0:
                            physical_output = i + 1  # Physical servo number (1-16)
                            
                            # Only process if value changed significantly
                            if abs(value - last_values[i]) > 5:
                                self._real_servo_values[i] = value
                                last_values[i] = value
                                
                                # Check if this is a detected motor
                                if physical_output in self._motor_display_mapping:
                                    # This is a motor - map to sequential display number
                                    display_number = self._motor_display_mapping[physical_output]
                                    self.realTimeServoUpdate.emit(display_number, value)
                                    
                                    # Log only significant changes
                                    if abs(value - 1500) > 50:
                                        print(f"[ServoCalibration] Motor {display_number} (physical output {physical_output}): {value}us")
                                
                                # For non-motor servos, show with original numbering but offset after motors
                                elif value > 800 and value < 2200 and abs(value - 1500) > 50:
                                    # Show other active servos after the motors
                                    display_number = self._motor_count + physical_output
                                    self.realTimeServoUpdate.emit(display_number, value)
                                    
                                    print(f"[ServoCalibration] Servo {display_number} (physical output {physical_output}): {value}us")
                            
        except Exception as e:
            if self._monitoring_active:
                print(f"[ServoCalibration] Monitoring error: {e}")
                time.sleep(0.5)
 
    
    def _receive_parameters(self):
        """Receive and process parameter values"""
        timeout = time.time() + 15  # 15 second timeout for more parameters
        received_params = set()
        frame_type = None
        
        while time.time() < timeout and self._drone_connection:
            try:
                msg = self._drone_connection.recv_match(type='PARAM_VALUE', blocking=True, timeout=1)
                if msg:
                    param_name = msg.param_id.decode('utf-8').rstrip('\x00')
                    param_value = msg.param_value
                    
                    # Detect frame type for automatic configuration
                    if param_name == 'FRAME_TYPE':
                        frame_type = int(param_value)
                        print(f"[ServoCalibration] Detected frame type: {frame_type}")
                        self._configure_for_frame_type(frame_type)
                    
                    # Parse servo parameters
                    if param_name.startswith('SERVO') and '_' in param_name:
                        try:
                            parts = param_name.split('_')
                            servo_num = int(parts[0][5:])  # Extract number from SERVO1, SERVO2, etc.
                            param_type = parts[1]
                            
                            if 1 <= servo_num <= 16:
                                index = servo_num - 1
                                
                                if param_type == 'FUNCTION':
                                    func_name = self._function_map.get(int(param_value), f"Unknown({int(param_value)})")
                                    self._servo_functions[index] = func_name
                                    print(f"[ServoCalibration] Servo {servo_num} function: {func_name}")
                                elif param_type == 'MIN':
                                    self._servo_min[index] = int(param_value)
                                elif param_type == 'MAX':
                                    self._servo_max[index] = int(param_value)
                                elif param_type == 'TRIM':
                                    self._servo_trim[index] = int(param_value)
                                    # Don't set position to trim, let real-time monitoring handle it
                                elif param_type == 'REVERSED':
                                    self._servo_reversed[index] = bool(int(param_value))
                                
                                received_params.add(param_name)
                                
                        except (ValueError, IndexError) as e:
                            print(f"[ServoCalibration] Error parsing parameter {param_name}: {e}")
                            
            except Exception as e:
                print(f"[ServoCalibration] Parameter reception error: {e}")
                break
        
        print(f"[ServoCalibration] Loaded {len(received_params)} servo parameters")
        
        # After loading parameters, request initial servo values
        self._request_initial_servo_values()
        
        # Emit configuration loaded signal
        self.servoConfigurationLoaded.emit()
    def _configure_for_frame_type(self, frame_type):
     """Configure default servo functions based on frame type and detect motors"""
    # Reset detection
     self._detected_motors = []
     self._motor_display_mapping = {}
    
    # ArduPilot frame types and expected motor counts
     motor_configs = {
        1: 4,   # Quad X
        2: 4,   # Quad +  
        3: 6,   # Hexa X
        4: 6,   # Hexa +
        10: 8,  # Octa X
        11: 8,  # Octa +
        13: 4,  # Quad Y4
        14: 6,  # Y6 configuration
     }
    
     expected_motors = motor_configs.get(frame_type, 4)  # Default to quad
     self._motor_count = expected_motors
    
     print(f"[ServoCalibration] Frame type {frame_type} detected - expecting {expected_motors} motors")
    
    # Start motor detection process
     self._start_motor_detection()

    def _start_motor_detection(self):
     """Start the process of detecting which physical outputs are motors"""
     if not self._is_connected or not self._drone_connection:
        return
    
     print("[ServoCalibration] Starting motor detection...")
     self._detection_complete = False
     self._detected_motors = []
    
    # Request motor/servo function parameters to identify motors
     for i in range(1, 17):  # Check all 16 possible outputs
        param_name = f"SERVO{i}_FUNCTION"
        self._drone_connection.mav.param_request_read_send(
            self._drone_connection.target_system,
            self._drone_connection.target_component,
            param_name.encode('utf-8'),
            -1
        )
    
    # Start detection monitoring thread
     threading.Thread(target=self._detect_motors_from_parameters, daemon=True).start()


    def _detect_motors_from_parameters(self):
     """Detect which outputs are configured as motors by reading SERVO_FUNCTION parameters"""
     timeout = time.time() + 10  # 10 second timeout
     motor_functions = set(range(33, 41))  # Motor functions 33-40 (Motor1-Motor8)
     detected_outputs = {}
    
     while time.time() < timeout and not self._detection_complete:
        try:
            msg = self._drone_connection.recv_match(type='PARAM_VALUE', blocking=True, timeout=1)
            if msg:
                param_name = msg.param_id
                if isinstance(param_name, bytes):
                    param_name = param_name.decode('utf-8').rstrip('\x00')
                elif isinstance(param_name, str):
                    param_name = param_name.rstrip('\x00')
                
                # Check if this is a servo function parameter
                if param_name.startswith('SERVO') and param_name.endswith('_FUNCTION'):
                    try:
                        servo_num = int(param_name.split('_')[0][5:])  # Extract number from SERVO1_FUNCTION
                        function_value = int(msg.param_value)
                        
                        # Check if this output is configured as a motor
                        if function_value in motor_functions:
                            detected_outputs[servo_num] = function_value
                            print(f"[ServoCalibration] Detected motor on output {servo_num} (function {function_value})")
                    
                    except (ValueError, IndexError):
                        continue
        
        except Exception as e:
            print(f"[ServoCalibration] Motor detection error: {e}")
            break
    
    # Process detected motors and create sequential mapping
     self._detected_motors = sorted(detected_outputs.keys())
     self._create_sequential_motor_mapping()
    
     print(f"[ServoCalibration] Motor detection complete. Found motors on outputs: {self._detected_motors}")
     self._detection_complete = True

    def _create_sequential_motor_mapping(self):
     """Create mapping from physical motor outputs to sequential display numbers (1,2,3,4...)"""
     self._motor_display_mapping = {}
    
     for display_num, physical_output in enumerate(self._detected_motors, 1):
        self._motor_display_mapping[physical_output] = display_num
    
     print(f"[ServoCalibration] Created motor mapping: {self._motor_display_mapping}")
    
    # Update motor count based on actual detection
     self._motor_count = len(self._detected_motors)
    
    # Emit signal to update UI
     self.motorConfigurationDetected.emit(self._motor_count, self._detected_motors)

# Add new signal for motor detection
    motorConfigurationDetected = pyqtSignal(int, list)  # motor_count, physical_outputs

    def _request_initial_servo_values(self):
        """Request initial servo output values to populate displays"""
        if not self._is_connected or not self._drone_connection:
            return
            
        try:
            # Request servo output data
            self._drone_connection.mav.request_data_stream_send(
                self._drone_connection.target_system,
                self._drone_connection.target_component,
                mavutil.mavlink.MAV_DATA_STREAM_RC_CHANNELS,
                5,  # 5Hz rate initially
                1   # start streaming
            )
            
            print("[ServoCalibration] Requested initial servo values")
            
        except Exception as e:
            print(f"[ServoCalibration] Error requesting initial servo values: {e}")
    
    @pyqtSlot(int, str)
    def setServoFunction(self, servo_num, function_name):
        """Set servo function"""
        if not self._is_connected or not self._drone_connection:
            return
        
        # Find function code from name
        function_code = self._reverse_function_map.get(function_name)
        
        if function_code is None:
            print(f"[ServoCalibration] Unknown function: {function_name}")
            return
        
        try:
            param_name = f"SERVO{servo_num}_FUNCTION"
            if self._set_parameter(param_name, float(function_code)):
                self._servo_functions[servo_num - 1] = function_name
                print(f"[ServoCalibration] Set servo {servo_num} function to {function_name}")
            
        except Exception as e:
            print(f"[ServoCalibration] Error setting servo function: {e}")
            self.errorOccurred.emit(f"Failed to set servo function: {str(e)}")
    
    @pyqtSlot(int, bool)
    def setServoReverse(self, servo_num, reversed_state):
        """Set servo reverse state"""
        if not self._is_connected or not self._drone_connection:
            return
            
        try:
            param_name = f"SERVO{servo_num}_REVERSED"
            if self._set_parameter(param_name, float(1 if reversed_state else 0)):
                self._servo_reversed[servo_num - 1] = reversed_state
                print(f"[ServoCalibration] Set servo {servo_num} reverse to {reversed_state}")
            
        except Exception as e:
            print(f"[ServoCalibration] Error setting servo reverse: {e}")
            self.errorOccurred.emit(f"Failed to set servo reverse: {str(e)}")
    
    @pyqtSlot(int, int)
    def setServoMin(self, servo_num, min_value):
        """Set servo minimum value"""
        if not self._is_connected or not self._drone_connection:
            return
            
        try:
            param_name = f"SERVO{servo_num}_MIN"
            if self._set_parameter(param_name, float(min_value)):
                self._servo_min[servo_num - 1] = min_value
                print(f"[ServoCalibration] Set servo {servo_num} min to {min_value}")
            
        except Exception as e:
            print(f"[ServoCalibration] Error setting servo min: {e}")
            self.errorOccurred.emit(f"Failed to set servo min: {str(e)}")
    
    @pyqtSlot(int, int)
    def setServoMax(self, servo_num, max_value):
        """Set servo maximum value"""
        if not self._is_connected or not self._drone_connection:
            return
            
        try:
            param_name = f"SERVO{servo_num}_MAX"
            if self._set_parameter(param_name, float(max_value)):
                self._servo_max[servo_num - 1] = max_value
                print(f"[ServoCalibration] Set servo {servo_num} max to {max_value}")
            
        except Exception as e:
            print(f"[ServoCalibration] Error setting servo max: {e}")
            self.errorOccurred.emit(f"Failed to set servo max: {str(e)}")
    
    @pyqtSlot(int, int)
    def setServoTrim(self, servo_num, trim_value):
        """Set servo trim value"""
        if not self._is_connected or not self._drone_connection:
            return
            
        try:
            param_name = f"SERVO{servo_num}_TRIM"
            if self._set_parameter(param_name, float(trim_value)):
                self._servo_trim[servo_num - 1] = trim_value
                print(f"[ServoCalibration] Set servo {servo_num} trim to {trim_value}")
            
        except Exception as e:
            print(f"[ServoCalibration] Error setting servo trim: {e}")
            self.errorOccurred.emit(f"Failed to set servo trim: {str(e)}")
    
    def _set_parameter(self, param_name, param_value):
     """Set a parameter on the flight controller"""
     try:
        # Ensure param_name is properly encoded for MAVLink
        if isinstance(param_name, str):
            param_name_bytes = param_name.encode('utf-8')
            param_name_str = param_name
        else:
            param_name_bytes = param_name
            param_name_str = param_name.decode('utf-8')
            
        self._drone_connection.mav.param_set_send(
            self._drone_connection.target_system,
            self._drone_connection.target_component,
            param_name_bytes,
            param_value,
            mavutil.mavlink.MAV_PARAM_TYPE_REAL32
        )
        
        # Wait for parameter acknowledgment
        timeout = time.time() + 3
        while time.time() < timeout:
            msg = self._drone_connection.recv_match(type='PARAM_VALUE', blocking=True, timeout=1)
            if msg:
                # Fix the decoding issue here
                received_param = msg.param_id
                if isinstance(received_param, bytes):
                    received_param = received_param.decode('utf-8').rstrip('\x00')
                elif isinstance(received_param, str):
                    received_param = received_param.rstrip('\x00')
                
                if received_param == param_name_str:
                    if abs(msg.param_value - param_value) < 0.01:
                        print(f"[ServoCalibration] Parameter {param_name_str} set successfully to {param_value}")
                        return True
                    else:
                        print(f"[ServoCalibration] Parameter {param_name_str} set but value mismatch: expected {param_value}, got {msg.param_value}")
                        return False
        
        print(f"[ServoCalibration] Timeout setting parameter {param_name_str}")
        return False
        
     except Exception as e:
        print(f"[ServoCalibration] Error setting parameter {param_name}: {e}")
        return False
    
    @pyqtSlot()
    def saveParameters(self):
        """Save current parameters to EEPROM"""
        if not self._is_connected or not self._drone_connection:
            self.errorOccurred.emit("Drone not connected")
            return
            
        try:
            # Send PREFLIGHT_STORAGE command to save parameters
            self._drone_connection.mav.command_long_send(
                self._drone_connection.target_system,
                self._drone_connection.target_component,
                mavutil.mavlink.MAV_CMD_PREFLIGHT_STORAGE,
                0,  # confirmation
                1,  # parameter 1: 1=save, 0=load
                0, 0, 0, 0, 0, 0  # unused parameters
            )
            
            print("[ServoCalibration] Parameters saved to EEPROM")
            self.calibrationStatusChanged.emit("Parameters Saved")
            
        except Exception as e:
            print(f"[ServoCalibration] Error saving parameters: {e}")
            self.errorOccurred.emit(f"Failed to save parameters: {str(e)}")
    
    @pyqtSlot(int)
    def getCurrentServoValue(self, servo_num):
        """Get current real-time servo value"""
        if 1 <= servo_num <= 16:
            return self._real_servo_values[servo_num - 1]
        return 1000
    
    @pyqtSlot(int, result=str)
    def getServoFunction(self, servo_num):
        """Get servo function name"""
        if 1 <= servo_num <= 16:
            return self._servo_functions[servo_num - 1]
        return "Disabled"
    
    @pyqtSlot(int, result=int)
    def getServoMin(self, servo_num):
        """Get servo minimum value"""
        if 1 <= servo_num <= 16:
            return self._servo_min[servo_num - 1]
        return 1100
        
    @pyqtSlot(int, result=int)
    def getServoMax(self, servo_num):
        """Get servo maximum value"""
        if 1 <= servo_num <= 16:
            return self._servo_max[servo_num - 1]
        return 1900
        
    @pyqtSlot(int, result=int)
    def getServoTrim(self, servo_num):
        """Get servo trim value"""
        if 1 <= servo_num <= 16:
            return self._servo_trim[servo_num - 1]
        return 1500
        
    @pyqtSlot(int, result=bool)
    def getServoReversed(self, servo_num):
        """Get servo reverse state"""
        if 1 <= servo_num <= 16:
            return self._servo_reversed[servo_num - 1]
        return False
    
    # Properties for QML access
    @pyqtProperty(bool, notify=connectionStatusChanged)
    def isDroneConnected(self):
        return self._is_connected
    
    @pyqtProperty(str, notify=calibrationStatusChanged)
    def calibrationStatus(self):
        return self._calibration_status
    @pyqtProperty(int, notify=motorConfigurationDetected)
    def motorCount(self):
     return self._motor_count

    @pyqtProperty(list, notify=motorConfigurationDetected) 
    def detectedMotorOutputs(self):
     return self._detected_motors

    @pyqtSlot(result=bool)
    def isMotorDetectionComplete(self):
     return self._detection_complete
    
    @pyqtSlot()
    def detectMotors(self):
     """Manually trigger motor detection process"""
     self._start_motor_detection()

    def cleanup(self):
        """Clean up resources"""
        print("[ServoCalibration] Cleaning up servo calibration model...")
        self._stop_servo_monitoring()
        self._status_timer.stop()