#!/usr/bin/env python3
"""
TiHAN Drone System - Main Application with Splash Screen
Version: 2.1.0
Features: Splash Screen First, then Main Application Load
"""

import os
import sys
import signal
import atexit
from pathlib import Path

# Force add current directory to Python path
current_dir = Path(__file__).parent.absolute()
if str(current_dir) not in sys.path:
    sys.path.insert(0, str(current_dir))
print(f"📂 Added to sys.path: {current_dir}")

from PyQt5 import QtCore
from PyQt5.QtCore import (
    QUrl, QTranslator, QCoreApplication, QTimer, QObject, pyqtSignal, pyqtSlot
)
from PyQt5.QtQml import QQmlApplicationEngine, qmlRegisterType
# Try to import QtWebEngine - make it optional
try:
    from PyQt5.QtWebEngine import QtWebEngine
    QTWEBENGINE_AVAILABLE = True
    # Initialize WebEngine before creating QApplication
    QtWebEngine.initialize()
except ImportError as e:
    QTWEBENGINE_AVAILABLE = False
    print(f"⚠️ QtWebEngine not available: {e}")
    print("   Web features will be disabled")
from PyQt5.QtWidgets import QApplication, QMessageBox

# Initialize WebEngine before creating QApplication

# Set environment variables for stability
os.environ["QT_QUICK_BACKEND"] = "software"
os.environ["QT_OPENGL"] = "software"
os.environ["QT_LOGGING_RULES"] = "qt.qml.connections.debug=false"
os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

# ============================================================
# IMPORT MODULES WITH ERROR HANDLING
# ============================================================

# Try to import Qt Location and Positioning
try:
    from PyQt5 import QtLocation, QtPositioning
    from PyQt5.QtLocation import QGeoServiceProvider, QGeoMapType
    from PyQt5.QtPositioning import QGeoCoordinate, QGeoAddress
    QT_LOCATION_AVAILABLE = True
    print("✅ Qt Location and Positioning modules available")
except ImportError as e:
    QT_LOCATION_AVAILABLE = False
    print(f"⚠️ Qt Location/Positioning not available: {e}")

# Import core modules
try:
    from port_scanner_backend import PortScannerBackend
    from modules.port_detector import PortDetectorBackend
    from modules.port_manager import PortManager
    from modules.drone_module import DroneModel
    from modules.drone_commander import DroneCommander
    from modules.drone_calibration import CalibrationModel
    from modules.compass_calibration import MissionPlannerCompassCalibration as CompassCalibrationModel
    from modules.radio_calibration import RadioCalibrationModel
    from modules.esc_calibration import ESCCalibrationModel
    from message_logger import MessageLogger
    from firmware_flasher_qml import FirmwareFlasher
    

    print("✅ All core modules imported successfully")
except ImportError as e:
    print(f"❌ Critical error importing modules: {e}")
    sys.exit(1)

# ============================================================
# GLOBAL APPLICATION STATE
# ============================================================

app_instance = None
app_manager = None
main_engine = None  # Store main engine globally

# ============================================================
# APPLICATION MANAGER CLASS
# ============================================================

