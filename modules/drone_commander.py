import time
import queue
import threading
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QThread
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
     self._mode_change_cooldown = 5.0  # ✅ INCREASED from 2.0 to 5.0 seconds
    
    # ✅ Debounce tracking (CRITICAL - prevents crash)
     self._last_mode_request = None
     self._mode_request_time = 0
    
    # Initialize Text-to-Speec

    @property
    def _drone(self):
        return self.drone_model.drone_connection

    def _is_drone_ready(self):
        if not self._drone or not self.drone_model.isConnected:
            self.commandFeedback.emit("Error: Drone not connected or ready.")
            print("Error. Drone not connected.")
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
            print("Error. Drone not connected.")
            return False
        try:
            self.commandFeedback.emit("Starting ESC Calibration...")
            print("Starting E S C Calibration. Follow safety steps.")

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
            print("E S C Calibration failed.")
            return False

    @pyqtSlot(result=bool)
    def rebootAutopilot(self):
        """Reboot the autopilot via MAVLink command"""
        if not self._is_drone_ready():
            self.commandFeedback.emit("Error: Drone not connected for reboot.")
            print("Error. Drone not connected for reboot.")
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
            print("Autopilot reboot command sent. Device will restart.")
            return True
            
        except Exception as e:
            error_msg = f"Reboot command failed: {e}"
            print(f"[DroneCommander] {error_msg}")
            self.commandFeedback.emit(error_msg)
            print("Reboot command failed.")
            return False
        
    @pyqtSlot(result=bool)
    def arm(self):
        if not self._is_drone_ready(): 
            self.armDisarmCompleted.emit(False, "Drone not connected.")
            print("Error. Drone not connected.")
            return False
        
        print(f"\n[DroneCommander] ===== ARM REQUEST =====")
        print(f"[DroneCommander] Target system: {self._drone.target_system}")
        print(f"[DroneCommander] Target component: {self._drone.target_component}")
        
        print("Arming drone. Please wait.")
        
        try:
            print("[DroneCommander] Sending ARM commands...")
            self._drone.mav.command_long_send(
                    self._drone.target_system,
                    self._drone.target_component,
                    mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
                    0,
                    1,
                    0, 0, 0, 0, 0, 0
            )
            print(f"[DroneCommander]   ARM attempt")
            
            return True    
        except Exception as e:
            msg = f"Error sending ARM command: {e}"
            self.commandFeedback.emit(msg)
            self.armDisarmCompleted.emit(False, msg)
            print("Error sending arm command.")
            print(f"[DroneCommander ERROR] ARM command failed: {e}")
            return False

    @pyqtSlot(result=bool)
    def disarm(self):
        if not self._is_drone_ready(): 
            self.armDisarmCompleted.emit(False, "Drone not connected.")
            print("Error. Drone not connected.")
            return False

        print("[DroneCommander] Sending DISARM command...")
        print("Disarming drone.")
        
        try:
            self._drone.mav.command_long_send(
                self._drone.target_system,
                self._drone.target_component,
                mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
                0, 0, 0, 0, 0, 0, 0, 0
            )
            self.commandFeedback.emit("Disarm command sent. Waiting for confirmation...")
            
            # ack_result = self._wait_for_command_ack(mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM)

            # if ack_result == mavutil.mavlink.MAV_RESULT_ACCEPTED:
            #     self.armDisarmCompleted.emit(True, "Drone Disarmed Successfully!")
            #     print("Drone disarmed successfully.")
            #     return True
            # elif ack_result == mavutil.mavlink.MAV_RESULT_DENIED:
            #     msg = "Disarm command denied by drone. (e.g., motors running)."
            #     self.armDisarmCompleted.emit(False, msg)
            #     print("Disarm command denied. Motors may be running.")
            #     return False
            # elif ack_result == mavutil.mavlink.MAV_RESULT_FAILED:
            #     msg = "Disarm command failed on drone. Check drone status/log."
            #     self.armDisarmCompleted.emit(False, msg)
            #     print("Disarm command failed. Check drone status.")
            #     return False
            # else:
            #     msg = "Disarm command timed out or received unknown ACK result. Check drone status/log."
            #     self.armDisarmCompleted.emit(False, msg)
            #     print("Disarm command timed out.")
            #     return False
        except Exception as e:
            msg = f"Error sending DISARM command: {e}"
            self.commandFeedback.emit(msg)
            self.armDisarmCompleted.emit(False, msg)
            print("Error sending disarm command.")
            print(f"[DroneCommander ERROR] DISARM command failed: {e}")
            return False

    @pyqtSlot(float, float, result=bool)
    def takeoff(self, target_altitude, target_speed):
     """
    Automated takeoff sequence:
    1. Change to GUIDED mode FIRST (critical for SITL)
    2. ARM the drone
    3. Set climb speed
    4. Execute takeoff to target altitude
    """
     if not self._is_drone_ready(): 
        self.commandFeedback.emit("Error: Drone not connected.")
        print("Error. Drone not connected.")
        return False

     print(f"\n[DroneCommander] ===== AUTOMATED TAKEOFF SEQUENCE =====")
     print(f"[DroneCommander] Target altitude: {target_altitude}m")
     print(f"[DroneCommander] Target speed: {target_speed}m/s")

    # ========== PRE-FLIGHT CHECKS ==========
     print("\n[DroneCommander] 🔍 Running pre-flight checks...")
     self.commandFeedback.emit("🔍 Running pre-flight checks...")
    
    # Check 1: GPS Status
     current_lat = self.drone_model.telemetry.get('lat')
     current_lon = self.drone_model.telemetry.get('lon')
     gps_fix = self.drone_model.telemetry.get('fix_type', 0)
     num_sats = self.drone_model.telemetry.get('satellites_visible', 0)
    
     print(f"[DroneCommander] GPS: lat={current_lat}, lon={current_lon}")
     print(f"[DroneCommander] GPS Fix Type: {gps_fix} (need 3+), Satellites: {num_sats}")
    
    # ✅ RELAXED GPS CHECK FOR SITL
     if current_lat is None or current_lon is None:
        self.commandFeedback.emit("❌ Error: GPS position not available.")
        print("Error. G P S position not available.")
        return False
    
    # ✅ ALLOW ZERO GPS FIX IN SITL (but coordinates must be valid)
     if gps_fix < 3:
        if gps_fix == 0 and (current_lat != 0 and current_lon != 0):
            # SITL often has fix_type=0 but valid coordinates
            print(f"[DroneCommander] ⚠️ GPS fix type is {gps_fix}, but coordinates are valid - continuing (SITL mode)")
            self.commandFeedback.emit(f"⚠️ Warning: GPS fix type {gps_fix} (SITL mode - proceeding anyway)")
        else:
            self.commandFeedback.emit(f"❌ Error: Insufficient GPS fix (type {gps_fix}, need 3D fix)")
            print("Error. Insufficient G P S fix.")
            return False
    
    # ✅ RELAXED SATELLITE CHECK
     if num_sats < 8 and num_sats > 0:
        self.commandFeedback.emit(f"⚠️ Warning: Only {num_sats} satellites (recommend 10+)")
        print(f"[DroneCommander] ⚠️ Low satellite count: {num_sats}")
     elif num_sats == 0:
        print(f"[DroneCommander] ⚠️ Zero satellites reported - likely SITL, continuing anyway")
    
    # Check 2: Battery
     battery_voltage = self.drone_model.telemetry.get('voltage_battery', 0)
     battery_percent = self.drone_model.telemetry.get('battery_remaining', 0)
     print(f"[DroneCommander] Battery: {battery_voltage}V ({battery_percent}%)")
    
    # ✅ RELAXED BATTERY CHECK FOR SITL
     if battery_voltage < 11.0 and battery_voltage > 0:
        self.commandFeedback.emit(f"❌ Error: Low battery ({battery_voltage}V)")
        print("Error. Low battery.")
        return False
     elif battery_voltage == 0:
        print(f"[DroneCommander] ⚠️ Battery voltage is 0 - likely SITL, continuing anyway")
        self.commandFeedback.emit("⚠️ No battery data (SITL mode)")
    
    # Get current mode for information
     current_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
     print(f"[DroneCommander] Current Mode: {current_mode}")
    
     print("[DroneCommander] ✅ Pre-flight checks passed")
     self.commandFeedback.emit("✅ Pre-flight checks passed")
     time.sleep(0.5)

    # ========== STEP 1: CHANGE TO GUIDED MODE FIRST (CRITICAL!) ==========
     print("\n[DroneCommander] 🎯 Step 1/3: Switching to GUIDED mode...")
     self.commandFeedback.emit("🎯 Step 1/3: Switching to GUIDED mode...")
     print("Step one. Switching to guided mode.")
    
     current_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
    
     if current_mode != 'GUIDED':
        mode_id = self._drone.mode_mapping().get('GUIDED')
        if mode_id is None:
            self.commandFeedback.emit("❌ Error: GUIDED mode not available")
            print("Error. Guided mode not available.")
            return False
        
        # Send mode change commands
        print(f"[DroneCommander] Changing from {current_mode} to GUIDED...")
        for i in range(3):
            self._drone.mav.set_mode_send(
                self._drone.target_system,
                mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                mode_id
            )
            time.sleep(0.2)
        
        # Wait for mode change confirmation
        start_time = time.time()
        mode_changed = False
        while time.time() - start_time < 5:
            current_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
            if current_mode == 'GUIDED':
                mode_changed = True
                break
            time.sleep(0.1)
        
        if not mode_changed:
            error_msg = f"❌ Failed to change mode. Current: {current_mode}"
            print(f"[DroneCommander] {error_msg}")
            self.commandFeedback.emit(error_msg)
            print("Failed to change to guided mode.")
            return False
        
        print("[DroneCommander] ✅ Mode changed to GUIDED")
        self.commandFeedback.emit("✅ Mode changed to GUIDED")
     else:
        print("[DroneCommander] ✅ Already in GUIDED mode")
        self.commandFeedback.emit("✅ Already in GUIDED mode")
    
     time.sleep(1.0)  # Give mode change time to settle

    # ========== STEP 2: ARM THE DRONE (now that we're in GUIDED mode) ==========
     print(f"\n[DroneCommander] 🔐 Step 2/3: Arming drone in GUIDED mode...")
     self.commandFeedback.emit(f"🔐 Step 2/3: Arming drone in GUIDED mode...")
     print("Step two. Arming drone.")
    
     is_armed = self.drone_model.telemetry.get('armed', False)
    
     if not is_armed:
        print("[DroneCommander] Sending ARM commands...")
        
        # Send ARM commands (multiple times for reliability)
        for i in range(5):
            self._drone.mav.command_long_send(
                self._drone.target_system,
                self._drone.target_component,
                mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
                0,
                1,  # 1 = ARM
                0,
                0, 0, 0, 0, 0
            )
            time.sleep(0.2)
        
        # Wait for ARM confirmation
        start_time = time.time()
        armed_confirmed = False
        
        while time.time() - start_time < 10:  # Increased timeout
            is_armed = self.drone_model.telemetry.get('armed', False)
            current_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
            
            print(f"[DroneCommander] Waiting for ARM... armed={is_armed}, mode={current_mode}")
            
            if is_armed:
                armed_confirmed = True
                print(f"[DroneCommander] ✅ Armed at {time.time() - start_time:.1f}s")
                break
            
            time.sleep(0.2)
        
        if not armed_confirmed:
            self.commandFeedback.emit("❌ Failed to arm. Check pre-arm checks in GCS.")
            print("Failed to arm. Check pre-arm checks.")
            print("[DroneCommander] ❌ ARM FAILED - Check Mission Planner/QGC for pre-arm error messages")
            print("[DroneCommander] Common issues:")
            print("  - Need GPS lock (try 'param set SIM_GPS_DISABLE 0' in SITL)")
            print("  - Need EKF healthy")
            print("  - Check ARMING_CHECK parameter")
            return False
        
        print("[DroneCommander] ✅ Drone armed successfully")
        self.commandFeedback.emit("✅ Drone armed successfully")
     else:
        print("[DroneCommander] ✅ Drone already armed")
        self.commandFeedback.emit("✅ Drone already armed")
    
    # Verify still in GUIDED mode after arming
     time.sleep(0.5)
     current_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
     if current_mode != 'GUIDED':
        self.commandFeedback.emit(f"❌ Mode changed to {current_mode} after arming!")
        print("Error. Mode changed after arming.")
        return False
    
     # Verify still armed
     is_armed = self.drone_model.telemetry.get('armed', False)
     if not is_armed:
        self.commandFeedback.emit("❌ Drone disarmed after arming!")
        print("Error. Drone disarmed after arming.")
        print("[DroneCommander] ❌ Drone disarmed immediately after arming - check pre-arm checks")
        return False
    
     time.sleep(1.0)

    # ========== STEP 3: SET CLIMB SPEED ==========
     print(f"\n[DroneCommander] ⚡ Setting climb speed to {target_speed} m/s...")
     self.commandFeedback.emit(f"⚡ Setting climb speed to {target_speed} m/s...")
    
     try:
        speed_cms = int(target_speed * 100)
        self._drone.mav.param_set_send(
            self._drone.target_system,
            self._drone.target_component,
            b'WPNAV_SPEED_UP',
            speed_cms,
            mavutil.mavlink.MAV_PARAM_TYPE_INT32
        )
        time.sleep(0.5)
        print(f"[DroneCommander] ✅ Climb speed set to {target_speed} m/s")
     except Exception as e:
        print(f"[DroneCommander] ⚠️ Could not set climb speed: {e}")

    # ========== STEP 4: EXECUTE TAKEOFF ==========
     print(f"\n[DroneCommander] 🚁 Step 3/3: Executing takeoff to {target_altitude}m...")
     self.commandFeedback.emit(f"🚁 Step 3/3: Taking off to {target_altitude}m...")
     print(f"Step three. Taking off to {int(target_altitude)} meters.")

     initial_alt = self.drone_model.telemetry.get('alt', 0)
    
     try:
        # Final armed check before takeoff
        is_armed = self.drone_model.telemetry.get('armed', False)
        if not is_armed:
            self.commandFeedback.emit("❌ Drone disarmed before takeoff!")
            print("Drone disarmed before takeoff.")
            return False
        
        # Send takeoff command
        self._drone.mav.command_long_send(
            self._drone.target_system,
            self._drone.target_component,
            mavutil.mavlink.MAV_CMD_NAV_TAKEOFF,
            0,
            0,  # Minimum pitch
            0,  # Empty
            0,  # Empty
            float('nan'),  # Yaw angle (NaN = use current)
            current_lat,
            current_lon,
            target_altitude
        )
        
        print("[DroneCommander] Takeoff command sent, monitoring altitude...")
        
        # Monitor altitude and armed status
        start_time = time.time()
        last_status_time = time.time()
        
        while time.time() - start_time < 15:  # Increased timeout to 15s
            current_alt = self.drone_model.telemetry.get('alt', initial_alt)
            is_armed = self.drone_model.telemetry.get('armed', False)
            current_mode = self.drone_model.telemetry.get('mode', 'UNKNOWN')
            
            # Status update every 2 seconds
            if time.time() - last_status_time > 2:
                print(f"[DroneCommander] Status: alt={current_alt:.2f}m, armed={is_armed}, mode={current_mode}")
                last_status_time = time.time()
            
            if not is_armed:
                self.commandFeedback.emit("❌ Drone disarmed during takeoff!")
                print("Drone disarmed during takeoff.")
                print("[DroneCommander] ❌ Drone disarmed during takeoff sequence")
                return False
            
            if current_mode != 'GUIDED':
                self.commandFeedback.emit(f"❌ Mode changed to {current_mode} during takeoff!")
                print("Mode changed during takeoff.")
                return False
            
            alt_gain = current_alt - initial_alt
            if alt_gain > 0.5:
                success_msg = f"✅ Takeoff confirmed! Climbing to {target_altitude}m (current: {current_alt:.1f}m)"
                self.commandFeedback.emit(success_msg)
                print("Takeoff successful. Climbing.")
                print(f"[DroneCommander] ✅ {success_msg}")
                return True
            
            time.sleep(0.2)
        
        # Timeout reached
        final_alt = self.drone_model.telemetry.get('alt', initial_alt)
        final_gain = final_alt - initial_alt
        is_armed = self.drone_model.telemetry.get('armed', False)
        
        print(f"[DroneCommander] Takeoff timeout: alt_gain={final_gain:.2f}m, armed={is_armed}")
        
        if final_gain > 0.2:
            success_msg = f"✅ Takeoff command accepted (altitude: {final_alt:.1f}m, gain: {final_gain:.2f}m)"
            self.commandFeedback.emit(success_msg)
            print("Takeoff in progress.")
            print(f"[DroneCommander] {success_msg}")
            return True
        else:
            error_msg = f"❌ No altitude gain detected (gain: {final_gain:.2f}m, armed: {is_armed})"
            self.commandFeedback.emit(error_msg)
            print("Takeoff failed. No altitude gain.")
            print(f"[DroneCommander] {error_msg}")
            print("[DroneCommander] Troubleshooting tips:")
            print("  - Check if throttle is enabled (param THR_MIN)")
            print("  - Verify motors are spinning")
            print("  - Check arming checks are passing")
            return False
        
     except Exception as e:
        error_msg = f"❌ Exception during takeoff: {e}"
        self.commandFeedback.emit(error_msg)
        print("Error during takeoff.")
        print(f"[DroneCommander ERROR] {e}")
        import traceback
        traceback.print_exc()
        return False
    
    @pyqtSlot(result=bool)
    def land(self):
        if not self._is_drone_ready(): 
            self.commandFeedback.emit("Error: Drone not connected.")
            print("Error. Drone not connected.")
            return False
            
        if self.drone_model.telemetry.get('lat') is None or self.drone_model.telemetry.get('lon') is None:
            self.commandFeedback.emit("Error: GPS position not available for land.")
            print("Error. G P S position not available for landing.")
            print("[DroneCommander] Land failed: GPS position not available.")
            return False

        print("[DroneCommander] Sending LAND command...")
        print("Drone landing initiated.")
        
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
                print("Landing initiated successfully.")
                return True
            else:
                self.commandFeedback.emit(f"Land command failed or denied. Result: {ack_result}")
                print("Land command failed or denied.")
                return False
        except Exception as e:
            self.commandFeedback.emit(f"Error sending LAND command: {e}")
            print("Error sending land command.")
            print(f"[DroneCommander ERROR] LAND command failed: {e}")
            return False

    @pyqtSlot(str, result=bool) # Takes mode name string
    def setMode(self, mode_name):
        if not self._is_drone_ready(): 
            self.commandFeedback.emit("Error: Drone not connected.")
            return False

        print(f"[DroneCommander] Sending SET_MODE command to '{mode_name}'...")
        try:
            mode_id = self._drone.mode_mapping().get(mode_name.upper())
            if mode_id is None:
                self.commandFeedback.emit(f"Error: Unknown mode '{mode_name}'.")
                print(f"[DroneCommander] SET_MODE failed: Unknown mode '{mode_name}'.")
                return False

            self._drone.mav.set_mode_send(
                self._drone.target_system,
                mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                mode_id
            )
            self.commandFeedback.emit(f"Set mode to '{mode_name}' command sent. Waiting for confirmation...")

            # Note: set_mode_send typically generates a COMMAND_ACK for MAV_CMD_DO_SET_MODE (176)
            ack_result = self._wait_for_command_ack(mavutil.mavlink.MAV_CMD_DO_SET_MODE)
            if ack_result == mavutil.mavlink.MAV_RESULT_ACCEPTED:
                self.commandFeedback.emit(f"Mode set to '{mode_name}' successfully.")
                return True
            else:
                self.commandFeedback.emit(f"Failed to set mode to '{mode_name}'. Result: {ack_result}")
                return False
        except Exception as e:
            self.commandFeedback.emit(f"Error sending SET_MODE command: {e}")
            print(f"[DroneCommander ERROR] SET_MODE command failed: {e}")
            return False
     
    @pyqtSlot('QVariantList', result=bool)
    def uploadMission(self, waypoints):
        if not self._is_drone_ready(): 
            print("Error. Drone not connected.")
            return False
        if not waypoints:
            self.commandFeedback.emit("Error: No waypoints provided for mission upload.")
            print("Error. No waypoints provided for mission upload.")
            return False

        print(f"[DroneCommander] Mission Upload: {len(waypoints)} waypoints...")
        self.commandFeedback.emit(f"Uploading mission with {len(waypoints)} waypoints...")
        print(f"Uploading mission with {len(waypoints)} waypoints.")

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
                print("Error. No messages received from drone.")
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
                            print("Mission rejected.")
                            return False
            
            self.commandFeedback.emit("ERROR: No mission request received - drone not accepting missions")
            print("Error. No mission request received.")
            print("[DroneCommander ERROR] No mission request received after mission count")
            return False
             
        except Exception as e:
            self.commandFeedback.emit(f"Mission upload error: {str(e)}")
            print("Mission upload error.")
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
                                print("Mission upload successful.")
                                return True
                            else:
                                error_msg = f"Mission rejected during upload: {msg.type}"
                                print(f"[DroneCommander] {error_msg}")
                                self.commandFeedback.emit(error_msg)
                                print("Mission rejected during upload.")
                                return False
                
                if not request_received:
                    error_msg = f"Timeout waiting for mission request {expected_seq}"
                    print(f"[DroneCommander ERROR] {error_msg}")
                    self.commandFeedback.emit(error_msg)
                    print("Timeout waiting for mission request.")
                    return False
            
            print("[DroneCommander] All waypoints sent successfully")
            self.commandFeedback.emit("Mission upload successful!")
            print("Mission upload successful.")
            return True
            
        except Exception as e:
            print(f"[DroneCommander ERROR] Waypoint sending failed: {e}")
            import traceback
            traceback.print_exc()
            self.commandFeedback.emit(f"Mission upload error: {str(e)}")
            print("Mission upload error.")
            return False

    @pyqtSlot(result=bool)
    def requestAllParameters(self):
     """Request ALL drone parameters - FIXED VERSION"""
     if not self._is_drone_ready():
        self.commandFeedback.emit("Error: Drone not connected to request parameters.")
        print("[DroneCommander] ❌ Cannot request parameters - drone not connected")
        return False
    
     if self._fetching_params:
        print("[DroneCommander] ⚠️ Parameter fetch already in progress")
        self.commandFeedback.emit("Parameter fetch already in progress...")
        return False
    
     print("\n" + "="*60)
     print("[DroneCommander] ✅ Starting parameter fetch")
     print("="*60)
    
    # Mark as active FIRST (before clearing queue)
     self._fetching_params = True
     self._param_request_active = True
    
    # Clear previous parameters
     with self._param_lock:
        self._parameters.clear()
    
    # Clear queue completely
     print("[DroneCommander] 🧹 Clearing parameter queue...")
     cleared_count = 0
     while not self._param_queue.empty():
        try:
            self._param_queue.get_nowait()
            cleared_count += 1
        except queue.Empty:
            break
    
     if cleared_count > 0:
         print(f"[DroneCommander] 🧹 Cleared {cleared_count} old parameters from queue")
    
    # Send parameter request (send multiple times for reliability)
     print("[DroneCommander] 📤 Sending PARAM_REQUEST_LIST...")
     for retry in range(3):
        self._drone.mav.param_request_list_send(
            self._drone.target_system,
            self._drone.target_component
        )
        time.sleep(0.1)
    
    # Start processing thread AFTER sending request
     print("[DroneCommander] 🚀 Starting processing thread...")
     fetch_thread = threading.Thread(target=self._process_parameter_queue_fixed, daemon=True)
     fetch_thread.start()
     
     self.commandFeedback.emit("Requesting parameters from drone...")
     return True

    
    def _process_parameter_queue_fixed(self):
     """Process parameters from queue - COMPLETE REWRITE"""
     print("[DroneCommander] 📥 Processing parameter queue (thread started)...")
    
     try:
        collected_params = {}
        total_params = None
        start_time = time.time()
        last_param_time = time.time()
        
        overall_timeout = 60  # 60 seconds total
        initial_timeout = 10  # 10 seconds to receive first parameter
        no_data_timeout = 3   # 3 seconds without new data
        
        print("[DroneCommander] ⏳ Waiting for first parameter...")
        first_param_received = False
        
        while time.time() - start_time < overall_timeout:
            try:
                # Try to get parameter from queue
                timeout_to_use = 0.5
                param_data = self._param_queue.get(timeout=timeout_to_use)
                
                if param_data:
                    if not first_param_received:
                        print("[DroneCommander] ✅ First parameter received!")
                        first_param_received = True
                    
                    last_param_time = time.time()
                    
                    param_id = param_data['name']
                    param_value = param_data['value']
                    param_type = param_data['type']
                    param_index = param_data['index']
                    param_count = param_data['count']
                    
                    # Set total on first parameter
                    if total_params is None:
                        total_params = param_count
                        print(f"[DroneCommander] 📊 Total parameters expected: {total_params}")
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
                        
                        # Progress update every 100 params
                        current_count = len(collected_params)
                        if current_count % 100 == 0:
                            progress_pct = (current_count * 100 // total_params) if total_params else 0
                            print(f"[DroneCommander] 📥 Progress: {current_count}/{total_params} ({progress_pct}%)")
                            self.commandFeedback.emit(f"Received {current_count}/{total_params} parameters ({progress_pct}%)...")
                    
                    # Check if complete
                    if total_params and len(collected_params) >= total_params:
                        print(f"[DroneCommander] ✅ All {len(collected_params)} unique parameters received!")
                        break
                
            except queue.Empty:
                # Check if we haven't received first parameter yet
                if not first_param_received:
                    elapsed = time.time() - start_time
                    if elapsed > initial_timeout:
                        print(f"[DroneCommander] ❌ No parameters received after {initial_timeout}s")
                        print("[DroneCommander] ❌ Check MAVLink connection and routing")
                        self.commandFeedback.emit("❌ No parameters received - check connection")
                        return
                    continue
                
                # Check timeout for ongoing reception
                current_count = len(collected_params)
                time_since_last = time.time() - last_param_time
                
                if time_since_last > no_data_timeout:
                    print(f"[DroneCommander] ℹ️ No new data for {no_data_timeout}s")
                    print(f"[DroneCommander] ℹ️ Received {current_count} unique parameters so far")
                    
                    # Check if we got most parameters
                    if total_params:
                        completion_pct = (current_count * 100 // total_params)
                        print(f"[DroneCommander] 📊 Completion: {completion_pct}%")
                        
                        if current_count >= total_params * 0.95:  # 95% threshold
                            print(f"[DroneCommander] ✅ Got {completion_pct}% - considering complete")
                            break
                        elif current_count > 1000:  # Absolute minimum
                            print(f"[DroneCommander] ✅ Got {current_count} parameters - considering complete")
                            break
                        else:
                            print(f"[DroneCommander] ⏳ Only got {completion_pct}% - waiting longer...")
                    elif current_count > 1000:
                        print(f"[DroneCommander] ✅ Got {current_count} parameters without total - considering complete")
                        break
                
                continue
        
        # Finalize
        final_count = len(collected_params)
        print(f"\n[DroneCommander] 📊 Parameter Collection Summary:")
        print(f"  - Unique parameters collected: {final_count}")
        print(f"  - Expected parameters: {total_params if total_params else 'Unknown'}")
        print(f"  - Time elapsed: {time.time() - start_time:.1f}s")
        
        if final_count > 0:
            # Update the property
            with self._param_lock:
                self._parameters = collected_params
            
            print(f"[DroneCommander] 💾 Stored {final_count} parameters in memory")
            
            # Small delay to ensure property is updated
            time.sleep(0.1)
            
            # Emit signal to QML
            print(f"[DroneCommander] 📤 Emitting parametersUpdated signal to QML...")
            self.parametersUpdated.emit()
            
            completion_pct = (final_count * 100 // total_params) if total_params else 100
            self.commandFeedback.emit(f"✅ Loaded {final_count} parameters ({completion_pct}%)!")
            print(f"[DroneCommander] ✅ Parameters available to QML - SUCCESS!")
        else:
            print("[DroneCommander] ❌ FAILED - No parameters received")
            self.commandFeedback.emit("❌ Failed to receive any parameters from drone")
    
     except Exception as e:
        print(f"[DroneCommander] ❌ EXCEPTION in parameter processing: {e}")
        import traceback
        traceback.print_exc()
        self.commandFeedback.emit(f"Error processing parameters: {e}")
    
     finally:
        self._fetching_params = False
        self._param_request_active = False
        print("[DroneCommander] 🏁 Parameter fetch thread completed")
        print("="*60 + "\n")

    def add_parameter_to_queue(self, param_msg):
     """
     Called by MAVLinkThread when it receives a PARAM_VALUE message.
    """
     if not self._param_request_active:
        return  # Ignore if we're not requesting parameters
    
     try:
        # Handle both bytes and string for param_id
        param_id = param_msg.param_id
        if isinstance(param_id, bytes):
            param_id = param_id.decode('utf-8').strip('\x00')
        elif isinstance(param_id, str):
            param_id = param_id.strip('\x00')
        else:
            param_id = str(param_id).strip('\x00')
        
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
