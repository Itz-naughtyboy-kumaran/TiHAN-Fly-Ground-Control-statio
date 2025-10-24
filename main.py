import os
import sys
import signal
import atexit
from PyQt5 import QtCore
from PyQt5.QtCore import (
    QUrl, QTranslator, QCoreApplication, QTimer, QObject, pyqtSignal, pyqtSlot
)
from PyQt5.QtQml import QQmlApplicationEngine, qmlRegisterType
from PyQt5.QtWebEngine import QtWebEngine
from port_scanner_backend import PortScannerBackend
from PyQt5.QtWidgets import QApplication, QDialog, QMessageBox
from modules.command_executor import CommandExecutor
from modules.port_detector import PortDetectorBackend
from modules.email_sender import EmailSender

# Initialize WebEngine before creating QApplication
QtWebEngine.initialize()

# Set environment variables for stability
os.environ["QT_QUICK_BACKEND"] = "software"
os.environ["QT_OPENGL"] = "software"
os.environ["QT_LOGGING_RULES"] = "qt.qml.connections.debug=false"

# Try to import Qt Location and Positioning at module level
try:
    from PyQt5 import QtLocation, QtPositioning
    from PyQt5.QtLocation import QGeoServiceProvider, QGeoMapType
    from PyQt5.QtPositioning import QGeoCoordinate, QGeoAddress
    QT_LOCATION_AVAILABLE = True
    print("✅ Qt Location and Positioning modules imported successfully")
except ImportError as e:
    QT_LOCATION_AVAILABLE = False
    print(f"⚠️ Warning: Qt Location/Positioning import failed: {e}")

# ============================================================
# Waypoints Saver/Loader
# ============================================================
class WaypointsSaver(QtCore.QObject):
    @QtCore.pyqtSlot(str, str, result=bool)
    def save_file(self, path, data):
        """Save the data to the selected path"""
        try:
            with open(path, "w", encoding="utf-8") as f:
                f.write(data)
            print(f"✅ Saved: {path}")
            return True
        except Exception as e:
            print(f"❌ Error saving: {e}")
            return False

    @QtCore.pyqtSlot(str, result=str)
    def load_file(self, file_path):
        """Load waypoints file content"""
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                return f.read()
        except Exception as e:
            print(f"❌ Error loading waypoints: {e}")
            return ""

# Global references for cleanup
global_engines = []
global_models = {}
app_instance = None

