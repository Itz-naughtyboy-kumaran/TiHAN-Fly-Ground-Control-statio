# main_radio_calibration.py
import sys
import os
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQml import qmlRegisterType, QQmlApplicationEngine
from PyQt5.QtCore import QUrl, QObject, pyqtProperty, pyqtSignal
from radio_calibration import RadioCalibrationModel

# Mock DroneModel for demonstration (replace with your actual DroneModel)
class MockDroneModel(QObject):
    """Mock DroneModel for testing - replace with your actual DroneModel"""
    droneConnectedChanged = pyqtSignal()
    
    def __init__(self):
        super().__init__()
        self._is_connected = False
        self._drone_connection = None
        
    @pyqtProperty(bool, notify=droneConnectedChanged)
    def isConnected(self):
        return self._is_connected
    
    @pyqtProperty('QVariant')
    def drone_connection(self):
        return self._drone_connection
    
    def connect_drone(self, connection_string):
        """Simulate drone connection"""
        try:
            from pymavlink import mavutil
            self._drone_connection = mavutil.mavlink_connection(connection_string)
            self._is_connected = True
            self.droneConnectedChanged.emit()
            print(f"[MockDroneModel] Connected to {connection_string}")
            return True
        except Exception as e:
            print(f"[MockDroneModel] Connection failed: {e}")
            return False
    
    def disconnect_drone(self):
        """Simulate drone disconnection"""
        if self._drone_connection:
            self._drone_connection.close()
        self._drone_connection = None
        self._is_connected = False
        self.droneConnectedChanged.emit()
        print("[MockDroneModel] Disconnected from drone")

def main():
    """Main application entry point"""
    print("=== Enhanced Radio Calibration System ===")
    print("Mission Planner Compatible - Real-time Channel Visualization")
    print("=" * 50)
    
    # Create QApplication
    app = QApplication(sys.argv)
    app.setApplicationName("Radio Calibration System")
    app.setApplicationVersion("3.0")
    
    # Create QML engine
    engine = QQmlApplicationEngine()
    
    # Create DroneModel (replace with your actual DroneModel instance)
    drone_model = MockDroneModel()
    
    # For testing, auto-connect to a simulated connection
    # Replace this with your actual drone connection logic
    connection_string = "udp:127.0.0.1:14550"  # SITL default
    print(f"[Main] Attempting connection to {connection_string}...")
    
    # Try to connect (this would be handled by your DroneModel)
    connected = drone_model.connect_drone(connection_string)
    if connected:
        print("[Main] ✅ Connected to drone successfully")
    else:
        print("[Main] ❌ Connection failed - using offline mode")
    
    # Create RadioCalibrationModel with DroneModel integration
    radio_model = RadioCalibrationModel(drone_model=drone_model)
    
    # Register the model with QML
    engine.rootContext().setContextProperty("radioCalibrationModel", radio_model)
    engine.rootContext().setContextProperty("droneModel", drone_model)
    
    # Load QML file
    qml_file = os.path.join(os.path.dirname(__file__), "radio_calibration.qml")
    if not os.path.exists(qml_file):
        print(f"[Main] ❌ QML file not found: {qml_file}")
        print("[Main] Please ensure radio_calibration.qml is in the same directory")
        return 1
    
    engine.load(QUrl.fromLocalFile(qml_file))
    
    # Check if QML loaded successfully
    if not engine.rootObjects():
        print("[Main] ❌ Failed to load QML file")
        return 1
    
    print("[Main] ✅ QML interface loaded successfully")
    print("\n=== USAGE INSTRUCTIONS ===")
    print("1. Ensure your transmitter is ON and bound to receiver")
    print("2. Connect drone via your DroneModel")
    print("3. Click 'START CALIBRATION' button")
    print("4. Move ALL sticks and switches through FULL range")
    print("5. Center all controls when prompted")
    print("6. Calibration saves automatically to flight controller")
    print("\n=== FEATURES ===")
    print("✅ Real-time channel visualization at 25Hz")
    print("✅ Mission Planner compatible calibration process")
    print("✅ Automatic movement detection and validation")
    print("✅ Live progress tracking and feedback")
    print("✅ Parameter saving to flight controller")
    print("✅ Enhanced UI with animations and status indicators")
    print("=" * 50)
    
    # Run the application
    result = app.exec_()
    
    # Cleanup
    print("[Main] Shutting down...")
    radio_model.cleanup()
    drone_model.disconnect_drone()
    
    return result

if __name__ == "__main__":
    sys.exit(main())