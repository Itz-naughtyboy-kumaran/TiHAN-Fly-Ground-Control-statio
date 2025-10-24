import time
from PyQt5.QtCore import QObject, pyqtSignal, QTimer
from modules.message_box_manager import MessageBoxManager
from modules.cred_manager import CredentialsManager

class TrialManager(QObject):
    """Manages trial period and warnings"""
    trial_expired = pyqtSignal()
    
    def __init__(self, parent=None):
        super().__init__()
        self.trial_duration = 30 * 24 * 60 * 60  #  30 days trial
        self.warning_interval = 29 * 24 * 60 * 60 # Warning every 10 seconds
        self.start_time = None
        self.timer = QTimer()
        self.timer.timeout.connect(self.check_trial_status)
        self.message_manager = MessageBoxManager(parent)
        self.last_warning_time = 0
        self.credentials_manager = CredentialsManager()
        
    def start_trial(self):
        """Start the trial period"""
        self.start_time = time.time()
        self.timer.start(1000)  # Check every second
        print("🚀 Trial period started - 1 minute remaining")
        
    def check_trial_status(self):
        """Check if trial has expired and send warnings"""
        if not self.start_time:
            return
        
        elapsed_time = time.time() - self.start_time
        remaining_time = self.trial_duration - elapsed_time
        
        # Check if trial has expired
        if remaining_time <= 0:
            print("⏰ Trial period has expired!")
            self.timer.stop()
            # Mark credentials as used permanently
            self.credentials_manager.mark_credentials_used()
            self.trial_expired.emit()
            return
        
        # Send warning every 10 seconds
        if elapsed_time - self.last_warning_time >= self.warning_interval:
            self.last_warning_time = elapsed_time
            seconds_left = int(remaining_time)
            
            # Show message box warning
            self.message_manager.show_trial_warning(int(seconds_left / (60 * 60 * 24)))
            
            print(f"⏱️ Trial warning: {seconds_left} seconds remaining")