class ApplicationManager(QObject):
    """Centralized application manager for proper cleanup and lifecycle management"""
    
    def __init__(self):
        super().__init__()
        self.cleanup_completed = False
        self.engines = []
        self.models = {}
        
    def register_engine(self, engine):
        """Register QML engines for cleanup"""
        self.engines.append(engine)
        print(f"  📝 Registered engine: {type(engine).__name__}")
        
    def register_model(self, name, model):
        """Register models for cleanup"""
        if model is not None:
            self.models[name] = model
            print(f"  📝 Registered model: {name}")
        
    def cleanup_all(self):
        """Comprehensive cleanup of all resources"""
        if self.cleanup_completed:
            return
            
        print("\n" + "="*80)
        print("🧹 STARTING COMPREHENSIVE CLEANUP")
        print("="*80)
        
        # 1. Stop firmware flasher first
        self._cleanup_component('firmware_flasher',
            lambda m: (m.cancel_flashing() if hasattr(m, 'cancel_flashing') else None,
                       m.cleanup() if hasattr(m, 'cleanup') else None),
            "Firmware Flasher")
        
        # 2. Stop message logger capture
        self._cleanup_component('message_logger', 
            lambda m: m.stop_capture() if hasattr(m, 'stop_capture') else None,
            "Message Logger")
        
        # 3. Stop directional pad controller
        self._cleanup_component('directional_pad_controller',
            lambda m: m.stopMovement() if hasattr(m, 'stopMovement') else None,
            "Directional Pad Controller")
        
        # 4. Stop all calibrations
        self._stop_all_calibrations()
        
        # 5. Cleanup command executor
        self._cleanup_component('command_executor',
            lambda m: m.cleanup() if hasattr(m, 'cleanup') else None,
            "Command Executor")
        
        # 6. Cleanup port detector
        self._cleanup_component('port_detector',
            lambda m: m.cleanup() if hasattr(m, 'cleanup') else None,
            "Port Detector")
        
        # 7. Cleanup all registered models
        self._cleanup_all_models()
        
        # 8. Clear QML engines
        self._cleanup_engines()
        
        self.cleanup_completed = True
        print("="*80)
        print("✅ CLEANUP COMPLETED SUCCESSFULLY")
        print("="*80 + "\n")
    
    def _cleanup_component(self, name, cleanup_func, display_name):
        """Helper to cleanup individual component"""
        try:
            if name in self.models:
                print(f"  🔧 Cleaning up {display_name}...")
                cleanup_func(self.models[name])
                print(f"    ✅ {display_name} cleaned up")
        except Exception as e:
            print(f"    ⚠️ Error during {display_name} cleanup: {e}")
    
    def _stop_all_calibrations(self):
        """Stop all active calibrations"""
        print("  🔧 Stopping calibrations...")
        
        calibration_configs = [
            ('calibration_model', ['isCalibrating', 'stopLevelCalibration', 'stopAccelCalibration'], 'Accel/Level'),
            ('compass_calibration_model', ['calibrationStarted', 'stopCalibration'], 'Compass'),
            ('radio_calibration_model', ['calibrationActive', 'stopCalibration'], 'Radio'),
            ('esc_calibration_model', ['isCalibrating', 'resetCalibrationStatus'], 'ESC'),
        ]
        
        for model_name, methods, display_name in calibration_configs:
            try:
                if model_name in self.models:
                    model = self.models[model_name]
                    check_attr, *stop_methods = methods
                    
                    if hasattr(model, check_attr):
                        is_active = getattr(model, check_attr)
                        if callable(is_active):
                            is_active = is_active()
                        
                        if is_active:
                            print(f"    ⚙️ Stopping {display_name} calibration...")
                            for method in stop_methods:
                                if hasattr(model, method):
                                    getattr(model, method)()
            except Exception as e:
                print(f"    ⚠️ Error stopping {display_name} calibration: {e}")
    
    def _cleanup_all_models(self):
        """Cleanup all registered models"""
        print("  🔧 Cleaning up models...")
        for name, model in list(self.models.items()):
            try:
                if hasattr(model, 'cleanup'):
                    print(f"    ⚙️ Cleaning up {name}...")
                    model.cleanup()
                elif hasattr(model, 'deleteLater'):
                    model.deleteLater()
            except Exception as e:
                print(f"    ⚠️ Error cleaning up {name}: {e}")
        
        self.models.clear()
    
    def _cleanup_engines(self):
        """Cleanup QML engines"""
        print("  🔧 Cleaning up QML engines...")
        for engine in self.engines:
            try:
                if engine and hasattr(engine, 'deleteLater'):
                    engine.deleteLater()
            except Exception as e:
                print(f"    ⚠️ Error cleaning up engine: {e}")
        
        self.engines.clear()

# ============================================================
# SPLASH SCREEN MANAGER
# ============================================================

