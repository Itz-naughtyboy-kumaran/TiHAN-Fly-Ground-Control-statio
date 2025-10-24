# mavlink_thread.py - Enhanced version for proper graph data flow (FIXED)
from PyQt5.QtCore import QThread, pyqtSignal
from pymavlink import mavutil
import time
import traceback
import math

class MAVLinkThread(QThread):
    telemetryUpdated = pyqtSignal('QVariant')
    statusTextChanged = pyqtSignal(str)
    heartbeatReceived = pyqtSignal()
    connectionError = pyqtSignal(str)
    dataRateUpdate = pyqtSignal(float)  # Messages per second

    def __init__(self, connection):
        super().__init__()
        self.connection = connection
        self.running = False
        self.message_count = 0
        self.last_rate_check = time.time()
        
        # Debug counters
        self.total_messages = 0
        self.attitude_messages = 0
        self.position_messages = 0
        self.last_debug_time = time.time()

    def run(self):
        """Enhanced run method with better error handling and debugging"""
        self.running = True
        print("[MAVLinkThread] Starting enhanced MAVLink thread...")
        
        consecutive_errors = 0
        max_consecutive_errors = 10
        
        while self.running:
            try:
                # Check for messages with timeout
                msg = self.connection.recv_match(timeout=0.1)
                
                if msg:
                    consecutive_errors = 0  # Reset error counter
                    self.total_messages += 1
                    self.message_count += 1
                    
                    # Process the message
                    self.process_message(msg)
                    
                    # Update data rate every second
                    current_time = time.time()
                    if current_time - self.last_rate_check >= 1.0:
                        rate = self.message_count / (current_time - self.last_rate_check)
                        self.dataRateUpdate.emit(rate)
                        self.message_count = 0
                        self.last_rate_check = current_time
                        
                        # Debug logging every 10 seconds
                        if current_time - self.last_debug_time >= 10.0:
                          
                            self.last_debug_time = current_time
                
                else:
                    # No message received, but this is normal with timeout
                    pass
                    
            except Exception as e:
                consecutive_errors += 1
                error_msg = f"MAVLink thread error #{consecutive_errors}: {str(e)}"
                print(f"[MAVLinkThread ERROR] {error_msg}")
                
                if consecutive_errors >= max_consecutive_errors:
                    print(f"[MAVLinkThread FATAL] Too many consecutive errors ({consecutive_errors}), stopping thread")
                    self.connectionError.emit(f"Connection failed after {consecutive_errors} errors")
                    break
                
                # Brief pause before retrying
                time.sleep(0.1)
        
        print("[MAVLinkThread] Thread stopped")

    def process_message(self, msg):
        """Enhanced message processing with better telemetry extraction"""
        try:
            msg_type = msg.get_type()
            telemetry_update = {}
            
            # Process different message types for comprehensive telemetry
            if msg_type == 'HEARTBEAT':
                telemetry_update.update({
                    'mode': self.get_flight_mode_name(msg.custom_mode, msg.type),
                    'armed': bool(msg.base_mode & mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED),
                    'system_status': msg.system_status
                })
                self.heartbeatReceived.emit()
                
            elif msg_type == 'GLOBAL_POSITION_INT':
                self.position_messages += 1
                telemetry_update.update({
                    'lat': msg.lat / 1e7,  # Convert from 1e7 degrees to degrees
                    'lon': msg.lon / 1e7,
                    'alt': msg.alt / 1000.0,  # Convert from mm to meters
                    'rel_alt': msg.relative_alt / 1000.0,
                    'vx': msg.vx / 100.0,  # Convert from cm/s to m/s
                    'vy': msg.vy / 100.0,
                    'vz': msg.vz / 100.0,
                    'heading': msg.hdg / 100.0  # Convert from centidegrees
                })
                
            elif msg_type == 'ATTITUDE':
                self.attitude_messages += 1
                telemetry_update.update({
                    'roll': math.degrees(msg.roll),
                    'pitch': math.degrees(msg.pitch),
                    'yaw': math.degrees(msg.yaw),
                    'rollspeed': math.degrees(msg.rollspeed),
                    'pitchspeed': math.degrees(msg.pitchspeed),
                    'yawspeed': math.degrees(msg.yawspeed)
                })
                
            elif msg_type == 'VFR_HUD':
                telemetry_update.update({
                    'airspeed': msg.airspeed,
                    'groundspeed': msg.groundspeed,
                    'heading': msg.heading,
                    'throttle': msg.throttle,
                    'alt': msg.alt,
                    'climb': msg.climb
                })
                
            elif msg_type == 'SYS_STATUS':
                telemetry_update.update({
                    'voltage_battery': msg.voltage_battery / 1000.0,  # Convert from mV to V
                    'current_battery': msg.current_battery / 100.0,  # Convert from cA to A
                    'battery_remaining': msg.battery_remaining,
                    'drop_rate_comm': msg.drop_rate_comm,
                    'errors_comm': msg.errors_comm
                })
                
            elif msg_type == 'BATTERY_STATUS':
                if msg.id == 0:  # Primary battery
                    voltages = [v/1000.0 for v in msg.voltages if v != 65535]  # Convert mV to V, ignore invalid readings
                    # FIXED: Use explicit value instead of INT16_MAX
                    temp_valid = hasattr(msg, 'temperature') and msg.temperature != 32767  # 32767 = INT16_MAX
                    telemetry_update.update({
                        'battery_voltage': voltages[0] if voltages else 0,
                        'battery_current': msg.current_battery / 100.0 if msg.current_battery != -1 else 0,
                        'battery_remaining': msg.battery_remaining if msg.battery_remaining != -1 else 0,
                        'battery_consumed': msg.current_consumed if hasattr(msg, 'current_consumed') else 0,
                        'battery_temperature': msg.temperature / 100.0 if temp_valid else 0
                    })
                
            elif msg_type == 'GPS_RAW_INT':
                telemetry_update.update({
                    'gps_lat': msg.lat / 1e7,
                    'gps_lon': msg.lon / 1e7,
                    'gps_alt': msg.alt / 1000.0,
                    'gps_eph': msg.eph / 100.0,
                    'gps_epv': msg.epv / 100.0,
                    'gps_vel': msg.vel / 100.0,
                    'gps_cog': msg.cog / 100.0,
                    'satellites_visible': msg.satellites_visible,
                    'fix_type': msg.fix_type
                })
                
            elif msg_type == 'RAW_IMU':
                # Raw IMU data for graphs
                telemetry_update.update({
                    'imu_xacc': msg.xacc,
                    'imu_yacc': msg.yacc,
                    'imu_zacc': msg.zacc,
                    'imu_xgyro': msg.xgyro,
                    'imu_ygyro': msg.ygyro,
                    'imu_zgyro': msg.zgyro,
                    'imu_xmag': msg.xmag,
                    'imu_ymag': msg.ymag,
                    'imu_zmag': msg.zmag
                })
                
            elif msg_type == 'SCALED_IMU':
                # Scaled IMU data (often more useful for displays)
                telemetry_update.update({
                    'imu_xacc_scaled': msg.xacc / 1000.0,  # Convert from mg to g
                    'imu_yacc_scaled': msg.yacc / 1000.0,
                    'imu_zacc_scaled': msg.zacc / 1000.0,
                    'imu_xgyro_scaled': msg.xgyro,  # Already in mrad/s
                    'imu_ygyro_scaled': msg.ygyro,
                    'imu_zgyro_scaled': msg.zgyro,
                    'imu_xmag_scaled': msg.xmag,   # Already in mgauss
                    'imu_ymag_scaled': msg.ymag,
                    'imu_zmag_scaled': msg.zmag
                })
                
            elif msg_type == 'STATUSTEXT':
                # Status messages from the autopilot
                try:
                    status_text = msg.text.decode('utf-8', errors='ignore').strip()
                    if status_text:
                        self.statusTextChanged.emit(f"[{msg.severity}] {status_text}")
                except:
                    # Fallback if decoding fails
                    self.statusTextChanged.emit(f"[{msg.severity}] Status message received")
                
            elif msg_type == 'PARAM_VALUE':
                # Parameter values (useful for configuration)
                try:
                    param_id = msg.param_id.decode('utf-8', errors='ignore').strip()
                    telemetry_update.update({
                        f'param_{param_id}': msg.param_value
                    })
                except:
                    # Skip if param_id can't be decoded
                    pass
            
            # Emit telemetry update if we have data
            if telemetry_update:
                # Add timestamp for graphs
                telemetry_update['timestamp'] = time.time()
                telemetry_update['message_type'] = msg_type
                
                # Emit the update
                self.telemetryUpdated.emit(telemetry_update)
                
                
        except Exception as e:
            print(f"[MAVLinkThread] Error processing {msg.get_type() if msg else 'unknown'} message: {e}")
            traceback.print_exc()

    def get_flight_mode_name(self, custom_mode, vehicle_type):
        """Convert custom mode number to flight mode name"""
        try:
            if vehicle_type == mavutil.mavlink.MAV_TYPE_QUADROTOR:
                # ArduCopter modes
                copter_modes = {
                    0: 'STABILIZE', 1: 'ACRO', 2: 'ALT_HOLD', 3: 'AUTO',
                    4: 'GUIDED', 5: 'LOITER', 6: 'RTL', 7: 'CIRCLE',
                    9: 'LAND', 11: 'DRIFT', 13: 'SPORT', 14: 'FLIP',
                    15: 'AUTOTUNE', 16: 'POSHOLD', 17: 'BRAKE', 18: 'THROW',
                    19: 'AVOID_ADSB', 20: 'GUIDED_NOGPS', 21: 'SMART_RTL',
                    22: 'FLOWHOLD', 23: 'FOLLOW', 24: 'ZIGZAG', 25: 'SYSTEMID',
                    26: 'AUTOROTATE'
                }
                return copter_modes.get(custom_mode, f'MODE_{custom_mode}')
            
            elif vehicle_type == mavutil.mavlink.MAV_TYPE_FIXED_WING:
                # ArduPlane modes
                plane_modes = {
                    0: 'MANUAL', 1: 'CIRCLE', 2: 'STABILIZE', 3: 'TRAINING',
                    4: 'ACRO', 5: 'FLY_BY_WIRE_A', 6: 'FLY_BY_WIRE_B',
                    7: 'CRUISE', 8: 'AUTOTUNE', 10: 'AUTO', 11: 'RTL',
                    12: 'LOITER', 15: 'GUIDED', 16: 'INITIALISING',
                    17: 'QSTABILIZE', 18: 'QHOVER', 19: 'QLOITER',
                    20: 'QLAND', 21: 'QRTL', 22: 'QAUTOTUNE'
                }
                return plane_modes.get(custom_mode, f'MODE_{custom_mode}')
            
            else:
                return f'MODE_{custom_mode}'
                
        except:
            return f'MODE_{custom_mode}'

    def stop(self):
        """Stop the thread gracefully"""
        print("[MAVLinkThread] Stopping MAVLink thread...")
        self.running = False
        
        # Wait for thread to finish (with timeout)
        if not self.wait(3000):  # 3 second timeout
            print("[MAVLinkThread WARNING] Thread did not stop gracefully, terminating...")
            self.terminate()
            self.wait(1000)  # Wait 1 more second for termination