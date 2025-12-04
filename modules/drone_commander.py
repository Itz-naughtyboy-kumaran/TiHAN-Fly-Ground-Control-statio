import time
import queue
import threading
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QThread
from PyQt5.QtTextToSpeech import QTextToSpeech
from pymavlink import mavutil
from pymavlink.dialects.v20 import ardupilotmega as mavlink_dialect
from pymavlink.dialects.v20 import common as mavlink_common
from pymavlink.dialects.v20 import ardupilotmega as mavutil_ardupilot

class DroneCommander(QObject):
    commandFeedback = pyqtSignal(str)
    armDisarmCompleted = pyqtSignal(bool, str)
    parametersUpdated = pyqtSignal()  # FIXED: No arguments, QML will read property
    parameterReceived = pyqtSignal(str, float)  # Individual parameter updates

   # Add to __init__
    def __init__(self, drone_model):
     super().__init__()
     self.drone_model = drone_model
     self._parameters = {}
     self._param_lock = threading.Lock()
     self._fetching_params = False
     self._param_queue = queue.Queue()
     self._param_request_active = False
    
    # Mode change protection
     self._mode_change_in_progress = False
     self._mode_change_lock = threading.Lock()
     self._last_mode_change_time = 0
     self._mode_change_cooldown = 0.5
    
    # Initialize Text-to-Speech
     self.tts = QTextToSpeech(self)
     self.tts.setRate(0.0)
     self.tts.setVolume(1.0)
    
     print("[DroneCommander] Initialized with non-blocking mode change.")

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
     """Takeoff command with automatic arming and mode change to GUIDED"""
     if not self._is_drone_ready(): 
        self.commandFeedback.emit("Error: Drone not connected.")
        self._speak("Error. Drone not connected.")
        return False

     print(f"\n[DroneCommander] ===== TAKEOFF REQUEST =====")
     print(f"[DroneCommander] Target altitude: {target_altitude}m")

    # Step 1: Check if armed, if not - ARM automatically
     is_armed = self.drone_model.telemetry.get('armed', False)
     print(f"[DroneCommander] Armed state: {is_armed}")
    
     if not is_armed:
        print("[DroneCommander] Drone not armed - arming automatically...")
        self.commandFeedback.emit("Arming drone automatically...")
        self._speak("Arming drone for takeoff.")
        
        # Send ARM commands
        for i in range(5):
            self._drone.mav.command_long_send(
                self._drone.target_system,
                self._drone.target_component,
                mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
                0,
                1,  # 1 = ARM
                0, 0, 0, 0, 0, 0
            )
            time.sleep(0.1)
        
        # Wait for armed confirmation (up to 5 seconds)
        start_time = time.time()
        armed_success = False
        while time.time() - start_time < 5:
            is_armed = self.drone_model.telemetry.get('armed', False)
            if is_armed:
                print("[DroneCommander] Drone armed successfully")
                self.commandFeedback.emit("Drone armed successfully!")
                armed_success = True
                break
            time.sleep(0.1)
        
        if not armed_success:
            self.commandFeedback.emit("Error: Failed to arm drone - check pre-arm checks")
            self._speak("Error. Failed to arm drone. Check pre-arm checks.")
            return False
        
        time.sleep(0.5)  # Small delay after arming

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
            
            time.sleep(0.3)

    # Step 4: Get initial altitude and send takeoff command
     initial_alt = self.drone_model.telemetry.get('alt', 0)
     print(f"[DroneCommander] Initial altitude: {initial_alt}m")
     print(f"[DroneCommander] Sending TAKEOFF command to {target_altitude}m...")

     self._speak(f"Drone taking off to {int(target_altitude)} meters altitude.")

     try:
        self._drone.mav.command_long_send(
            self._drone.target_system,
            self._drone.target_component,
            mavutil.mavlink.MAV_CMD_NAV_TAKEOFF,
            0,
            0, 0, 0, 0,
            current_lat,
            current_lon,
            target_altitude
        )
        
        self.commandFeedback.emit(f"Takeoff command sent to {target_altitude}m. Monitoring...")
        print("[DroneCommander] Takeoff command sent, monitoring altitude change...")
        
        # Monitor altitude for 3 seconds to confirm takeoff
        start_time = time.time()
        while time.time() - start_time < 3:
            current_alt = self.drone_model.telemetry.get('alt', initial_alt)
            
            if current_alt > initial_alt + 0.5:
                success_msg = f"Takeoff initiated! Climbing to {target_altitude}m (current: {current_alt:.1f}m)"
                self.commandFeedback.emit(success_msg)
                self._speak("Takeoff initiated successfully.")
                print(f"[DroneCommander] Takeoff confirmed - altitude: {current_alt}m")
                return True
            
            time.sleep(0.1)
        
        success_msg = f"Takeoff command sent successfully to {target_altitude}m"
        self.commandFeedback.emit(success_msg)
        self._speak("Takeoff command sent successfully.")
        return True
        
     except Exception as e:
        error_msg = f"Error sending takeoff command: {e}"
        self.commandFeedback.emit(error_msg)
        self._speak("Error sending takeoff command.")
        print(f"[DroneCommander ERROR] {e}")
        return False

    @pyqtSlot(result=bool)
    def land(self):
     """Land command with automatic disarm after landing"""
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
        # Send land command
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
        self.commandFeedback.emit("Land command sent. Monitoring landing...")

        # Wait for command acknowledgment
        ack_result = self._wait_for_command_ack(mavutil.mavlink.MAV_CMD_NAV_LAND)
        
        if ack_result == mavutil.mavlink.MAV_RESULT_ACCEPTED:
            self.commandFeedback.emit("Landing initiated successfully!")
            self._speak("Landing initiated successfully.")
            
            # Start monitoring thread for automatic disarm after landing
            disarm_thread = threading.Thread(target=self._monitor_landing_and_disarm, daemon=True)
            disarm_thread.start()
            
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
     
    def _monitor_landing_and_disarm(self):
     """Monitor landing progress and automatically disarm when landed"""
     print("[DroneCommander] 🔍 Monitoring landing for automatic disarm...")
    
     try:
        start_time = time.time()
        timeout = 120  # 2 minutes timeout for landing
        ground_time_threshold = 3  # seconds on ground before disarming
        ground_start_time = None
        
        while time.time() - start_time < timeout:
            # Get current altitude and armed state
            current_alt = self.drone_model.telemetry.get('alt', None)
            is_armed = self.drone_model.telemetry.get('armed', False)
            current_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
            
            # Check if already disarmed
            if not is_armed:
                print("[DroneCommander] ✅ Drone already disarmed")
                self.commandFeedback.emit("Drone landed and disarmed")
                self._speak("Drone landed and disarmed.")
                return
            
            # Check if on ground (altitude < 0.5m and armed)
            if current_alt is not None and current_alt < 0.5:
                if ground_start_time is None:
                    ground_start_time = time.time()
                    print(f"[DroneCommander] 🛬 Drone on ground (alt: {current_alt:.2f}m)")
                
                # Check if been on ground long enough
                time_on_ground = time.time() - ground_start_time
                if time_on_ground >= ground_time_threshold:
                    print(f"[DroneCommander] ⏱️ On ground for {time_on_ground:.1f}s - disarming...")
                    self.commandFeedback.emit("Landing complete - disarming drone...")
                    self._speak("Landing complete. Disarming drone.")
                    
                    # Send disarm command
                    for i in range(3):
                        self._drone.mav.command_long_send(
                            self._drone.target_system,
                            self._drone.target_component,
                            mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
                            0,
                            0,  # 0 = DISARM
                            0, 0, 0, 0, 0, 0
                        )
                        time.sleep(0.1)
                    
                    # Wait for disarm confirmation
                    disarm_start = time.time()
                    while time.time() - disarm_start < 3:
                        is_armed = self.drone_model.telemetry.get('armed', False)
                        if not is_armed:
                            print("[DroneCommander] ✅ Automatic disarm successful!")
                            self.commandFeedback.emit("✅ Drone disarmed automatically after landing")
                            self._speak("Drone disarmed successfully.")
                            self.armDisarmCompleted.emit(True, "Drone disarmed automatically after landing")
                            return
                        time.sleep(0.1)
                    
                    # Disarm command sent but not confirmed
                    print("[DroneCommander] ⚠️ Disarm command sent but not confirmed")
                    self.commandFeedback.emit("⚠️ Disarm command sent - check drone status")
                    return
            else:
                # Reset ground timer if altitude increases
                if ground_start_time is not None:
                    ground_start_time = None
                    print(f"[DroneCommander] 📈 Altitude increased to {current_alt:.2f}m - resetting ground timer")
            
            time.sleep(0.5)  # Check every 0.5 seconds
        
        # Timeout reached
        print("[DroneCommander] ⏰ Landing monitor timeout - check drone manually")
        self.commandFeedback.emit("⚠️ Landing monitor timeout - please check drone status")
        
     except Exception as e:
        print(f"[DroneCommander ERROR] Landing monitor failed: {e}")
        self.commandFeedback.emit(f"Error monitoring landing: {e}")

    @pyqtSlot(str, result=bool)
    def setMode(self, mode_name):
     """Set flight mode - NON-BLOCKING version using thread"""
     if not self._is_drone_ready(): 
        self.commandFeedback.emit("Error: Drone not connected.")
        self._speak("Error. Drone not connected.")
        return False

    # Check if mode change already in progress
     with self._mode_change_lock:
        if self._mode_change_in_progress:
            self.commandFeedback.emit("Mode change already in progress, please wait...")
            print("[DroneCommander] ⚠️ Mode change already in progress - rejecting request")
            return False
        
        # Check cooldown period
        current_time = time.time()
        time_since_last = current_time - self._last_mode_change_time
        if time_since_last < self._mode_change_cooldown:
            remaining = self._mode_change_cooldown - time_since_last
            self.commandFeedback.emit(f"Please wait {remaining:.1f}s before changing mode again")
            print(f"[DroneCommander] ⚠️ Mode change cooldown active ({remaining:.1f}s remaining)")
            return False
        
        # Lock mode change
        self._mode_change_in_progress = True
        self._last_mode_change_time = current_time

     print(f"\n[DroneCommander] ===== MODE CHANGE REQUEST =====")
     print(f"[DroneCommander] Requested mode: {mode_name}")
    
    # Get current mode for comparison
     current_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
     print(f"[DroneCommander] Current mode: {current_mode}")
    
    # Check if already in requested mode
     if current_mode == mode_name.upper():
        self.commandFeedback.emit(f"Already in {mode_name} mode")
        self._speak(f"Already in {mode_name} mode.")
        with self._mode_change_lock:
            self._mode_change_in_progress = False
        return True
    
    # Get mode ID
     mode_id = self._drone.mode_mapping().get(mode_name.upper())
     if mode_id is None:
        available_modes = list(self._drone.mode_mapping().keys())
        self.commandFeedback.emit(f"Error: Unknown mode '{mode_name}'")
        self._speak(f"Error. Unknown mode {mode_name}.")
        with self._mode_change_lock:
            self._mode_change_in_progress = False
        return False

    # Start mode change in separate thread (NON-BLOCKING)
     mode_thread = threading.Thread(
        target=self._do_mode_change,
        args=(mode_name, mode_id),
        daemon=True
    )
     mode_thread.start()
    
     self.commandFeedback.emit(f"Changing mode to {mode_name}...")
     self._speak(f"Changing mode to {mode_name}.")
    
     return True

    
    def _do_mode_change(self, mode_name, mode_id):
     """
    Internal method that does the actual mode change.
    Runs in a separate thread to avoid blocking UI.
    """
     try:
        # ⭐ NOTIFY DroneModel that user requested this mode ⭐
        self.drone_model.notifyModeChangeRequest(mode_name.upper())
        
        print(f"[DroneCommander] Mode ID: {mode_id}")
        print("[DroneCommander] Sending mode change command (non-blocking)...")
        
        max_attempts = 3
        
        for attempt in range(max_attempts):
            # Send command
            self._drone.mav.set_mode_send(
                self._drone.target_system,
                mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                mode_id
            )
            print(f"[DroneCommander] Sent mode change attempt {attempt + 1}/{max_attempts}")
            
            # Wait for confirmation (shorter timeout per attempt)
            confirmation_timeout = 2.0
            start_time = time.time()
            
            while time.time() - start_time < confirmation_timeout:
                current_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
                
                if current_mode == mode_name.upper():
                    self.commandFeedback.emit(f"✅ Mode changed to '{mode_name}' successfully!")
                    self._speak(f"Mode changed to {mode_name} successfully.")
                    print(f"[DroneCommander] ✅ Mode change confirmed")
                    return  # Success - exit function
                
                time.sleep(0.1)  # Safe because we're in a separate thread
            
            # Retry if not last attempt
            if attempt < max_attempts - 1:
                print(f"[DroneCommander] ⚠️ Attempt {attempt + 1} timeout, retrying...")
                time.sleep(0.3)
        
        # After all attempts, check one final time
        final_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
        if final_mode == mode_name.upper():
            self.commandFeedback.emit(f"✅ Mode changed to '{mode_name}' successfully!")
            self._speak(f"Mode changed to {mode_name} successfully.")
            print(f"[DroneCommander] ✅ Mode change confirmed (delayed)")
        else:
            self.commandFeedback.emit(f"⚠️ Mode change may have failed (current: {final_mode})")
            self._speak(f"Mode change to {mode_name} may have failed.")
            print(f"[DroneCommander] ⚠️ Mode change not confirmed - current: {final_mode}")
    
     except Exception as e:
        self.commandFeedback.emit(f"Error sending mode change: {e}")
        self._speak("Error sending mode change command.")
        print(f"[DroneCommander ERROR] {e}")
    
     finally:
        # CRITICAL: Always unlock
        with self._mode_change_lock:
            self._mode_change_in_progress = False
        print("[DroneCommander] Mode change lock released")