class SplashScreenManager(QObject):
    """Manages splash screen lifecycle and main window loading"""
    
    splashCompleted = pyqtSignal()
    
    def __init__(self, qml_base_path, app_mgr):
        super().__init__()
        self.qml_base_path = qml_base_path
        self.app_mgr = app_mgr
        self.splash_engine = None
        self.splash_window = None
        
    def show_splash(self):
        """Show splash screen"""
        print("\n" + "="*80)
        print("🎬 LOADING SPLASH SCREEN")
        print("="*80)
        
        try:
            # Create splash engine
            self.splash_engine = QQmlApplicationEngine()
            self.app_mgr.register_engine(self.splash_engine)
            
            # Load splash QML
            splash_qml = self.qml_base_path / "SplashScreen.qml"
            
            if not splash_qml.exists():
                print(f"⚠️ Splash screen file not found: {splash_qml}")
                print("   Proceeding to main window...")
                self.splashCompleted.emit()
                return
            
            print(f"📄 Loading splash screen: {splash_qml}")
            self.splash_engine.load(QUrl.fromLocalFile(str(splash_qml)))
            
            if not self.splash_engine.rootObjects():
                print("⚠️ Failed to load splash screen")
                print("   Proceeding to main window...")
                self.splashCompleted.emit()
                return
            
            # Get splash window object
            self.splash_window = self.splash_engine.rootObjects()[0]
            print("✅ Splash screen loaded successfully")
            
            # Monitor splash completion
            self._connect_splash_signals()
            
        except Exception as e:
            print(f"❌ Error loading splash screen: {e}")
            print("   Proceeding to main window...")
            self.splashCompleted.emit()
    
    def _connect_splash_signals(self):
        """Connect to splash window signals"""
        try:
            # Check for splashComplete property changes
            splash_complete_prop = self.splash_window.property("splashComplete")
            
            # Create a timer to check splash completion
            self.check_timer = QTimer()
            self.check_timer.timeout.connect(self._check_splash_complete)
            self.check_timer.start(100)  # Check every 100ms
            
            print("🔗 Monitoring splash screen completion...")
            
        except Exception as e:
            print(f"⚠️ Error connecting splash signals: {e}")
            # If we can't monitor, just wait a fixed time
            QTimer.singleShot(7000, self._on_splash_complete)
    
    def _check_splash_complete(self):
        """Check if splash screen is complete"""
        try:
            if self.splash_window:
                splash_complete = self.splash_window.property("splashComplete")
                if splash_complete:
                    print("✅ Splash screen completed")
                    self.check_timer.stop()
                    self._on_splash_complete()
        except Exception as e:
            print(f"⚠️ Error checking splash completion: {e}")
            self.check_timer.stop()
            self._on_splash_complete()
    
    def _on_splash_complete(self):
        """Handle splash screen completion"""
        print("🚀 Transitioning to main application...")
        
        # Clean up splash resources
        try:
            if self.splash_window:
                self.splash_window.close()
                self.splash_window = None
            
            if self.splash_engine:
                # Don't delete immediately, let it clean up gracefully
                QTimer.singleShot(500, self._cleanup_splash_engine)
        except Exception as e:
            print(f"⚠️ Error closing splash: {e}")
        
        # Emit signal to load main window
        self.splashCompleted.emit()
    
    def _cleanup_splash_engine(self):
        """Cleanup splash engine after delay"""
        try:
            if self.splash_engine:
                self.splash_engine.deleteLater()
                self.splash_engine = None
        except Exception as e:
            print(f"⚠️ Error cleaning up splash engine: {e}")

# ============================================================
# WAYPOINTS SAVER/LOADER
# ============================================================

class WaypointsSaver(QObject):
    """Handle saving and loading waypoints files"""
    
    @pyqtSlot(str, str, result=bool)
    def save_file(self, path, data):
        """Save waypoints data to file"""
        try:
            with open(path, "w", encoding="utf-8") as f:
                f.write(data)
            print(f"✅ Waypoints saved: {path}")
            return True
        except Exception as e:
            print(f"❌ Error saving waypoints: {e}")
            return False

    @pyqtSlot(str, result=str)
    def load_file(self, file_path):
        """Load waypoints from file"""
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            print(f"✅ Waypoints loaded: {file_path}")
            return content
        except Exception as e:
            print(f"❌ Error loading waypoints: {e}")
            return ""

# ============================================================
# MAP COMMUNICATION BRIDGE
# ============================================================

