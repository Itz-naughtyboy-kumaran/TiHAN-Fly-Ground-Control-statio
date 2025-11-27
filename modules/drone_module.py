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
            'alt': 0, 
            'rel_alt': 0,
            'roll': None, 
            'pitch': None, 
            'yaw': None, 
            'heading': None,
            'groundspeed': 0.0, 
            'airspeed': 0.0, 
            'battery_remaining': 0.0, 
            'voltage_battery': 0.0
        }
        self._status_texts = []
        self._drone = None
        self._thread = None
        self._is_connected = False
        self._connection_monitor = QTimer()
        self._connection_monitor.timeout.connect(self._check_connection_health)
        
        print("[DroneModel] Initialized.")

    def setCalibrationModel(self, calibration_model):
        """Set a reference to the CalibrationModel for calling methods"""
        self._calibration_model = calibration_model
        print("[DroneModel] CalibrationModel reference set.")

    @pyqtSlot()
    def triggerLevelCalibration(self):
        """Trigger level calibration from DroneModel"""
        if hasattr(self, '_calibration_model'):
            print("[DroneModel] Triggering level calibration...")
            self._calibration_model.startLevelCalibration()
        else:
            print("[DroneModel] CalibrationModel not available.")

    @pyqtSlot()
    def triggerAccelCalibration(self):
        """Trigger accelerometer calibration from DroneModel"""
        if hasattr(self, '_calibration_model'):
            print("[DroneModel] Triggering accelerometer calibration...")
            self._calibration_model.startAccelCalibration()
        else:
            print("[DroneModel] CalibrationModel not available.")

    @pyqtSlot(str, str, int, result=bool)
    def connectToDrone(self, drone_id, uri, baud):
        """Connect to drone with improved error handling"""
        print(f"[DroneModel] Attempting to connect to drone {drone_id} at {uri} with baud {baud}...")
        
        # Clean up any existing connection first
        if self._is_connected:
            print("[DroneModel] Cleaning up existing connection before reconnecting...")
            self.cleanup()
            time.sleep(1)  # Brief delay to ensure port is released
        
        try:
            # Create connection
            print(f"[DroneModel] Opening MAVLink connection to {uri}...")
            self._drone = mavutil.mavlink_connection(uri, baud=baud)
            
            # Wait for heartbeat with timeout
            print("[DroneModel] Waiting for heartbeat...")
            self._drone.wait_heartbeat(timeout=10)
            
            print(f"[DroneModel] Connection established successfully!")
            print(f"[DroneModel] System ID: {self._drone.target_system}, Component ID: {self._drone.target_component}")
            
            self._is_connected = True
            self.droneConnectedChanged.emit()
            
            # Request message rates with delays to avoid overwhelming the connection
            print("[DroneModel] Requesting MAVLink message rates...")
            
            # GLOBAL_POSITION_INT (ID: 33) at 20Hz (50000 microseconds)
            self._drone.mav.command_long_send(
                self._drone.target_system,
                self._drone.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0,  # confirmation
                33,  # message ID
                50000,  # interval in microseconds (20Hz)
                0, 0, 0, 0, 0
            )
            time.sleep(0.1)
            
            # ATTITUDE (ID: 30) at 20Hz
            self._drone.mav.command_long_send(
                self._drone.target_system,
                self._drone.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0,
                30,
                50000,
                0, 0, 0, 0, 0
            )
            time.sleep(0.1)
            
            # VFR_HUD (ID: 74) at 10Hz (100000 microseconds)
            self._drone.mav.command_long_send(
                self._drone.target_system,
                self._drone.target_component,
                mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                0,
                74,
                100000,
                0, 0, 0, 0, 0
            )
            
            print("[DroneModel] Message rate requests sent.")
            
            # Start MAVLink reading thread
            self._thread = MAVLinkThread(self._drone)
            self._thread.telemetryUpdated.connect(self.updateTelemetry)
            self._thread.statusTextChanged.connect(self.addStatusText)
            self._thread.start()
            print("[DroneModel] MAVLinkThread started successfully.")
            
            # Start connection health monitor
            self._connection_monitor.start(5000)  # Check every 5 seconds
            
            return True

        except Exception as e:
            print(f"[DroneModel ERROR] Connection failed: {e}")
            import traceback
            traceback.print_exc()
            
            # Clean up failed connection
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
        """Monitor connection health"""
        if not self._is_connected or not self._drone:
            self._connection_monitor.stop()
            return
        
        try:
            # Check if we're still receiving heartbeats
            # The MAVLink thread should be updating telemetry
            # If telemetry stops updating, we might have a connection issue
            pass  # Basic check - can be enhanced
        except Exception as e:
            print(f"[DroneModel] Connection health check failed: {e}")
            self.addStatusText(f"Connection issue detected: {e}")

    def updateTelemetry(self, data):
        """Update internal telemetry dictionary and emit signal if changes occurred"""
        try:
            updated_any_field = False
            for key, value in data.items():
                if self._telemetry.get(key) != value:
                    self._telemetry[key] = value
                    updated_any_field = True
                    # Debug print for position updates
                    if key in ['lat', 'lon', 'alt']:
                        print(f"[DroneModel] Updated {key}: {value}")
            
            if updated_any_field:
                self.telemetryChanged.emit()
        except Exception as e:
            print(f"[DroneModel ERROR] Error updating telemetry: {e}")

    @pyqtSlot(str)
    def addStatusText(self, text):
        """Add status text to log"""
        try:
            self._status_texts.append(text)
            if len(self._status_texts) > 50:  # Keep log size manageable
                self._status_texts.pop(0)
            self.statusTextsChanged.emit()
        except Exception as e:
            print(f"[DroneModel ERROR] Error adding status text: {e}")

    @pyqtSlot()
    def disconnectDrone(self):
        """Disconnect from drone"""
        print("[DroneModel] Disconnecting drone...")
        self.cleanup()
        self._is_connected = False
        self.droneConnectedChanged.emit()
        print("[DroneModel] Drone disconnected.")

    @pyqtProperty('QVariant', notify=telemetryChanged)
    def telemetry(self):
        """Get current telemetry data - return original dict for QML binding"""
        return self._telemetry  # Return original, not copy, for QML binding to work

    @pyqtProperty('QVariantList', notify=statusTextsChanged)
    def statusTexts(self):
        """Get status text log"""
        return self._status_texts  # Return original for QML binding

    @pyqtProperty(bool, notify=droneConnectedChanged)
    def isConnected(self):
        """Check if drone is connected"""
        return self._is_connected

    @property
    def drone_connection(self):
        """Property to allow DroneCommander to access the mavutil.mavlink_connection object"""
        return self._drone

    def cleanup(self):
        """Clean up all resources"""
        print("[DroneModel] Cleaning up DroneModel resources...")
        
        # Stop connection monitor
        if self._connection_monitor.isActive():
            self._connection_monitor.stop()
        
        # Stop MAVLink thread
        if self._thread:
            print("[DroneModel] Stopping MAVLink thread...")
            self._thread.stop()
            self._thread.wait(2000)  # Wait up to 2 seconds for thread to stop
            self._thread = None
            print("[DroneModel] MAVLink thread stopped.")
        
        # Close MAVLink connection
        if self._drone:
            try:
                print("[DroneModel] Closing MAVLink connection...")
                self._drone.close()
                print("[DroneModel] MAVLink connection closed.")
            except Exception as e:
                print(f"[DroneModel] Error closing connection: {e}")
            finally:
                self._drone = None
        
        print("[DroneModel] Cleanup complete.")
