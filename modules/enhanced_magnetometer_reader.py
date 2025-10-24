# enhanced_magnetometer_reader.py - Multiple source magnetometer reading

def _read_magnetometer_data_enhanced(self):
    """Enhanced magnetometer reading with multiple source support"""
    if not self.isDroneConnected or not self._drone_model.drone_connection:
        return False
        
    try:
        got_real_data = False
        
        # Try multiple message types in order of preference
        message_types_to_try = [
            'RAW_IMU',
            'SCALED_IMU', 
            'SCALED_IMU2',
            'SCALED_IMU3',
            'HIGHRES_IMU'
        ]
        
        for msg_type in message_types_to_try:
            try:
                msg = self._drone_model.drone_connection.recv_match(
                    type=msg_type, blocking=False, timeout=0.001
                )
                
                if msg and hasattr(msg, 'xmag') and hasattr(msg, 'ymag') and hasattr(msg, 'zmag'):
                    # Got magnetometer data
                    if msg_type == 'RAW_IMU':
                        # RAW_IMU usually needs scaling
                        self._mag_x = msg.xmag / 10.0
                        self._mag_y = msg.ymag / 10.0
                        self._mag_z = msg.zmag / 10.0
                    else:
                        # SCALED_IMU types are usually already scaled
                        self._mag_x = msg.xmag
                        self._mag_y = msg.ymag
                        self._mag_z = msg.zmag
                    
                    print(f"[CompassCalibrationModel] Got {msg_type} data: X={self._mag_x:.1f}, Y={self._mag_y:.1f}, Z={self._mag_z:.1f}")
                    got_real_data = True
                    break
                    
            except Exception as e:
                continue  # Try next message type
        
        # If no IMU messages, try other sources
        if not got_real_data:
            # Try ATTITUDE message for heading only
            attitude_msg = self._drone_model.drone_connection.recv_match(
                type='ATTITUDE', blocking=False, timeout=0.001
            )
            
            if attitude_msg and hasattr(attitude_msg, 'yaw'):
                # Convert yaw to compass heading and simulate magnetometer
                heading_deg = attitude_msg.yaw * 57.2958  # radians to degrees
                if heading_deg < 0:
                    heading_deg += 360
                
                # Simulate magnetometer from heading
                heading_rad = attitude_msg.yaw
                self._mag_x = 300 * math.cos(heading_rad)
                self._mag_y = 300 * math.sin(heading_rad)
                self._mag_z = 0  # Assume level flight
                
                print(f"[CompassCalibrationModel] Using ATTITUDE yaw: {heading_deg:.1f}° (simulated mag data)")
                got_real_data = True
        
        if got_real_data:
            # Update compass display values
            self._compass_x = self._mag_x / 100.0
            self._compass_y = self._mag_y / 100.0
            self._compass_z = self._mag_z / 100.0
            
            # Calculate heading
            self._compass_heading = math.degrees(math.atan2(self._mag_y, self._mag_x))
            if self._compass_heading < 0:
                self._compass_heading += 360
            
            # Add to history for movement detection
            self._magnetometer_history.append([self._mag_x, self._mag_y, self._mag_z])
            if len(self._magnetometer_history) > self._history_size:
                self._magnetometer_history.pop(0)
            
            self.magnetometerDataChanged.emit()
            self.compassHeadingChanged.emit()
            return True
        
        return False
        
    except Exception as e:
        print(f"[CompassCalibrationModel] Error in enhanced magnetometer reading: {e}")
        return False

def _request_magnetometer_stream(self):
    """Request magnetometer data stream from autopilot"""
    if not self.isDroneConnected or not self._drone_model.drone_connection:
        return
        
    try:
        # Request IMU data stream
        self._drone_model.drone_connection.mav.request_data_stream_send(
            self._drone_model.drone_connection.target_system,
            self._drone_model.drone_connection.target_component,
            mavutil.mavlink.MAV_DATA_STREAM_RAW_SENSORS,  # Raw sensor data
            10,  # 10 Hz
            1    # Enable
        )
        
        # Also request extra sensor data
        self._drone_model.drone_connection.mav.request_data_stream_send(
            self._drone_model.drone_connection.target_system,
            self._drone_model.drone_connection.target_component,
            mavutil.mavlink.MAV_DATA_STREAM_EXTRA1,  # Extra sensor data
            5,   # 5 Hz
            1    # Enable
        )
        
        print("[CompassCalibrationModel] Requested magnetometer data streams")
        
    except Exception as e:
        print(f"[CompassCalibrationModel] Error requesting data streams: {e}")

def _check_autopilot_parameters(self):
    """Check if compass is enabled in autopilot parameters"""
    if not self.isDroneConnected or not self._drone_model.drone_connection:
        return
        
    try:
        # Request compass-related parameters
        compass_params = [
            'COMPASS_USE',
            'COMPASS_ENABLE', 
            'COMPASS1_USE',
            'COMPASS_AUTODEC',
            'MAG_ENABLE'
        ]
        
        for param in compass_params:
            self._drone_model.drone_connection.mav.param_request_read_send(
                self._drone_model.drone_connection.target_system,
                self._drone_model.drone_connection.target_component,
                param.encode('utf-8'),
                -1  # param_index
            )
        
        print("[CompassCalibrationModel] Requested compass parameters")
        
    except Exception as e:
        print(f"[CompassCalibrationModel] Error requesting parameters: {e}")