class ApplicationManager(QObject):
    """Centralized application manager for proper cleanup"""
    
    def __init__(self):
        super().__init__()
        self.cleanup_completed = False
        self.engines = []
        self.models = {}
        
    def register_engine(self, engine):
        """Register QML engines for cleanup"""
        self.engines.append(engine)
        
    def register_model(self, name, model):
        """Register models for cleanup"""
        self.models[name] = model
        
    def cleanup_all(self):
        """Comprehensive cleanup of all resources"""
        if self.cleanup_completed:
            return
            
        print("🧹 Starting comprehensive cleanup...")
        
        # Stop message logger capture first
        try:
            if 'message_logger' in self.models and hasattr(self.models['message_logger'], 'stop_capture'):
                print("  - Stopping message logger...")
                self.models['message_logger'].stop_capture()
        except Exception as e:
            print(f"  ⚠️ Error during message logger cleanup: {e}")
        
        # Stop firmware flasher if active
        try:
            if 'firmware_flasher' in self.models and hasattr(self.models['firmware_flasher'], 'is_flashing'):
                if self.models['firmware_flasher'].is_flashing:
                    print("  - Stopping firmware flasher...")
                    self.models['firmware_flasher'].cancel_flash()
        except Exception as e:
            print(f"  ⚠️ Error during firmware flasher cleanup: {e}")
        
        # Cleanup email sender threads
        try:
            if 'email_sender' in self.models:
                print("  - Cleaning up email sender...")
                # Email sender threads are daemon threads, so they'll stop automatically
        except Exception as e:
            print(f"  ⚠️ Error during email sender cleanup: {e}")
        
        # Stop all calibrations first
        try:
            if 'calibration_model' in self.models and hasattr(self.models['calibration_model'], 'isCalibrating'):
                if self.models['calibration_model'].isCalibrating():
                    print("  - Stopping accel/level calibration...")
                    self.models['calibration_model'].stopLevelCalibration()
                    self.models['calibration_model'].stopAccelCalibration()
                    
            if 'compass_calibration_model' in self.models:
                if hasattr(self.models['compass_calibration_model'], 'calibrationStarted') and self.models['compass_calibration_model'].calibrationStarted:
                    print("  - Stopping compass calibration...")
                    self.models['compass_calibration_model'].stopCalibration()
                    
            if 'radio_calibration_model' in self.models:
                if hasattr(self.models['radio_calibration_model'], 'calibrationActive') and self.models['radio_calibration_model'].calibrationActive:
                    print("  - Stopping radio calibration...")
                    self.models['radio_calibration_model'].stopCalibration()
                    
            if 'esc_calibration_model' in self.models:
                if hasattr(self.models['esc_calibration_model'], 'isCalibrating') and self.models['esc_calibration_model'].isCalibrating:
                    print("  - Stopping ESC calibration...")
                    self.models['esc_calibration_model'].resetCalibrationStatus()
                    
            if 'servo_calibration_model' in self.models:
                if hasattr(self.models['servo_calibration_model'], 'calibrationActive') and self.models['servo_calibration_model'].calibrationActive:
                    print("  - Stopping servo calibration...")
                    self.models['servo_calibration_model'].stopCalibration()
                    
        except Exception as e:
            print(f"  ⚠️ Error during calibration cleanup: {e}")
        
        # Cleanup command executor
        try:
            if 'command_executor' in self.models and hasattr(self.models['command_executor'], 'cleanup'):
                print("  - Cleaning up command executor...")
                self.models['command_executor'].cleanup()
        except Exception as e:
            print(f"  ⚠️ Error during command executor cleanup: {e}")
        
        # Cleanup port detector
        try:
            if 'port_detector' in self.models and hasattr(self.models['port_detector'], 'cleanup'):
                print("  - Cleaning up port detector...")
                self.models['port_detector'].cleanup()
        except Exception as e:
            print(f"  ⚠️ Error during port detector cleanup: {e}")
        
        # Cleanup firmware flasher
        try:
            if 'firmware_flasher' in self.models and hasattr(self.models['firmware_flasher'], 'cleanup'):
                print("  - Cleaning up firmware flasher...")
                self.models['firmware_flasher'].cleanup()
        except Exception as e:
            print(f"  ⚠️ Error during firmware flasher cleanup: {e}")
        
        # Cleanup models
        try:
            for name, model in self.models.items():
                if hasattr(model, 'cleanup'):
                    print(f"  - Cleaning up {name}...")
                    model.cleanup()
                elif hasattr(model, 'deleteLater'):
                    model.deleteLater()
        except Exception as e:
            print(f"  ⚠️ Error during model cleanup: {e}")
            
        # Clear QML engines
        try:
            for engine in self.engines:
                if engine and hasattr(engine, 'deleteLater'):
                    print("  - Cleaning up QML engine...")
                    engine.deleteLater()
        except Exception as e:
            print(f"  ⚠️ Error during engine cleanup: {e}")
            
        self.engines.clear()
        self.models.clear()
        self.cleanup_completed = True
        print("✅ Cleanup completed successfully")

# Global application manager
app_manager = ApplicationManager()

# Enhanced try/except imports with better error handling
def safe_import_qt_modules():
    """Safely import Qt Location and Positioning modules"""
    return QT_LOCATION_AVAILABLE

# Import other modules with error handling
try:
    from modules.port_manager import PortManager
    from modules.trail_manager import TrialManager
    from modules.drone_module import DroneModel
    from modules.drone_commander import DroneCommander
    from modules.drone_calibration import CalibrationModel
    from modules.compass_calibration import MissionPlannerCompassCalibration as CompassCalibrationModel
    from modules.radio_calibration import RadioCalibrationModel
    from modules.esc_calibration import ESCCalibrationModel
    from modules.servo_calibration import ServoCalibrationModel
    from message_logger import MessageLogger
    print("✅ All drone modules imported successfully")
