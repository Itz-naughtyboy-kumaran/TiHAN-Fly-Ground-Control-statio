import os, sys, re, subprocess, time
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, QThread

class FirmwareFlasherWorker(QThread):
    log = pyqtSignal(str)
    eraseProgress = pyqtSignal(int)
    writeProgress = pyqtSignal(int)
    finished = pyqtSignal(bool)
    
    def __init__(self, port, baud_boot, baud_flash, firmware_path):
        super().__init__()
        self.port = port
        self.baud_boot = baud_boot
        self.baud_flash = baud_flash
        self.firmware_path = firmware_path
        self.running = True
        self.process = None
    
    def check_modem_manager(self):
        """Check if ModemManager is running and warn user"""
        try:
            result = subprocess.run(
                ["systemctl", "is-active", "ModemManager"],
                capture_output=True,
                text=True,
                timeout=2
            )
            if result.stdout.strip() == "active":
                self.log.emit("⚠️ WARNING: ModemManager is running!")
                self.log.emit("   This may interfere with flashing.")
                self.log.emit("   Run: sudo systemctl stop ModemManager.service")
                return True
        except Exception:
            pass
        return False
    
    def verify_port_access(self):
        """Verify we have access to the serial port"""
        if not os.path.exists(self.port):
            self.log.emit(f"❌ Port {self.port} does not exist!")
            return False
        
        if not os.access(self.port, os.R_OK | os.W_OK):
            self.log.emit(f"❌ No read/write access to {self.port}")
            self.log.emit(f"   Run: sudo chmod 666 {self.port}")
            self.log.emit(f"   Or add user to dialout group: sudo usermod -aG dialout $USER")
            return False
        
        return True
    
    def verify_firmware_file(self):
        """Verify firmware file exists and is readable"""
        if not os.path.exists(self.firmware_path):
            self.log.emit(f"❌ Firmware file not found: {self.firmware_path}")
            return False
        
        if not os.access(self.firmware_path, os.R_OK):
            self.log.emit(f"❌ Cannot read firmware file: {self.firmware_path}")
            return False
        
        # Check if it's an .apj file
        if not self.firmware_path.endswith('.apj'):
            self.log.emit(f"⚠️ WARNING: File doesn't have .apj extension")
        
        return True
    
    def run(self):
        try:
            # Pre-flight checks
            self.log.emit("🔍 Running pre-flight checks...")
            
            if not self.verify_port_access():
                self.finished.emit(False)
                return
            
            if not self.verify_firmware_file():
                self.finished.emit(False)
                return
            
            self.check_modem_manager()
            
            # Small delay to ensure port is ready
            time.sleep(0.5)
            
            # Build command
            cmd = [
                sys.executable, "uploader.py",
                "--port", self.port,
                "--baud-bootloader", str(self.baud_boot),
                "--baud-bootloader-flash", str(self.baud_flash),
                self.firmware_path
            ]
            
            self.log.emit(f"📡 Command: {' '.join(cmd)}")
            self.log.emit("🔄 Starting upload process...")
            
            # Start process
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )
            
            error_detected = False
            timeout_count = 0
            last_progress_time = time.time()
            
            for raw in self.process.stdout:
                if not self.running:
                    self.log.emit("⏹️ Flash cancelled by user")
                    self.process.terminate()
                    break
                
                line = raw.strip()
                if line:  # Only log non-empty lines
                    self.log.emit(line)
                
                # Progress pattern detection
                erase = re.search(r"Erase\s*:\s*\[.*?\]\s*(\d{1,3}(?:\.\d+)?)%", line)
                write = re.search(r"Write\s*:\s*\[.*?\]\s*(\d{1,3}(?:\.\d+)?)%", line)
                
                if erase:
                    progress = int(float(erase.group(1)))
                    self.eraseProgress.emit(progress)
                    last_progress_time = time.time()
                    timeout_count = 0
                
                if write:
                    progress = int(float(write.group(1)))
                    self.writeProgress.emit(progress)
                    last_progress_time = time.time()
                    timeout_count = 0
                
                # Detect various error conditions
                if any(err in line for err in ["ERROR:", "Flash failed", "timed out", "sync failed"]):
                    error_detected = True
                
                # Check for stuck progress (no update for 30 seconds)
                if time.time() - last_progress_time > 30:
                    timeout_count += 1
                    if timeout_count > 3:
                        self.log.emit("⚠️ No progress for 30 seconds, operation may be stuck")
                        error_detected = True
                        break
            
            # Wait for process to complete
            self.process.wait()
            success = self.process.returncode == 0 and not error_detected
            
            if success:
                self.eraseProgress.emit(100)
                self.writeProgress.emit(100)
            
            self.finished.emit(success)
            
        except FileNotFoundError:
            self.log.emit("❌ Error: uploader.py not found!")
            self.log.emit("   Make sure uploader.py is in the same directory")
            self.finished.emit(False)
        except Exception as e:
            self.log.emit(f"❌ Python-side error: {e}")
            self.finished.emit(False)
    
    def stop(self):
        self.running = False
        if self.process:
            self.process.terminate()


