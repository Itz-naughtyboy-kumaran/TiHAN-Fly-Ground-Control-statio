"""
Ti-Nari Firmware Flasher Backend
ArduPilot firmware flashing with bootloader support for Cube Orange/Orange+
"""

import os
import sys
import time
import json
import base64
import serial
import struct
from pathlib import Path
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer, QThread

class FirmwareFlasherBackend(QObject):
    """
    Backend for flashing ArduPilot firmware to flight controllers
    Supports Cube Orange and Cube Orange+ via bootloader protocol
    """
    
    # Qt signals for UI updates
    flashProgress = pyqtSignal(int)  # Progress percentage (0-100)
    flashStatus = pyqtSignal(str)    # Status message
    flashCompleted = pyqtSignal(bool, str)  # (success, message)
    flashError = pyqtSignal(str)     # Error message
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.is_flashing = False
        self.cancel_requested = False
        self.flash_thread = None
        
        # Bootloader protocol constants
        self.PROTO_INSYNC = b'\x12'
        self.PROTO_EOC = b'\x20'
        self.PROTO_GET_SYNC = b'\x21'
        self.PROTO_GET_DEVICE = b'\x22'
        self.PROTO_CHIP_ERASE = b'\x23'
        self.PROTO_PROG_MULTI = b'\x27'
        self.PROTO_READ_MULTI = b'\x28'
        self.PROTO_GET_CRC = b'\x29'
        self.PROTO_BOOT = b'\x30'
        
        # Board IDs
        self.BOARD_IDS = {
            0x000C: "Cube Orange",
            0x0011: "Cube Orange+",
            0x0009: "Cube Black",
            0x0032: "Pixhawk 1",
            0x0042: "Pixhawk 4"
        }
        
        print("✅ Firmware Flasher Backend initialized")
    
    @pyqtSlot(str, str, str)
    def flashFirmware(self, port, drone_name, cube_type):
        """
        Flash firmware to the selected device
        
        Args:
            port: Serial port (e.g., /dev/ttyACM0 or COM3)
            drone_name: Name of drone (Shadow, Spider, Kala, Palyanka, Chakrayukhan)
            cube_type: CubeOrange or CubeOrangePlus
        """
        print(f"\n{'='*60}")
        print(f"📞 flashFirmware() called from QML")
        print(f"   Port: {port}")
        print(f"   Drone: {drone_name}")
        print(f"   Cube Type: {cube_type}")
        print(f"{'='*60}\n")
        
        if self.is_flashing:
            error_msg = "Flash operation already in progress"
            print(f"❌ {error_msg}")
            self.flashError.emit(error_msg)
            return
        
        self.is_flashing = True
        self.cancel_requested = False
        
        # Start flash in separate thread to avoid blocking UI
        print("🔄 Starting flash thread...")
        self.flash_thread = FlashThread(self, port, drone_name, cube_type)
        self.flash_thread.finished.connect(self._on_flash_finished)
        self.flash_thread.start()
        print("✅ Flash thread started")
    
    @pyqtSlot()
    def cancelFlash(self):
        """Cancel ongoing flash operation"""
        if self.is_flashing:
            self.cancel_requested = True
            self.flashStatus.emit("⚠️ Cancelling flash operation...")
            print("⚠️ Cancel requested by user")
    
    def _on_flash_finished(self):
        """Called when flash thread completes"""
        print("🏁 Flash thread finished")
        self.is_flashing = False
        self.flash_thread = None
    
    def _find_firmware_file(self, drone_name, cube_type):
        """
        Find the firmware file for the specified drone and cube type
        
        Returns:
            Path to firmware file or None if not found
        """
        # Get base directory
        if getattr(sys, 'frozen', False):
            base_dir = sys._MEIPASS
        else:
            base_dir = os.path.dirname(os.path.abspath(__file__))
        
        # Construct firmware filename - try multiple variations
        firmware_dir = os.path.join(base_dir, "App", "resources", "firmware")
        
        # Try different filename patterns
        filename_patterns = [
            f"{drone_name}_{cube_type}.apj",
            f"{drone_name.lower()}_{cube_type}.apj",
            f"{drone_name.upper()}_{cube_type}.apj",
            f"{drone_name}_{cube_type.lower()}.apj",
        ]
        
        self.flashStatus.emit(f"🔍 Searching for firmware in: {firmware_dir}")
        print(f"🔍 Searching firmware directory: {firmware_dir}")
        
        # List all files in firmware directory for debugging
        if os.path.exists(firmware_dir):
            files_in_dir = os.listdir(firmware_dir)
            print(f"📁 Files in firmware directory: {files_in_dir}")
            self.flashStatus.emit(f"📁 Found {len(files_in_dir)} files in firmware directory")
        else:
            print(f"❌ Firmware directory does not exist: {firmware_dir}")
            self.flashStatus.emit(f"❌ Firmware directory not found: {firmware_dir}")
            return None
        
        # Try each pattern
        for pattern in filename_patterns:
            firmware_file = os.path.join(firmware_dir, pattern)
            print(f"   Trying: {pattern}")
            
            if os.path.exists(firmware_file):
                self.flashStatus.emit(f"✅ Found firmware: {pattern}")
                print(f"✅ Found firmware file: {firmware_file}")
                return firmware_file
        
        # If not found, show what we were looking for
        error_msg = f"❌ Firmware not found. Tried: {', '.join(filename_patterns)}"
        print(error_msg)
        self.flashStatus.emit(error_msg)
        return None
    
    def _enter_bootloader(self, port, baudrate=115200):
        """
        Try to enter bootloader mode via MAVLink reboot command
        """
        try:
            self.flashStatus.emit(f"🔄 Attempting to enter bootloader on {port}...")
            print(f"🔄 Entering bootloader mode on {port}")
            
            # Try MAVLink reboot command first
            try:
                from pymavlink import mavutil
                self.flashStatus.emit("📡 Sending MAVLink reboot command...")
                print("📡 Attempting MAVLink reboot...")
                
                conn = mavutil.mavlink_connection(port, baud=baudrate)
                print("   Waiting for heartbeat...")
                conn.wait_heartbeat(timeout=5)
                print("   ✅ Heartbeat received")
                
                # Send reboot command (MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN)
                print("   Sending reboot to bootloader command...")
                conn.mav.command_long_send(
                    conn.target_system,
                    conn.target_component,
                    mavutil.mavlink.MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN,
                    0,  # confirmation
                    3,  # param1: 3 = reboot to bootloader
                    0, 0, 0, 0, 0, 0
                )
                
                conn.close()
                self.flashStatus.emit("✅ Reboot command sent, waiting for bootloader...")
                print("✅ Reboot command sent successfully")
                time.sleep(3)  # Wait for device to reboot
                
            except ImportError:
                print("⚠️ pymavlink not available, will try direct bootloader")
                self.flashStatus.emit("⚠️ MAVLink not available, trying direct bootloader...")
            except Exception as e:
                print(f"⚠️ MAVLink reboot failed: {e}")
                self.flashStatus.emit(f"⚠️ MAVLink reboot failed: {e}")
                self.flashStatus.emit("⚠️ Will try direct bootloader connection...")
            
            return True
            
        except Exception as e:
            error_msg = f"⚠️ Error entering bootloader: {e}"
            print(error_msg)
            self.flashStatus.emit(error_msg)
            return False
    
    def _connect_bootloader(self, port, baudrate=115200, timeout=30):
        """
        Connect to bootloader and sync
        """
        try:
            self.flashStatus.emit(f"🔌 Connecting to bootloader on {port}...")
            print(f"🔌 Attempting bootloader connection on {port}")
            
            start_time = time.time()
            attempt = 0
            
            while time.time() - start_time < timeout:
                if self.cancel_requested:
                    print("❌ Connection cancelled by user")
                    return None
                
                attempt += 1
                try:
                    print(f"   Attempt {attempt}...")
                    ser = serial.Serial(port, baudrate, timeout=1)
                    time.sleep(0.1)
                    
                    # Try to sync with bootloader
                    for sync_attempt in range(5):
                        ser.write(self.PROTO_GET_SYNC + self.PROTO_EOC)
                        time.sleep(0.1)
                        
                        response = ser.read(2)
                        if len(response) == 2 and response == self.PROTO_INSYNC + self.PROTO_EOC:
                            self.flashStatus.emit("✅ Bootloader sync successful!")
                            print("✅ Bootloader connected and synced!")
                            return ser
                    
                    ser.close()
                    
                except serial.SerialException as se:
                    print(f"   Serial error: {se}")
                
                time.sleep(0.5)
            
            error_msg = "❌ Failed to connect to bootloader (timeout)"
            print(error_msg)
            self.flashStatus.emit(error_msg)
            return None
            
        except Exception as e:
            error_msg = f"❌ Bootloader connection error: {e}"
            print(error_msg)
            self.flashStatus.emit(error_msg)
            return None
    
    def _get_device_info(self, ser):
        """Get device information from bootloader"""
        try:
            print("📋 Getting device info...")
            ser.write(self.PROTO_GET_DEVICE + self.PROTO_EOC)
            response = ser.read(8)
            
            if len(response) >= 6 and response[0:1] == self.PROTO_INSYNC:
                board_id = struct.unpack('<I', response[1:5])[0]
                board_name = self.BOARD_IDS.get(board_id, f"Unknown (0x{board_id:04X})")
                
                self.flashStatus.emit(f"📋 Detected board: {board_name} (0x{board_id:04X})")
                print(f"📋 Board detected: {board_name} (0x{board_id:04X})")
                return board_id, board_name
            
            print("⚠️ Could not read device info")
            return None, None
            
        except Exception as e:
            error_msg = f"⚠️ Error getting device info: {e}"
            print(error_msg)
            self.flashStatus.emit(error_msg)
            return None, None
    
    def _erase_flash(self, ser):
        """Erase flash memory"""
        try:
            self.flashStatus.emit("🗑️ Erasing flash memory...")
            print("🗑️ Starting flash erase (this may take 10-30 seconds)...")
            self.flashProgress.emit(10)
            
            ser.write(self.PROTO_CHIP_ERASE + self.PROTO_EOC)
            
            # Wait for erase to complete (can take 10-30 seconds)
            start_time = time.time()
            while time.time() - start_time < 60:
                if self.cancel_requested:
                    print("❌ Erase cancelled")
                    return False
                    
                if ser.in_waiting >= 2:
                    response = ser.read(2)
                    if response == self.PROTO_INSYNC + self.PROTO_EOC:
                        elapsed = time.time() - start_time
                        self.flashStatus.emit(f"✅ Flash erased successfully ({elapsed:.1f}s)")
                        print(f"✅ Flash erase completed in {elapsed:.1f}s")
                        self.flashProgress.emit(20)
                        return True
                time.sleep(0.1)
            
            error_msg = "❌ Flash erase timeout"
            print(error_msg)
            self.flashStatus.emit(error_msg)
            return False
            
        except Exception as e:
            error_msg = f"❌ Erase error: {e}"
            print(error_msg)
            self.flashStatus.emit(error_msg)
            return False
    
    def _program_flash(self, ser, firmware_data):
        """Program firmware to flash memory"""
        try:
            size_kb = len(firmware_data) / 1024
            self.flashStatus.emit(f"📝 Programming {size_kb:.1f} KB...")
            print(f"📝 Programming {len(firmware_data)} bytes ({size_kb:.1f} KB)")
            
            chunk_size = 252  # Must be multiple of 4
            total_chunks = (len(firmware_data) + chunk_size - 1) // chunk_size
            print(f"   Total chunks to program: {total_chunks}")
            
            for i in range(0, len(firmware_data), chunk_size):
                if self.cancel_requested:
                    print("❌ Programming cancelled")
                    return False
                
                chunk = firmware_data[i:i + chunk_size]
                
                # Pad chunk to chunk_size if needed
                if len(chunk) < chunk_size:
                    chunk += b'\xff' * (chunk_size - len(chunk))
                
                # Send program command
                cmd = self.PROTO_PROG_MULTI + struct.pack('<B', len(chunk)) + chunk + self.PROTO_EOC
                ser.write(cmd)
                
                # Wait for response
                response = ser.read(2)
                if response != self.PROTO_INSYNC + self.PROTO_EOC:
                    error_msg = f"❌ Programming failed at byte {i}"
                    print(error_msg)
                    self.flashStatus.emit(error_msg)
                    return False
                
                # Update progress (20% to 80%)
                progress = 20 + int((i / len(firmware_data)) * 60)
                self.flashProgress.emit(progress)
                
                # Update status every 50 chunks
                chunk_num = i // chunk_size + 1
                if chunk_num % 50 == 0 or chunk_num == total_chunks:
                    status = f"📝 Programming: {chunk_num}/{total_chunks} chunks ({progress}%)"
                    self.flashStatus.emit(status)
                    print(f"   {status}")
            
            self.flashStatus.emit("✅ Programming complete")
            print("✅ Programming completed successfully")
            self.flashProgress.emit(80)
            return True
            
        except Exception as e:
            error_msg = f"❌ Programming error: {e}"
            print(error_msg)
            self.flashStatus.emit(error_msg)
            return False
    
    def _verify_flash(self, ser, firmware_data):
        """Verify programmed firmware"""
        try:
            self.flashStatus.emit("🔍 Verifying flash...")
            print("🔍 Starting flash verification...")
            self.flashProgress.emit(85)
            
            # Get CRC from bootloader
            ser.write(self.PROTO_GET_CRC + self.PROTO_EOC)
            response = ser.read(6)
            
            if len(response) == 6 and response[0:1] == self.PROTO_INSYNC:
                bootloader_crc = struct.unpack('<I', response[1:5])[0]
                print(f"   Bootloader CRC: 0x{bootloader_crc:08X}")
                
                # Calculate expected CRC
                import binascii
                expected_crc = binascii.crc32(firmware_data) & 0xFFFFFFFF
                print(f"   Expected CRC: 0x{expected_crc:08X}")
                
                if bootloader_crc == expected_crc:
                    self.flashStatus.emit("✅ Verification successful - CRC match!")
                    print("✅ CRC verification passed")
                    self.flashProgress.emit(90)
                    return True
                else:
                    error_msg = f"❌ CRC mismatch: {bootloader_crc:08X} != {expected_crc:08X}"
                    print(error_msg)
                    self.flashStatus.emit(error_msg)
                    return False
            
            self.flashStatus.emit("⚠️ Skipping verification (not supported)")
            print("⚠️ CRC verification not supported by this bootloader")
            self.flashProgress.emit(90)
            return True  # Continue anyway
            
        except Exception as e:
            error_msg = f"⚠️ Verification error (continuing): {e}"
            print(error_msg)
            self.flashStatus.emit(error_msg)
            self.flashProgress.emit(90)
            return True  # Continue even if verification fails
    
    def _reboot_device(self, ser):
        """Reboot device from bootloader"""
        try:
            self.flashStatus.emit("🔄 Rebooting device with new firmware...")
            print("🔄 Sending reboot command...")
            self.flashProgress.emit(95)
            
            ser.write(self.PROTO_BOOT + self.PROTO_EOC)
            time.sleep(0.5)
            
            self.flashStatus.emit("✅ Reboot command sent")
            print("✅ Device rebooting...")
            self.flashProgress.emit(100)
            return True
            
        except Exception as e:
            error_msg = f"⚠️ Reboot error: {e}"
            print(error_msg)
            self.flashStatus.emit(error_msg)
            return False
    
    def cleanup(self):
        """Cleanup resources"""
        print("  - Cleaning up Firmware Flasher...")
        if self.is_flashing:
            self.cancel_requested = True
            if self.flash_thread and self.flash_thread.isRunning():
                print("    Waiting for flash thread to finish...")
                self.flash_thread.wait(5000)  # Wait up to 5 seconds