except ImportError as e:
    print(f"❌ Critical error importing modules: {e}")
    sys.exit(1)

class MapCommunicationBridge(QObject):
    """Enhanced bridge with better error handling"""
    
    mapClicked = pyqtSignal(float, float)
    markerClicked = pyqtSignal(int, float, float, float, float)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.markers = []
        self._destroyed = False
    
    @pyqtSlot(str)
    def processWebMessage(self, message):
        """Process messages from WebEngine with error handling"""
        if self._destroyed:
            return
            
        try:
            import json
            data = json.loads(message)
            
            if data.get('type') == 'mapClick':
                lat = data.get('lat', 0)
                lng = data.get('lng', 0)
                self.mapClicked.emit(lat, lng)
                print(f"Map clicked: {lat:.6f}, {lng:.6f}")
            
            elif data.get('type') == 'markerClick':
                index = data.get('index', -1)
                lat = data.get('lat', 0)
                lng = data.get('lng', 0)
                altitude = data.get('altitude', 10)
                speed = data.get('speed', 5)
                self.markerClicked.emit(index, lat, lng, altitude, speed)
                print(f"Marker {index} clicked at: {lat:.6f}, {lng:.6f}")
                
        except Exception as e:
            if not self._destroyed:
                print(f"Error processing web message: {e}")
    
    @pyqtSlot(float, float, float, float, result=int)
    def addMarker(self, lat, lng, altitude, speed):
        """Add a marker with bounds checking"""
        if self._destroyed:
            return -1
            
        try:
            marker_data = {
                'lat': lat,
                'lng': lng,
                'altitude': altitude,
                'speed': speed,
                'index': len(self.markers)
            }
            self.markers.append(marker_data)
            return len(self.markers) - 1
        except Exception as e:
            print(f"Error adding marker: {e}")
            return -1
    
    @pyqtSlot(int)
    def deleteMarker(self, index):
        """Delete a marker with bounds checking"""
        if self._destroyed:
            return
            
        try:
            if 0 <= index < len(self.markers):
                self.markers.pop(index)
                for i, marker in enumerate(self.markers):
                    marker['index'] = i
        except Exception as e:
            print(f"Error deleting marker: {e}")
    
    @pyqtSlot(result=str)
    def getMarkersJson(self):
        """Get all markers as JSON string with error handling"""
        if self._destroyed:
            return "[]"
            
        try:
            import json
            return json.dumps(self.markers)
        except Exception as e:
            print(f"Error getting markers JSON: {e}")
            return "[]"
            
    def cleanup(self):
        """Clean up the bridge"""
        print("  - Cleaning up MapCommunicationBridge...")
        self._destroyed = True
        self.markers.clear()

def force_load_qt_modules():
    """Enhanced Qt module loading with error recovery"""
    if not QT_LOCATION_AVAILABLE:
        print("⚠️ Qt Location modules not available at startup")
        return False
    
    try:
        # Test if we can actually use the imported classes
        if QT_LOCATION_AVAILABLE:
            # Just verify the classes are accessible
            provider_test = QGeoServiceProvider
            coord_test = QGeoCoordinate
            print("✅ Qt Location modules verified and accessible")
            return True
    except Exception as e:
        print(f"⚠️ Qt Location modules imported but not functional: {e}")
        return False
    
    return QT_LOCATION_AVAILABLE

