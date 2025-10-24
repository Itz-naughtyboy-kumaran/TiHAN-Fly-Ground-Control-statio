# main_window_integration.py
# This shows how to CORRECTLY integrate PortManager with QML

from PyQt5.QtCore import QUrl, QObject, pyqtSlot, pyqtSignal
from PyQt5.QtQml import QQmlApplicationEngine, qmlRegisterType
from PyQt5.QtWidgets import QApplication
import sys

# Import your modules
from port_manager import PortManager  # Your existing port manager
from firmware_flasher import FirmwareFlasher  # Your existing firmware flasher


class TinariWindow(QObject):
    """
    Main window bridge between Python and QML
    This is the CRITICAL connection point
    """
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.engine = None
        self.root_window = None
        
        # Create backend objects
        self.port_manager = PortManager()
        self.firmware_flasher = FirmwareFlasher()
        
        print("[TinariWindow] ✅ Initialized")
        print("[TinariWindow]   Port Manager:", self.port_manager)
        print("[TinariWindow]   Firmware Flasher:", self.firmware_flasher)
    
    def setup_qml_engine(self, qml_file_path):
        """
        Setup QML engine and expose Python objects to QML
        """
        self.engine = QQmlApplicationEngine()
        
        # CRITICAL: Expose Python objects to QML BEFORE loading QML file
        print("[TinariWindow] 📌 Exposing Python objects to QML context...")
        
        root_context = self.engine.rootContext()
        
        # Method 1: Set context properties (RECOMMENDED)
        root_context.setContextProperty("portManager", self.port_manager)
        root_context.setContextProperty("firmwareFlasher", self.firmware_flasher)
        root_context.setContextProperty("tinariWindow", self)
        
        print("[TinariWindow]   ✓ Set portManager context property")
        print("[TinariWindow]   ✓ Set firmwareFlasher context property")
        print("[TinariWindow]   ✓ Set tinariWindow context property")
        
        # Load QML file
        print(f"[TinariWindow] 📂 Loading QML file: {qml_file_path}")
        self.engine.load(QUrl.fromLocalFile(qml_file_path))
        
        if not self.engine.rootObjects():
            print("[TinariWindow] ❌ ERROR: Failed to load QML!")
            return False
        
        # Get root window
        self.root_window = self.engine.rootObjects()[0]
        print("[TinariWindow] ✅ QML loaded successfully")
        
        # Connect signals
        self._connect_signals()
        
        return True
    
    def _connect_signals(self):
        """Connect Python signals to QML"""
        print("[TinariWindow] 🔗 Connecting signals...")
        
        # Port manager signals
        self.port_manager.portsChanged.connect(self._on_ports_changed)
        self.port_manager.deviceDetected.connect(self._on_device_detected)
        
        print("[TinariWindow]   ✓ Connected port manager signals")
    
    def _on_ports_changed(self):
        """Handle ports changed signal"""
        print("[TinariWindow] 📡 Ports changed - notifying QML")
    
    def _on_device_detected(self, port_name, device_info):
        """Handle device detected signal"""
        print(f"[TinariWindow] 🎉 Device detected: {port_name}")
    
    @pyqtSlot()
    def test_connection(self):
        """Test method callable from QML"""
        print("[TinariWindow] ✅ test_connection() called from QML!")
        return "Connection OK"


def main():
    """
    Main application entry point
    """
    print("\n" + "="*70)
    print("🚀 STARTING TI-NARI FIRMWARE INSTALLATION")
    print("="*70 + "\n")
    
    app = QApplication(sys.argv)
    
    # Create window
    tinari = TinariWindow()
    
    # Setup QML (use your actual QML file path)
    qml_path = "firmware_installation_window.qml"  # CHANGE THIS to your actual path
    
    if not tinari.setup_qml_engine(qml_path):
        print("❌ Failed to initialize QML engine")
        return -1
    
    print("\n" + "="*70)
    print("✅ APPLICATION READY")
    print("="*70 + "\n")
    
    # Run application
    return app.exec_()


# Alternative Method: Using QML Type Registration
# If you want to create objects directly in QML

def main_with_type_registration():
    """
    Alternative: Register types so QML can create instances
    """
    print("\n🚀 Starting with Type Registration\n")
    
    app = QApplication(sys.argv)
    
    # Register Python types with QML
    qmlRegisterType(PortManager, 'TinariModules', 1, 0, 'PortManager')
    qmlRegisterType(FirmwareFlasher, 'TinariModules', 1, 0, 'FirmwareFlasher')
    
    # Create engine
    engine = QQmlApplicationEngine()
    
    # Load QML
    engine.load(QUrl.fromLocalFile("firmware_installation_window.qml"))
    
    if not engine.rootObjects():
        return -1
    
    return app.exec_()


# ============================================================================
# HOW TO USE IN YOUR EXISTING APPLICATION
# ============================================================================

