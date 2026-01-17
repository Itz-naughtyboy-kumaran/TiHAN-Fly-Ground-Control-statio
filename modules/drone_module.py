from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QTimer, QThread
from pymavlink import mavutil
from modules.mavlink_thread import MAVLinkThread
from modules.drone_commander import DroneCommander  # ← ADD THIS IMPORT
import time

class ConnectionWorker(QThread):
    """Worker thread to handle drone connection without blocking UI"""
    connectionSuccess = pyqtSignal(object)  # Sends drone connection object
    connectionFailed = pyqtSignal(str)  # Sends error message
    
    def __init__(self, uri, baud, target_system=1, target_component=1):
        super().__init__()
        self.uri = uri
        self.baud = baud
        self.target_system = target_system
        self.target_component = target_component
        self._should_stop = False
    
    def run(self):
        """Run in background thread - won't block UI"""
        try:
            print(f"[ConnectionWorker] Opening MAVLink connection to {self.uri}...")
            drone = mavutil.mavlink_connection(self.uri, baud=self.baud)
            
            if self._should_stop:
                return
            
            print("[ConnectionWorker] Waiting for heartbeat...")
            drone.wait_heartbeat(timeout=10)
            
            if self._should_stop:
                drone.close()
                return
            
            print(f"[ConnectionWorker] ✅ Connection established!")
            print(f"[ConnectionWorker] System ID: {drone.target_system}, Component ID: {drone.target_component}")
            
            self.connectionSuccess.emit(drone)
            
        except Exception as e:
            if not self._should_stop:
                print(f"[ConnectionWorker] ❌ Connection failed: {e}")
                self.connectionFailed.emit(str(e))
    
    def stop(self):
        """Stop the connection attempt"""
        self._should_stop = True


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
        self._drone_commander = None  # ← ADD THIS
        self._is_connected = False
        self._connection_monitor = QTimer()
        self._connection_monitor.timeout.connect(self._check_connection_health)
        self._connection_worker = None
        
        # State tracking
        self._prev_mode = None
        self._prev_armed = None
        self._prev_ekf_ok = None
        self._prev_gps_fix = None
        self._prev_satellites = None
        self._prev_battery_level = None
        
        # Message suppression
        self._last_waypoint_time = 0
        self._suppress_waypoint_interval = 10.0
        self._message_cooldowns = {}
        
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

    @pyqtSlot(str, str, int, result=bool)
    def connectToDrone(self, drone_id, uri, baud):
        """NON-BLOCKING connection - Returns immediately, emits signals when done"""
        print(f"[DroneModel] 🚀 Starting connection to {uri}...")
        
        if self._is_connected:
            print("[DroneModel] Cleaning up existing connection...")
            self.cleanup()
            time.sleep(0.5)
        
        # Cancel any existing connection attempt
        if self._connection_worker and self._connection_worker.isRunning():
            print("[DroneModel] Stopping previous connection attempt...")
            self._connection_worker.stop()
            self._connection_worker.wait(2000)
        
        # Create connection worker thread
        self._connection_worker = ConnectionWorker(uri, baud)
        self._connection_worker.connectionSuccess.connect(self._on_connection_success)
        self._connection_worker.connectionFailed.connect(self._on_connection_failed)
        
        # Start connection in background - UI remains responsive!
        self._connection_worker.start()
        
        print("[DroneModel] ✅ Connection worker started (non-blocking)")
        return True  # Returns immediately
    
    def _on_connection_success(self, drone):
        """Called when connection succeeds in background thread"""
        print("[DroneModel] 🎉 Connection successful! Setting up...")
        
        self._drone = drone
        self._is_connected = True
        self.droneConnectedChanged.emit()
        self.addStatusText("✅ Drone connected successfully")
        
        # Configure the drone (this is fast, won't block)
        self._configure_drone()
        
        # ==========================================
        # ✅ CREATE DRONE COMMANDER FIRST
        # ==========================================
        print("[DroneModel] 📡 Creating DroneCommander...")
        self._drone_commander = DroneCommander(self)
        print("[DroneModel] ✅ DroneCommander created")
        
        # ==========================================
        # ✅ PASS DRONE_COMMANDER TO MAVLINK THREAD
        # ==========================================
        print("[DroneModel] 🧵 Creating MAVLinkThread with DroneCommander...")
        self._thread = MAVLinkThread(
            self._drone,
            drone_commander=self._drone_commander  # ← CRITICAL: Pass it here!
        )
        
        self._thread.telemetryUpdated.connect(self.updateTelemetry)
        self._thread.statusTextChanged.connect(self._handleRawStatusText)
        if hasattr(self, '_calibration_model'):
            self._thread.current_msg.connect(self._calibration_model.handle_mavlink_message)

            self._calibration_model.mav = self._drone
        
        self._thread.start()
        print("[DroneModel] ✅ MAVLinkThread started with parameter support")
        
        self._connection_monitor.start(5000)
        print("[DroneModel] ✅ Setup complete!")
    
    def _on_connection_failed(self, error_message):
        """Called when connection fails in background thread"""
        print(f"[DroneModel] ❌ Connection failed: {error_message}")
        self.addStatusText(f"❌ Connection failed: {error_message}")
        
        self._is_connected = False
        self.droneConnectedChanged.emit()
    
    def _configure_drone(self):
        """Configure drone parameters (fast, non-blocking operations)"""
        try:
            # Disable safety switch
            print("[DroneModel] Disabling safety switch requirement...")
            self._drone.mav.param_set_send(
                self._drone.target_system,
                self._drone.target_component,
                b'BRD_SAFETYENABLE',
                0,
                mavutil.mavlink.MAV_PARAM_TYPE_INT8
            )
            time.sleep(0.2)
            self.addStatusText("🔓 Safety switch bypassed")
            
            # Disable RC mode switching
            print("[DroneModel] 🔒 Disabling RC flight mode switching...")
            self._drone.mav.param_set_send(
                self._drone.target_system,
                self._drone.target_component,
                b'FLTMODE_CH',
                0,
                mavutil.mavlink.MAV_PARAM_TYPE_INT8
            )
            time.sleep(0.5)
            
            # Save parameters
            print("[DroneModel] 💾 Saving parameters...")
            self._drone.mav.command_long_send(
                self._drone.target_system,
                self._drone.target_component,
                mavutil.mavlink.MAV_CMD_PREFLIGHT_STORAGE,
                0, 1, 0, 0, 0, 0, 0, 0
            )
            time.sleep(0.5)
            
            self.addStatusText("🔒 RC mode switch DISABLED")
            self.addStatusText("💾 Settings saved")
            
        except Exception as e:
            print(f"[DroneModel] Configuration warning: {e}")
            self.addStatusText("⚠️ Some parameters not configured")
        
        # Configure message rates
        print("[DroneModel] Configuring message rates...")
        message_rates = [
            (33, 200000),   # GLOBAL_POSITION_INT at 5Hz
            (30, 100000),   # ATTITUDE at 10Hz
            (74, 200000),   # VFR_HUD at 5Hz
            (1, 500000),    # SYS_STATUS at 2Hz
            (24, 500000),   # GPS_RAW_INT at 2Hz
            (193, 1000000), # EKF_STATUS_REPORT at 1Hz
        ]
        
        for msg_id, interval in message_rates:
            self._drone.mav.command_long_send(
                self._drone.target_system,
                self._drone.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0, msg_id, interval, 0, 0, 0, 0, 0
            )
            time.sleep(0.1)
        
        self.addStatusText("📡 Telemetry streams active")

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
        
        self.addStatusText(text)

    def updateTelemetry(self, data):
        try:
            updated = False
            for key, value in data.items():
                if self._telemetry.get(key) != value:
                    old_value = self._telemetry.get(key)
                    self._telemetry[key] = value
                    updated = True
                    self._detect_status_changes(key, old_value, value)
            
            if updated:
                self.telemetryChanged.emit()
        except Exception as e:
            print(f"[DroneModel ERROR] {e}")

    def _detect_status_changes(self, key, old_value, new_value):
        """Detect IMPORTANT status changes"""
        
        if key == 'mode' and old_value and old_value != new_value:
            self.addStatusText(f"🔄 Mode: {old_value} → {new_value}")
        
        if key == 'armed' and old_value is not None and old_value != new_value:
            if new_value:
                self.addStatusText("🔴 ARMED - Motors enabled!")
            else:
                self.addStatusText("🟢 DISARMED - Motors safe")
        
        if key == 'ekf_ok':
            if old_value is None and not new_value:
                self.addStatusText("⚠️ EKF: Initializing...")
            elif old_value is not None and old_value != new_value:
                if new_value:
                    self.addStatusText("✅ EKF: Healthy - Ready to fly")
                else:
                    self.addStatusText("❌ EKF: FAILURE - DO NOT FLY!")
        
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
        
        if key == 'voltage_battery' and new_value and new_value > 0:
            if new_value < 10.5:
                if not self._check_message_cooldown('low_voltage', 30):
                    self.addStatusText(f"⚠️ Voltage: {new_value:.1f}V - Very low!")
            elif new_value < 11.1:
                if not self._check_message_cooldown('low_voltage', 60):
                    self.addStatusText(f"🔋 Voltage: {new_value:.1f}V - Low")

    def _check_message_cooldown(self, msg_id, cooldown_seconds):
        """Prevent message spam"""
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
            print(f"[DroneModel ERROR] {e}")

    @pyqtSlot()
    def clearStatusTexts(self):
        print("[DroneModel] Clearing status texts...")
        self._status_texts.clear()
        self.statusTextsChanged.emit()
        self.addStatusText("🧹 Status cleared")

    @pyqtSlot()
    def disconnectDrone(self):
        """Properly disconnect the drone with immediate state update"""
        print("[DroneModel] 🔌 Disconnecting...")
        self.addStatusText("🔌 Disconnecting...")
        
        # Stop connection worker if running
        if self._connection_worker and self._connection_worker.isRunning():
            print("[DroneModel] Stopping connection worker...")
            self._connection_worker.stop()
            self._connection_worker.wait(2000)
            self._connection_worker = None
        
        # CRITICAL: Update connection state IMMEDIATELY before cleanup
        was_connected = self._is_connected
        self._is_connected = False
        
        # Emit signal to update UI immediately
        if was_connected:
            print("[DroneModel] ⚡ Emitting droneConnectedChanged (disconnected)")
            self.droneConnectedChanged.emit()
        
        # Now cleanup resources
        self.cleanup()
        
        self.addStatusText("❌ Disconnected")
        print("[DroneModel] ✅ Disconnect complete")

    # ==========================================
    # ✅ ADD PROPERTY TO EXPOSE DRONE_COMMANDER TO QML
    # ==========================================
    @pyqtProperty(QObject, constant=True)
    def droneCommander(self):
        """Expose DroneCommander to QML"""
        return self._drone_commander

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
        """Clean up all drone resources"""
        print("[DroneModel] 🧹 Cleanup starting...")
        
        # Stop connection monitor
        if self._connection_monitor.isActive():
            self._connection_monitor.stop()
            print("[DroneModel]   ✓ Connection monitor stopped")
        
        # Stop MAVLink thread
        if self._thread:
            print("[DroneModel]   ⏸️ Stopping MAVLink thread...")
            self._thread.stop()
            self._thread.wait(2000)
            self._thread = None
            print("[DroneModel]   ✓ MAVLink thread stopped")
        
        # Close drone connection
        if self._drone:
            try:
                print("[DroneModel]   🔌 Closing drone connection...")
                self._drone.close()
                print("[DroneModel]   ✓ Drone connection closed")
            except Exception as e:
                print(f"[DroneModel]   ⚠️ Close error: {e}")
            self._drone = None
        
        # Clear drone commander
        self._drone_commander = None
        
        # Reset all tracking variables
        self._prev_mode = None
        self._prev_armed = None
        self._prev_ekf_ok = None
        self._prev_gps_fix = None
        self._prev_satellites = None
        self._prev_battery_level = None
        self._message_cooldowns.clear()
        
        print("[DroneModel] ✅ Cleanup complete")