# Optional: Emergency unlock method
    @pyqtSlot(result=bool)  
    def forceUnlockModeChange(self):
     """Force unlock mode change (debugging only)"""
     with self._mode_change_lock:
        was_locked = self._mode_change_in_progress
        self._mode_change_in_progress = False
        self._last_mode_change_time = 0
    
     if was_locked:
        print("[DroneCommander] ⚠️ Force unlocked mode change")
        self.commandFeedback.emit("Mode change unlocked")
        return True
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

    @pyqtSlot(result=bool)
    def requestAllParameters(self):
     """Request ALL drone parameters - QUEUE-BASED (NO CONFLICTS)"""
     if not self._is_drone_ready():
        self.commandFeedback.emit("Error: Drone not connected to request parameters.")
        print("[DroneCommander] ❌ Cannot request parameters - drone not connected")
        return False
    
     if self._fetching_params:
        print("[DroneCommander] ⚠️ Parameter fetch already in progress")
        self.commandFeedback.emit("Parameter fetch already in progress...")
        return False
    
     print("\n" + "="*60)
     print("[DroneCommander] ✅ Parameter fetch started (QUEUE MODE)")
     print("="*60)
    
    # Clear previous parameters and queue
     with self._param_lock:
        self._parameters.clear()
    
    # Clear queue
     while not self._param_queue.empty():
        try:
            self._param_queue.get_nowait()
        except queue.Empty:
            break
    
    # Mark as active
     self._fetching_params = True
     self._param_request_active = True
    
    # Send parameter request (MAVLinkThread will collect them)
     print("[DroneCommander] 📤 Sending PARAM_REQUEST_LIST...")
     for retry in range(3):
        self._drone.mav.param_request_list_send(
            self._drone.target_system,
            self._drone.target_component
        )
        time.sleep(0.1)
    
    # Start processing thread
     fetch_thread = threading.Thread(target=self._process_parameter_queue, daemon=True)
     fetch_thread.start()
    
     self.commandFeedback.emit("Requesting parameters from drone...")
     return True
    def _process_parameter_queue(self):
     """Process parameters from queue (collected by MAVLinkThread)"""
     print("[DroneCommander] 📥 Processing parameter queue...")
    
     try:
        collected_params = {}
        total_params = None
        start_time = time.time()
        last_param_time = time.time()
        
        timeout = 60  # 60 seconds total
        no_data_timeout = 10  # 10 seconds without new data
        
        while time.time() - start_time < timeout:
            try:
                # Get parameter from queue (non-blocking)
                param_data = self._param_queue.get(timeout=0.5)
                
                if param_data:
                    last_param_time = time.time()
                    
                    param_id = param_data['name']
                    param_value = param_data['value']
                    param_type = param_data['type']
                    param_index = param_data['index']
                    param_count = param_data['count']
                    
                    # Set total on first parameter
                    if total_params is None:
                        total_params = param_count
                        print(f"[DroneCommander] 📊 Total parameters: {total_params}")
                        self.commandFeedback.emit(f"Loading {total_params} parameters...")
                    
                    # Store parameter (avoid duplicates)
                    if param_id not in collected_params:
                        collected_params[param_id] = {
                            "name": param_id,
                            "value": str(param_value),
                            "type": "FLOAT" if param_type in [9, 10] else "INT32",
                            "index": param_index,
                            "count": param_count,
                            "synced": True,
                            "default": "0",
                            "units": "",
                            "range": "",
                            "description": ""
                        }
                        
                        # Progress update every 50 params
                        if len(collected_params) % 50 == 0:
                            print(f"[DroneCommander] 📥 Progress: {len(collected_params)}/{total_params}")
                            self.commandFeedback.emit(f"Received {len(collected_params)} parameters...")
                    
                    # Check if complete
                    if total_params and len(collected_params) >= total_params:
                        print(f"[DroneCommander] ✅ All {len(collected_params)} parameters received!")
                        break
                
            except queue.Empty:
                # Check timeout
                if len(collected_params) > 0:
                    time_since_last = time.time() - last_param_time
                    if time_since_last > no_data_timeout:
                        print(f"[DroneCommander] ⏹️ No new data for {no_data_timeout}s - assuming complete")
                        break
                continue
        
        # Store results
        final_count = len(collected_params)
        print(f"\n[DroneCommander] 📊 Final Results: {final_count} parameters")
        
        if final_count > 0:
            with self._param_lock:
                self._parameters = collected_params
            
            print(f"[DroneCommander] 📤 Emitting parametersUpdated signal...")
            self.parametersUpdated.emit()
            self.commandFeedback.emit(f"✅ Loaded {final_count} parameters!")
        else:
            print("[DroneCommander] ❌ No parameters received")
            self.commandFeedback.emit("❌ No parameters received from drone")
    
     except Exception as e:
        print(f"[DroneCommander] ❌ ERROR processing parameters: {e}")
        import traceback
        traceback.print_exc()
        self.commandFeedback.emit(f"Error processing parameters: {e}")
    
     finally:
        self._fetching_params = False
        self._param_request_active = False
        print("="*60 + "\n")

    def add_parameter_to_queue(self, param_msg):
     """
     Called by MAVLinkThread when it receives a PARAM_VALUE message.
     Thread-safe parameter collection without blocking main telemetry.
     """
     if not self._param_request_active:
        return  # Ignore parameters if we're not requesting them
    
     try:
        param_id = param_msg.param_id.decode('utf-8').strip('\x00')
        param_value = float(param_msg.param_value)
        param_type = int(param_msg.param_type)
        param_index = int(param_msg.param_index)
        param_count = int(param_msg.param_count)
        
        param_data = {
            'name': param_id,
            'value': param_value,
            'type': param_type,
            'index': param_index,
            'count': param_count
        }
        
        # Add to queue (non-blocking)
        self._param_queue.put(param_data)
        
     except Exception as e:
        print(f"[DroneCommander] ⚠️ Error queuing parameter: {e}")

    def _fetch_parameters_blocking(self):
     """BLOCKING parameter fetch - dedicated thread with exclusive message access"""
     print("[DroneCommander] 🔄 REQUESTING PARAMETERS (BLOCKING MODE)")
    
     try:
        # Step 1: Temporarily pause main telemetry thread (if possible)
        print("[DroneCommander] 📤 Sending PARAM_REQUEST_LIST...")
        
        # Send request with retries
        for retry in range(3):
            self._drone.mav.param_request_list_send(
                self._drone.target_system,
                self._drone.target_component
            )
            time.sleep(0.2)
        
        # Step 2: Dedicated parameter collection
        print("[DroneCommander] ⏳ Collecting parameters...")
        
        collected_params = {}
        total_params = None
        start_time = time.time()
        last_param_time = time.time()
        no_data_timeout = 8  # 8 seconds without new data
        overall_timeout = 90  # 90 seconds total
        
        consecutive_failures = 0
        max_consecutive_failures = 50  # Allow 50 empty reads before giving up
        
        while time.time() - start_time < overall_timeout:
            try:
                # CRITICAL: Use blocking=True with timeout to get exclusive access
                msg = self._drone.recv_match(
                    type='PARAM_VALUE', 
                    blocking=True,  # BLOCKING - this is the key fix
                    timeout=0.5
                )
                
                if msg:
                    # Reset counters on successful read
                    consecutive_failures = 0
                    last_param_time = time.time()
                    
                    # Extract parameter info
                    param_id = msg.param_id.decode('utf-8').strip('\x00')
                    param_value = float(msg.param_value)
                    param_type = int(msg.param_type)
                    param_index = int(msg.param_index)
                    param_count = int(msg.param_count)
                    
                    # Set total on first message
                    if total_params is None:
                        total_params = param_count
                        print(f"[DroneCommander] 📊 Total parameters: {total_params}")
                        self.commandFeedback.emit(f"Loading {total_params} parameters...")
                    
                    # Store parameter (avoid duplicates)
                    if param_id not in collected_params:
                        collected_params[param_id] = {
                            "name": param_id,
                            "value": str(param_value),
                            "type": "FLOAT" if param_type in [9, 10] else "INT32",
                            "index": param_index,
                            "count": param_count,
                            "synced": True,
                            "default": "0",
                            "units": "",
                            "range": "",
                            "description": ""
                        }
                        
                        # Progress update every 25 params
                        if len(collected_params) % 25 == 0:
                            print(f"[DroneCommander] 📥 Progress: {len(collected_params)}/{total_params if total_params else '?'}")
                            self.commandFeedback.emit(f"Received {len(collected_params)} parameters...")
                            if total_params:
                                self.parameterProgress.emit(len(collected_params), total_params)
                    
                    # Check if complete
                    if total_params and len(collected_params) >= total_params:
                        print(f"[DroneCommander] ✅ All {len(collected_params)} parameters received!")
                        break
                
                else:
                    # No message received
                    consecutive_failures += 1
                    
                    # Check if we have some parameters and timed out
                    if len(collected_params) > 0:
                        time_since_last = time.time() - last_param_time
                        if time_since_last > no_data_timeout:
                            print(f"[DroneCommander] ⏹️ No new data for {no_data_timeout}s - assuming complete")
                            break
                    
                    # Check consecutive failures
                    if consecutive_failures >= max_consecutive_failures:
                        if len(collected_params) > 0:
                            print(f"[DroneCommander] ⚠️ {consecutive_failures} empty reads - assuming complete with {len(collected_params)} params")
                            break
                        else:
                            print(f"[DroneCommander] ❌ No parameters received after {consecutive_failures} attempts")
                            break
                
            except Exception as e:
                print(f"[DroneCommander] ⚠️ recv_match exception: {e}")
                consecutive_failures += 1
                time.sleep(0.1)
                continue
        
        # Step 3: Store results
        final_count = len(collected_params)
        print(f"\n[DroneCommander] 📊 Final Results: {final_count} parameters")
        
        if final_count > 0:
            # Update shared storage
            with self._param_lock:
                self._parameters = collected_params
            
            # Emit to QML
            print(f"[DroneCommander] 📤 Emitting parametersUpdated signal...")
            self.parametersUpdated.emit()
            self.commandFeedback.emit(f"✅ Loaded {final_count} parameters!")
            print(f"[DroneCommander] ✅ Parameters available to QML")
        else:
            print("[DroneCommander] ❌ No parameters received")
            self.commandFeedback.emit("❌ No parameters received from drone")
    
     except Exception as e:
        print(f"[DroneCommander] ❌ ERROR during parameter fetch: {e}")
        import traceback
        traceback.print_exc()
        self.commandFeedback.emit(f"Error fetching parameters: {e}")
    
     finally:
        self._fetching_params = False
        print("="*60 + "\n")
    
    def _fetch_parameters_improved(self):
        """Improved parameter fetching with proper error handling"""
        print("\n" + "="*60)
        print("[DroneCommander] 🔄 REQUESTING PARAMETERS")
        print("="*60)
        
        try:
            with self._param_lock:
                self._parameters.clear()
            
            # Step 1: Send parameter request list
            print("[DroneCommander] 📤 Sending PARAM_REQUEST_LIST...")
            self._drone.mav.param_request_list_send(
                self._drone.target_system,
                self._drone.target_component
            )
            
            # Step 2: Wait for initial response
            print("[DroneCommander] ⏳ Waiting for initial response...")
            start_time = time.time()
            first_param_received = False
            
            while time.time() - start_time < 5:  # 5 second timeout for first param
                try:
                    msg = self._drone.recv_match(type='PARAM_VALUE', blocking=False, timeout=0.1)
                    
                    if msg:
                        first_param_received = True
                        print(f"[DroneCommander] ✅ First parameter received!")
                        
                        # Process this first parameter
                        self._process_param_message(msg)
                        break
                    
                    time.sleep(0.05)
                except Exception as e:
                    # Ignore recv_match errors from thread conflicts
                    time.sleep(0.1)
                    continue
            
            if not first_param_received:
                print("[DroneCommander] ❌ No response from drone - check connection")
                self.commandFeedback.emit("❌ No parameter response from drone")
                self._fetching_params = False
                return
            
            # Step 3: Continue receiving parameters
            print("[DroneCommander] 📥 Receiving parameters...")
            
            total_params = None
            last_received_time = time.time()
            no_data_timeout = 5  # 5 seconds without new data = done
            overall_timeout = 60  # 60 seconds total timeout
            
            while time.time() - start_time < overall_timeout:
                try:
                    msg = self._drone.recv_match(type='PARAM_VALUE', blocking=False, timeout=0.1)
                    
                    if msg:
                        last_received_time = time.time()
                        
                        # Get total param count from first message
                        if total_params is None:
                            total_params = msg.param_count
                            print(f"[DroneCommander] 📊 Total parameters: {total_params}")
                        
                        # Process parameter
                        self._process_param_message(msg)
                        
                        # Check if we got all parameters
                        current_count = len(self._parameters)
                        if total_params and current_count >= total_params:
                            print(f"[DroneCommander] ✅ All {current_count} parameters received!")
                            break
                        
                        # Progress logging every 50 params
                        if current_count % 50 == 0:
                            print(f"[DroneCommander] 📥 Progress: {current_count} parameters")
                            self.commandFeedback.emit(f"Received {current_count} parameters...")
                    
                    # Check for timeout
                    if time.time() - last_received_time > no_data_timeout:
                        current_count = len(self._parameters)
                        if current_count > 0:
                            print(f"[DroneCommander] ⏹️ Timeout - received {current_count} parameters")
                            break
                    
                    time.sleep(0.02)
                    
                except Exception as e:
                    # Ignore thread conflict errors
                    time.sleep(0.05)
                    continue
            
            # Step 4: Finalize and emit results
            final_count = len(self._parameters)
            print(f"\n[DroneCommander] 📊 Final Results:")
            print(f"  ✅ Received: {final_count} parameters")
            
            if final_count > 0:
                # Emit signal to QML (QML will read the property)
                print(f"[DroneCommander] 📤 Emitting parametersUpdated signal...")
                self.parametersUpdated.emit()
                
                self.commandFeedback.emit(f"✅ Loaded {final_count} parameters!")
                print(f"[DroneCommander] ✅ Parameters emitted to QML")
            else:
                print("[DroneCommander] ❌ No parameters received")
                self.commandFeedback.emit("❌ No parameters received from drone")
        
        except Exception as e:
            print(f"[DroneCommander] ❌ ERROR during parameter fetch: {e}")
            import traceback
            traceback.print_exc()
            self.commandFeedback.emit(f"Error fetching parameters: {e}")
        
        finally:
            self._fetching_params = False
            print("="*60 + "\n")
    
    def _process_param_message(self, msg):
        """Process a single PARAM_VALUE message"""
        try:
            param_id = msg.param_id.decode('utf-8').strip('\x00')
            param_value = float(msg.param_value)  # Always convert to float
            param_type = int(msg.param_type)
            param_index = int(msg.param_index)
            param_count = int(msg.param_count)
            
            # Don't add duplicates
            if param_id not in self._parameters:
                with self._param_lock:
                    self._parameters[param_id] = {
                        "name": param_id,
                        "value": str(param_value),  # Convert to string for QML
                        "type": "FLOAT" if param_type in [9, 10] else "INT32",
                        "index": param_index,
                        "count": param_count,
                        "synced": True,
                        "default": "0",
                        "units": "",
                        "range": "",
                        "description": ""
                    }
                
                # Emit individual parameter update
                self.parameterReceived.emit(param_id, param_value)
        
        except Exception as e:
            print(f"[DroneCommander] ⚠️ Error processing parameter: {e}")
    
    @pyqtProperty('QVariant', notify=parametersUpdated)
    def parameters(self):
     """Return parameters as QVariant (dictionary) for QML"""
     with self._param_lock:
        result = dict(self._parameters)
    
     print(f"[DroneCommander] 📤 Returning {len(result)} parameters to QML")
     return result
    
    @pyqtSlot(str, float, result=bool)
    def setParameter(self, param_id, param_value):
        """Set a single parameter on the drone"""
        if not self._is_drone_ready():
            self.commandFeedback.emit("Error: Drone not connected.")
            return False
        
        print(f"[DroneCommander] 📝 Setting parameter '{param_id}' to {param_value}")
        self.commandFeedback.emit(f"Setting '{param_id}' to {param_value}...")
        
        try:
            # Convert param_id to bytes
            param_id_bytes = param_id.encode('utf-8')
            
            # Determine parameter type
            param_type = mavutil.mavlink.MAV_PARAM_TYPE_REAL32
            if param_id in self._parameters:
                stored_type = self._parameters[param_id].get('type', 'FLOAT')
                if stored_type == 'INT32':
                    param_type = mavutil.mavlink.MAV_PARAM_TYPE_INT32
                    param_value = int(param_value)
            
            # Send parameter set command
            self._drone.mav.param_set_send(
                self._drone.target_system,
                self._drone.target_component,
                param_id_bytes,
                param_value,
                param_type
            )
            
            # Wait for acknowledgment
            start_time = time.time()
            timeout = 3
            
            while time.time() - start_time < timeout:
                msg = self._drone.recv_match(type='PARAM_VALUE', blocking=False, timeout=0.1)
                
                if msg:
                    received_id = msg.param_id.decode('utf-8').strip('\x00')
                    if received_id == param_id:
                        received_value = float(msg.param_value)
                        
                        # Update local cache
                        with self._param_lock:
                            if param_id in self._parameters:
                                self._parameters[param_id]['value'] = str(received_value)
                        
                        # Check if value matches
                        if abs(received_value - param_value) < 0.001:
                            self.commandFeedback.emit(f"✅ Parameter '{param_id}' set to {received_value}")
                            self.parametersUpdated.emit()
                            return True
                        else:
                            self.commandFeedback.emit(f"⚠️ Value mismatch: expected {param_value}, got {received_value}")
                            self.parametersUpdated.emit()
                            return False
                
                time.sleep(0.05)
            
            self.commandFeedback.emit(f"⏱️ Timeout setting parameter '{param_id}'")
            return False
        
        except Exception as e:
            error_msg = f"Error setting parameter: {e}"
            print(f"[DroneCommander] ❌ {error_msg}")
            self.commandFeedback.emit(error_msg)
            return False