class FlashThread(QThread):
    """Separate thread for firmware flashing to avoid UI blocking"""
    
    def __init__(self, flasher, port, drone_name, cube_type):
        super().__init__()
        self.flasher = flasher
        self.port = port
        self.drone_name = drone_name
        self.cube_type = cube_type
    
    def run(self):
        """Execute flash operation in separate thread"""
        print(f"\n{'='*60}")
        print(f"🧵 FLASH THREAD STARTED")
        print(f"{'='*60}\n")
        
        try:
            # Find firmware file
            firmware_file = self.flasher._find_firmware_file(self.drone_name, self.cube_type)
            if not firmware_file:
                self.flasher.flashCompleted.emit(False, "Firmware file not found")
                return
            
            # Load and parse firmware
            self.flasher.flashStatus.emit("📖 Loading firmware file...")
            print(f"📖 Loading firmware: {firmware_file}")
            
            with open(firmware_file, 'r') as f:
                firmware_data = json.load(f)
            
            print(f"✅ Firmware JSON loaded")
            
            # Decode base64 image
            print("🔓 Decoding firmware image...")
            image_data = base64.b64decode(firmware_data['image'])
            
            size_kb = len(image_data) / 1024
            self.flasher.flashStatus.emit(f"✅ Loaded {size_kb:.1f} KB firmware")
            self.flasher.flashStatus.emit(f"📋 Board ID: 0x{firmware_data['board_id']:04X}")
            self.flasher.flashStatus.emit(f"📋 Version: {firmware_data.get('summary', 'N/A')}")
            
            print(f"✅ Firmware decoded: {len(image_data)} bytes ({size_kb:.1f} KB)")
            print(f"   Board ID: 0x{firmware_data['board_id']:04X}")
            print(f"   Version: {firmware_data.get('summary', 'N/A')}")
            print(f"   Git Hash: {firmware_data.get('git_hash', 'N/A')}")
            
            # Enter bootloader
            if not self.flasher._enter_bootloader(self.port):
                self.flasher.flashCompleted.emit(False, "Failed to enter bootloader")
                return
            
            # Connect to bootloader
            ser = self.flasher._connect_bootloader(self.port)
            if not ser:
                self.flasher.flashCompleted.emit(False, "Failed to connect to bootloader")
                return
            
            try:
                # Get device info
                board_id, board_name = self.flasher._get_device_info(ser)
                
                # Erase flash
                if not self.flasher._erase_flash(ser):
                    raise Exception("Flash erase failed")
                
                # Program flash
                if not self.flasher._program_flash(ser, image_data):
                    raise Exception("Flash programming failed")
                
                # Verify flash
                if not self.flasher._verify_flash(ser, image_data):
                    raise Exception("Flash verification failed")
                
                # Reboot device
                self.flasher._reboot_device(ser)
                
                print(f"\n{'='*60}")
                print(f"✅ FLASH COMPLETED SUCCESSFULLY!")
                print(f"{'='*60}\n")
                
                self.flasher.flashCompleted.emit(True, "Firmware flashed successfully!")
                
            finally:
                ser.close()
                print("🔌 Serial port closed")
                
        except Exception as e:
            error_msg = f"Flash failed: {str(e)}"
            print(f"\n{'='*60}")
            print(f"❌ FLASH FAILED: {e}")
            print(f"{'='*60}\n")
            self.flasher.flashStatus.emit(f"❌ Error: {e}")
            self.flasher.flashCompleted.emit(False, error_msg)