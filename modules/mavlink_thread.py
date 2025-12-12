# ========================================
# FILE 1: mavlink_thread.py (COMPLETE REPLACEMENT)
# ========================================

import math
import time
from PyQt5.QtCore import pyqtSignal, QThread
from pymavlink import mavutil
from pymavlink.dialects.v20 import ardupilotmega as mavlink_dialect
from pymavlink.dialects.v20 import common as mavlink_common
from pymavlink.dialects.v20 import ardupilotmega as mavutil_ardupilot

class MAVLinkThread(QThread):
    telemetryUpdated = pyqtSignal(dict)
    statusTextChanged = pyqtSignal(str)

    def __init__(self, drone):
        super().__init__()
        self.drone = drone
        self.running = True
        self.current_telemetry_components = {
            'mode': "UNKNOWN", 'armed': False,
            'lat': None, 'lon': None, 'alt': None, 'rel_alt': None,
            'roll': None, 'pitch': None, 'yaw': None,
            'heading': None,
            'groundspeed': 0.0, 'airspeed': 0.0,
            'battery_remaining': None,
            'voltage_battery': None,
            'current_battery': None,
            'gps_fix_type': 0,
            'satellites_visible': 0
        }
        
        # GCS mode priority system
        self.gcs_commanded_mode = None
        self.ignore_rc_mode_changes = True
        self.last_mode_enforcement_time = 0
        self.mode_enforcement_interval = 0.5
        self.last_mode_change_time = 0
        
        print("[MAVLinkThread] ✅ Initialized with GCS mode priority ENABLED by default")
        print("[MAVLinkThread] 🔒 RC mode switch will be IGNORED (RC flight controls still work)")

    def set_gcs_mode(self, mode_name):
        """
        Call this when GCS commands a mode change.
        CRITICAL: Immediately updates telemetry so DroneCommander sees the change.
        """
        mode_upper = mode_name.upper()
        old_mode = self.current_telemetry_components['mode']
        
        self.gcs_commanded_mode = mode_upper
        self.last_mode_enforcement_time = 0
        
        # ✅ CRITICAL FIX: Immediately update telemetry
        self.current_telemetry_components['mode'] = mode_upper
        
        # ✅ CRITICAL: Emit signal so DroneModel updates immediately
        self.telemetryUpdated.emit(self.current_telemetry_components.copy())
        
        print(f"[MAVLinkThread] 🎯 GCS mode set to: {mode_upper}")
        print(f"[MAVLinkThread] 📤 Telemetry updated: {old_mode} -> {mode_upper}")
        print(f"[MAVLinkThread] 🔒 RC mode switch will be overridden to maintain {mode_upper}")

    def enable_gcs_mode_priority(self):
        """Enable GCS mode priority - RC mode switch is ignored."""
        self.ignore_rc_mode_changes = True
        print("[MAVLinkThread] 🔒 GCS mode priority ENABLED")
        print("[MAVLinkThread] ✅ RC mode switch DISABLED - only GCS can change modes")

    def disable_gcs_mode_priority(self):
        """Disable GCS mode priority - RC mode switch works normally."""
        self.ignore_rc_mode_changes = False
        self.gcs_commanded_mode = None
        print("[MAVLinkThread] 🔓 GCS mode priority DISABLED")
        print("[MAVLinkThread] ✅ RC mode switch ENABLED - works normally")

    def _should_enforce_gcs_mode(self, current_mode):
        """Check if we need to enforce GCS mode (override RC)."""
        if not self.gcs_commanded_mode:
            return False
        
        if not self.ignore_rc_mode_changes:
            return False
        
        if current_mode == self.gcs_commanded_mode:
            return False
        
        current_time = time.time()
        time_since_last_enforcement = current_time - self.last_mode_enforcement_time
        
        if time_since_last_enforcement >= self.mode_enforcement_interval:
            return True
        
        return False

    def _force_gcs_mode(self):
        """Actively send mode change command to enforce GCS mode."""
        if not self.gcs_commanded_mode:
            return
        
        try:
            mode_map = self.drone.mode_mapping()
            mode_id = mode_map.get(self.gcs_commanded_mode)
            
            if mode_id is not None:
                self.drone.mav.set_mode_send(
                    self.drone.target_system,
                    mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                    mode_id
                )
                
                self.last_mode_enforcement_time = time.time()
                print(f"[MAVLinkThread] 🔄 Enforcing GCS mode: {self.gcs_commanded_mode} (overriding RC)")
        
        except Exception as e:
            print(f"[MAVLinkThread] ⚠️ Error enforcing GCS mode: {e}")

    def run(self):
        print("[MAVLinkThread] Thread started. Monitoring MAVLink messages...")
        
        while self.running:
            try:
                msg = self.drone.recv_match(blocking=False, timeout=0.01)

                if msg:
                    msg_type = msg.get_type()
                    msg_dict = msg.to_dict()
                    telemetry_component_changed = False

                    if msg_type == "HEARTBEAT":
                        mode_map = self.drone.mode_mapping()
                        inv_mode_map = {v: k for k, v in mode_map.items()}
                        new_mode = inv_mode_map.get(msg_dict['custom_mode'], "UNKNOWN")
                        new_armed_status = bool(
                            msg_dict['base_mode'] & mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED
                        )
                        
                        # ========== GCS MODE PRIORITY ENFORCEMENT ==========
                        if self._should_enforce_gcs_mode(new_mode):
                            print(f"[MAVLinkThread] 🚫 Blocked RC mode change: {new_mode} (GCS wants {self.gcs_commanded_mode})")
                            self._force_gcs_mode()
                            # Keep GCS mode in telemetry
                            new_mode = self.gcs_commanded_mode
                        
                        # ========== MODE CHANGE DETECTION ==========
                        if self.current_telemetry_components['mode'] != new_mode:
                            old_mode = self.current_telemetry_components['mode']
                            self.current_telemetry_components['mode'] = new_mode
                            telemetry_component_changed = True
                            
                            print(f"[MAVLinkThread] ✅ Mode changed: {old_mode} -> {new_mode}")
                            self.last_mode_change_time = time.time()
                            
                            if new_mode == self.gcs_commanded_mode:
                                print(f"[MAVLinkThread] ✅ GCS mode confirmed: {new_mode}")
                        
                        # ========== ARM STATUS ==========
                        if self.current_telemetry_components['armed'] != new_armed_status:
                            self.current_telemetry_components['armed'] = new_armed_status
                            telemetry_component_changed = True

                    elif msg_type == "GLOBAL_POSITION_INT":
                        new_lat = msg_dict['lat'] / 1e7
                        new_lon = msg_dict['lon'] / 1e7
                        new_alt = msg_dict['alt'] / 1000.0
                        new_rel_alt = msg_dict['relative_alt'] / 1000.0

                        if (
                            self.current_telemetry_components['lat'] != new_lat
                            or self.current_telemetry_components['lon'] != new_lon
                            or self.current_telemetry_components['alt'] != new_alt
                            or self.current_telemetry_components['rel_alt'] != new_rel_alt
                        ):
                            self.current_telemetry_components.update({
                                'lat': new_lat,
                                'lon': new_lon,
                                'alt': new_alt,
                                'rel_alt': new_rel_alt,
                            })
                            telemetry_component_changed = True

                    elif msg_type == "GPS_RAW_INT":
                        new_fix_type = msg_dict.get('fix_type', 0)
                        new_satellites = msg_dict.get('satellites_visible', 0)
                        
                        if (self.current_telemetry_components['gps_fix_type'] != new_fix_type or
                            self.current_telemetry_components['satellites_visible'] != new_satellites):
                            self.current_telemetry_components['gps_fix_type'] = new_fix_type
                            self.current_telemetry_components['satellites_visible'] = new_satellites
                            telemetry_component_changed = True

                    elif msg_type == "ATTITUDE":
                        new_roll = math.degrees(msg_dict['roll'])
                        new_pitch = math.degrees(msg_dict['pitch'])
                        new_yaw = math.degrees(msg_dict['yaw'])
                        if (
                            self.current_telemetry_components['roll'] != new_roll
                            or self.current_telemetry_components['pitch'] != new_pitch
                            or self.current_telemetry_components['yaw'] != new_yaw
                        ):
                            self.current_telemetry_components.update({
                                'roll': new_roll,
                                'pitch': new_pitch,
                                'yaw': new_yaw,
                            })
                            telemetry_component_changed = True

                    elif msg_type == "VFR_HUD":
                        new_heading = msg_dict['heading']
                        new_groundspeed = msg_dict['groundspeed']
                        new_airspeed = msg_dict['airspeed']
                        if (
                            self.current_telemetry_components['heading'] != new_heading
                            or self.current_telemetry_components['groundspeed'] != new_groundspeed
                            or self.current_telemetry_components['airspeed'] != new_airspeed
                        ):
                            self.current_telemetry_components.update({
                                'heading': new_heading,
                                'groundspeed': new_groundspeed,
                                'airspeed': new_airspeed,
                            })
                            telemetry_component_changed = True

                    elif msg_type == "SYS_STATUS":
                        new_battery_remaining = msg_dict.get('battery_remaining')
                        new_voltage_battery = msg_dict.get('voltage_battery')
                        new_current_battery = msg_dict.get('current_battery')

                        if new_voltage_battery not in (None, 65535):
                            new_voltage_battery /= 1000.0
                        else:
                            new_voltage_battery = None

                        if new_current_battery not in (None, -1):
                            new_current_battery /= 100.0
                        else:
                            new_current_battery = None

                        if new_battery_remaining == -1:
                            new_battery_remaining = None

                        if (
                            self.current_telemetry_components['battery_remaining'] != new_battery_remaining
                            or self.current_telemetry_components['voltage_battery'] != new_voltage_battery
                            or self.current_telemetry_components['current_battery'] != new_current_battery
                        ):
                            self.current_telemetry_components.update({
                                'battery_remaining': new_battery_remaining,
                                'voltage_battery': new_voltage_battery,
                                'current_battery': new_current_battery,
                            })
                            telemetry_component_changed = True

                    elif msg_type == "STATUSTEXT":
                        self.statusTextChanged.emit(msg.text)

                    # ✅ ALWAYS emit telemetry updates
                    if telemetry_component_changed:
                        self.telemetryUpdated.emit(self.current_telemetry_components.copy())

                else:
                    self.msleep(10)

            except Exception as e:
                print(f"[MAVLinkThread] Error reading telemetry: {e}")
                self.running = False
                if hasattr(self, "on_disconnect_callback") and self.on_disconnect_callback:
                    self.on_disconnect_callback()
                time.sleep(0.1)

    def stop(self):
        print("[MAVLinkThread] Stopping thread...")
        self.running = False
        self.quit()
        self.wait()
        print("[MAVLinkThread] Thread stopped.")


# ========================================
# FILE 2: drone_module.py - ONLY UPDATE updateTelemetry METHOD
# ========================================
# Replace your updateTelemetry method with this improved version:

def updateTelemetry(self, data):
    """
    Handle telemetry updates from MAVLinkThread.
    CRITICAL: This updates self._telemetry which DroneCommander reads.
    """
    try:
        updated = False
        
        # ✅ CRITICAL: Update telemetry dictionary
        for key, value in data.items():
            if self._telemetry.get(key) != value:
                old_value = self._telemetry.get(key)
                self._telemetry[key] = value
                updated = True
                
                # Log mode changes for debugging
                if key == 'mode':
                    print(f"[DroneModel] 📥 Telemetry updated: mode={old_value} -> {value}")
                
                # Detect status changes
                self._detect_status_changes(key, old_value, value)
        
        # ✅ Always emit signal when telemetry updates
        if updated:
            self.telemetryChanged.emit()
            
    except Exception as e:
        print(f"[DroneModel ERROR] updateTelemetry failed: {e}")
        import traceback
        traceback.print_exc()
