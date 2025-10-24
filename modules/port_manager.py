import sys
import serial.tools.list_ports
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer
from pymavlink import mavutil
import threading
import time


class PortManager(QObject):
    """
    Enhanced Port Manager with real-time MAVLink device detection
    Integrates seamlessly with existing TiHAN architecture
    """
    portsChanged = pyqtSignal()
    deviceDetected = pyqtSignal(str, dict)  # portName, deviceInfo
    mavlinkDeviceFound = pyqtSignal(str, str, str)  # portName, autopilot, vehicleType
    
    def __init__(self):
        super().__init__()
        self.ports = []
        self.mavlink_devices = {}
        self.monitoring_threads = {}
        self.stop_monitoring = {}
        self._cleanup_requested = False
        
        # Setup auto-refresh timer (scan every 2 seconds)
        self.refresh_timer = QTimer()
        self.refresh_timer.timeout.connect(self.scanPorts)
        self.refresh_timer.start(2000)
        
        # Initial scan
        print("🔌 PortManager initialized with MAVLink detection")
        self.scanPorts()
    
    @pyqtSlot()
    def scanPorts(self):
        """Scan for available serial ports and detect MAVLink devices"""
        if self._cleanup_requested:
            return
            
        try:
            available_ports = list(serial.tools.list_ports.comports())
            
            # Check if ports changed
            new_port_names = {port.device for port in available_ports}
            old_port_names = {port['portName'] for port in self.ports}
            
            if new_port_names != old_port_names:
                self.ports.clear()
                
                for port in available_ports:
                    port_info = {
                        'portName': port.device,
                        'description': port.description or 'Unknown Device',
                        'manufacturer': port.manufacturer or 'Unknown',
                        'location': port.device,
                        'vendorId': f"0x{port.vid:04x}" if port.vid else 'N/A',
                        'productId': f"0x{port.pid:04x}" if port.pid else 'N/A',
                        'type': 'Serial',
                        'isMavlink': False,
                        'mavlinkInfo': {}
                    }
                    
                    self.ports.append(port_info)
                    
                    # Start MAVLink detection for this port
                    if port.device not in self.monitoring_threads:
                        self.startMavlinkDetection(port.device)
                
                # Stop monitoring removed ports
                removed_ports = old_port_names - new_port_names
                for port_name in removed_ports:
                    self.stopMavlinkDetection(port_name)
                
                self.portsChanged.emit()
                print(f"📡 Port scan complete: {len(self.ports)} ports found")
                
        except Exception as e:
            print(f"⚠️ Error scanning ports: {e}")
    
    def startMavlinkDetection(self, port_name):
        """Start MAVLink detection thread for a specific port"""
        if self._cleanup_requested:
            return
            
        if port_name in self.monitoring_threads and self.monitoring_threads[port_name].is_alive():
            return
        
        self.stop_monitoring[port_name] = False
        thread = threading.Thread(
            target=self._detectMavlink, 
            args=(port_name,), 
            daemon=True,
            name=f"MAVLink-{port_name}"
        )
        thread.start()
        self.monitoring_threads[port_name] = thread
    
    def stopMavlinkDetection(self, port_name):
        """Stop MAVLink detection for a specific port"""
        if port_name in self.stop_monitoring:
            self.stop_monitoring[port_name] = True
        
        if port_name in self.monitoring_threads:
            del self.monitoring_threads[port_name]
        
        if port_name in self.mavlink_devices:
            del self.mavlink_devices[port_name]
    
    def _detectMavlink(self, port_name):
        """
        Detect if a port has a MAVLink device connected
        Runs in a separate thread to avoid blocking UI
        """
        if self._cleanup_requested:
            return
            
        connection = None
        # Try common MAVLink baudrates
        baudrates = [115200, 57600, 921600, 500000, 230400]
        
        for baudrate in baudrates:
            if self.stop_monitoring.get(port_name, False) or self._cleanup_requested:
                return
            
            try:
                # Attempt MAVLink connection
                connection = mavutil.mavlink_connection(
                    port_name,
                    baud=baudrate,
                    source_system=255,
                    source_component=0
                )
                
                # Wait for heartbeat with short timeout
                print(f"🔍 Probing {port_name} at {baudrate} baud...")
                msg = connection.wait_heartbeat(timeout=2)
                
                if msg and connection.target_system != 0:
                    # MAVLink device detected!
                    device_info = {
                        'system_id': connection.target_system,
                        'component_id': connection.target_component,
                        'baudrate': baudrate,
                        'autopilot': self._get_autopilot_name(msg.autopilot),
                        'vehicle_type': self._get_vehicle_type(msg.type),
                        'firmware_version': 'Unknown',
                        'board_id': None
                    }
                    
                    # Try to get firmware version
                    try:
                        version_info = self._request_autopilot_version(connection)
                        if version_info:
                            device_info['firmware_version'] = version_info['version']
                            device_info['board_id'] = version_info.get('board_id')
                    except:
                        pass
                    
                    # Update port info
                    for port in self.ports:
                        if port['portName'] == port_name:
                            port['isMavlink'] = True
                            port['mavlinkInfo'] = device_info
                            port['description'] = f"✓ {device_info['vehicle_type']} ({device_info['autopilot']})"
                            port['manufacturer'] = device_info['autopilot']
                            break
                    
                    self.mavlink_devices[port_name] = device_info
                    self.deviceDetected.emit(port_name, device_info)
                    self.mavlinkDeviceFound.emit(
                        port_name, 
                        device_info['autopilot'], 
                        device_info['vehicle_type']
                    )
                    self.portsChanged.emit()
                    
                    print(f"✅ MAVLink device found on {port_name}:")
                    print(f"   System ID: {device_info['system_id']}")
                    print(f"   Autopilot: {device_info['autopilot']}")
                    print(f"   Vehicle: {device_info['vehicle_type']}")
                    print(f"   Baudrate: {baudrate}")
                    
                    if connection:
                        connection.close()
                    return
                    
            except Exception as e:
                # Silently continue to next baudrate
                pass
            finally:
                if connection:
                    try:
                        connection.close()
                    except:
                        pass
        
                        
    
    def _get_autopilot_name(self, autopilot_id):
        """Get human-readable autopilot name from MAV_AUTOPILOT enum"""
        autopilot_names = {
            0: 'Generic',
            3: 'ArduPilot',
            4: 'OpenPilot',
            12: 'PX4',
            13: 'SmartAP',
            14: 'AirRails',
        }
        return autopilot_names.get(autopilot_id, f'Unknown ({autopilot_id})')
    
    def _get_vehicle_type(self, vehicle_type_id):
        """Get human-readable vehicle type from MAV_TYPE enum"""
        vehicle_types = {
            0: 'Generic',
            1: 'Fixed Wing',
            2: 'Quadcopter',
            3: 'Coaxial Heli',
            4: 'Helicopter',
            5: 'Antenna Tracker',
            6: 'GCS',
            10: 'Ground Rover',
            11: 'Surface Boat',
            12: 'Submarine',
            13: 'Hexacopter',
            14: 'Octocopter',
            15: 'Tricopter',
            19: 'VTOL Quad',
            20: 'VTOL Tiltrotor',
            21: 'VTOL',
        }
        return vehicle_types.get(vehicle_type_id, f'Unknown ({vehicle_type_id})')
    
    def _request_autopilot_version(self, connection):
        """Request autopilot version information"""
        try:
            # Request AUTOPILOT_VERSION message
            connection.mav.command_long_send(
                connection.target_system,
                connection.target_component,
                mavutil.mavlink.MAV_CMD_REQUEST_MESSAGE,
                0,
                mavutil.mavlink.MAVLINK_MSG_ID_AUTOPILOT_VERSION,
                0, 0, 0, 0, 0, 0
            )
            
            # Wait for response
            msg = connection.recv_match(
                type='AUTOPILOT_VERSION', 
                blocking=True, 
                timeout=3
            )
            
            if msg:
                # Parse version
                major = (msg.flight_sw_version >> 24) & 0xFF
                minor = (msg.flight_sw_version >> 16) & 0xFF
                patch = (msg.flight_sw_version >> 8) & 0xFF
                version = f"{major}.{minor}.{patch}"
                
                return {
                    'version': version,
                    'board_id': msg.board_version if hasattr(msg, 'board_version') else None
                }
        except:
            pass
        
        return None
    
    @pyqtSlot(result=list)
    def getDetailedPorts(self):
        """Get list of all detected ports with MAVLink info"""
        return self.ports
    
    @pyqtSlot(str, result=dict)
    def getPortInfo(self, port_name):
        """Get detailed info for a specific port"""
        for port in self.ports:
            if port['portName'] == port_name:
                return port
        return {}
    
    @pyqtSlot(str, result=bool)
    def isMavlinkDevice(self, port_name):
        """Check if a port has a MAVLink device"""
        return port_name in self.mavlink_devices
    
    @pyqtSlot(str, result=str)
    def getMavlinkInfo(self, port_name):
        """Get MAVLink device info as string"""
        if port_name in self.mavlink_devices:
            info = self.mavlink_devices[port_name]
            return f"{info['autopilot']} - {info['vehicle_type']} (SysID: {info['system_id']})"
        return "Not a MAVLink device"
    
    @pyqtSlot()
    def refreshPorts(self):
        """Manual port refresh (called from QML)"""
        print("🔄 Manual port refresh requested")
        self.scanPorts()
    
    def cleanup(self):
        """Cleanup resources when closing application"""
        print("🧹 Cleaning up PortManager...")
        self._cleanup_requested = True
        
        # Stop refresh timer
        if self.refresh_timer:
            self.refresh_timer.stop()
        
        # Stop all monitoring threads
        for port_name in list(self.stop_monitoring.keys()):
            self.stop_monitoring[port_name] = True
        
        # Wait briefly for threads to finish
        time.sleep(0.5)
        
        # Clear data
        self.ports.clear()
        self.mavlink_devices.clear()
        self.monitoring_threads.clear()
        
        print("✅ PortManager cleanup complete")