class MapCommunicationBridge(QObject):
    """Bridge for communication between QML and Google Maps WebEngine"""
    
    mapClicked = pyqtSignal(float, float)
    markerClicked = pyqtSignal(int, float, float, float, float)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.markers = []
        self._destroyed = False
    
    @pyqtSlot(str)
    def processWebMessage(self, message):
        """Process messages from WebEngine"""
        if self._destroyed:
            return
            
        try:
            import json
            data = json.loads(message)
            
            if data.get('type') == 'mapClick':
                lat = data.get('lat', 0)
                lng = data.get('lng', 0)
                self.mapClicked.emit(lat, lng)
            
            elif data.get('type') == 'markerClick':
                index = data.get('index', -1)
                lat = data.get('lat', 0)
                lng = data.get('lng', 0)
                altitude = data.get('altitude', 10)
                speed = data.get('speed', 5)
                self.markerClicked.emit(index, lat, lng, altitude, speed)
                
        except Exception as e:
            if not self._destroyed:
                print(f"❌ Error processing web message: {e}")
    
    @pyqtSlot(float, float, float, float, result=int)
    def addMarker(self, lat, lng, altitude, speed):
        """Add a marker to the map"""
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
            print(f"❌ Error adding marker: {e}")
            return -1
    
    @pyqtSlot(int)
    def deleteMarker(self, index):
        """Delete a marker from the map"""
        if self._destroyed:
            return
            
        try:
            if 0 <= index < len(self.markers):
                self.markers.pop(index)
                # Re-index remaining markers
                for i, marker in enumerate(self.markers):
                    marker['index'] = i
        except Exception as e:
            print(f"❌ Error deleting marker: {e}")
    
    @pyqtSlot(result=str)
    def getMarkersJson(self):
        """Get all markers as JSON string"""
        if self._destroyed:
            return "[]"
            
        try:
            import json
            return json.dumps(self.markers)
        except Exception as e:
            print(f"❌ Error getting markers JSON: {e}")
            return "[]"
            
    def cleanup(self):
        """Clean up the bridge"""
        self._destroyed = True
        self.markers.clear()

# ============================================================
# SIGNAL HANDLERS
# ============================================================

def setup_signal_handlers(app):
    """Setup signal handlers for graceful shutdown"""
    def signal_handler(signum, frame):
        print(f"\n🛑 Received signal {signum}, initiating shutdown...")
        if app:
            QTimer.singleShot(0, app.quit)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    if hasattr(signal, 'SIGBREAK'):
        signal.signal(signal.SIGBREAK, signal_handler)

# ============================================================
# QT PATHS SETUP
# ============================================================

def setup_qt_paths():
    """Setup Qt paths for plugins and QML"""
    try:
        if getattr(sys, 'frozen', False):
            base_path = Path(sys._MEIPASS)
            qml_path = base_path / "App" / "qml"

            QCoreApplication.setLibraryPaths([])
            
            # Plugin directories
            plugin_dirs = [
                'platforms', 'position', 'geoservices', 'imageformats',
                'bearer', 'tls', 'iconengines', 'generic'
            ]
            
            for plugin_dir in plugin_dirs:
                full_path = base_path / plugin_dir
                if full_path.exists():
                    QCoreApplication.addLibraryPath(str(full_path))

            # QML import paths
            qml_dirs = [
                qml_path,
                base_path / 'qml',
                base_path / 'QtLocation',
                base_path / 'QtPositioning'
            ]
            
            existing_dirs = [str(d) for d in qml_dirs if d.exists()]
            if existing_dirs:
                os.environ['QML2_IMPORT_PATH'] = os.pathsep.join(existing_dirs)
                os.environ['QML_IMPORT_PATH'] = os.environ['QML2_IMPORT_PATH']
            
            os.environ['QT_PLUGIN_PATH'] = str(base_path)
            return qml_path
        else:
            return current_dir / "App" / "qml"
            
    except Exception as e:
        print(f"⚠️ Error setting up Qt paths: {e}")
        return current_dir / "App" / "qml"

# ============================================================
# WINDOW OPENERS
# ============================================================

def create_calibration_window_opener(qml_base_path, calibration_model, drone_model, drone_commander, app_mgr):
    """Create calibration window opener"""
    @pyqtSlot()
    def openCalibrationWindow():
        try:
            if not drone_model.isConnected:
                QMessageBox.warning(None, "Connection Required", 
                                   "Please connect to the drone before opening calibration.")
                return
            
            print("🔧 Opening calibration window...")
            calibration_engine = QQmlApplicationEngine()
            app_mgr.register_engine(calibration_engine)
            
            calibration_engine.rootContext().setContextProperty("calibrationModel", calibration_model)
            calibration_engine.rootContext().setContextProperty("droneModel", drone_model)
            calibration_engine.rootContext().setContextProperty("droneCommander", drone_commander)
            
            calibration_qml = qml_base_path / "AccelCalibration.qml"
            if calibration_qml.exists():
                calibration_engine.load(QUrl.fromLocalFile(str(calibration_qml)))
                if calibration_engine.rootObjects():
                    print("✅ Calibration window opened")
                else:
                    QMessageBox.critical(None, "Error", "Failed to load calibration window")
            else:
                QMessageBox.critical(None, "File Error", f"Calibration file not found:\n{calibration_qml}")
        except Exception as e:
            print(f"❌ Error opening calibration window: {e}")
            QMessageBox.critical(None, "Error", f"Failed to open calibration window:\n{str(e)}")
    
    return openCalibrationWindow


