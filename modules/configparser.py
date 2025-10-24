"""
Commercial App SMS Configuration
For apps you're selling to customers
"""

import os
import json
import configparser
from PyQt5.QtWidgets import QMessageBox, QInputDialog

class CommercialSMSConfig:
    """Handle SMS configuration for commercial apps"""
    
    def __init__(self):
        self.config_file = os.path.join(os.path.dirname(__file__), 'sms_config.json')
        self.load_config()
    
    def load_config(self):
        """Load SMS configuration"""
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    config = json.load(f)
                    self.sms_service = config.get('service', 'twilio')
                    self.credentials = config.get('credentials', {})
                    return True
            except:
                pass
        
        # First time setup
        self.setup_wizard()
        return False
    
    def setup_wizard(self):
        """SMS setup wizard for first-time users"""
        from PyQt5.QtWidgets import QDialog, QVBoxLayout, QLabel, QComboBox, QPushButton, QLineEdit, QFormLayout
        
        dialog = QDialog()
        dialog.setWindowTitle("SMS Service Setup")
        dialog.setFixedSize(400, 300)
        
        layout = QVBoxLayout()
        
        # Instructions
        info = QLabel("Welcome! Please configure your SMS service to enable OTP verification.")
        info.setWordWrap(True)
        layout.addWidget(info)
        
        # Service selection
        form = QFormLayout()
        service_combo = QComboBox()
        service_combo.addItems(['twilio', 'fast2sms', 'textlocal'])
        form.addRow("SMS Service:", service_combo)
        
        # Credential fields (will show based on selection)
        cred_fields = {}
        
        def update_fields():
            # Clear existing fields
            for field in cred_fields.values():
                field.setParent(None)
            cred_fields.clear()
            
            service = service_combo.currentText()
            
            if service == 'twilio':
                cred_fields['account_sid'] = QLineEdit()
                cred_fields['auth_token'] = QLineEdit()
                cred_fields['phone_number'] = QLineEdit()
                
                form.addRow("Account SID:", cred_fields['account_sid'])
                form.addRow("Auth Token:", cred_fields['auth_token'])
                form.addRow("Phone Number:", cred_fields['phone_number'])
                
            elif service == 'fast2sms':
                cred_fields['api_key'] = QLineEdit()
                form.addRow("API Key:", cred_fields['api_key'])
                
            elif service == 'textlocal':
                cred_fields['api_key'] = QLineEdit()
                cred_fields['sender'] = QLineEdit()
                cred_fields['sender'].setText('TIHAN')
                
                form.addRow("API Key:", cred_fields['api_key'])
                form.addRow("Sender ID:", cred_fields['sender'])
        
        service_combo.currentTextChanged.connect(update_fields)
        update_fields()  # Initialize
        
        layout.addLayout(form)
        
        # Buttons
        save_btn = QPushButton("Save Configuration")
        
        def save_config():
            service = service_combo.currentText()
            credentials = {}
            
            for key, field in cred_fields.items():
                if not field.text().strip():
                    QMessageBox.warning(dialog, "Error", f"Please fill in {key}")
                    return
                credentials[key] = field.text().strip()
            
            # Save to file
            config = {
                'service': service,
                'credentials': credentials
            }
            
            try:
                with open(self.config_file, 'w') as f:
                    json.dump(config, f, indent=2)
                
                self.sms_service = service
                self.credentials = credentials
                
                QMessageBox.information(dialog, "Success", "SMS configuration saved successfully!")
                dialog.accept()
                
            except Exception as e:
                QMessageBox.critical(dialog, "Error", f"Failed to save configuration: {str(e)}")
        
        save_btn.clicked.connect(save_config)
        layout.addWidget(save_btn)
        
        dialog.setLayout(layout)
        dialog.exec_()
    
    def get_sms_config(self):
        """Get SMS configuration for the sender"""
        return self.sms_service, self.credentials

# Updated SMSSender class for commercial use
class CommercialSMSSender(QThread):
    """Commercial SMS sender with dynamic configuration"""
    sms_sent = pyqtSignal(bool, str)
    
    def __init__(self, phone_number, otp):
        super().__init__()
        self.phone_number = phone_number
        self.otp = otp
        
        # Load configuration
        self.config = CommercialSMSConfig()
        self.sms_service, self.credentials = self.config.get_sms_config()
    
    def run(self):
        try:
            if self.sms_service == 'twilio':
                self.send_twilio_sms()
            elif self.sms_service == 'textlocal':
                self.send_textlocal_sms()
            elif self.sms_service == 'fast2sms':
                self.send_fast2sms()
            else:
                self.sms_sent.emit(False, "SMS service not configured")
                
        except Exception as e:
            self.sms_sent.emit(False, f"SMS failed: {str(e)}")
    
    def send_twilio_sms(self):
        """Send SMS using Twilio with stored credentials"""
        try:
            from twilio.rest import Client
            
            client = Client(
                self.credentials['account_sid'], 
                self.credentials['auth_token']
            )
            
            message = client.messages.create(
                body=f"Your TiHAN Drone Telemetry OTP is: {self.otp}. Valid for 5 minutes.",
                from_=self.credentials['phone_number'],
                to=self.phone_number
            )
            
            self.sms_sent.emit(True, "OTP sent successfully!")
            
        except ImportError:
            self.sms_sent.emit(False, "Twilio library not installed. Run: pip install twilio")
        except Exception as e:
            self.sms_sent.emit(False, f"Twilio error: {str(e)}")
    
    def send_fast2sms(self):
        """Send SMS using Fast2SMS"""
        try:
            import requests
            
            url = "https://www.fast2sms.com/dev/bulkV2"
            
            headers = {
                'authorization': self.credentials['api_key'],
                'Content-Type': 'application/x-www-form-urlencoded'
            }
            
            data = {
                'route': 'dlt',
                'sender_id': 'TIHAN',
                'message': f"Your TiHAN Drone Telemetry OTP is: {self.otp}. Valid for 5 minutes.",
                'numbers': self.phone_number.replace('+91', ''),
                'flash': 0
            }
            
            response = requests.post(url, headers=headers, data=data)
            result = response.json()
            
            if result['return']:
                self.sms_sent.emit(True, "OTP sent successfully!")
            else:
                self.sms_sent.emit(False, f"Fast2SMS error: {result.get('message', 'Unknown error')}")
                
        except Exception as e:
            self.sms_sent.emit(False, f"Fast2SMS error: {str(e)}")
    
    def send_textlocal_sms(self):
        """Send SMS using TextLocal"""
        try:
            import requests
            
            url = "https://api.textlocal.in/send/"
            
            data = {
                'apikey': self.credentials['api_key'],
                'numbers': self.phone_number,
                'message': f"Your TiHAN Drone Telemetry OTP is: {self.otp}. Valid for 5 minutes.",
                'sender': self.credentials.get('sender', 'TIHAN')
            }
            
            response = requests.post(url, data=data)
            result = response.json()
            
            if result['status'] == 'success':
                self.sms_sent.emit(True, "OTP sent successfully!")
            else:
                self.sms_sent.emit(False, f"TextLocal error: {result.get('errors', 'Unknown error')}")
                
        except Exception as e:
            self.sms_sent.emit(False, f"TextLocal error: {str(e)}")

# Usage in your registration tab:
# Replace the SMS sender initialization with:
# self.sms_thread = CommercialSMSSender(formatted_phone, self.otp_generated)