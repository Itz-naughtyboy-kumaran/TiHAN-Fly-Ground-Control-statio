"""
Port Scanner Backend for Ti-NARI Firmware Installation
Integrates DronePortScanner with QML interface
"""

from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer
from drone_port_scanner import DronePortScanner
import json

class PortScannerBackend(QObject):
    """Backend service for port scanning with live detection"""
    
    # Signals for QML
    portsChanged = pyqtSignal()
    deviceDetected = pyqtSignal(str, str)  # portName, deviceInfo
    mavlinkDeviceFound = pyqtSignal(str, str, str)  # portName, autopilot, vehicleType
    scanStatusChanged = pyqtSignal(str)  # status message
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        print("=" * 70)
        print("🔧 Initializing Port Scanner Backend")
        print("=" * 70)
        
        # Initialize scanner
        self.scanner = DronePortScanner()
        
        # Cache for detected ports
        self._cached_ports = []
        self._last_port_count = 0
        
        # Setup auto-refresh timer
        self._refresh_timer = QTimer(self)
        self._refresh_timer.timeout.connect(self._auto_refresh)
        self._refresh_timer.setInterval(2000)  # 2 seconds
        
        # Connect scanner signals
        self.scanner.portDetected.connect(self._on_port_detected)
        
        print("✅ Port Scanner Backend initialized")
        print("   Auto-refresh: 2 seconds")
        print("=" * 70 + "\n")
        
    def start(self):
        """Start the port scanner service"""
        print("🚀 Starting Port Scanner Service...")
        self._refresh_timer.start()
        # Do initial scan
        self.refreshPorts()
        
    def stop(self):
        """Stop the port scanner service"""
        print("🛑 Stopping Port Scanner Service...")
        self._refresh_timer.stop()
        
    @pyqtSlot()
    def refreshPorts(self):
        """Force refresh all ports"""
        print("\n" + "=" * 60)
        print("🔄 REFRESHING PORTS")
        print("=" * 60)
        
        try:
            # Scan for ports
            self.scanStatusChanged.emit("Scanning for devices...")
            ports = self.scanner.getDetailedPorts()
            
            print(f"  Found {len(ports)} total ports")
            
            # Update cache
            old_count = len(self._cached_ports)
            self._cached_ports = ports
            
            # Emit signal if count changed
            if len(ports) != old_count:
                print(f"  Port count changed: {old_count} → {len(ports)}")
                self.portsChanged.emit()
            
            # Log ports
            for i, port in enumerate(ports, 1):
                print(f"\n  Port {i}:")
                print(f"    Name: {port['portName']}")
                print(f"    Type: {port['type']}")
                print(f"    Desc: {port['description']}")
                print(f"    Mfg:  {port['manufacturer']}")
                
            status_msg = f"Found {len(ports)} device(s)"
            self.scanStatusChanged.emit(status_msg)
            
            print("=" * 60 + "\n")
            
        except Exception as e:
            error_msg = f"Error scanning ports: {str(e)}"
            print(f"❌ {error_msg}")
            self.scanStatusChanged.emit(error_msg)
    
    @pyqtSlot(result=list)
    def getDetailedPorts(self):
        """Get detailed port information for QML"""
        print(f"📋 QML requesting port list ({len(self._cached_ports)} ports)")
        
        # Return cached ports with additional formatting
        formatted_ports = []
        for port in self._cached_ports:
            formatted_port = {
                'portName': port.get('portName', 'Unknown'),
                'description': port.get('description', 'Unknown Device'),
                'manufacturer': port.get('manufacturer', 'Unknown'),
                'type': port.get('type', 'Unknown'),
                'vendorId': port.get('vid', 'N/A'),
                'productId': port.get('pid', 'N/A'),
                'location': port.get('location', ''),
                'isMavlink': False,  # TODO: Add MAVLink detection
                'mavlinkInfo': {}
            }
            formatted_ports.append(formatted_port)
        
        return formatted_ports
    
    @pyqtSlot(str, result=bool)
    def isPortAvailable(self, port_name):
        """Check if a specific port is available"""
        return self.scanner.isPortAvailable(port_name)
    
    @pyqtSlot(str, result=str)
    def getPortInfo(self, port_name):
        """Get detailed info for a specific port as JSON"""
        info = self.scanner.getPortInfo(port_name)
        if info:
            return json.dumps(info)
        return "{}"
    
    def _auto_refresh(self):
        """Auto-refresh timer callback"""
        ports = self.scanner.getAvailablePorts()
        current_count = len(ports)
        
        # Only refresh if count changed
        if current_count != self._last_port_count:
            print(f"⏰ Auto-refresh: Port count changed ({self._last_port_count} → {current_count})")
            self._last_port_count = current_count
            self.refreshPorts()
    
    def _on_port_detected(self, port_name, description, manufacturer):
        """Handle port detection signal from scanner"""
        print(f"🔔 Port detected: {port_name} - {description}")
        device_info = f"{description} ({manufacturer})"
        self.deviceDetected.emit(port_name, device_info)
        self.portsChanged.emit()
    
    @pyqtSlot()
    def scanPorts(self):
        """Explicitly trigger port scan"""
        print("📡 Explicit port scan requested")
        self.scanner.scanPorts()
        self.refreshPorts()
    
    def cleanup(self):
        """Cleanup resources"""
        print("🧹 Cleaning up Port Scanner Backend...")
        self.stop()
        self._cached_ports.clear()