def create_tinari_window_opener(qml_base_path, firmware_flasher, port_detector, app_mgr):
    """Create Ti-NARI firmware flashing window opener"""
    @pyqtSlot()
    def openTinariWindow():
        try:
            print("⚡ Opening Ti-NARI Firmware Flasher...")
            tinari_engine = QQmlApplicationEngine()
            app_mgr.register_engine(tinari_engine)
            
            tinari_engine.rootContext().setContextProperty("firmwareFlasher", firmware_flasher)
            tinari_engine.rootContext().setContextProperty("portDetector", port_detector)
            
            tinari_qml = qml_base_path / "TinariWindow.qml"
            if tinari_qml.exists():
                tinari_engine.load(QUrl.fromLocalFile(str(tinari_qml)))
                if tinari_engine.rootObjects():
                    print("✅ Ti-NARI window opened")
                else:
                    QMessageBox.critical(None, "Error", "Failed to load Ti-NARI window")
            else:
                QMessageBox.critical(None, "File Error", f"Ti-NARI file not found:\n{tinari_qml}")
        except Exception as e:
            print(f"❌ Error opening Ti-NARI window: {e}")
            QMessageBox.critical(None, "Error", f"Failed to open Ti-NARI window:\n{str(e)}")
    
    return openTinariWindow

# ============================================================
# MAIN WINDOW LOADING
# ============================================================