"""
OPTION 1: If you have an existing main.py

In your main.py, BEFORE loading QML:

    from port_manager import PortManager
    from firmware_flasher import FirmwareFlasher
    
    # Create instances
    port_manager = PortManager()
    firmware_flasher = FirmwareFlasher()
    
    # Get QML context BEFORE loading
    root_context = engine.rootContext()
    
    # Set properties
    root_context.setContextProperty("portManager", port_manager)
    root_context.setContextProperty("firmwareFlasher", firmware_flasher)
    
    # NOW load QML
    engine.load(QUrl.fromLocalFile("your_qml_file.qml"))


OPTION 2: If you're opening this as a sub-window

In your main window code that opens the firmware window:

    def open_firmware_window(self):
        # Create port manager
        self.port_manager = PortManager()
        self.firmware_flasher = FirmwareFlasher()
        
        # Create QML component
        component = QQmlComponent(self.engine, 
                                  QUrl.fromLocalFile("firmware_window.qml"))
        
        # Create object with context
        context = QQmlContext(self.engine.rootContext())
        context.setContextProperty("portManager", self.port_manager)
        context.setContextProperty("firmwareFlasher", self.firmware_flasher)
        
        # Create window
        window = component.create(context)


OPTION 3: Set properties on the QML object directly

After loading QML:

    root_object = engine.rootObjects()[0]
    
    # Set properties directly on QML object
    root_object.setProperty("portManager", port_manager)
    root_object.setProperty("firmwareFlasher", firmware_flasher)
"""


# ============================================================================
# DEBUGGING HELPER
# ============================================================================

class DebugPortManager(PortManager):
    """
    Enhanced PortManager with debug output
    """
    
    def __init__(self):
        super().__init__()
        print("[DebugPortManager] ✅ Created")
    
    @pyqtSlot(result='QVariantList')
    def getDetailedPorts(self):
        print("[DebugPortManager] 📞 getDetailedPorts() called from QML")
        result = super().getDetailedPorts()
        print(f"[DebugPortManager]   Returning {len(result)} ports")
        return result
    
    @pyqtSlot()
    def refreshPorts(self):
        print("[DebugPortManager] 📞 refreshPorts() called from QML")
        super().refreshPorts()
        print("[DebugPortManager]   ✓ Refresh complete")


# ============================================================================
# TEST SCRIPT
# ============================================================================

def test_qml_integration():
    """
    Test script to verify QML integration works
    """
    print("\n" + "="*70)
    print("🧪 TESTING QML INTEGRATION")
    print("="*70 + "\n")
    
    from PyQt5.QtQml import QQmlContext
    
    app = QApplication(sys.argv)
    
    # Create objects
    port_mgr = DebugPortManager()
    firmware_flash = FirmwareFlasher()
    
    # Test 1: Can we call methods?
    print("\n📋 Test 1: Calling Python methods directly")
    ports = port_mgr.getDetailedPorts()
    print(f"  ✓ Got {len(ports)} ports")
    
    # Test 2: Create minimal QML context
    print("\n📋 Test 2: Creating QML context")
    engine = QQmlApplicationEngine()
    context = engine.rootContext()
    
    print("  Setting context properties...")
    context.setContextProperty("portManager", port_mgr)
    context.setContextProperty("firmwareFlasher", firmware_flash)
    print("  ✓ Context properties set")
    
    # Test 3: Create simple QML to test
    print("\n📋 Test 3: Loading test QML")
    test_qml = '''
    import QtQuick 2.15
    import QtQuick.Window 2.15
    
    Window {
        visible: true
        width: 400
        height: 200
        title: "Integration Test"
        
        Component.onCompleted: {
            console.log("QML: Window loaded")
            console.log("QML: portManager =", portManager)
            console.log("QML: firmwareFlasher =", firmwareFlasher)
            
            if (portManager) {
                console.log("QML: ✅ portManager is accessible")
                console.log("QML: Calling refreshPorts()...")
                portManager.refreshPorts()
                
                console.log("QML: Calling getDetailedPorts()...")
                var ports = portManager.getDetailedPorts()
                console.log("QML: Got", ports.length, "ports")
            } else {
                console.log("QML: ❌ portManager is NULL!")
            }
        }
    }
    '''
    
    # Save and load test QML
    with open('/tmp/test_integration.qml', 'w') as f:
        f.write(test_qml)
    
    engine.load(QUrl.fromLocalFile('/tmp/test_integration.qml'))
    
    if not engine.rootObjects():
        print("  ❌ Failed to load test QML")
        return -1
    
    print("\n  ✅ Test QML loaded - check console output above")
    print("\n" + "="*70)
    print("✅ INTEGRATION TEST COMPLETE")
    print("="*70 + "\n")
    
    return app.exec_()


if __name__ == "__main__":
    # Run test
    test_qml_integration()
    
    # Or run normal application
    # main()