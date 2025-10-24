# drone_port_scanner.py
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty
import serial.tools.list_ports

class DronePortScanner(QObject):
    """
    Enhanced port scanner for detecting drone flight controllers
    Detects USB serial devices commonly used with ArduPilot/PX4
    """
    portsChanged = pyqtSignal()
    portDetected = pyqtSignal(str, str, str)  # port, description, manufacturer
    
    def __init__(self):
        super().__init__()
        self._ports = []
        self._detailed_ports = []
        print("[DronePortScanner] Initialized")
    
    @pyqtSlot(result='QVariantList')
    def getAvailablePorts(self):
        """
        Scan and return available drone ports
        Returns: List of port device names (e.g., '/dev/ttyUSB0', 'COM3')
        """
        ports = serial.tools.list_ports.comports()
        available_ports = []
        
        print(f"[DronePortScanner] Scanning for ports... Found {len(ports)} total ports")
        
        for port in ports:
            # Enhanced detection for common flight controller chips
            if any(keyword in port.description.upper() or 
                   keyword in str(port.manufacturer).upper() or
                   keyword in str(port.hwid).upper() 
                   for keyword in ["USB", "SERIAL", "CP210", "FTDI", "CH340", 
                                   "PL2303", "ARDUINO", "PIXHAWK", "CUBE"]):
                available_ports.append(port.device)
                print(f"[DronePortScanner] ✓ Detected: {port.device} - {port.description}")
        
        # Add SITL as first option
        sitl_port = "udp:127.0.0.1:14550"
        if sitl_port not in available_ports:
            available_ports.insert(0, sitl_port)
        
        self._ports = available_ports
        self.portsChanged.emit()
        
        print(f"[DronePortScanner] Total available ports: {len(available_ports)}")
        return available_ports
    
    @pyqtSlot(result='QVariantList')
    def getDetailedPorts(self):
        """
        Get detailed information about all detected ports
        Returns: List of dictionaries with port details
        """
        ports = serial.tools.list_ports.comports()
        detailed_ports = []
        
        # Add SITL first
        detailed_ports.append({
            'portName': 'udp:127.0.0.1:14550',
            'description': 'Software In The Loop (SITL) - Simulator Connection',
            'manufacturer': 'Simulated Device',
            'type': 'Network',
            'icon': '🌐',
            'hwid': 'SITL',
            'vid': '',
            'pid': '',
            'serial_number': ''
        })
        
        for port in ports:
            # Check if it's a potential drone port
            is_drone_port = any(keyword in port.description.upper() or 
                               keyword in str(port.manufacturer).upper() or
                               keyword in str(port.hwid).upper() 
                               for keyword in ["USB", "SERIAL", "CP210", "FTDI", "CH340", 
                                              "PL2303", "ARDUINO", "PIXHAWK", "CUBE"])
            
            if is_drone_port:
                # Determine device type and icon
                port_type = self._determine_port_type(port)
                icon = self._get_port_icon(port)
                
                detailed_ports.append({
                    'portName': port.device,
                    'description': port.description,
                    'manufacturer': str(port.manufacturer) if port.manufacturer else 'Unknown',
                    'type': port_type,
                    'icon': icon,
                    'hwid': port.hwid,
                    'vid': hex(port.vid) if port.vid else '',
                    'pid': hex(port.pid) if port.pid else '',
                    'serial_number': port.serial_number if port.serial_number else ''
                })
                
                print(f"[DronePortScanner] Added port: {port.device} - {port.description}")
        
        self._detailed_ports = detailed_ports
        print(f"[DronePortScanner] Total detailed ports: {len(detailed_ports)}")
        return detailed_ports
    
    def _determine_port_type(self, port):
        """Determine the type of port based on its properties"""
        desc_upper = port.description.upper()
        manufacturer_upper = str(port.manufacturer).upper() if port.manufacturer else ""
        
        if "PIXHAWK" in desc_upper or "PX4" in desc_upper:
            return "Pixhawk"
        elif "CUBE" in desc_upper or "CUBEPILOT" in manufacturer_upper:
            return "CubePilot"
        elif "ARDUINO" in desc_upper:
            return "Arduino"
        elif "FTDI" in desc_upper or "FTDI" in manufacturer_upper:
            return "FTDI USB"
        elif "CP210" in desc_upper:
            return "CP2102 USB"
        elif "CH340" in desc_upper:
            return "CH340 USB"
        elif "PL2303" in desc_upper:
            return "PL2303 USB"
        elif "ACM" in port.device:
            return "USB ACM"
        else:
            return "USB Serial"
    
    def _get_port_icon(self, port):
        """Get appropriate icon for the port type"""
        port_type = self._determine_port_type(port)
        
        icon_map = {
            "Pixhawk": "🚁",
            "CubePilot": "📦",
            "Arduino": "🔧",
            "FTDI USB": "🔌",
            "CP2102 USB": "🔌",
            "CH340 USB": "🔌",
            "PL2303 USB": "🔌",
            "USB ACM": "🔌",
            "USB Serial": "🔌"
        }
        
        return icon_map.get(port_type, "🔌")
    
    @pyqtSlot(str, result=bool)
    def isPortAvailable(self, port_name):
        """
        Check if a specific port is currently available
        Args:
            port_name: Name of the port to check
        Returns:
            True if port exists and is available
        """
        ports = serial.tools.list_ports.comports()
        for port in ports:
            if port.device == port_name:
                return True
        return port_name.startswith("udp:") or port_name.startswith("tcp:")
    
    @pyqtSlot()
    def scanPorts(self):
        """
        Trigger a port scan and emit signals for each detected port
        """
        print("[DronePortScanner] Starting port scan...")
        ports = serial.tools.list_ports.comports()
        
        for port in ports:
            if any(keyword in port.description.upper() or 
                   keyword in str(port.manufacturer).upper() or
                   keyword in str(port.hwid).upper() 
                   for keyword in ["USB", "SERIAL", "CP210", "FTDI", "CH340", 
                                   "PL2303", "ARDUINO", "PIXHAWK", "CUBE"]):
                manufacturer = str(port.manufacturer) if port.manufacturer else "Unknown"
                self.portDetected.emit(port.device, port.description, manufacturer)
                print(f"[DronePortScanner] Emitted signal for: {port.device}")
        
        print("[DronePortScanner] Port scan complete")
    
    @pyqtSlot(str, result='QVariantMap')
    def getPortInfo(self, port_name):
        """
        Get detailed information about a specific port
        Args:
            port_name: Name of the port to query
        Returns:
            Dictionary with port details
        """
        ports = serial.tools.list_ports.comports()
        
        for port in ports:
            if port.device == port_name:
                return {
                    'device': port.device,
                    'description': port.description,
                    'manufacturer': str(port.manufacturer) if port.manufacturer else 'Unknown',
                    'hwid': port.hwid,
                    'vid': hex(port.vid) if port.vid else '',
                    'pid': hex(port.pid) if port.pid else '',
                    'serial_number': port.serial_number if port.serial_number else '',
                    'location': port.location if hasattr(port, 'location') else ''
                }
        
        return {}
    
    @pyqtProperty('QVariantList', notify=portsChanged)
    def availablePorts(self):
        """Property to access available ports from QML"""
        return self._ports
    
    @pyqtProperty('QVariantList', notify=portsChanged)
    def detailedPorts(self):
        """Property to access detailed port information from QML"""
        return self._detailed_ports


# Example usage and testing
if __name__ == "__main__":
    import sys
    from PyQt5.QtWidgets import QApplication
    
    app = QApplication(sys.argv)
    
    scanner = DronePortScanner()
    
    print("\n=== Testing Port Scanner ===\n")
    
    # Test basic port listing
    print("1. Basic Port List:")
    ports = scanner.getAvailablePorts()
    for port in ports:
        print(f"   - {port}")
    
    # Test detailed port information
    print("\n2. Detailed Port Information:")
    detailed = scanner.getDetailedPorts()
    for port_info in detailed:
        print(f"   Port: {port_info['portName']}")
        print(f"   Type: {port_info['type']}")
        print(f"   Icon: {port_info['icon']}")
        print(f"   Description: {port_info['description']}")
        print(f"   Manufacturer: {port_info['manufacturer']}")
        print()
    
    # Test port availability check
    if ports:
        test_port = ports[1] if len(ports) > 1 else ports[0]
        print(f"3. Port Availability Check for {test_port}:")
        print(f"   Available: {scanner.isPortAvailable(test_port)}")
    
    print("\n=== Test Complete ===\n")