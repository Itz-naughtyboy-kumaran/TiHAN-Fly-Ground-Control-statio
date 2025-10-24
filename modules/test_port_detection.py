#!/usr/bin/env python3
"""
Test script for MAVLink port detection
Run this to verify your PortManager is working correctly
"""

import sys
import os
import time
from PyQt5.QtWidgets import QApplication
from PyQt5.QtCore import QTimer

# Add parent directory to path if running from modules directory
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

# Import the PortManager
try:
    # Try importing from modules package first
    from modules.port_manager import PortManager
    print("✅ PortManager imported successfully (from modules)")
except ImportError:
    try:
        # If that fails, try importing directly (if running from modules dir)
        from port_manager import PortManager
        print("✅ PortManager imported successfully (direct import)")
    except ImportError as e:
        print(f"❌ Failed to import PortManager: {e}")
        print("\n📁 Current directory:", current_dir)
        print("📁 Parent directory:", parent_dir)
        print("\n💡 Please run this script from the project root directory:")
        print(f"   cd {parent_dir}")
        print("   python test_port_detection.py")
        print("\n   OR run from modules directory:")
        print("   python -m test_port_detection")
        sys.exit(1)


def test_port_detection():
    """Test the port detection functionality"""
    print("\n" + "="*60)
    print("MAVLink Port Detection Test")
    print("="*60 + "\n")
    
    # Create Qt application
    app = QApplication(sys.argv)
    
    # Create port manager
    print("🔌 Creating PortManager...")
    port_manager = PortManager()
    
    # Connect signals to display results
    def on_ports_changed():
        print("\n📡 Port list updated:")
        ports = port_manager.getDetailedPorts()
        
        if len(ports) == 0:
            print("  ⚠️  No ports detected")
            print("  💡 Tips:")
            print("     - Connect your flight controller via USB")
            print("     - Check cable connection")
            print("     - Verify device drivers are installed")
        else:
            print(f"  Found {len(ports)} port(s):\n")
            
            for i, port in enumerate(ports, 1):
                print(f"  [{i}] {port['portName']}")
                print(f"      Description: {port['description']}")
                print(f"      Manufacturer: {port['manufacturer']}")
                print(f"      Vendor ID: {port['vendorId']}")
                print(f"      Product ID: {port['productId']}")
                
                if port['isMavlink']:
                    print(f"      ✅ MAVLink Device Detected!")
                    info = port['mavlinkInfo']
                    print(f"         • System ID: {info['system_id']}")
                    print(f"         • Autopilot: {info['autopilot']}")
                    print(f"         • Vehicle Type: {info['vehicle_type']}")
                    print(f"         • Baudrate: {info['baudrate']}")
                    print(f"         • Firmware: {info['firmware_version']}")
                    if info.get('board_id'):
                        print(f"         • Board ID: {info['board_id']}")
                else:
                    print(f"      ⚪ Not a MAVLink device (or detection in progress...)")
                print()
    
    def on_device_detected(port_name, device_info):
        print(f"\n🎉 New MAVLink device detected!")
        print(f"   Port: {port_name}")
        print(f"   Autopilot: {device_info['autopilot']}")
        print(f"   Vehicle: {device_info['vehicle_type']}")
        print(f"   System ID: {device_info['system_id']}\n")
    
    # Connect signals
    port_manager.portsChanged.connect(on_ports_changed)
    port_manager.deviceDetected.connect(on_device_detected)
    
    print("⏳ Scanning for devices...")
    print("   (This may take a few seconds per port)\n")
    
    # Let it run for 30 seconds to detect devices
    def stop_test():
        print("\n" + "="*60)
        print("Test completed!")
        print("="*60)
        
        # Cleanup
        port_manager.cleanup()
        app.quit()
    
    # Stop after 30 seconds
    QTimer.singleShot(30000, stop_test)
    
    # Initial scan
    port_manager.scanPorts()
    
    print("💡 Keep your flight controller connected")
    print("💡 Detection will continue for 30 seconds...")
    print("💡 Press Ctrl+C to stop early\n")
    
    # Run the application
    try:
        sys.exit(app.exec_())
    except KeyboardInterrupt:
        print("\n\n⚠️  Test interrupted by user")
        port_manager.cleanup()
        sys.exit(0)


if __name__ == "__main__":
    test_port_detection()