def load_main_window(qml_base_path, app_mgr):
    """Load the main application window after splash"""
    global main_engine
    
    print("\n" + "="*80)
    print("🚁 LOADING MAIN APPLICATION")
    print("="*80 + "\n")
    
    try:
        # Initialize trial manager
        print("⏱️ Initializing trial manager...")
        try:
            trial_manager = TrialManager()
        except Exception as e:
            print(f"⚠️ Trial manager initialization failed: {e}")
            trial_manager = None
        
        # Setup translation
        print("🌐 Setting up translations...")
        translator = QTranslator()
        translation_path = qml_base_path.parent / "translations_ta.qm"
        if translation_path.exists() and translator.load(str(translation_path)):
            app_instance.installTranslator(translator)
            print("✅ Translation loaded")
        
        # Initialize main QML engine
        print("🎨 Initializing main QML engine...")
        main_engine = QQmlApplicationEngine()
        app_mgr.register_engine(main_engine)
        
        # Initialize Map Communication Bridge
        print("🌐 Initializing Map Communication Bridge...")
        map_bridge = MapCommunicationBridge()
        app_mgr.register_model('map_bridge', map_bridge)
        
        # Initialize backend models
        print("🔧 Initializing backend models...")
        
        # Message Logger
        print("  📨 Message Logger...")
        message_logger = MessageLogger()
        app_mgr.register_model('message_logger', message_logger)
        
        # Drone models
        drone_model = DroneModel()
        app_mgr.register_model('drone_model', drone_model)
        
        drone_commander = DroneCommander(drone_model)
        app_mgr.register_model('drone_commander', drone_commander)
        
        # Firmware Flasher
        firmware_flasher = FirmwareFlasher()
        app_mgr.register_model('firmware_flasher', firmware_flasher)
        
        # Directional Pad Controller
        print("  🎮 Directional Pad Controller...")
        try:
            directional_pad_controller = DirectionalPadController(drone_model)
            app_mgr.register_model('directional_pad_controller', directional_pad_controller)
            
            # Connect to message logger
            directional_pad_controller.statusChanged.connect(
                lambda msg, sev: message_logger.logMessage(msg, sev)
            )
            print("    ✅ Directional Pad Controller initialized")
        except Exception as e:
            print(f"    ❌ Error: {e}")
            directional_pad_controller = None
        
        # Port Manager
        port_manager = PortManager()
        app_mgr.register_model('port_manager', port_manager)
        
        # Command Executor
        # command_executor = CommandExecutor()
        # app_mgr.register_model('command_executor', command_executor)
        
        # Port Detector
        print("  🔌 Port Detector...")
        try:
            port_detector = PortDetectorBackend()
            app_mgr.register_model('port_detector', port_detector)
            print("    ✅ Port Detector initialized")
        except Exception as e:
            print(f"    ❌ Error: {e}")
            port_detector = None
        
        # Email Sender
        print("  📧 Email Sender...")
        try:
            email_sender = EmailSender()
            app_mgr.register_model('email_sender', email_sender)
            print("    ✅ Email Sender initialized")
        except Exception as e:
            print(f"    ❌ Error: {e}")
            email_sender = None
        
        # Calibration models
        calibration_model = CalibrationModel(drone_model._drone)
        app_mgr.register_model('calibration_model', calibration_model)
        drone_model.setCalibrationModel(calibration_model)
        
        compass_calibration_model = CompassCalibrationModel(drone_model)
        app_mgr.register_model('compass_calibration_model', compass_calibration_model)
        
        radio_calibration_model = RadioCalibrationModel(drone_model)
        app_mgr.register_model('radio_calibration_model', radio_calibration_model)
        
        esc_calibration_model = ESCCalibrationModel(drone_model)
        app_mgr.register_model('esc_calibration_model', esc_calibration_model)
      
        print("✅ All models initialized successfully\n")
        
        # Register QML types
        print("📋 Registering QML types...")
        try:
            qmlRegisterType(CalibrationModel, "TiHAN.Calibration", 1, 0, "CalibrationModel")
            qmlRegisterType(CompassCalibrationModel, "TiHAN.Compass", 1, 0, "CompassCalibrationModel")
            qmlRegisterType(RadioCalibrationModel, "TiHAN.Radio", 1, 0, "RadioCalibrationModel")
            qmlRegisterType(ESCCalibrationModel, "TiHAN.ESC", 1, 0, "ESCCalibrationModel")
            print("✅ QML types registered\n")
        except Exception as e:
            print(f"⚠️ QML type registration warning: {e}\n")
        
        # Setup signal connections
        print("🔗 Setting up signal connections...")
        
        # Map bridge handlers
        def handle_map_click(lat, lng):
            message_logger.logMessage(f"Map clicked: {lat:.6f}, {lng:.6f}", "info")
            
        def handle_marker_click(index, lat, lng, altitude, speed):
            message_logger.logMessage(f"Marker {index} clicked: {lat:.6f}, {lng:.6f}", "info")
            
        map_bridge.mapClicked.connect(handle_map_click)
        map_bridge.markerClicked.connect(handle_marker_click)
        
        # Drone connection handlers
        def on_drone_disconnected():
            message_logger.logMessage("⚠️ Drone disconnected - stopping operations", "warning")
            if directional_pad_controller:
                directional_pad_controller.stopMovement()
            # Stop all calibrations
            app_mgr._stop_all_calibrations()
        
        def on_drone_connected():
            if drone_model.isConnected:
                message_logger.logMessage("✅ Drone connected successfully", "success")
                
                # ✅ NOW UPDATE THE QML CONTEXT WITH THE REAL DRONECOMMANDER
                if drone_model._drone_commander:
                    print("📡 Updating droneCommander in QML context...")
                    main_engine.rootContext().setContextProperty("droneCommander", drone_model._drone_commander)
                    print("✅ droneCommander available to QML")
                
                if esc_calibration_model:
                    QTimer.singleShot(2000, esc_calibration_model.testBuzzer)
        
        drone_model.droneConnectedChanged.connect(
            lambda: on_drone_disconnected() if not drone_model.isConnected else on_drone_connected()
        )
        
        # Email sender connections
        if email_sender:
            email_sender.emailSent.connect(
                lambda success, msg: message_logger.logMessage(f"📧 {msg}", "success" if success else "error")
            )
        
        print("✅ Signal connections established\n")
        
        # Expose models to QML
        print("🔗 Exposing models to QML...")
        ctx = main_engine.rootContext()
        
        # Core models
        ctx.setContextProperty("droneModel", drone_model)
        ctx.setContextProperty("droneCommander", drone_commander)
        ctx.setContextProperty("portManager", port_manager)
        # ctx.setContextProperty("commandExecutor", command_executor)
        ctx.setContextProperty("messageLogger", message_logger)
        ctx.setContextProperty("firmwareFlasher", firmware_flasher)
        
        # Optional models
        ctx.setContextProperty("portDetector", port_detector)
        ctx.setContextProperty("emailSender", email_sender)
        ctx.setContextProperty("directionalPadController", directional_pad_controller)
        
        # Calibration models
        ctx.setContextProperty("calibrationModel", calibration_model)
        ctx.setContextProperty("compassCalibrationModel", compass_calibration_model)
        ctx.setContextProperty("radioCalibrationModel", radio_calibration_model)
        ctx.setContextProperty("escCalibrationModel", esc_calibration_model)
        
        # Utility objects
        ctx.setContextProperty("mapBridge", map_bridge)
        ctx.setContextProperty("waypointsSaver", WaypointsSaver())
        ctx.setContextProperty("googleMapsApiKey", "AIzaSyDnBjIddcNnhfndEEJHi8puawYx3cPspWI")
        
        # Window openers
        tinari_opener = create_tinari_window_opener(qml_base_path, firmware_flasher, port_detector, app_mgr)
        ctx.setContextProperty("tinariWindowOpener", tinari_opener)

        calibration_opener = create_calibration_window_opener(
            qml_base_path, calibration_model, drone_model, drone_commander, app_mgr
        )
        ctx.setContextProperty("calibrationWindowOpener", calibration_opener)
        
        print("✅ Models exposed to QML successfully\n")
        
        # Load main QML file
        qml_file = qml_base_path / "Main.qml"
        print(f"📄 Loading main QML file: {qml_file}")
        
        if not qml_file.exists():
            print(f"❌ Main QML file not found: {qml_file}")
            QMessageBox.critical(None, "File Error", f"Main QML file not found:\n{qml_file}")
            return False
        
        try:
            main_engine.load(QUrl.fromLocalFile(str(qml_file)))
            if not main_engine.rootObjects():
                print("❌ Failed to load main QML file")
                QMessageBox.critical(None, "QML Error", "Failed to load the main QML file")
                return False
            print("✅ Main QML file loaded successfully\n")
        except Exception as e:
            print(f"❌ Exception loading main QML: {e}")
            QMessageBox.critical(None, "QML Error", f"Exception loading main QML file:\n{str(e)}")
            return False
        
        # Start message logger capture
        print("📨 Starting message logger capture...")
        message_logger.start_capture()
        message_logger.logMessage("🚀 TiHAN Drone System initialized successfully", "success")
        
        # Log component status
        if email_sender:
            message_logger.logMessage("📧 Feedback system ready - multiple delivery methods active", "info")
        
        if directional_pad_controller:
            message_logger.logMessage("🎮 Directional Pad Controller ready for flight control", "info")
        
        # Setup trial manager
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
                print(f"⚠️ Trial manager setup warning: {e}")
        
        # Print system status
        print_system_status(directional_pad_controller, email_sender, firmware_flasher)
        
        return True
        
    except Exception as e:
        print(f"❌ Error loading main window: {e}")
        import traceback
        traceback.print_exc()
        QMessageBox.critical(None, "Error", f"Failed to load main application:\n{str(e)}")
        return False

