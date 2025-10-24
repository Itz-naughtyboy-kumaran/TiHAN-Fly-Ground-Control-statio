from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QTimer
from pymavlink import mavutil
from modules.mavlink_thread import MAVLinkThread
import copy
import time

class DroneModel(QObject):
    telemetryChanged = pyqtSignal()
    statusTextsChanged = pyqtSignal()
    droneConnectedChanged = pyqtSignal()
    secondConnectionChanged = pyqtSignal()
    # Add new signals for map integration
    positionUpdated = pyqtSignal(float, float, float, bool)  # lat, lon, alt, connected
    connectionStatusChanged = pyqtSignal(bool)  # connected status

    def __init__(self):
        super().__init__()
        self._telemetry = {
            'mode': "UNKNOWN", 'armed': False,
            'lat': None, 'lon': None, 'alt': 0, 'rel_alt': 0,
            'roll': None, 'pitch': None, 'yaw': None, 'heading': None,
            'groundspeed': 0.0, 'airspeed': 0.0, 'battery_remaining': 0.0, 'voltage_battery': 0.0
        }
        self._status_texts = []
        self._drone = None
        self._thread = None
        self._is_connected = False
        
        # Connection tracking for map integration
        self._current_connection_string = ""
        self._current_connection_id = ""
        self._last_position_update = 0
        self._position_update_interval = 0.5  # Update position every 500ms for map
        
        # Second connection variables
        self._second_drone = None
        self._second_thread = None
        self._is_second_connection_active = False
        self._second_connection_config = None
        
        # Timer to monitor second connection
        self._second_connection_timer = QTimer()
        self._second_connection_timer.timeout.connect(self._check_second_connection)
        
        # Timer for map position updates
        self._map_update_timer = QTimer()
        self._map_update_timer.timeout.connect(self._update_map_position)
        self._map_update_timer.start(500)  # Update map every 500ms
        
        print("[DroneModel] Initialized with dual connection support and map integration.")

    def setCalibrationModel(self, calibration_model):
        """Set a reference to the CalibrationModel for calling methods"""
        self._calibration_model = calibration_model

    @pyqtSlot()
    def triggerLevelCalibration(self):
        """Trigger level calibration from DroneModel"""
        if hasattr(self, '_calibration_model'):
            print("[DroneModel] Triggering level calibration...")
            self._calibration_model.startLevelCalibration()

    @pyqtSlot()
    def triggerAccelCalibration(self):
        """Trigger accelerometer calibration from DroneModel"""
        if hasattr(self, '_calibration_model'):
            print("[DroneModel] Triggering accelerometer calibration...")
            self._calibration_model.startAccelCalibration()

    @pyqtSlot(str, str, int, result=bool)
    def connectToDrone(self, drone_id, uri, baud):
     print(f"[DroneModel] Attempting to connect to drone {drone_id} at {uri} with baud {baud}...")
     try:
        if uri.startswith("udp") or uri.startswith("tcp"):
            self._drone = mavutil.mavlink_connection(uri)
        else:
            self._drone = mavutil.mavlink_connection(uri)
        
        # Wait for heartbeat with extended timeout for UDP
        print("[DroneModel] Waiting for heartbeat...")
        self._drone.wait_heartbeat(timeout=10)
        
        # CRITICAL: Explicitly set target system and component from heartbeat
        print(f"[DroneModel] Heartbeat received from system {self._drone.target_system}, component {self._drone.target_component}")
        
        # Force target if not set
        if self._drone.target_system == 0:
            self._drone.target_system = 1
            print("[DroneModel] WARNING: target_system was 0, forcing to 1")
        
        if self._drone.target_component == 0:
            self._drone.target_component = 1
            print("[DroneModel] WARNING: target_component was 0, forcing to 1")
        
        print(f"[DroneModel] Using target_system={self._drone.target_system}, target_component={self._drone.target_component}")
        
        # Store connection details
        self._current_connection_string = uri
        self._current_connection_id = drone_id
        self._is_connected = True
        
        self.droneConnectedChanged.emit()
        self.connectionStatusChanged.emit(True)
        
        # Start telemetry thread
        self._thread = MAVLinkThread(self._drone)
        self._thread.telemetryUpdated.connect(self.updateTelemetry)
        self._thread.statusTextChanged.connect(self.addStatusText)
        self._thread.start()
        
        # IMPORTANT: Request message rates AFTER thread starts
        QTimer.singleShot(1000, self._request_message_rates)
        
        print("[DroneModel] Connection established successfully")
        return True

     except Exception as e:
        print(f"[DroneModel ERROR] Connection failed: {e}")
        self._drone = None
        self._is_connected = False
        self.droneConnectedChanged.emit()
        self.connectionStatusChanged.emit(False)
        return False

    def _request_message_rates(self):
        """Request specific MAVLink message rates for better telemetry"""
        if not self._drone:
            return
            
        try:
            # Request GLOBAL_POSITION_INT at 10Hz (essential for map)
            self._drone.mav.command_long_send(
                self._drone.target_system, 
                self._drone.target_component, 
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL, 
                0,
                33,  # GLOBAL_POSITION_INT
                100000,  # 10Hz (100ms interval in microseconds)
                0, 0, 0, 0, 0
            )
            
            # Request ATTITUDE at 10Hz
            self._drone.mav.command_long_send(
                self._drone.target_system, 
                self._drone.target_component, 
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL, 
                0,
                30,  # ATTITUDE
                100000,  # 10Hz
                0, 0, 0, 0, 0
            )
            
            # Request VFR_HUD at 5Hz
            self._drone.mav.command_long_send(
                self._drone.target_system, 
                self._drone.target_component, 
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL, 
                0,
                74,  # VFR_HUD
                200000,  # 5Hz
                0, 0, 0, 0, 0
            )
            
            print("[DroneModel] Requested enhanced MAVLink message rates for map integration.")
            
        except Exception as e:
            print(f"[DroneModel] Error requesting message rates: {e}")

    def _update_map_position(self):
        """Update map with current drone position"""
        current_time = time.time()
        
        # Check if we should update (rate limiting)
        if current_time - self._last_position_update < self._position_update_interval:
            return
            
        self._last_position_update = current_time
        
        # Get current position data
        lat = self._telemetry.get('lat')
        lon = self._telemetry.get('lon')
        alt = self._telemetry.get('rel_alt', 0)
        
        # Validate coordinates
        if lat is not None and lon is not None:
            # Convert from degrees*1e7 to degrees if needed (ArduPilot format)
            if abs(lat) > 90:  # Likely in 1e7 format
                lat = lat / 1e7
            if abs(lon) > 180:  # Likely in 1e7 format
                lon = lon / 1e7
            
            # Update telemetry with corrected values
            if lat != self._telemetry.get('lat'):
                self._telemetry['lat'] = lat
            if lon != self._telemetry.get('lon'):
                self._telemetry['lon'] = lon
            
            # Emit position update for map
            self.positionUpdated.emit(lat, lon, alt, self._is_connected)
            
        else:
            # Still emit update to show connection status
            default_lat = 17.4875  # Hyderabad default
            default_lon = 78.3953
            self.positionUpdated.emit(default_lat, default_lon, 0, self._is_connected)

    @pyqtSlot()
    def activateSecondConnection(self):
        """Activate the second connection using the same parameters as primary"""
        if not self._is_connected or not self._second_connection_config:
            print("[DroneModel] Cannot activate second connection - primary not connected")
            return False
            
        if self._is_second_connection_active:
            print("[DroneModel] Second connection already active")
            return True
            
        try:
            config = self._second_connection_config
            print(f"[DroneModel] Activating second connection to {config['uri']}")
            
            self._second_drone = mavutil.mavlink_connection(config['uri'])
            self._second_drone.wait_heartbeat(timeout=5)
            
            print("[DroneModel] Second connection established - Heartbeat OK!")
            self._is_second_connection_active = True
            
            self._second_thread = MAVLinkThread(self._second_drone)
            self._second_thread.telemetryUpdated.connect(self._updateSecondTelemetry)
            self._second_thread.statusTextChanged.connect(self._addSecondStatusText)
            self._second_thread.start()
            
            self._second_connection_timer.start(5000)
            
            print("[DroneModel] Second MAVLinkThread started.")
            self.secondConnectionChanged.emit()
            return True
            
        except Exception as e:
            print(f"[DroneModel ERROR] Second connection failed: {e}")
            return False

    @pyqtSlot()
    def deactivateSecondConnection(self):
        """Deactivate the second connection"""
        print("[DroneModel] Deactivating second connection...")
        
        self._second_connection_timer.stop()
        
        if self._second_thread:
            self._second_thread.stop()
            self._second_thread = None
            
        if self._second_drone:
            self._second_drone.close()
            self._second_drone = None
            
        self._is_second_connection_active = False
        self.secondConnectionChanged.emit()
        print("[DroneModel] Second connection deactivated.")

    def _check_second_connection(self):
        """Monitor second connection health"""
        if not self._is_second_connection_active or not self._second_drone:
            return
            
        try:
            if not self._is_connected:
                print("[DroneModel] Primary disconnected - deactivating second connection")
                self.deactivateSecondConnection()
        except Exception as e:
            print(f"[DroneModel] Second connection check failed: {e}")
            self.deactivateSecondConnection()

    def _updateSecondTelemetry(self, data):
        """Handle telemetry from second connection"""
        print(f"[DroneModel] Second connection telemetry received: {len(data)} fields")

    def _addSecondStatusText(self, text):
        """Handle status text from second connection"""
        prefixed_text = f"[SECONDARY] {text}"
        self.addStatusText(prefixed_text)

    def updateTelemetry(self, data):
        """Update internal telemetry dictionary and emit signals if changes occurred"""
        updated_any_field = False
        position_changed = False
        
        for key, value in data.items():
            if self._telemetry.get(key) != value:
                self._telemetry[key] = value
                updated_any_field = True
                
                # Check if position-related data changed
                if key in ['lat', 'lon', 'alt', 'rel_alt']:
                    position_changed = True
        
        if updated_any_field:
            self.telemetryChanged.emit()
            
        # If position changed, update map immediately (don't wait for timer)
        if position_changed:
            self._update_map_position()

    @pyqtSlot(str)
    def addStatusText(self, text):
        self._status_texts.append(text)
        if len(self._status_texts) > 50:
            self._status_texts.pop(0)
        self.statusTextsChanged.emit()

    @pyqtSlot()
    def disconnectDrone(self):
        """Disconnect from drone"""
        if self._is_second_connection_active:
            self.deactivateSecondConnection()
        
        self.cleanup()
        self._is_connected = False
        self._current_connection_string = ""
        self._current_connection_id = ""
        
        # Emit disconnection signals
        self.droneConnectedChanged.emit()
        self.connectionStatusChanged.emit(False)
        
        # Update map with disconnected status
        self._update_map_position()

    # Properties for QML access
    @pyqtProperty('QVariant', notify=telemetryChanged)
    def telemetry(self):
        return self._telemetry

    @pyqtProperty('QVariantList', notify=statusTextsChanged)
    def statusTexts(self):
        return self._status_texts

    @pyqtProperty(bool, notify=droneConnectedChanged)
    def isConnected(self):
        return self._is_connected

    @pyqtProperty(bool, notify=secondConnectionChanged)
    def isSecondConnectionActive(self):
        return self._is_second_connection_active

    @pyqtProperty(str, notify=droneConnectedChanged)
    def current_connection_string(self):
        return self._current_connection_string

    @current_connection_string.setter
    def current_connection_string(self, value):
        self._current_connection_string = value

    @pyqtProperty(str, notify=droneConnectedChanged)
    def current_connection_id(self):
        return self._current_connection_id

    @current_connection_id.setter
    def current_connection_id(self, value):
        self._current_connection_id = value

    # Properties for accessing drone connections
    @property
    def drone_connection(self):
        return self._drone
    
    @property
    def second_drone_connection(self):
        return self._second_drone

    def cleanup(self):
        """Clean up DroneModel resources"""
        print("[DroneModel] Cleaning up DroneModel resources...")
        
        # Stop map update timer
        if self._map_update_timer:
            self._map_update_timer.stop()
        
        # Clean up second connection first
        if self._is_second_connection_active:
            self.deactivateSecondConnection()
        
        # Clean up primary connection
        if self._thread:
            self._thread.stop()
        if self._drone:
            self._drone.close()
            print("[DroneModel] Primary MAVLink connection closed.")
        
        self._second_connection_config = None