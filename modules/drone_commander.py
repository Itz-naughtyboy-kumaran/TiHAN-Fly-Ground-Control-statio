import time
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QThread
from PyQt5.QtTextToSpeech import QTextToSpeech
from pymavlink import mavutil
from pymavlink.dialects.v20 import ardupilotmega as mavlink_dialect
from pymavlink.dialects.v20 import common as mavlink_common
from pymavlink.dialects.v20 import ardupilotmega as mavutil_ardupilot

class DroneCommander(QObject):
    commandFeedback = pyqtSignal(str)
    armDisarmCompleted = pyqtSignal(bool, str)
    parametersUpdated = pyqtSignal(dict)

    def __init__(self, drone_model):
        super().__init__()
        self.drone_model = drone_model
        self._parameters = {}
        
        # Initialize Text-to-Speech
        self.tts = QTextToSpeech(self)
        self.tts.setRate(0.0)  # Normal speed
        self.tts.setVolume(1.0)  # Full volume
        
        print("[DroneCommander] Initialized with TTS support.")

    def _speak(self, message):
        """Helper method to speak messages"""
        try:
            self.tts.say(message)
            print(f"[DroneCommander TTS] Speaking: {message}")
        except Exception as e:
            print(f"[DroneCommander TTS ERROR] Failed to speak: {e}")

    @property
    def _drone(self):
        return self.drone_model.drone_connection

    def _is_drone_ready(self):
        if not self._drone or not self.drone_model.isConnected:
            self.commandFeedback.emit("Error: Drone not connected or ready.")
            self._speak("Error. Drone not connected.")
            print("[DroneCommander] Command failed: Drone not connected.")
            return False
        
        if self._drone.target_system == 0 or self._drone.target_component == 0:
            print(f"[DroneCommander] WARNING: target_system={self._drone.target_system}, target_component={self._drone.target_component}")
            if self._drone.target_system == 0:
                self._drone.target_system = 1
            if self._drone.target_component == 0:
                self._drone.target_component = 1
            print(f"[DroneCommander] Set target_system={self._drone.target_system}, target_component={self._drone.target_component}")
        
        return True
    
    @pyqtSlot(result=bool)
    def calibrateESCs(self):
        if not self._is_drone_ready():
            self.commandFeedback.emit("Error: Drone not connected.")
            self._speak("Error. Drone not connected.")
            return False
        try:
            self.commandFeedback.emit("Starting ESC Calibration...")
            self._speak("Starting E S C Calibration. Follow safety steps.")

            self._drone.mav.param_set_send(
                self._drone.target_system,
                self._drone.target_component,
                b'ESC_CALIBRATION',
                1,
                mavutil.mavlink.MAV_PARAM_TYPE_INT32
            )

            self._drone.mav.command_long_send(
                self._drone.target_system,
                self._drone.target_component,
                mavutil.mavlink.MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN,
                0,
                1, 0, 0, 0, 0, 0, 0
            )

            self.commandFeedback.emit("ESC Calibration initiated. Follow safety steps.")
            return True
        except Exception as e:
            self.commandFeedback.emit(f"ESC Calibration failed: {e}")
            self._speak("E S C Calibration failed.")
            return False

    @pyqtSlot(result=bool)
    def rebootAutopilot(self):
        """Reboot the autopilot via MAVLink command"""
        if not self._is_drone_ready():
            self.commandFeedback.emit("Error: Drone not connected for reboot.")
            self._speak("Error. Drone not connected for reboot.")
            return False
        
        print("[DroneCommander] Reboot autopilot requested")
        
        try:
            print("[DroneCommander] Sending autopilot reboot command...")
            
            self._drone.mav.command_long_send(
                self._drone.target_system,
                self._drone.target_component,
                mavutil.mavlink.MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN,
                0,
                1,
                0,
                0, 0, 0, 0, 0
            )
            
            print("[DroneCommander] Reboot command sent successfully")
            self.commandFeedback.emit("Autopilot reboot command sent - device will restart")
            self._speak("Autopilot reboot command sent. Device will restart.")
            return True
            
        except Exception as e:
            error_msg = f"Reboot command failed: {e}"
            print(f"[DroneCommander] {error_msg}")
            self.commandFeedback.emit(error_msg)
            self._speak("Reboot command failed.")
            return False
        
    @pyqtSlot(result=bool)
    def arm(self):
        if not self._is_drone_ready(): 
            self.armDisarmCompleted.emit(False, "Drone not connected.")
            self._speak("Error. Drone not connected.")
            return False
        
        print(f"\n[DroneCommander] ===== ARM REQUEST =====")
        print(f"[DroneCommander] Target system: {self._drone.target_system}")
        print(f"[DroneCommander] Target component: {self._drone.target_component}")
        
        self._speak("Arming drone. Please wait.")
        
        try:
            print("[DroneCommander] Sending ARM commands...")
            for i in range(5):
                self._drone.mav.command_long_send(
                    self._drone.target_system,
                    self._drone.target_component,
                    mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
                    0,
                    1,
                    0, 0, 0, 0, 0, 0
                )
                print(f"[DroneCommander]   ARM attempt {i+1}/5")
                time.sleep(0.1)
            
            self.commandFeedback.emit("Arm commands sent, waiting for confirmation...")
            
            print("[DroneCommander] Monitoring telemetry for armed state...")
            start_time = time.time()
            while time.time() - start_time < 5:
                is_armed = self.drone_model.telemetry.get('armed', False)
                if is_armed:
                    self.armDisarmCompleted.emit(True, "Drone Armed Successfully!")
                    self._speak("Drone armed successfully.")
                    print("[DroneCommander] ARM confirmed via telemetry")
                    return True
                
                msg = self._drone.recv_match(type='COMMAND_ACK', blocking=False, timeout=0.1)
                if msg and msg.command == mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM:
                    if msg.result == mavutil.mavlink.MAV_RESULT_ACCEPTED:
                        self.armDisarmCompleted.emit(True, "Drone Armed Successfully!")
                        self._speak("Drone armed successfully.")
                        print("[DroneCommander] ARM confirmed via ACK")
                        return True
                    elif msg.result == mavutil.mavlink.MAV_RESULT_DENIED:
                        self.armDisarmCompleted.emit(False, "ARM denied - check pre-arm checks")
                        self._speak("Arm command denied. Check pre-arm checks.")
                        print(f"[DroneCommander] ARM denied: {msg.result}")
                        return False
                
                time.sleep(0.1)
            
            is_armed = self.drone_model.telemetry.get('armed', False)
            if is_armed:
                self.armDisarmCompleted.emit(True, "Drone Armed Successfully!")
                self._speak("Drone armed successfully.")
                return True
            else:
                self.armDisarmCompleted.emit(False, "ARM command timeout - check drone logs")
                self._speak("Arm command timeout. Check drone logs.")
                print("[DroneCommander] ARM timeout")
                return False
                
        except Exception as e:
            msg = f"Error sending ARM command: {e}"
            self.commandFeedback.emit(msg)
            self.armDisarmCompleted.emit(False, msg)
            self._speak("Error sending arm command.")
            print(f"[DroneCommander ERROR] ARM command failed: {e}")
            return False

    @pyqtSlot(result=bool)
    def disarm(self):
        if not self._is_drone_ready(): 
            self.armDisarmCompleted.emit(False, "Drone not connected.")
            self._speak("Error. Drone not connected.")
            return False

        print("[DroneCommander] Sending DISARM command...")
        self._speak("Disarming drone.")
        
        try:
            self._drone.mav.command_long_send(
                self._drone.target_system,
                self._drone.target_component,
                mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
                0, 0, 0, 0, 0, 0, 0, 0
            )
            self.commandFeedback.emit("Disarm command sent. Waiting for confirmation...")
            
            ack_result = self._wait_for_command_ack(mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM)

            if ack_result == mavutil.mavlink.MAV_RESULT_ACCEPTED:
                self.armDisarmCompleted.emit(True, "Drone Disarmed Successfully!")
                self._speak("Drone disarmed successfully.")
                return True
            elif ack_result == mavutil.mavlink.MAV_RESULT_DENIED:
                msg = "Disarm command denied by drone. (e.g., motors running)."
                self.armDisarmCompleted.emit(False, msg)
                self._speak("Disarm command denied. Motors may be running.")
                return False
            elif ack_result == mavutil.mavlink.MAV_RESULT_FAILED:
                msg = "Disarm command failed on drone. Check drone status/log."
                self.armDisarmCompleted.emit(False, msg)
                self._speak("Disarm command failed. Check drone status.")
                return False
            else:
                msg = "Disarm command timed out or received unknown ACK result. Check drone status/log."
                self.armDisarmCompleted.emit(False, msg)
                self._speak("Disarm command timed out.")
                return False
        except Exception as e:
            msg = f"Error sending DISARM command: {e}"
            self.commandFeedback.emit(msg)
            self.armDisarmCompleted.emit(False, msg)
            self._speak("Error sending disarm command.")
            print(f"[DroneCommander ERROR] DISARM command failed: {e}")
            return False

    @pyqtSlot(float, result=bool)
    def takeoff(self, target_altitude):
     """
     Simple takeoff command with automatic mode change to GUIDED
     """
     if not self._is_drone_ready(): 
        self.commandFeedback.emit("Error: Drone not connected.")
        self._speak("Error. Drone not connected.")
        return False
    
     print(f"\n[DroneCommander] ===== TAKEOFF REQUEST =====")
     print(f"[DroneCommander] Target altitude: {target_altitude}m")
    
    # Step 1: Check if armed
     is_armed = self.drone_model.telemetry.get('armed', False)
     print(f"[DroneCommander] Armed state: {is_armed}")
     if not is_armed:
        self.commandFeedback.emit("Error: Drone must be armed before takeoff.")
        self._speak("Error. Drone must be armed before takeoff.")
        return False
    
    # Step 2: Check GPS
     current_lat = self.drone_model.telemetry.get('lat')
     current_lon = self.drone_model.telemetry.get('lon')
     print(f"[DroneCommander] GPS position: lat={current_lat}, lon={current_lon}")
    
     if current_lat is None or current_lon is None:
        self.commandFeedback.emit("Error: GPS position not available.")
        self._speak("Error. G P S position not available.")
        return False
    
    # Step 3: Automatically change to GUIDED mode if not already
     current_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
     print(f"[DroneCommander] Current mode: {current_mode}")
    
     if current_mode != 'GUIDED':
        print("[DroneCommander] Changing mode to GUIDED for takeoff...")
        self.commandFeedback.emit("Changing to GUIDED mode for takeoff...")
        self._speak("Changing to guided mode.")
        
        # Send mode change command
        mode_id = self._drone.mode_mapping().get('GUIDED')
        if mode_id is not None:
            for i in range(3):
                self._drone.mav.set_mode_send(
                    self._drone.target_system,
                    mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                    mode_id
                )
                time.sleep(0.1)
            
            # Wait for mode change (up to 2 seconds)
            start_time = time.time()
            while time.time() - start_time < 2:
                current_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
                if current_mode == 'GUIDED':
                    print("[DroneCommander] Mode changed to GUIDED successfully")
                    break
                time.sleep(0.1)
            
            time.sleep(0.3)  # Small delay after mode change
    
    # Step 4: Get initial altitude
     initial_alt = self.drone_model.telemetry.get('alt', 0)
     print(f"[DroneCommander] Initial altitude: {initial_alt}m")
     print(f"[DroneCommander] Sending TAKEOFF command to {target_altitude}m...")
    
     self._speak(f"Drone taking off to {int(target_altitude)} meters altitude.")
    
     try:
        # Send takeoff command
        self._drone.mav.command_long_send(
            self._drone.target_system,
            self._drone.target_component,
            mavutil.mavlink.MAV_CMD_NAV_TAKEOFF,
            0,  # confirmation
            0,  # param1: pitch
            0,  # param2: empty
            0,  # param3: empty
            0,  # param4: yaw angle
            current_lat,  # param5: latitude
            current_lon,  # param6: longitude
            target_altitude  # param7: altitude
        )
        
        self.commandFeedback.emit(f"Takeoff command sent to {target_altitude}m. Monitoring...")
        print("[DroneCommander] Takeoff command sent, monitoring altitude change...")
        
        # Monitor altitude for 3 seconds to confirm takeoff
        start_time = time.time()
        while time.time() - start_time < 3:
            current_alt = self.drone_model.telemetry.get('alt', initial_alt)
            
            # If altitude increased, takeoff is working
            if current_alt > initial_alt + 0.5:
                success_msg = f"Takeoff initiated! Climbing to {target_altitude}m (current: {current_alt:.1f}m)"
                self.commandFeedback.emit(success_msg)
                self._speak("Takeoff initiated successfully.")
                print(f"[DroneCommander] Takeoff confirmed - altitude: {current_alt}m")
                return True
            
            time.sleep(0.1)
        
        # After 3 seconds, check final altitude
        final_alt = self.drone_model.telemetry.get('alt', initial_alt)
        print(f"[DroneCommander] After 3s - altitude: {final_alt}m (started at {initial_alt}m)")
        
        # Assume success if command was sent (drone might be climbing slowly)
        success_msg = f"Takeoff command sent successfully to {target_altitude}m"
        self.commandFeedback.emit(success_msg)
        self._speak("Takeoff command sent successfully.")
        print(f"[DroneCommander] Takeoff command sent (altitude may be changing: {final_alt}m)")
        return True
        
     except Exception as e:
        error_msg = f"Error sending takeoff command: {e}"
        self.commandFeedback.emit(error_msg)
        self._speak("Error sending takeoff command.")
        print(f"[DroneCommander ERROR] {e}")
        return False

    @pyqtSlot(result=bool)
    def land(self):
        if not self._is_drone_ready(): 
            self.commandFeedback.emit("Error: Drone not connected.")
            self._speak("Error. Drone not connected.")
            return False
            
        if self.drone_model.telemetry.get('lat') is None or self.drone_model.telemetry.get('lon') is None:
            self.commandFeedback.emit("Error: GPS position not available for land.")
            self._speak("Error. G P S position not available for landing.")
            print("[DroneCommander] Land failed: GPS position not available.")
            return False

        print("[DroneCommander] Sending LAND command...")
        self._speak("Drone landing initiated.")
        
        try:
            self._drone.mav.command_long_send(
                self._drone.target_system,
                self._drone.target_component,
                mavutil.mavlink.MAV_CMD_NAV_LAND,
                0,
                0, 0, 0, 0,
                self.drone_model.telemetry['lat'],
                self.drone_model.telemetry['lon'],
                0
            )
            self.commandFeedback.emit("Land command sent. Waiting for confirmation...")

            ack_result = self._wait_for_command_ack(mavutil.mavlink.MAV_CMD_NAV_LAND)
            if ack_result == mavutil.mavlink.MAV_RESULT_ACCEPTED:
                self.commandFeedback.emit("Land initiated successfully!")
                self._speak("Landing initiated successfully.")
                return True
            else:
                self.commandFeedback.emit(f"Land command failed or denied. Result: {ack_result}")
                self._speak("Land command failed or denied.")
                return False
        except Exception as e:
            self.commandFeedback.emit(f"Error sending LAND command: {e}")
            self._speak("Error sending land command.")
            print(f"[DroneCommander ERROR] LAND command failed: {e}")
            return False

    @pyqtSlot(str, result=bool)
    def setMode(self, mode_name):
        if not self._is_drone_ready(): 
            self.commandFeedback.emit("Error: Drone not connected.")
            self._speak("Error. Drone not connected.")
            return False

        print(f"\n[DroneCommander] ===== MODE CHANGE REQUEST =====")
        print(f"[DroneCommander] Requested mode: {mode_name}")
        print(f"[DroneCommander] Target system: {self._drone.target_system}")
        print(f"[DroneCommander] Target component: {self._drone.target_component}")
        
        self._speak(f"Changing mode to {mode_name}.")
        
        try:
            mode_id = self._drone.mode_mapping().get(mode_name.upper())
            if mode_id is None:
                available_modes = list(self._drone.mode_mapping().keys())
                self.commandFeedback.emit(f"Error: Unknown mode '{mode_name}'. Available: {available_modes}")
                self._speak(f"Error. Unknown mode {mode_name}.")
                print(f"[DroneCommander] Available modes: {available_modes}")
                return False

            print(f"[DroneCommander] Mode ID: {mode_id}")
            
            print("[DroneCommander] Sending mode change commands...")
            for i in range(5):
                self._drone.mav.set_mode_send(
                    self._drone.target_system,
                    mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                    mode_id
                )
                print(f"[DroneCommander]   Sent attempt {i+1}/5")
                time.sleep(0.1)
            
            self.commandFeedback.emit(f"Mode change to '{mode_name}' sent (waiting for confirmation)")
            
            print("[DroneCommander] Monitoring telemetry for mode change...")
            start_time = time.time()
            while time.time() - start_time < 3:
                current_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
                if current_mode == mode_name.upper():
                    self.commandFeedback.emit(f"Mode changed to '{mode_name}' successfully!")
                    self._speak(f"Mode changed to {mode_name} successfully.")
                    print(f"[DroneCommander] Mode change confirmed via telemetry")
                    return True
                time.sleep(0.1)
            
            print("[DroneCommander] Mode change sent, no telemetry confirmation yet")
            self.commandFeedback.emit(f"Mode change command sent to '{mode_name}'")
            self._speak(f"Mode change command sent to {mode_name}.")
            return True
            
        except Exception as e:
            self.commandFeedback.emit(f"Error sending SET_MODE command: {e}")
            self._speak("Error sending mode change command.")
            print(f"[DroneCommander ERROR] SET_MODE command failed: {e}")
            return False

    def _wait_for_command_ack(self, command_id, timeout=5):
        """Helper to wait for command acknowledgment"""
        start_time = time.time()
        while time.time() - start_time < timeout:
            msg = self._drone.recv_match(type='COMMAND_ACK', blocking=True, timeout=0.1)
            if msg and msg.command == command_id:
                return msg.result
        return None
     
    @pyqtSlot('QVariantList', result=bool)
    def uploadMission(self, waypoints):
        if not self._is_drone_ready(): 
            self._speak("Error. Drone not connected.")
            return False
        if not waypoints:
            self.commandFeedback.emit("Error: No waypoints provided for mission upload.")
            self._speak("Error. No waypoints provided for mission upload.")
            return False

        print(f"[DroneCommander] Mission Upload: {len(waypoints)} waypoints...")
        self.commandFeedback.emit(f"Uploading mission with {len(waypoints)} waypoints...")
        self._speak(f"Uploading mission with {len(waypoints)} waypoints.")

        try:
            print("\n=== MISSION UPLOAD DIAGNOSTICS ===")
            print(f"Connection object: {type(self._drone)}")
            print(f"Target system: {self._drone.target_system}")
            print(f"Target component: {self._drone.target_component}")
            print(f"Source system: {getattr(self._drone, 'source_system', 'Unknown')}")
            print(f"Source component: {getattr(self._drone, 'source_component', 'Unknown')}")
            print(f"Connection port: {getattr(self._drone, 'port', 'Unknown')}")
            print("=====================================\n")
            
            print("[DroneCommander] Testing basic communication...")
            
            self._drone.mav.heartbeat_send(
                mavutil.mavlink.MAV_TYPE_GCS,
                mavutil.mavlink.MAV_AUTOPILOT_INVALID,
                0, 0, 0
            )
            
            print("[DroneCommander] Listening for ANY messages from drone...")
            message_count = 0
            start_time = time.time()
            
            while time.time() - start_time < 3:
                msg = self._drone.recv_match(blocking=False, timeout=0.1)
                if msg:
                    message_count += 1
                    print(f"[DroneCommander] Received: {msg.get_type()} from system {msg.get_srcSystem()}")
                    
                    if msg.get_type() == 'HEARTBEAT':
                        print(f"  - Heartbeat details: type={msg.type}, autopilot={msg.autopilot}")
                    elif msg.get_type() == 'MISSION_ACK':
                        print(f"  - Mission ACK: type={msg.type}")
                    elif msg.get_type() == 'MISSION_REQUEST':
                        print(f"  - Mission Request: seq={msg.seq}")
                        
                if message_count > 0 and message_count % 10 == 0:
                    print(f"[DroneCommander] Received {message_count} messages so far...")
            
            print(f"[DroneCommander] Total messages received in 3s: {message_count}")
            
            if message_count == 0:
                self.commandFeedback.emit("ERROR: No messages received from drone - connection may be broken")
                self._speak("Error. No messages received from drone.")
                print("[DroneCommander ERROR] No communication with drone detected")
                return False
            
            if self._drone.target_system == 0:
                self._drone.target_system = 1
                print("[DroneCommander] Set target_system to 1")
            
            if self._drone.target_component == 0:
                self._drone.target_component = 1
                print("[DroneCommander] Set target_component to 1")
            
            print("[DroneCommander] Testing mission protocol - requesting current mission...")
            self._drone.mav.mission_request_list_send(
                self._drone.target_system,
                self._drone.target_component
            )
            
            mission_protocol_works = False
            start_time = time.time()
            while time.time() - start_time < 8:
                msg = self._drone.recv_match(type=['MISSION_COUNT', 'MISSION_ACK'], blocking=False, timeout=0.5)
                if msg:
                    print(f"[DroneCommander] Mission protocol test result: {msg.get_type()}")
                    if msg.get_type() == 'MISSION_COUNT':
                        print(f"  - Current mission has {msg.count} waypoints")
                        mission_protocol_works = True
                        break
                    elif msg.get_type() == 'MISSION_ACK':
                        print(f"  - Mission ACK: {msg.type}")
                        if msg.type == mavutil.mavlink.MAV_MISSION_ACCEPTED or msg.type == mavutil.mavlink.MAV_MISSION_NO_SPACE:
                            mission_protocol_works = True
                            break
            
            if not mission_protocol_works:
                print("[DroneCommander] Mission protocol test failed, but continuing anyway...")
                print("[DroneCommander] This is common with some SITL configurations")
            else:
                print("[DroneCommander] Mission protocol is working, proceeding with upload...")
            
            print("[DroneCommander] Clearing existing mission...")
            self._drone.mav.mission_clear_all_send(
                self._drone.target_system,
                self._drone.target_component
            )
            
            clear_ack = self._drone.recv_match(type='MISSION_ACK', blocking=True, timeout=3)
            if clear_ack:
                print(f"[DroneCommander] Mission clear result: {clear_ack.type}")
            else:
                print("[DroneCommander] No clear acknowledgment received, continuing...")
            
            time.sleep(0.5)
            
            mission_waypoints = []
            
            current_lat = self.drone_model.telemetry.get('lat', 0.0)
            current_lon = self.drone_model.telemetry.get('lon', 0.0)
            takeoff_alt = waypoints[0].get('z', 10.0) if waypoints else 10.0
            
            print(f"[DroneCommander] Current position: {current_lat:.6f}, {current_lon:.6f}")
            
            takeoff_waypoint = {
                'seq': 0,
                'frame': mavutil.mavlink.MAV_FRAME_GLOBAL_RELATIVE_ALT_INT,
                'command': mavutil.mavlink.MAV_CMD_NAV_TAKEOFF,
                'current': 1,
                'autocontinue': 1,
                'param1': 0, 'param2': 0, 'param3': 0, 'param4': 0,
                'x': current_lat, 'y': current_lon, 'z': takeoff_alt
            }
            mission_waypoints.append(takeoff_waypoint)
            
            for i, wp in enumerate(waypoints):
                waypoint = {
                    'seq': i + 1,
                    'frame': mavutil.mavlink.MAV_FRAME_GLOBAL_RELATIVE_ALT_INT,
                    'command': mavutil.mavlink.MAV_CMD_NAV_WAYPOINT,
                    'current': 0,
                    'autocontinue': 1,
                    'param1': 0, 'param2': 0, 'param3': 0, 'param4': 0,
                    'x': wp.get('x', 0), 'y': wp.get('y', 0), 'z': wp.get('z', 10)
                }
                mission_waypoints.append(waypoint)
            
            total_waypoints = len(mission_waypoints)
            print(f"[DroneCommander] Prepared {total_waypoints} waypoints")
            
            print(f"[DroneCommander] Sending MISSION_COUNT: {total_waypoints}")
            self._drone.mav.mission_count_send(
                self._drone.target_system,
                self._drone.target_component,
                total_waypoints
            )
            
            print("[DroneCommander] Monitoring for mission response...")
            start_time = time.time()
            timeout = 10
            
            while time.time() - start_time < timeout:
                msg = self._drone.recv_match(blocking=False, timeout=0.1)
                if msg:
                    msg_type = msg.get_type()
                    print(f"[DroneCommander] Received during mission upload: {msg_type}")
                    
                    if msg_type == 'MISSION_REQUEST':
                        print(f"[DroneCommander] SUCCESS: Mission request for seq {msg.seq}")
                        if msg.seq == 0:
                            return self._send_waypoints_inline(mission_waypoints)
                        
                    elif msg_type == 'MISSION_ACK':
                        print(f"[DroneCommander] Mission ACK during upload: {msg.type}")
                        if msg.type != mavutil.mavlink.MAV_MISSION_ACCEPTED:
                            self.commandFeedback.emit(f"Mission rejected: {msg.type}")
                            self._speak("Mission rejected.")
                            return False
            
            self.commandFeedback.emit("ERROR: No mission request received - drone not accepting missions")
            self._speak("Error. No mission request received.")
            print("[DroneCommander ERROR] No mission request received after mission count")
            return False
             
        except Exception as e:
            self.commandFeedback.emit(f"Mission upload error: {str(e)}")
            self._speak("Mission upload error.")
            print(f"[DroneCommander ERROR] Exception: {e}")
            import traceback
            traceback.print_exc()
            return False

    def _send_waypoints_inline(self, waypoints):
        """Send all waypoints in response to mission requests - inline implementation"""
        try:
            total_waypoints = len(waypoints)
            waypoints_sent = 0
            
            wp = waypoints[0]
            x_int = int(wp['x'] * 1e7)
            y_int = int(wp['y'] * 1e7)
            z_float = float(wp['z'])
            
            self._drone.mav.mission_item_int_send(
                self._drone.target_system, self._drone.target_component,
                wp['seq'], wp['frame'], wp['command'], wp['current'], wp['autocontinue'],
                wp['param1'], wp['param2'], wp['param3'], wp['param4'],
                x_int, y_int, z_float
            )
            print(f"[DroneCommander] Sent waypoint 0: cmd={wp['command']}, lat={wp['x']:.6f}, lon={wp['y']:.6f}, alt={wp['z']}")
            waypoints_sent = 1
            
            while waypoints_sent < total_waypoints:
                print(f"[DroneCommander] Waiting for mission request {waypoints_sent}...")
                
                start_time = time.time()
                request_received = False
                expected_seq = waypoints_sent
                
                while time.time() - start_time < 15:
                    msg = self._drone.recv_match(type=['MISSION_REQUEST', 'MISSION_ACK'], blocking=False, timeout=0.5)
                    
                    if msg:
                        if msg.get_type() == 'MISSION_REQUEST':
                            print(f"[DroneCommander] Got mission request for seq {msg.seq} (expected {expected_seq})")
                            request_received = True
                            
                            if msg.seq < total_waypoints:
                                wp_to_send = waypoints[msg.seq]
                                
                                x_int = int(wp_to_send['x'] * 1e7)
                                y_int = int(wp_to_send['y'] * 1e7)
                                z_float = float(wp_to_send['z'])
                                
                                self._drone.mav.mission_item_int_send(
                                    self._drone.target_system, self._drone.target_component,
                                    wp_to_send['seq'], wp_to_send['frame'], wp_to_send['command'], 
                                    wp_to_send['current'], wp_to_send['autocontinue'],
                                    wp_to_send['param1'], wp_to_send['param2'], wp_to_send['param3'], wp_to_send['param4'],
                                    x_int, y_int, z_float
                                )
                                print(f"[DroneCommander] Sent waypoint {msg.seq}: cmd={wp_to_send['command']}, lat={wp_to_send['x']:.6f}, lon={wp_to_send['y']:.6f}, alt={wp_to_send['z']}")
                                
                                if msg.seq == expected_seq:
                                    waypoints_sent += 1
                                elif msg.seq >= waypoints_sent:
                                    waypoints_sent = msg.seq + 1
                                    
                            break
                            
                        elif msg.get_type() == 'MISSION_ACK':
                            print(f"[DroneCommander] Received early mission ACK: {msg.type}")
                            if msg.type == mavutil.mavlink.MAV_MISSION_ACCEPTED:
                                print("[DroneCommander] Mission completed successfully (early ACK)")
                                self.commandFeedback.emit("Mission upload successful!")
                                self._speak("Mission upload successful.")
                                return True
                            else:
                                error_msg = f"Mission rejected during upload: {msg.type}"
                                print(f"[DroneCommander] {error_msg}")
                                self.commandFeedback.emit(error_msg)
                                self._speak("Mission rejected during upload.")
                                return False
                
                if not request_received:
                    error_msg = f"Timeout waiting for mission request {expected_seq}"
                    print(f"[DroneCommander ERROR] {error_msg}")
                    self.commandFeedback.emit(error_msg)
                    self._speak("Timeout waiting for mission request.")
                    return False
            
            print("[DroneCommander] All waypoints sent successfully")
            self.commandFeedback.emit("Mission upload successful!")
            self._speak("Mission upload successful.")
            return True
            
        except Exception as e:
            print(f"[DroneCommander ERROR] Waypoint sending failed: {e}")
            import traceback
            traceback.print_exc()
            self.commandFeedback.emit(f"Mission upload error: {str(e)}")
            self._speak("Mission upload error.")
            return False

    def requestAllParameters(self):
        if not self._is_drone_ready():
            self.commandFeedback.emit("Error: Drone not connected to request parameters.")
            self._speak("Error. Drone not connected to request parameters.")
            return False
    
        print("[DroneCommander] Requesting all MAVLink parameters...")
        self.commandFeedback.emit("Requesting all MAVLink parameters...")
        self._speak("Requesting all MAVLink parameters.")
        
        self._parameters = {}
    
        try:
            self._drone.mav.param_request_list_send(
                self._drone.target_system,
                self._drone.target_component
            )
    
            start_time = time.time()
            received_count = 0
            total_params = -1
    
            timeout_per_param = 0.5
            max_total_timeout = 30
    
            while time.time() - start_time < max_total_timeout:
                msg = self._drone.recv_match(type='PARAM_VALUE', blocking=True, timeout=timeout_per_param)
                
                if msg:
                    param_id = msg.param_id.strip()
                    param_value = msg.param_value
                    
                    self._parameters[param_id] = {
                        "name": param_id,
                        "value": param_value,
                        "type": msg.param_type,
                        "index": msg.param_index,
                        "count": msg.param_count
                    }
    
                    if total_params == -1:
                        total_params = msg.param_count
                        print(f"[DroneCommander] Expected {total_params} parameters.")
    
                    received_count = msg.param_index + 1
    
                    self.commandFeedback.emit(f"Received {received_count}/{total_params}: {param_id} = {param_value}")
                    
                    if total_params != -1 and received_count >= total_params:
                        print(f"[DroneCommander] All {total_params} parameters received.")
                        break
                else:
                    if total_params != -1 and received_count > 0:
                        print(f"[DroneCommander] Finished receiving parameters. Received {received_count}/{total_params} (or timed out waiting for more).")
                        break
                    
            if total_params == -1:
                self.commandFeedback.emit("Failed to receive any parameters. Drone might not be responding.")
                self._speak("Failed to receive any parameters.")
                print("[DroneCommander ERROR] No parameters received.")
                return False
            elif received_count < total_params:
                self.commandFeedback.emit(f"Warning: Only received {received_count}/{total_params} parameters.")
                self._speak(f"Warning. Only received {received_count} of {total_params} parameters.")
                print(f"[DroneCommander WARNING] Only received {received_count}/{total_params} parameters.")
            else:
                self.commandFeedback.emit(f"Successfully received all {total_params} parameters!")
                self._speak(f"Successfully received all {total_params} parameters.")
                print(f"[DroneCommander] Successfully received all {total_params} parameters!")
    
            self.parametersUpdated.emit(self._parameters)  
            return True
    
        except Exception as e:
            msg = f"Error requesting parameters: {e}"
            self.commandFeedback.emit(msg)
            self._speak("Error requesting parameters.")
            print(f"[DroneCommander ERROR] {msg}")
            return False

    @pyqtProperty('QVariant', notify=parametersUpdated)
    def parameters(self):
        print(self._parameters)
        return self._parameters

    @pyqtSlot(str, float, result=bool)
    def setParameter(self, param_id, param_value):
        if not self._is_drone_ready():
            self.commandFeedback.emit("Error: Drone not connected to set parameters.")
            self._speak("Error. Drone not connected to set parameters.")
            return False
        
        print(f"[DroneCommander] Setting parameter '{param_id}' to {param_value}...")
        self.commandFeedback.emit(f"Setting parameter '{param_id}' to {param_value}...")
        self._speak(f"Setting parameter {param_id} to {param_value}.")
        
        try:
            self._drone.mav.param_set_send(
                self._drone.target_system,
                self._drone.target_component,
                param_id.encode('utf-8'),
                param_value,
                mavutil.mavlink.MAV_PARAM_TYPE_REAL32
            )
            
            start_time = time.time()
            ack_timeout = 5
            while time.time() - start_time < ack_timeout:
                msg = self._drone.recv_match(type='PARAM_VALUE', blocking=True, timeout=0.1)
                if msg and msg.param_id.decode().strip() == param_id:
                    if msg.param_value == param_value:
                        self.commandFeedback.emit(f"Parameter '{param_id}' set successfully to {msg.param_value}")
                        self._speak(f"Parameter {param_id} set successfully.")
                        self._parameters[param_id] = msg.param_value
                        self.parametersUpdated.emit(self._parameters.copy())
                        return True
                    else:
                        self.commandFeedback.emit(f"Parameter '{param_id}' set, but value mismatch (expected {param_value}, got {msg.param_value}).")
                        self._speak(f"Parameter {param_id} set, but value mismatch.")
                        self._parameters[param_id] = msg.param_value
                        self.parametersUpdated.emit(self._parameters.copy())
                        return False
            
            self.commandFeedback.emit(f"Failed to get confirmation for parameter '{param_id}' set within timeout.")
            self._speak("Failed to get parameter confirmation.")
            return False
            
        except Exception as e:
            msg = f"Error setting parameter '{param_id}': {e}"
            self.commandFeedback.emit(msg)
            self._speak(f"Error setting parameter {param_id}.")
            print(f"[DroneCommander ERROR] {msg}")
            return False