# ============================================================
# MAIN APPLICATION
# ============================================================

def main():
    """Main application entry point"""
    global app_instance, app_manager
    
    try:
        print("\n" + "="*80)
        print("🚁 TiHAN DRONE SYSTEM - v2.1.0")
        print("="*80 + "\n")
        
        # Initialize application manager
        app_manager = ApplicationManager()
        
        # Setup Qt paths
        qml_base_path = setup_qt_paths()
        
        # Create application
        app_instance = QApplication(sys.argv)
        app_instance.setApplicationName("TihanFly")
        from PyQt5.QtCore import QTimer
        def keep_responsive():
         QApplication.processEvents()
    
        keepalive = QTimer()
        keepalive.timeout.connect(keep_responsive)
        keepalive.start(100)
        app_instance.setApplicationVersion("v2.1.0")
        app_instance.setOrganizationName("TiHAN")
        
        # Setup signal handlers
        setup_signal_handlers(app_instance)
        
        # Create splash screen manager
        splash_manager = SplashScreenManager(qml_base_path, app_manager)
        
        # Connect splash completion to main window loading
        def on_splash_completed():
            """Load main window after splash completes"""
            success = load_main_window(qml_base_path, app_manager)
            if not success:
                print("❌ Failed to load main window, exiting...")
                app_instance.quit()
        
        splash_manager.splashCompleted.connect(on_splash_completed)
        
        # Show splash screen first
        splash_manager.show_splash()
        
        # Setup cleanup
        def cleanup_application():
            print("\n🧹 Application cleanup initiated...")
            try:
                # Stop firmware flashing if in progress
                if 'firmware_flasher' in app_manager.models:
                    print("  🔧 Stopping firmware flasher...")
                    try:
                        fw_flasher = app_manager.models['firmware_flasher']
                        if hasattr(fw_flasher, 'cancel_flashing'):
                            fw_flasher.cancel_flashing()
                        if hasattr(fw_flasher, 'cleanup'):
                            fw_flasher.cleanup()
                    except Exception as e:
                        print(f"    ⚠️ Error cleaning firmware flasher: {e}")
                
                # Continue with normal cleanup
                app_manager.cleanup_all()
                
                # Force exit after timeout
                QTimer.singleShot(5000, lambda: os._exit(0))
            except Exception as e:
                print(f"❌ Error during cleanup: {e}")
                os._exit(1)
        
        app_instance.aboutToQuit.connect(cleanup_application)
        atexit.register(lambda: app_manager.cleanup_all() if not app_manager.cleanup_completed else None)
        
        # Run application
        exit_code = app_instance.exec_()
        print(f"\n👋 Application exited with code: {exit_code}")
        return exit_code
        
    except KeyboardInterrupt:
        print("\n👋 Application interrupted by user")
        return 0
        
    except Exception as e:
        print(f"\n❌ FATAL ERROR: {e}")
        import traceback
        traceback.print_exc()
        
        try:
            if app_instance is None:
                app_instance = QApplication(sys.argv)
            QMessageBox.critical(None, "Fatal Error", 
                f"An unexpected error occurred:\n\n{str(e)}\n\nCheck console for details.")
        except:
            pass
        
        return 1
        
    finally:
        try:
            if app_manager and not app_manager.cleanup_completed:
                app_manager.cleanup_all()
        except:
            pass

