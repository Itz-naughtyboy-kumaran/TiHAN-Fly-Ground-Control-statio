"""
Port Detector Backend for Ti-NARI
Detects available serial ports with detailed information
"""

from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QTimer
import serial.tools.list_ports
import platform
import sys


class PortInfo(QObject):
    """Class to hold individual port information"""
    
    def __init__(self, port_data, parent=None):
        super().__init__(parent)
        self._port_name = port_data.device
        self._description = port_data.description
        self._manufacturer = port_data.manufacturer if port_data.manufacturer else "Unknown"
        self._system_location = port_data.device
        self._vendor_id = port_data.vid if port_data.vid else 0
        self._product_id = port_data.pid if port_data.pid else 0
        self._serial_number = port_data.serial_number if port_data.serial_number else "N/A"
        
    @pyqtProperty(str, constant=True)
    def portName(self):
        return self._port_name
    
    @pyqtProperty(str, constant=True)
    def description(self):
        return self._description
    
    @pyqtProperty(str, constant=True)
    def manufacturer(self):
        return self._manufacturer
    
    @pyqtProperty(str, constant=True)
    def systemLocation(self):
        return self._system_location
    
    @pyqtProperty(int, constant=True)
    def vendorIdentifier(self):
        return self._vendor_id
    
    @pyqtProperty(int, constant=True)
    def productIdentifier(self):
        return self._product_id
    
    @pyqtProperty(str, constant=True)
    def serialNumber(self):
        return self._serial_number


