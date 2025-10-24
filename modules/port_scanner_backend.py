"""
Port Scanner Backend Module
Place this file in: modules/port_scanner_backend.py
"""

import serial.tools.list_ports
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, QAbstractListModel, Qt, QModelIndex


class PortInfo(QObject):
    """Represents information about a single serial port"""
    
    def __init__(self, port, description, manufacturer, location, vid, pid, parent=None):
        super().__init__(parent)
        self._port = port
        self._description = description
        self._manufacturer = manufacturer
        self._location = location
        self._vid = vid
        self._pid = pid

    def get_port(self):
        return self._port
    
    def get_description(self):
        return self._description
    
    def get_manufacturer(self):
        return self._manufacturer
    
    def get_location(self):
        return self._location
    
    def get_vendor_ident(self):
        return self._vid
    
    def get_product_ident(self):
        return self._pid


class PortScannerBackend(QAbstractListModel):
    """Backend model for scanning and managing serial ports"""
    
    # Define custom roles for QML access
    PortRole = Qt.UserRole + 1
    DescriptionRole = Qt.UserRole + 2
    ManufacturerRole = Qt.UserRole + 3
    LocationRole = Qt.UserRole + 4
    VendorIdentRole = Qt.UserRole + 5
    ProductIdentRole = Qt.UserRole + 6

    # Signal emitted when ports are refreshed
    portsRefreshed = pyqtSignal()
    portCountChanged = pyqtSignal(int)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._ports = []
        self._destroyed = False
        # Auto-scan ports on initialization
        self.refresh_ports()

    def rowCount(self, parent=QModelIndex()):
        """Return the number of ports in the model"""
        if self._destroyed:
            return 0
        return len(self._ports)

    def data(self, index, role=Qt.DisplayRole):
        """Return data for a given index and role"""
        if self._destroyed:
            return None
            
        if not index.isValid() or index.row() >= len(self._ports):
            return None

        port = self._ports[index.row()]

        if role == self.PortRole:
            return port.get_port()
        elif role == self.DescriptionRole:
            return port.get_description()
        elif role == self.ManufacturerRole:
            return port.get_manufacturer()
        elif role == self.LocationRole:
            return port.get_location()
        elif role == self.VendorIdentRole:
            return port.get_vendor_ident()
        elif role == self.ProductIdentRole:
            return port.get_product_ident()

        return None

    def roleNames(self):
        """Define role names for QML access"""
        return {
            self.PortRole: b'port',
            self.DescriptionRole: b'description',
            self.ManufacturerRole: b'manufacturer',
            self.LocationRole: b'location',
            self.VendorIdentRole: b'vendorIdent',
            self.ProductIdentRole: b'productIdent'
        }

    @pyqtSlot()
    def refresh_ports(self):
        """Scan system for available serial ports and update the model"""
        if self._destroyed:
            return
            
        try:
            print("🔍 Scanning for serial ports...")
            
            # Begin model reset
            self.beginResetModel()
            self._ports.clear()

            # Scan for available ports
            ports = serial.tools.list_ports.comports()
            
            for port in ports:
                port_name = port.device
                description = port.description or "N/A"
                manufacturer = port.manufacturer or "N/A"
                location = port.location or "N/A"
                
                # Format VID and PID as hexadecimal strings
                vid = f"0x{port.vid:04X}" if port.vid is not None else "N/A"
                pid = f"0x{port.pid:04X}" if port.pid is not None else "N/A"

                # Create PortInfo object
                port_info = PortInfo(
                    port_name, 
                    description, 
                    manufacturer, 
                    location, 
                    vid, 
                    pid,
                    self
                )
                self._ports.append(port_info)
                
                print(f"  📍 Found: {port_name} - {description}")

            # End model reset
            self.endResetModel()
            
            # Emit signals
            self.portsRefreshed.emit()
            self.portCountChanged.emit(len(self._ports))
            
            print(f"✅ Port scan complete. Found {len(self._ports)} port(s)")
            
        except Exception as e:
            print(f"❌ Error scanning ports: {e}")
            self.endResetModel()

    @pyqtSlot(result=int)
    def getPortCount(self):
        """Return the number of detected ports"""
        if self._destroyed:
            return 0
        return len(self._ports)

    @pyqtSlot(int, result=str)
    def getPortName(self, index):
        """Get port name by index"""
        if self._destroyed or index < 0 or index >= len(self._ports):
            return ""
        return self._ports[index].get_port()

    @pyqtSlot(int, result=str)
    def getPortDescription(self, index):
        """Get port description by index"""
        if self._destroyed or index < 0 or index >= len(self._ports):
            return ""
        return self._ports[index].get_description()

    @pyqtSlot(str, result=bool)
    def isPortAvailable(self, port_name):
        """Check if a specific port is available"""
        if self._destroyed:
            return False
            
        for port in self._ports:
            if port.get_port() == port_name:
                return True
        return False

    @pyqtSlot(result=list)
    def getPortNames(self):
        """Return list of all port names"""
        if self._destroyed:
            return []
        return [port.get_port() for port in self._ports]

    def cleanup(self):
        """Clean up resources"""
        print("  - Cleaning up PortScannerBackend...")
        self._destroyed = True
        self.beginResetModel()
        self._ports.clear()
        self.endResetModel()