# ============================================================
# SYSTEM STATUS DISPLAY
# ============================================================

def print_system_status(directional_pad, email_sender, firmware_flasher=None):
    """Print comprehensive system status"""
    print("\n" + "="*80)
    print("🚁 TiHAN DRONE SYSTEM - READY")
    print("="*80)
    print("✅ System initialization completed successfully")
    print("\n🔧 Core Features:")
    print("    • Enhanced error handling and recovery")
    print("    • Comprehensive resource cleanup")
    print("    • Signal handler for proper shutdown")
    print("    • Memory leak prevention")
    print("    • QML engine lifecycle management")
    print("    • Model reference tracking")
    print("    • WebEngine stability improvements")
    print("    • Command executor integration")
    print("    • Ti-NARI Port Detector with real-time scanning")
    print("    • Message Logger with terminal capture")
    print("    • Splash screen with smooth transition")
    
    if firmware_flasher:
        print("\n⚡ Ti-NARI Firmware Flasher Features:")
        print("    • APM Planner 2-style firmware flashing")
        print("    • Automatic bootloader detection")
        print("    • Reboot-then-flash workflow")
        print("    • Support for .apj, .px4, .bin files")
        print("    • Password-protected drone selection")
        print("    • Multi-drone support (5 drone types)")
        print("    • Real-time progress tracking")
        print("    • Comprehensive error handling")
        print("    • Automatic port monitoring")
        print("    • Safe flash cancellation")
    
    if directional_pad:
        print("\n🎮 Directional Pad Controller Features:")
        print("    • Keyboard arrow key control (↑ ↓ ← →)")
        print("    • Center button for ARM & TAKEOFF")
        print("    • Automatic STOP on key release")
        print("    • Configurable takeoff altitude (default: 5m)")
        print("    • Emergency stop functionality")
        print("    • Real-time status feedback")
        print("    • Integrated with message logger")
    
    if email_sender:
        print("\n📧 Feedback System Features:")
        print("    • Multi-method email delivery (FormSubmit + SMTP)")
        print("    • No configuration required for basic operation")
        print("    • Automatic fallback to file backup")
        print("    • Background thread processing (non-blocking UI)")
        print("    • Integrated with message logger")
        print("    • Feedback saved to: feedback_submissions/")
    
    print("\n" + "="*80)
    print("🚀 System is ready for operation")
    print("="*80 + "\n")

# ============================================================
# APPLICATION ENTRY POINT
# ============================================================

if __name__ == "__main__":
    sys.exit(main())