class PortDetectorBackend(QObject):
    """
    Backend for detecting and managing serial ports
    Compatible with pymavlink and Ti-NARI system
    """
    
    # Signals
    portsChanged = pyqtSignal()
    portCountChanged = pyqtSignal(int)
    scanCompleted = pyqtSignal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._available_ports = []
        self._auto_refresh_enabled = False
        self._refresh_timer = QTimer(self)
        self._refresh_timer.timeout.connect(self.refreshPorts)
        
        print("✅ PortDetectorBackend initialized")
        
        # Initial scan
        self.refreshPorts()
    
    @pyqtProperty('QVariantList', notify=portsChanged)
    def availablePorts(self):
        """Returns list of available ports"""
        return self._available_ports
    
    @pyqtProperty(int, notify=portCountChanged)
    def portCount(self):
        """Returns number of available ports"""
        return len(self._available_ports)
    
    @pyqtSlot()
    def refreshPorts(self):
        """Scan for available serial ports"""
        try:
            print("🔍 Scanning for available serial ports...")
            
            # Clear old list - need to clear and rebuild to trigger QML update
            self._available_ports.clear()
            
            # Get all available ports
            ports = serial.tools.list_ports.comports()
            
            # Create PortInfo objects for each port
            port_list = []
            for port in ports:
                port_info = PortInfo(port, self)
                port_list.append(port_info)
                
                # Log port details
                print(f"  📍 Found: {port.device}")
                print(f"     Description: {port.description}")
                print(f"     Manufacturer: {port.manufacturer if port.manufacturer else 'Unknown'}")
                if port.vid and port.pid:
                    print(f"     VID:PID = 0x{port.vid:04X}:0x{port.pid:04X}")
            
            # Update the list
            self._available_ports = port_list
            
            new_count = len(self._available_ports)
            print(f"✅ Port scan completed: {new_count} port(s) found")
            
            # IMPORTANT: Emit signals to update QML
            self.portsChanged.emit()
            self.portCountChanged.emit(new_count)
            self.scanCompleted.emit()
            
            # Force QML to update by logging
            print(f"📊 Emitting portsChanged signal with {new_count} ports")
            
        except Exception as e:
            print(f"❌ Error scanning ports: {e}")
            import traceback
            traceback.print_exc()
    
    @pyqtSlot(str, result=bool)
    def isPortAvailable(self, port_name):
        """Check if a specific port is available"""
        for port in self._available_ports:
            if port.portName == port_name:
                return True
        return False
    
    @pyqtSlot(str, result='QVariant')
    def getPortInfo(self, port_name):
        """Get detailed information about a specific port"""
        for port in self._available_ports:
            if port.portName == port_name:
                return port
        return None
    
    @pyqtSlot(result='QVariantList')
    def getPortNames(self):
        """Get list of port names only"""
        return [port.portName for port in self._available_ports]
    
    @pyqtSlot(result='QVariantList')
    def getArduPilotPorts(self):
        """
        Get ports that are likely ArduPilot/Pixhawk devices
        Common VID:PID combinations for flight controllers
        """
        ardupilot_ports = []
        
        # Common ArduPilot/Pixhawk VID:PID combinations
        known_devices = [
            (0x26AC, None),  # 3D Robotics (any PID)
            (0x2DAE, None),  # Hex/ProfiCNC (any PID)
            (0x0483, 0x5740), # STM32 in DFU mode
            (0x0483, 0xDF11), # STM32 bootloader
            (0x16D0, None),  # MindPX (any PID)
        ]
        
        for port in self._available_ports:
            vid = port.vendorIdentifier
            pid = port.productIdentifier
            
            # Check against known devices
            for known_vid, known_pid in known_devices:
                if vid == known_vid:
                    if known_pid is None or pid == known_pid:
                        ardupilot_ports.append(port)
                        break
            
            # Also check description for common keywords
            desc_lower = port.description.lower()
            if any(keyword in desc_lower for keyword in ['pixhawk', 'ardupilot', 'px4', 'cube']):
                if port not in ardupilot_ports:
                    ardupilot_ports.append(port)
        
        return ardupilot_ports
    
    @pyqtSlot(bool)
    def setAutoRefresh(self, enabled):
        """Enable/disable automatic port refresh"""
        self._auto_refresh_enabled = enabled
        
        if enabled:
            # Refresh every 3 seconds
            self._refresh_timer.start(3000)
            print("✅ Auto-refresh enabled (3s interval)")
        else:
            self._refresh_timer.stop()
            print("⏸️ Auto-refresh disabled")
    
    @pyqtProperty(bool)
    def autoRefreshEnabled(self):
        return self._auto_refresh_enabled
    
    @pyqtSlot(result=str)
    def getSystemInfo(self):
        """Get system information"""
        return f"{platform.system()} {platform.release()}"
    
    @pyqtSlot(str, result=bool)
    def testPortConnection(self, port_name):
        """
        Test if a port can be opened
        Returns True if successful, False otherwise
        """
        try:
            import serial
            ser = serial.Serial(port_name, 57600, timeout=1)
            ser.close()
            print(f"✅ Port {port_name} test: SUCCESS")
            return True
        except Exception as e:
            print(f"❌ Port {port_name} test: FAILED - {e}")
            return False
    
    def cleanup(self):
        """Cleanup resources"""
        print("  - Cleaning up PortDetectorBackend...")
        self._refresh_timer.stop()
        self._available_ports.clear()
        print("✅ PortDetectorBackend cleanup completed")


# Standalone test function
def test_port_detector():
    """Test the port detector"""
    print("=" * 80)
    print("Testing Port Detector Backend")
    print("=" * 80)
    
    from PyQt5.QtWidgets import QApplication
    import sys
    
    app = QApplication(sys.argv)
    detector = PortDetectorBackend()
    
    print(f"\nTotal ports found: {detector.portCount}")
    print("\nPort Details:")
    print("-" * 80)
    
    for port in detector.availablePorts:
        print(f"Port: {port.portName}")
        print(f"  Description: {port.description}")
        print(f"  Manufacturer: {port.manufacturer}")
        print(f"  Location: {port.systemLocation}")
        print(f"  Vendor ID: 0x{port.vendorIdentifier:04X}")
        print(f"  Product ID: 0x{port.productIdentifier:04X}")
        print(f"  Serial Number: {port.serialNumber}")
        print("-" * 80)
    
    print("\nArduPilot/Pixhawk Ports:")
    ardupilot_ports = detector.getArduPilotPorts()
    if ardupilot_ports:
        for port in ardupilot_ports:
            print(f"  - {port.portName}: {port.description}")
    else:
        print("  No ArduPilot/Pixhawk devices detected")
    
    print("\n" + "=" * 80)
    detector.cleanup()


if __name__ == "__main__":
    test_port_detector()