def setup_qt_paths():
    """Enhanced Qt paths setup with error handling"""
    try:
        if getattr(sys, 'frozen', False):
            base_path = sys._MEIPASS
            qml_path = os.path.join(base_path, "App", "qml")

            QCoreApplication.setLibraryPaths([])
            plugin_dirs = [
                os.path.join(base_path, 'platforms'),
                os.path.join(base_path, 'position'),
                os.path.join(base_path, 'geoservices'),
                os.path.join(base_path, 'imageformats'),
                os.path.join(base_path, 'bearer'),
                os.path.join(base_path, 'tls'),
                os.path.join(base_path, 'iconengines'),
                os.path.join(base_path, 'generic'),
            ]
            
            for plugin_dir in plugin_dirs:
                if os.path.exists(plugin_dir):
                    QCoreApplication.addLibraryPath(plugin_dir)
                    print(f"Added plugin path: {plugin_dir}")

            qml_dirs = [
                qml_path,
                os.path.join(base_path, 'qml'),
                os.path.join(base_path, 'QtLocation'),
                os.path.join(base_path, 'QtPositioning')
            ]
            
            existing_dirs = [d for d in qml_dirs if os.path.exists(d)]
            if existing_dirs:
                os.environ['QML2_IMPORT_PATH'] = os.pathsep.join(existing_dirs)
                os.environ['QML_IMPORT_PATH'] = os.environ['QML2_IMPORT_PATH']
                print(f"Set QML import paths: {existing_dirs}")
            
            os.environ['QT_PLUGIN_PATH'] = base_path
            return qml_path
        else:
            current_dir = os.path.dirname(os.path.abspath(__file__))
            qml_path = os.path.join(current_dir, "App", "qml")
            return qml_path
            
    except Exception as e:
        print(f"Error setting up Qt paths: {e}")
        # Fallback to current directory
        return os.path.join(os.path.dirname(os.path.abspath(__file__)), "App", "qml")

def setup_signal_handlers():
    """Setup signal handlers for proper shutdown"""
    def signal_handler(signum, frame):
        print(f"\n🛑 Received signal {signum}, initiating shutdown...")
        if app_instance:
            QTimer.singleShot(0, app_instance.quit)
    
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Windows-specific signal handling
    if hasattr(signal, 'SIGBREAK'):
        signal.signal(signal.SIGBREAK, signal_handler)

def setup_google_maps_config():
    """Setup Google Maps configuration with validation"""
    try:
        google_maps_api_key = "AIzaSyDnBjIddcNnhfndEEJHi8puawYx3cPspWI"
        
        if google_maps_api_key == "AIzaSyDnBjIddcNnhfndEEJHi8puawYx3cPspWI":
            print("⚠️ WARNING: Using placeholder Google Maps API key")
            print("   Please get an API key from: https://developers.google.com/maps/documentation/javascript/get-api-key")
            return ""
        else:
            print("✅ Google Maps API key configured")
            return google_maps_api_key
    except Exception as e:
        print(f"Error setting up Google Maps config: {e}")
        return ""

def create_calibration_window_opener(qml_base_path, calibration_model, drone_model, drone_commander):
    """Create calibration window opener with proper error handling"""
    @pyqtSlot()
    def openCalibrationWindow():
        try:
            if not drone_model.isConnected:
                QMessageBox.warning(None, "Connection Required", 
                                   "Please connect to the drone before opening calibration.")
                return
            
            print("🔧 Opening calibration window...")
            calibration_engine = QQmlApplicationEngine()
            app_manager.register_engine(calibration_engine)
            
            calibration_engine.rootContext().setContextProperty("calibrationModel", calibration_model)
            calibration_engine.rootContext().setContextProperty("droneModel", drone_model)
            calibration_engine.rootContext().setContextProperty("droneCommander", drone_commander)
            
            calibration_qml = os.path.join(qml_base_path, "AccelCalibration.qml")
            if os.path.exists(calibration_qml):
                calibration_engine.load(QUrl.fromLocalFile(calibration_qml))
                if calibration_engine.rootObjects():
                    print("✅ Calibration window opened successfully")
                else:
                    print("❌ Failed to load calibration window")
                    QMessageBox.critical(None, "Error", "Failed to load calibration window")
            else:
                print(f"❌ Calibration QML file not found: {calibration_qml}")
                QMessageBox.critical(None, "File Error", f"Calibration file not found:\n{calibration_qml}")
        except Exception as e:
            print(f"Error opening calibration window: {e}")
            QMessageBox.critical(None, "Error", f"Failed to open calibration window:\n{str(e)}")
    
    return openCalibrationWindow

