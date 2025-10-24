import time
import os
import json
from PyQt5.QtCore import QStandardPaths
from modules.encrypt_manager import EncryptionManager  # Assuming this is defined in another file

class CredentialsManager:
    """Enhanced Manages trial credentials and usage tracking with admin functionality"""
    
    def __init__(self):
        # Get user's home directory for storing trial data
        config_dir = QStandardPaths.writableLocation(QStandardPaths.AppConfigLocation)
        self.trial_file = os.path.join(config_dir, 'tihan_trial_status.json')
        self.credentials_file = os.path.join(config_dir, 'tihan_credentials.json')
        self.encryption = EncryptionManager()

        # Ensure directory exists
        os.makedirs(os.path.dirname(self.trial_file), exist_ok=True)
        
        # Admin credentials (hardcoded for security)
        self.admin_username = "admin"
        self.admin_password = "admin"
        
        # Initialize default credentials if not exists
        self.initialize_default_credentials()
        
    def initialize_default_credentials(self):
        """Initialize default credentials if file doesn't exist"""
        if not os.path.exists(self.credentials_file):
            default_creds = {
                "username": self.encryption.encrypt("tihanfly"),
                "password": self.encryption.encrypt("tihanfly@123"),
                "created_at": time.time(),
                "created_on": time.strftime('%Y-%m-%d %H:%M:%S'),
                "created_by": "system",
                "usage_count": 0,
                "last_used": None
            }
            try:
                with open(self.credentials_file, 'w') as f:
                    json.dump(default_creds, f, indent=2)
                print("Default credentials initialized")
            except Exception as e:
                print(f"Error initializing default credentials: {e}")
    
    def get_current_credentials(self):
        """Get current username and password"""
        try:
            if os.path.exists(self.credentials_file):
                with open(self.credentials_file, 'r') as f:
                    data = json.load(f)
                    username_enc = data.get('username')
                    password_enc = data.get('password')
                    return self.encryption.decrypt(username_enc), self.encryption.decrypt(password_enc)
            return "TiHAN", "TihanFly@1230"  # Fallback
        except Exception as e:
            print(f"Error reading credentials: {e}")
            return "TiHAN", "TihanFly@1230"  # Fallback
    
    def update_credentials(self, new_username, new_password, admin_user):
        """Update credentials (admin only)"""
        try:
            # Reset trial status when credentials are changed
            if os.path.exists(self.trial_file):
                os.remove(self.trial_file)
                print("Trial status reset due to credential change")
            
            new_creds = {
                "username": new_username,
                "password": new_password,
                "created_at": time.time(),
                "created_by": admin_user,
                "usage_count": 0,
                "last_used": None,
                "change_history": self._get_change_history() + [{
                    "changed_at": time.time(),
                    "changed_by": admin_user,
                    "date": time.strftime('%Y-%m-%d %H:%M:%S')
                }]
            }
            
            with open(self.credentials_file, 'w') as f:
                json.dump(new_creds, f, indent=2)
            
            print(f"Credentials updated by admin: {admin_user}")
            return True
        except Exception as e:
            print(f"Error updating credentials: {e}")
            return False
    
    def _get_change_history(self):
        """Get existing change history"""
        try:
            if os.path.exists(self.credentials_file):
                with open(self.credentials_file, 'r') as f:
                    data = json.load(f)
                    return data.get('change_history', [])
            return []
        except:
            return []
    
    def are_credentials_valid(self):
        """Check if credentials are still valid (haven't been used)"""
        try:
            if os.path.exists(self.trial_file):
                with open(self.trial_file, 'r') as f:
                    data = json.load(f)
                    return not data.get('used', False)
            return True  # First time use
        except Exception as e:
            print(f"Error checking credentials: {e}")
            return True  # Default to valid if we can't read the file
    
    def mark_credentials_used(self):
        """Mark credentials as used permanently"""
        try:
            # Update trial status
            trial_data = {
                'used': True,
                'timestamp': time.time(),
                'date': time.strftime('%Y-%m-%d %H:%M:%S')
            }
            with open(self.trial_file, 'w') as f:
                json.dump(trial_data, f, indent=2)
            
            # Update credentials usage count
            if os.path.exists(self.credentials_file):
                with open(self.credentials_file, 'r') as f:
                    cred_data = json.load(f)
                
                cred_data['usage_count'] = cred_data.get('usage_count', 0) + 1
                cred_data['last_used'] = time.time()
                
                with open(self.credentials_file, 'w') as f:
                    json.dump(cred_data, f, indent=2)
            
            print(f"Credentials marked as used: {self.trial_file}")
        except Exception as e:
            print(f"Error marking credentials as used: {e}")
    
    def verify_admin_credentials(self, username, password):
        """Verify admin credentials"""
        return username == self.admin_username and password == self.admin_password
    
    def get_credentials_info(self):
        """Get credentials information for admin panel"""
        try:
            if os.path.exists(self.credentials_file):
                with open(self.credentials_file, 'r') as f:
                    data = json.load(f)
                    return {
                        'username': data.get('username', 'N/A'),
                        'created_at': time.strftime('%Y-%m-%d %H:%M:%S', 
                                                  time.localtime(data.get('created_at', 0))),
                        'created_by': data.get('created_by', 'N/A'),
                        'usage_count': data.get('usage_count', 0),
                        'last_used': time.strftime('%Y-%m-%d %H:%M:%S', 
                                                 time.localtime(data.get('last_used', 0))) if data.get('last_used') else 'Never',
                        'change_count': len(data.get('change_history', []))
                    }
            return None
        except Exception as e:
            print(f"Error getting credentials info: {e}")
            return None
        
