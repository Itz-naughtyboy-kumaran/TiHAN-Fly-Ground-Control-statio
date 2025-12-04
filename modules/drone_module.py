from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QTimer
from pymavlink import mavutil
from modules.mavlink_thread import MAVLinkThread
import time

class DroneModel(QObject):
    telemetryChanged = pyqtSignal()
    statusTextsChanged = pyqtSignal()
    droneConnectedChanged = pyqtSignal()

    def __init__(self):
        super().__init__()
        self._telemetry = {
            'mode': "UNKNOWN", 
            'armed': False,
            'lat': None, 
            'lon': None, 
            'vibration': 0.0,
            'vibration_x': 0.0,
            'vibration_y': 0.0,
            'vibration_z': 0.0,
            'ekf_variance': 0.0,
            'alt': 0, 
            'rel_alt': 0,
            'roll': None, 
            'pitch': None, 
            'yaw': None, 
            'heading': None,
            'groundspeed': 0.0, 
            'airspeed': 0.0, 
            'battery_remaining': 0.0, 
            'voltage_battery': 0.0,
            'safety_armed': False,
            'ekf_ok': False,
            'gps_status': 0,
            'satellites_visible': 0,
            'gps_fix_type': 0
        }
        self._status_texts = []
        self._drone = None
        self._thread = None
        self._is_connected = False
        self._connection_monitor = QTimer()
        self._connection_monitor.timeout.connect(self._check_connection_health)
        
        # State tracking
        self._prev_mode = None
        self._prev_armed = None
        self._prev_safety_armed = None
        self._prev_ekf_ok = None
        self._prev_gps_fix = None
        self._prev_satellites = None
        self._prev_battery_level = None
        
        # Message suppression
        self._last_waypoint_time = 0
        self._suppress_waypoint_interval = 10.0
        self._message_cooldowns = {}
        
        # User-initiated mode tracking
        self._user_requested_mode = None
        self._user_mode_request_time = 0
        self._mode_change_grace_period = 3.0
        self._stable_mode = None
        self._stable_mode_time = 0
        self._stable_mode_duration = 2.0
        
        print("[DroneModel] Initialized.")

    def setCalibrationModel(self, calibration_model):
        self._calibration_model = calibration_model
        print("[DroneModel] CalibrationModel reference set.")

    @pyqtSlot()
    def triggerLevelCalibration(self):
        if hasattr(self, '_calibration_model'):
            print("[DroneModel] Triggering level calibration...")
            self._calibration_model.startLevelCalibration()
        else:
            print("[DroneModel] CalibrationModel not available.")

    @pyqtSlot()
    def triggerAccelCalibration(self):
        if hasattr(self, '_calibration_model'):
            print("[DroneModel] Triggering accelerometer calibration...")
            self._calibration_model.startAccelCalibration()
        else:
            print("[DroneModel] CalibrationModel not available.")

    @pyqtSlot(str)
    def notifyModeChangeRequest(self, requested_mode):
        """Called by DroneCommander when user requests a mode change"""
        self._user_requested_mode = requested_mode
        self._user_mode_request_time = time.time()
        print(f"[DroneModel] 🎯 User requested mode change to: {requested_mode}")

    @pyqtSlot(str, str, int, result=bool)
    def connectToDrone(self, drone_id, uri, baud):
        print(f"[DroneModel] Attempting to connect to drone {drone_id} at {uri} with baud {baud}...")
        
        if self._is_connected:
            print("[DroneModel] Cleaning up existing connection...")
            self.cleanup()
            time.sleep(1)
        
        try:
            print(f"[DroneModel] Opening MAVLink connection to {uri}...")
            self._drone = mavutil.mavlink_connection(uri, baud=baud)
            
            print("[DroneModel] Waiting for heartbeat...")
            self._drone.wait_heartbeat(timeout=10)
            
            print(f"[DroneModel] Connection established!")
            print(f"[DroneModel] System ID: {self._drone.target_system}, Component ID: {self._drone.target_component}")
            
            self._is_connected = True
            self.droneConnectedChanged.emit()
            self.addStatusText("✅ Drone connected successfully")
            
            # Request message rates
            print("[DroneModel] Configuring message rates...")
            
            self._drone.mav.command_long_send(
                self._drone.target_system, self._drone.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0, 33, 200000, 0, 0, 0, 0, 0
            )
            time.sleep(0.1)
            
            self._drone.mav.command_long_send(
                self._drone.target_system, self._drone.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0, 30, 100000, 0, 0, 0, 0, 0
            )
            time.sleep(0.1)
            
            self._drone.mav.command_long_send(
                self._drone.target_system, self._drone.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0, 74, 200000, 0, 0, 0, 0, 0
            )
            time.sleep(0.1)
            
            self._drone.mav.command_long_send(
                self._drone.target_system, self._drone.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0, 1, 500000, 0, 0, 0, 0, 0
            )
            time.sleep(0.1)
            
            self._drone.mav.command_long_send(
                self._drone.target_system, self._drone.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0, 24, 500000, 0, 0, 0, 0, 0
            )
            time.sleep(0.1)
            
            self._drone.mav.command_long_send(
                self._drone.target_system, self._drone.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0, 193, 1000000, 0, 0, 0, 0, 0
            )
            time.sleep(0.1)
            
            print("[DroneModel] Requesting VIBRATION messages...")
            self._drone.mav.command_long_send(
                self._drone.target_system, self._drone.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0, 241, 200000, 0, 0, 0, 0, 0
            )
            time.sleep(0.1)
            
            print("[DroneModel] Message rates configured")
            self.addStatusText("📡 Telemetry streams active")
            
            # Start MAVLink thread
            self._thread = MAVLinkThread(self._drone)
            self._thread.telemetryUpdated.connect(self.updateTelemetry)
            self._thread.statusTextChanged.connect(self._handleRawStatusText)
            self._thread.start()
            print("[DroneModel] MAVLinkThread started")
            
            self._connection_monitor.start(5000)
            return True

        except Exception as e:
            print(f"[DroneModel ERROR] Connection failed: {e}")
            import traceback
            traceback.print_exc()
            
            self.addStatusText(f"❌ Connection failed: {str(e)}")
            
            if self._drone:
                try:
                    self._drone.close()
                except:
                    pass
                self._drone = None
            
            self._is_connected = False
            self.droneConnectedChanged.emit()
            return False

    def _check_connection_health(self):
        if not self._is_connected or not self._drone:
            self._connection_monitor.stop()

    def _handleRawStatusText(self, text):
        """Filter and process raw status messages from MAVLink"""
        if "waypoint" in text.lower() or "📍" in text:
            current_time = time.time()
            if current_time - self._last_waypoint_time < self._suppress_waypoint_interval:
                return
            self._last_waypoint_time = current_time
        
        if "command 511" in text.lower() and "accepted" in text.lower():
            return
        
        self.addStatusText(text)

    def updateTelemetry(self, data):
        """⭐ CRITICAL: Update telemetry and ALWAYS emit signal ⭐"""
        try:
            updated = False
            for key, value in data.items():
                if self._telemetry.get(key) != value:
                    old_value = self._telemetry.get(key)
                    self._telemetry[key] = value
                    updated = True
                    
                    # Special handling for mode changes
                    if key == 'mode':
                        print(f"[DroneModel] 🔄 MODE UPDATE: {old_value} → {value}")
                    
                    self._detect_status_changes(key, old_value, value)
            
            # ⭐ CRITICAL: Always emit telemetryChanged, even for small updates
            if updated:
                self.telemetryChanged.emit()
                
        except Exception as e:
            print(f"[DroneModel ERROR] updateTelemetry: {e}")
            import traceback
            traceback.print_exc()

    def _detect_status_changes(self, key, old_value, new_value):
        """Detect IMPORTANT status changes"""
        
        # ========== FLIGHT MODE (Smart Detection) ==========
        if key == 'mode' and old_value and old_value != new_value:
            current_time = time.time()
            
            # Track if mode is stable
            if self._stable_mode != new_value:
                self._stable_mode = new_value
                self._stable_mode_time = current_time
                print(f"[DroneModel] 🔄 Mode stability tracker reset: {new_value}")
            
            # Calculate how long mode has been stable
            time_in_mode = current_time - self._stable_mode_time
            
            # Check if user requested this mode
            user_requested_recently = (
                self._user_requested_mode == new_value and 
                current_time - self._user_mode_request_time < self._mode_change_grace_period
            )
            
            mode_is_stable = time_in_mode >= self._stable_mode_duration
            
            if user_requested_recently:
                # User requested this mode - show it immediately
                self.addStatusText(f"🔄 Mode changed: {new_value}")
                print(f"[DroneModel] ✅ User-requested mode confirmed: {new_value}")
                # Clear the user request
                self._user_requested_mode = None
                self._prev_mode = new_value
                
            elif mode_is_stable and self._prev_mode != new_value:
                # Mode has been stable for 2+ seconds and we haven't reported it yet
                self.addStatusText(f"🔄 Mode: {new_value}")
                print(f"[DroneModel] ✅ Stable mode change detected: {new_value}")
                self._prev_mode = new_value
        
        # ========== ARM/DISARM (CRITICAL) ==========
        if key == 'armed' and old_value is not None and old_value != new_value:
            if new_value:
                self.addStatusText("🔴 ARMED - Motors enabled!")
            else:
                self.addStatusText("🟢 DISARMED - Motors safe")
        
        # ========== SAFETY SWITCH (VERY IMPORTANT) ==========
        if key == 'safety_armed':
            if old_value is None:
                if not new_value:
                    self.addStatusText("⚠️ Safety switch: NOT PRESSED")
                    self.addStatusText("   → Press safety button to enable arming")
                else:
                    self.addStatusText("🔓 Safety switch: PRESSED - Ready")
            elif old_value != new_value:
                if new_value:
                    self.addStatusText("🔓 Safety: PRESSED - Can arm now")
                else:
                    self.addStatusText("🔒 Safety: RELEASED - Cannot arm")
        
        # ========== EKF STATUS (CRITICAL) ==========
        if key == 'ekf_ok':
            if old_value is None and not new_value:
                self.addStatusText("⚠️ EKF: Initializing...")
            elif old_value is not None and old_value != new_value:
                if new_value:
                    self.addStatusText("✅ EKF: Healthy - Ready to fly")
                else:
                    self.addStatusText("❌ EKF: FAILURE - DO NOT FLY!")
        
        # ========== EKF VARIANCE WARNINGS ==========
        if key == 'ekf_variance' and new_value is not None:
            if new_value > 1.0:
                if not self._check_message_cooldown('ekf_high_variance', 30):
                    self.addStatusText(f"⚠️ EKF variance high: {new_value:.3f}")
        
        # ========== VIBRATION WARNINGS ==========
        if key == 'vibration' and new_value is not None:
            if new_value > 60:
                if not self._check_message_cooldown('vibration_critical', 30):
                    self.addStatusText(f"🚨 Vibration CRITICAL: {new_value:.1f} m/s²")
            elif new_value > 30:
                if not self._check_message_cooldown('vibration_high', 60):
                    self.addStatusText(f"⚠️ Vibration HIGH: {new_value:.1f} m/s²")
        
        # ========== GPS FIX TYPE ==========
        if key == 'gps_fix_type' and (old_value is None or old_value != new_value):
            gps_map = {
                0: ("❌ GPS: No GPS", "error"),
                1: ("❌ GPS: No Fix", "error"),
                2: ("⚠️ GPS: 2D Fix (weak)", "warning"),
                3: ("✅ GPS: 3D Fix - Good", "success"),
                4: ("✅ GPS: DGPS - Excellent", "success"),
                5: ("✅ GPS: RTK Float", "success"),
                6: ("✅ GPS: RTK Fixed - Best", "success")
            }
            
            status, level = gps_map.get(new_value, (f"GPS: Unknown ({new_value})", "info"))
            
            if old_value is None or abs(new_value - old_value) >= 1:
                self.addStatusText(status)
                
                if new_value < 3:
                    self.addStatusText("   → Wait for 3D fix before arming")
        
        # ========== SATELLITE COUNT ==========
        if key == 'satellites_visible':
            prev_sats = self._prev_satellites
            
            if prev_sats is not None:
                if new_value >= 10 and prev_sats < 10:
                    self.addStatusText(f"📡 Satellites: {new_value} - Excellent")
                elif new_value < 6 and prev_sats >= 6:
                    self.addStatusText(f"⚠️ Satellites: {new_value} - Too low!")
                elif new_value == 0 and prev_sats > 0:
                    self.addStatusText("❌ Satellites: Signal lost!")
            elif new_value > 0:
                if new_value >= 10:
                    self.addStatusText(f"📡 Satellites: {new_value} - Excellent")
                elif new_value >= 6:
                    self.addStatusText(f"📡 Satellites: {new_value} - Good")
                else:
                    self.addStatusText(f"⚠️ Satellites: {new_value} - Low")
            
            self._prev_satellites = new_value
        
        # ========== BATTERY WARNINGS ==========
        if key == 'battery_remaining':
            if new_value is not None:
                prev_level = self._prev_battery_level
                
                if new_value <= 10 and (prev_level is None or prev_level > 10):
                    self.addStatusText(f"🔋 CRITICAL: Battery {new_value}% - LAND NOW!")
                elif new_value <= 20 and (prev_level is None or prev_level > 20):
                    self.addStatusText(f"⚠️ Battery LOW: {new_value}% - Return home")
                elif new_value <= 30 and (prev_level is None or prev_level > 30):
                    self.addStatusText(f"🔋 Battery: {new_value}% - Plan landing")
                
                self._prev_battery_level = new_value
        
        # ========== VOLTAGE WARNINGS ==========
        if key == 'voltage_battery' and new_value and new_value > 0:
            if new_value < 10.5:
                if not self._check_message_cooldown('low_voltage', 30):
                    self.addStatusText(f"⚠️ Voltage: {new_value:.1f}V - Very low!")
            elif new_value < 11.1:
                if not self._check_message_cooldown('low_voltage', 60):
                    self.addStatusText(f"🔋 Voltage: {new_value:.1f}V - Low")

    def _check_message_cooldown(self, msg_id, cooldown_seconds):
        """Prevent message spam - returns True if still in cooldown"""
        current_time = time.time()
        last_time = self._message_cooldowns.get(msg_id, 0)
        
        if current_time - last_time < cooldown_seconds:
            return True
        
        self._message_cooldowns[msg_id] = current_time
        return False

    @pyqtSlot(str)
    def addStatusText(self, text):
        try:
            from datetime import datetime
            timestamp = datetime.now().strftime("%H:%M:%S")
            formatted = f"[{timestamp}] {text}"
            
            self._status_texts.append(formatted)
            if len(self._status_texts) > 100:
                self._status_texts.pop(0)
            
            self.statusTextsChanged.emit()
            print(f"[Status] {formatted}")
        except Exception as e:
            print(f"[DroneModel ERROR] addStatusText: {e}")

    @pyqtSlot()
    def clearStatusTexts(self):
        print("[DroneModel] Clearing status texts...")
        self._status_texts.clear()
        self.statusTextsChanged.emit()
        self.addStatusText("🧹 Status cleared")

    @pyqtSlot()
    def disconnectDrone(self):
        print("[DroneModel] Disconnecting...")
        self.addStatusText("🔌 Disconnecting...")
        self.cleanup()
        self._is_connected = False
        self.droneConnectedChanged.emit()
        self.addStatusText("❌ Disconnected")

    @pyqtProperty('QVariant', notify=telemetryChanged)
    def telemetry(self):
        return self._telemetry

    @pyqtProperty('QVariantList', notify=statusTextsChanged)
    def statusTexts(self):
        return self._status_texts

    @pyqtProperty(bool, notify=droneConnectedChanged)
    def isConnected(self):
        return self._is_connected

    @property
    def drone_connection(self):
        return self._drone

    def cleanup(self):
        print("[DroneModel] Cleanup...")
        
        if self._connection_monitor.isActive():
            self._connection_monitor.stop()
        
        if self._thread:
            print("[DroneModel] Stopping thread...")
            self._thread.stop()
            self._thread.wait(2000)
            self._thread = None
        
        if self._drone:
            try:
                self._drone.close()
            except Exception as e:
                print(f"[DroneModel] Close error: {e}")
            self._drone = None
        
        # Reset tracking
        self._prev_mode = None
        self._prev_armed = None
        self._prev_safety_armed = None
        self._prev_ekf_ok = None
        self._prev_gps_fix = None
        self._prev_satellites = None
        self._prev_battery_level = None
        self._message_cooldowns.clear()
        self._user_requested_mode = None
        self._stable_mode = None
        
        print("[DroneModel] Cleanup complete")