class FirmwareFlasher(QObject):
    logMessage = pyqtSignal(str)
    eraseValue = pyqtSignal(int)
    writeValue = pyqtSignal(int)
    flashFinished = pyqtSignal(bool)
    
    def __init__(self):
        super().__init__()
        self.worker = None
    
    @pyqtSlot(str, int, int, str)
    def startFlash(self, port, baud_boot, baud_flash, firmware_path):
        if self.worker and self.worker.isRunning():
            self.logMessage.emit("⚠️ Flash already in progress!")
            return
        
        # Validate inputs
        if not port:
            self.logMessage.emit("❌ No port selected!")
            return
        
        if not firmware_path:
            self.logMessage.emit("❌ No firmware file selected!")
            return
        
        self.logMessage.emit("=" * 60)
        self.logMessage.emit(f"🚀 Starting flash operation")
        self.logMessage.emit(f"📍 Port: {port}")
        self.logMessage.emit(f"📦 Firmware: {os.path.basename(firmware_path)}")
        self.logMessage.emit(f"⚡ Bootloader Baud: {baud_boot}")
        self.logMessage.emit(f"⚡ Flash Baud: {baud_flash}")
        self.logMessage.emit("=" * 60)
        
        self.worker = FirmwareFlasherWorker(port, baud_boot, baud_flash, firmware_path)
        self.worker.log.connect(self.logMessage.emit)
        self.worker.eraseProgress.connect(self.eraseValue.emit)
        self.worker.writeProgress.connect(self.writeValue.emit)
        self.worker.finished.connect(self._onFinished)
        self.worker.start()
    
    def _onFinished(self, success):
        if success:
            self.logMessage.emit("=" * 60)
            self.logMessage.emit("✅ FLASH COMPLETED SUCCESSFULLY!")
            self.logMessage.emit("=" * 60)
        else:
            self.logMessage.emit("=" * 60)
            self.logMessage.emit("❌ FLASH FAILED")
            self.logMessage.emit("")
            self.logMessage.emit("📋 Troubleshooting checklist:")
            self.logMessage.emit("   1. Is ModemManager running? Stop it:")
            self.logMessage.emit("      sudo systemctl stop ModemManager.service")
            self.logMessage.emit("")
            self.logMessage.emit("   2. Is the board in bootloader mode?")
            self.logMessage.emit("      - No GPS light should be visible")
            self.logMessage.emit("      - Try power cycling the board")
            self.logMessage.emit("")
            self.logMessage.emit("   3. Does the firmware match your board?")
            self.logMessage.emit("      - Check board ID in firmware vs device")
            self.logMessage.emit("      - CubeOrange+ should use 0x2dae firmware")
            self.logMessage.emit("")
            self.logMessage.emit("   4. Try using 115200 baud for both rates")
            self.logMessage.emit("")
            self.logMessage.emit("   5. Check port permissions:")
            self.logMessage.emit("      sudo chmod 666 /dev/ttyACM0")
            self.logMessage.emit("      OR: sudo usermod -aG dialout $USER")
            self.logMessage.emit("=" * 60)
        
        self.flashFinished.emit(success)
        self.worker = None
    
    @pyqtSlot()
    def cancelFlash(self):
        if self.worker:
            self.logMessage.emit("⏹️ Cancelling flash operation...")
            self.worker.stop()
            self.worker.wait()  # Wait for thread to finish
            self.worker = None