def main():
    global app_instance, global_engines, global_models
    
    try:
        # Setup signal handlers
        setup_signal_handlers()
        
        # Setup Qt paths BEFORE creating QApplication
        qml_base_path = setup_qt_paths()
        
        # Force Basic style for stability
        os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
        
        # Create application with error handling
        app_instance = QApplication(sys.argv)
        app_instance.setApplicationName("TihanFly")
        app_instance.setApplicationVersion("v1.0.0 - Enhanced with Feedback System")
        app_instance.setOrganizationName("TiHAN")
        
        # Setup Google Maps configuration
        google_api_key = setup_google_maps_config()
        
        # Force load Qt modules
        if not force_load_qt_modules():
            print("Warning: Qt Location modules may not be available")
        
        # Additional stability settings for WebEngine
        if getattr(sys, 'frozen', False):
            os.environ['QT_QUICK_CONTROLS_STYLE'] = 'Basic'
            os.environ['QT_OPENGL'] = 'desktop'
            plugin_path = os.path.join(sys._MEIPASS, 'plugins')
            if os.path.exists(plugin_path):
                os.environ['QT_PLUGIN_PATH'] = plugin_path
        
        # Enable WebEngine debugging only in development
        if not getattr(sys, 'frozen', False):
            os.environ['QTWEBENGINE_REMOTE_DEBUGGING'] = '9222'
        
        # Initialize trial manager with error handling
        try:
            print("⏱️ Initializing trial manager...")
            trial_manager = TrialManager()
        except Exception as e:
            print(f"Warning: Trial manager failed to initialize: {e}")
            trial_manager = None
        
        # Setup translation with error handling
        print("🌐 Setting up translations...")
        translator = QTranslator()
        try:
            translation_path = os.path.join(os.path.dirname(qml_base_path), "translations_ta.qm")
            if os.path.exists(translation_path) and translator.load(translation_path):
                app_instance.installTranslator(translator)
                print("✅ Translation loaded successfully")
            else:
                print("⚠️ Translation file not found, using default language")
        except Exception as e:
            print(f"Warning: Translation setup failed: {e}")
        
        # Initialize QML engine with error handling
        print("🎨 Initializing QML engine with WebEngine support...")
        engine = QQmlApplicationEngine()
        app_manager.register_engine(engine)
        
        # Initialize Map Communication Bridge
        print("🌐 Initializing Google Maps communication bridge...")
        map_bridge = MapCommunicationBridge()
        app_manager.register_model('map_bridge', map_bridge)
        
        # Initialize backend models with error handling
        print("🔧 Initializing enhanced backend models...")
        try:
            # Initialize Message Logger first
            print("📨 Initializing Message Logger...")
            message_logger = MessageLogger()
            app_manager.register_model('message_logger', message_logger)
            print("✅ Message Logger initialized")
            
            drone_model = DroneModel()
            app_manager.register_model('drone_model', drone_model)
            
            drone_commander = DroneCommander(drone_model)
            app_manager.register_model('drone_commander', drone_commander)
            
            port_manager = PortManager()
            app_manager.register_model('port_manager', port_manager)
            
            # Initialize CommandExecutor
            command_executor = CommandExecutor()
            app_manager.register_model('command_executor', command_executor)
            
            # Initialize Port Detector Backend
            print("🔌 Initializing Port Detector Backend...")
            try:
                port_detector = PortDetectorBackend()
                app_manager.register_model('port_detector', port_detector)
                print("✅ Port Detector initialized successfully")
            except Exception as e:
                print(f"❌ Error initializing Port Detector: {e}")
                port_detector = None
            
            # Initialize Firmware Flasher Backend
           
            
            # Initialize Email Sender with enhanced fallback support
            print("📧 Initializing Enhanced Email Sender...")
            try:
                email_sender = EmailSender()
                app_manager.register_model('email_sender', email_sender)
                print("✅ Email Sender initialized successfully")
                print("   • FormSubmit.co integration (no config needed)")
                print("   • Local SMTP fallback")
                print("   • Automatic file backup on failure")
            except Exception as e:
                print(f"❌ Error initializing Email Sender: {e}")
                email_sender = None

            calibration_model = CalibrationModel(drone_model)
            app_manager.register_model('calibration_model', calibration_model)
            drone_model.setCalibrationModel(calibration_model)
            
            compass_calibration_model = CompassCalibrationModel(drone_model)
            app_manager.register_model('compass_calibration_model', compass_calibration_model)
            
            radio_calibration_model = RadioCalibrationModel(drone_model)
            app_manager.register_model('radio_calibration_model', radio_calibration_model)
            
            esc_calibration_model = ESCCalibrationModel(drone_model)
            app_manager.register_model('esc_calibration_model', esc_calibration_model)
            
            servo_calibration_model = ServoCalibrationModel(drone_model)
            app_manager.register_model('servo_calibration_model', servo_calibration_model)
            
            print("✅ All models initialized successfully")
            
        except Exception as e:
            print(f"❌ Critical error initializing models: {e}")
            QMessageBox.critical(None, "Initialization Error", 
                               f"Failed to initialize drone models:\n{str(e)}")
            sys.exit(1)
        
        # Register QML types with error handling
        try:
            qmlRegisterType(CalibrationModel, "TiHAN.Calibration", 1, 0, "CalibrationModel")
            qmlRegisterType(CompassCalibrationModel, "TiHAN.Compass", 1, 0, "CompassCalibrationModel")
            qmlRegisterType(RadioCalibrationModel, "TiHAN.Radio", 1, 0, "RadioCalibrationModel")
            qmlRegisterType(ESCCalibrationModel, "TiHAN.ESC", 1, 0, "ESCCalibrationModel")
            qmlRegisterType(ServoCalibrationModel, "TiHAN.Servo", 1, 0, "ServoCalibrationModel")
            print("✅ QML types registered successfully")
        except Exception as e:
            print(f"Warning: QML type registration failed: {e}")
        
        # Setup signal connections with error handling
        try:
            def handle_map_click(lat, lng):
                print(f"Map clicked: {lat:.6f}, {lng:.6f}")
                message_logger.logMessage(f"Map clicked: {lat:.6f}, {lng:.6f}", "info")
                
            def handle_marker_click(index, lat, lng, altitude, speed):
                print(f"Marker {index} clicked: {lat:.6f}, {lng:.6f}")
                message_logger.logMessage(f"Marker {index} clicked: {lat:.6f}, {lng:.6f}", "info")
                
            map_bridge.mapClicked.connect(handle_map_click)
            map_bridge.markerClicked.connect(handle_marker_click)
            
            # Enhanced drone disconnection handler
            def on_drone_disconnected():
                try:
                    message_logger.logMessage("⚠️ Drone disconnected - stopping all calibrations", "warning")
                    
                    if calibration_model and calibration_model.isCalibrating():
                        print("⚠️ [SAFETY] Stopping calibration due to disconnection")
                        calibration_model.stopLevelCalibration()
                        calibration_model.stopAccelCalibration()
                    
                    if compass_calibration_model and hasattr(compass_calibration_model, 'calibrationStarted') and compass_calibration_model.calibrationStarted:
                        compass_calibration_model.stopCalibration()
                    
                    if radio_calibration_model and hasattr(radio_calibration_model, 'calibrationActive') and radio_calibration_model.calibrationActive:
                        radio_calibration_model.stopCalibration()
                    
                    if esc_calibration_model and hasattr(esc_calibration_model, 'isCalibrating') and esc_calibration_model.isCalibrating:
                        esc_calibration_model.resetCalibrationStatus()
                    
                    if servo_calibration_model and hasattr(servo_calibration_model, 'calibrationActive') and servo_calibration_model.calibrationActive:
                        servo_calibration_model.stopCalibration()
                except Exception as e:
                    print(f"Error in disconnection handler: {e}")
            
            def on_drone_connected():
                if drone_model.isConnected:
                    print("✅ Drone connected - testing hardware...")
                    message_logger.logMessage("✅ Drone connected successfully", "success")
                    if esc_calibration_model:
                        QTimer.singleShot(2000, esc_calibration_model.testBuzzer)
            
            # Connect signals with error handling
            drone_model.droneConnectedChanged.connect(
                lambda: on_drone_disconnected() if not drone_model.isConnected else on_drone_connected()
            )
            
            if hasattr(drone_model, 'secondConnectionChanged'):
                drone_model.secondConnectionChanged.connect(
                    lambda: message_logger.logMessage("✅ Second connection state changed", "info")
                )
            
            # Connect email sender signals to message logger
            if email_sender:
                def on_email_sent(success, message):
                    severity = "success" if success else "error"
                    message_logger.logMessage(f"📧 {message}", severity)
                    print(f"📧 Email feedback: {message}")
                
                email_sender.emailSent.connect(on_email_sent)
                print("✅ Email sender signals connected to message logger")
                
        except Exception as e:
            print(f"Warning: Signal connection setup failed: {e}")
        
        # Expose Python objects to QML with error handling
        print("🔗 Exposing Python models to QML...")
        try:
            # Helper function to log messages from anywhere
            def log_to_messages(message, severity="info"):
                """Helper function to log messages from anywhere in the code"""
                if message_logger:
                    message_logger.logMessage(message, severity)
            
            engine.rootContext().setContextProperty("droneModel", drone_model)
            engine.rootContext().setContextProperty("droneCommander", drone_commander)
            engine.rootContext().setContextProperty("portManager", port_manager)
            engine.rootContext().setContextProperty("commandExecutor", command_executor)
            
            # Expose Port Detector to QML
            if port_detector:
                engine.rootContext().setContextProperty("portDetector", port_detector)
                print("✅ Port Detector exposed to QML")
            
            # Expose Firmware Flasher to QML
           
            
            # Expose Email Sender to QML
            if email_sender:
                engine.rootContext().setContextProperty("emailSender", email_sender)
                print("✅ Email Sender exposed to QML")
            
            engine.rootContext().setContextProperty("calibrationModel", calibration_model)
            engine.rootContext().setContextProperty("compassCalibrationModel", compass_calibration_model)
            engine.rootContext().setContextProperty("radioCalibrationModel", radio_calibration_model)
            engine.rootContext().setContextProperty("escCalibrationModel", esc_calibration_model)
            engine.rootContext().setContextProperty("servoCalibrationModel", servo_calibration_model)
            engine.rootContext().setContextProperty("mapBridge", map_bridge)
            waypoints_saver = WaypointsSaver()
            engine.rootContext().setContextProperty("waypointsSaver", waypoints_saver)
            engine.rootContext().setContextProperty("googleMapsApiKey", google_api_key)
            
            # Expose Message Logger to QML
            engine.rootContext().setContextProperty("messageLogger", message_logger)
            engine.rootContext().setContextProperty("logToMessages", log_to_messages)
            print("✅ Message Logger exposed to QML")
            
            # Create window openers
            calibration_opener = create_calibration_window_opener(qml_base_path, calibration_model, drone_model, drone_commander)
            engine.rootContext().setContextProperty("calibrationWindowOpener", calibration_opener)
            
            print("✅ Python models exposed to QML successfully")
            
        except Exception as e:
            print(f"❌ Critical error exposing models to QML: {e}")
            QMessageBox.critical(None, "QML Error", 
                               f"Failed to expose models to QML:\n{str(e)}")
            sys.exit(1)
        
        # Load the main QML file with error handling
        qml_file = os.path.join(qml_base_path, "Main.qml")
        print(f"📄 Loading QML file: {qml_file}")
        
        if not os.path.exists(qml_file):
            print(f"❌ ERROR: QML file not found: {qml_file}")
            QMessageBox.critical(None, "File Error", f"QML file not found:\n{qml_file}")
            sys.exit(1)
        
        try:
            engine.load(QUrl.fromLocalFile(qml_file))
            if not engine.rootObjects():
                print("❌ ERROR: Failed to load QML file")
                QMessageBox.critical(None, "QML Error", "Failed to load the main QML file")
                sys.exit(1)
        except Exception as e:
            print(f"❌ ERROR: Exception loading QML file: {e}")
            QMessageBox.critical(None, "QML Error", f"Exception loading QML file:\n{str(e)}")
            sys.exit(1)
        
        # Start capturing terminal output to messages panel
        print("📨 Starting message logger capture...")
        QTimer.singleShot(1000, lambda: message_logger.start_capture())
        message_logger.logMessage("🚀 TiHAN Drone System initialized successfully", "success")
        
        # Log email sender status
        if email_sender:
            message_logger.logMessage("📧 Feedback system ready - multiple delivery methods active", "info")
        
        # Setup trial manager if available
        if trial_manager:
            try:
                def handle_trial_expired():
                    msg = QMessageBox()
                    msg.setIcon(QMessageBox.Information)
                    msg.setText("Trial period expired")
                    msg.setStandardButtons(QMessageBox.Ok)
                    msg.exec_()
                    app_instance.quit()
                
                trial_manager.trial_expired.connect(handle_trial_expired)
                trial_manager.start_trial()
            except Exception as e:
                print(f"Warning: Trial manager setup failed: {e}")
        
        # Setup comprehensive cleanup
        def cleanup_application():
            print("🧹 Application cleanup initiated...")
            try:
                app_manager.cleanup_all()
                
                # Force process termination after cleanup timeout
                QTimer.singleShot(5000, lambda: os._exit(0))
                
            except Exception as e:
                print(f"Error during cleanup: {e}")
                # Force exit if cleanup fails
                os._exit(1)
        
        # Connect cleanup to multiple signals for reliability
        app_instance.aboutToQuit.connect(cleanup_application)
        
        # Register cleanup with atexit as backup
        atexit.register(lambda: app_manager.cleanup_all() if not app_manager.cleanup_completed else None)
        
        # Print system status
        print("=" * 80)
        print("🚁 TiHAN Drone System - Enhanced with Feedback System")
        print("=" * 80)
        print("✅ System initialization completed successfully")
        print("🔧 Stability Features:")
        print("    • Enhanced error handling and recovery")
        print("    • Comprehensive resource cleanup")
        print("    • Signal handler for proper shutdown")
        print("    • Memory leak prevention")
        print("    • QML engine lifecycle management")
        print("    • Model reference tracking")
        print("    • WebEngine stability improvements")
        print("    • Fallback error handling")
        print("    • Command executor integration")
        print("    • Ti-NARI Port Detector with real-time scanning")
        print("    • Message Logger with terminal capture")
        print("    • Firmware Flasher with bootloader support")
        print("=" * 80)
        print("📧 Feedback System Features:")
        print("    • Multi-method email delivery (FormSubmit + SMTP)")
        print("    • No configuration required for basic operation")
        print("    • Automatic fallback to file backup")
        print("    • Background thread processing (non-blocking UI)")
        print("    • Integrated with message logger")
        print("    • Feedback saved to: feedback_submissions/")
        print("=" * 80)
        print("📱 Firmware Flasher Features:")
        print("    • ArduPilot firmware flashing (.apj files)")
        print("    • Cube Orange / Cube Orange+ support")
        print("    • Automatic bootloader entry via MAVLink")
        print("    • Progress tracking with detailed status")
        print("    • Flash memory erase and verification")
        print("    • Automatic device reboot after flash")
        print("    • Mission Planner-compatible workflow")
        print("=" * 80)
        
        # Run the application with proper exit handling
        exit_code = app_instance.exec_()
        print(f"Application exited with code: {exit_code}")
        return exit_code
        
    except KeyboardInterrupt:
        print("\n👋 Application interrupted by user")
        return 0
    except Exception as e:
        print(f"❌ FATAL ERROR in main(): {e}")
        import traceback
        traceback.print_exc()
        
        # Show error dialog if possible
        try:
            if app_instance is None:
                app_instance = QApplication(sys.argv)
            QMessageBox.critical(None, "Fatal Error", 
                f"An unexpected error occurred:\n\n{str(e)}\n\nCheck console for details.")
        except:
            pass  # Ignore if we can't show dialog
        
        return 1
    finally:
        # Final cleanup attempt
        try:
            if not app_manager.cleanup_completed:
                app_manager.cleanup_all()
        except:
            pass

if __name__ == "__main__":
    sys.exit(main())