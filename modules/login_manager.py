from PyQt5.QtWidgets import *
from PyQt5.QtCore import Qt, QTimer, QUrl
from PyQt5.QtGui import QFont
from PyQt5.QtWebEngineWidgets import QWebEngineView
import json, hashlib, sys, re, uuid, random, string
from datetime import datetime
import pymongo
from pymongo import MongoClient
import threading
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import webbrowser
import socketserver

class DatabaseManager:
    def __init__(self):
        self.client = None
        self.db = None
        self.users_collection = None
        self.connect_to_database()
    
    def connect_to_database(self):
        try:
            connection_string = "mongodb+srv://Tihanfly:tihanfly123@tihanfly0.botdqn3.mongodb.net/?retryWrites=true&w=majority&appName=Tihanfly0"
            self.client = MongoClient(connection_string, serverSelectionTimeoutMS=5000)
            self.db = self.client['tihan_fly_gcs']
            self.users_collection = self.db['users']
            self.client.admin.command('ping')
            return True
        except Exception as e:
            return False
    
    def find_user_by_email(self, email):
        try:
            if self.users_collection is None:
                return None
            user = self.users_collection.find_one({"email": email.lower()})
            return user
        except Exception as e:
            return None
    
    def find_user_by_name(self, name):
        """Check if a name already exists in the database"""
        try:
            if self.users_collection is None:
                return None
            # Case-insensitive search for name
            user = self.users_collection.find_one({"name": {"$regex": f"^{re.escape(name)}$", "$options": "i"}})
            return user
        except Exception as e:
            return None
    
    def find_user_by_id(self, user_id):
        try:
            if self.users_collection is None:
                return None
            user = self.users_collection.find_one({"user_id": user_id})
            return user
        except Exception as e:
            return None
    
    def validate_email(self, email):
        """Validate email format"""
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(email_pattern, email) is not None
    
    def validate_name(self, name):
        """Validate name format - only letters and spaces, minimum 2 characters"""
        if not name or len(name.strip()) < 2:
            return False
        # Allow only letters, spaces, and common name characters
        name_pattern = r'^[a-zA-Z\s\'-\.]+$'
        return re.match(name_pattern, name.strip()) is not None
    
    def create_user(self, user_data):
        try:
            if self.users_collection is None:
                return {"success": False, "message": "Database connection failed"}
            
            # Validate name format
            if not self.validate_name(user_data.get('name', '')):
                return {"success": False, "message": "Invalid name format. Name should contain only letters and spaces, minimum 2 characters"}
            
            # Validate email format
            if not self.validate_email(user_data.get('email', '')):
                return {"success": False, "message": "Invalid email format"}
            
            # Check for existing name
            existing_name = self.find_user_by_name(user_data['name'])
            if existing_name:
                return {"success": False, "message": f"Name '{user_data['name']}' is already registered. Please choose a different name."}
            
            # Check for existing email
            existing_email = self.find_user_by_email(user_data['email'])
            if existing_email:
                return {"success": False, "message": f"Email '{user_data['email']}' is already registered. Please use a different email."}
            
            # Generate simple user ID and password
            user_id = self.generate_simple_user_id()
            password = self.generate_simple_password()
            
            # Prepare user data
            user_data['user_id'] = user_id
            user_data['name'] = user_data['name'].strip()  # Clean up name
            user_data['email'] = user_data['email'].lower().strip()  # Normalize email
            user_data['created_at'] = datetime.now().isoformat()
            user_data['login_count'] = 0
            user_data['status'] = 'active'
            user_data['password'] = hashlib.sha256(password.encode()).hexdigest()
            
            # Insert user into database
            result = self.users_collection.insert_one(user_data)
            
            if result.inserted_id:
                return {"success": True, "user_id": user_id, "password": password, "message": "User created successfully"}
            else:
                return {"success": False, "message": "Failed to create user"}
                
        except Exception as e:
            return {"success": False, "message": f"Registration failed: {str(e)}"}
    
    def generate_simple_user_id(self):
        """Generate a simple user ID like user001, user002, etc."""
        while True:
            # Get current user count and add 1
            user_count = self.get_user_count() + 1
            user_id = f"user{user_count:03d}"  # Format as user001, user002, etc.
            
            # Check if this ID already exists
            if not self.find_user_by_id(user_id):
                return user_id
            else:
                # If exists, try next number
                user_count += 1
    
    def generate_simple_password(self):
        """Generate a simple 6-character password with letters and numbers"""
        # Use simple combination of letters and numbers
        letters = string.ascii_lowercase
        numbers = string.digits
        
        # Generate 4 letters + 2 numbers
        password_parts = [
            ''.join(random.choices(letters, k=4)),
            ''.join(random.choices(numbers, k=2))
        ]
        
        # Combine and shuffle
        password = ''.join(password_parts)
        password_list = list(password)
        random.shuffle(password_list)
        
        return ''.join(password_list)
    
    def update_user(self, user_id, update_data):
        try:
            if self.users_collection is None:
                return False
            result = self.users_collection.update_one({"user_id": user_id}, {"$set": update_data})
            return result.modified_count > 0
        except Exception as e:
            return False
    
    def authenticate_user(self, user_id, password, mac_address):
        try:
            if self.users_collection is None:
                return False
            user = self.users_collection.find_one({"user_id": user_id})
            if not user:
                return False
            if user.get("password") != password:
                return False
            if user.get("mac_address") != mac_address:
                return False
            return True
        except Exception as e:
            return False
    
    def get_user_count(self):
        try:
            if self.users_collection is None:
                return 0
            count = self.users_collection.count_documents({})
            return count
        except Exception as e:
            return 0

class RegistrationServer(BaseHTTPRequestHandler):
    def __init__(self, *args, db_manager=None, callback=None, **kwargs):
        self.db_manager = db_manager
        self.callback = callback
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            html_content = """<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>TiHAN Fly GCS - Registration</title><style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);min-height:100vh;display:flex;justify-content:center;align-items:center}.container{background:white;border-radius:20px;box-shadow:0 20px 40px rgba(0,0,0,0.1);overflow:hidden;width:100%;max-width:500px;margin:20px}.header{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;text-align:center;padding:40px 20px}.header h1{font-size:28px;margin-bottom:10px}.header p{font-size:16px;opacity:0.9}.form-container{padding:40px}.form-group{margin-bottom:25px}label{display:block;margin-bottom:8px;font-weight:600;color:#333}input[type="text"],input[type="email"],input[type="tel"],select{width:100%;padding:15px;border:2px solid #e1e5e9;border-radius:10px;font-size:16px;transition:border-color 0.3s}input:focus,select:focus{outline:none;border-color:#667eea}.submit-btn{width:100%;padding:15px;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;border:none;border-radius:10px;font-size:18px;font-weight:600;cursor:pointer;transition:transform 0.3s}.submit-btn:hover{transform:translateY(-2px)}.loading{display:none;text-align:center;padding:20px}.success{background:#d4edda;color:#155724;padding:20px;border-radius:10px;margin-bottom:20px;display:none}.error{background:#f8d7da;color:#721c24;padding:20px;border-radius:10px;margin-bottom:20px;display:none}.validation-hint{font-size:12px;color:#666;margin-top:5px}.error-field{border-color:#dc3545 !important}.credentials-box{background:#f8f9fa;border:2px solid #28a745;border-radius:10px;padding:20px;margin:20px 0;text-align:center}.credentials-box h4{color:#28a745;margin-bottom:15px}.credential-item{background:white;border-radius:8px;padding:15px;margin:10px 0;border:1px solid #dee2e6}.credential-item strong{color:#495057;font-size:16px}.credential-item .value{color:#007bff;font-size:18px;font-weight:bold;margin-top:5px}</style></head><body><div class="container"><div class="header"><h1>TiHAN Fly GCS</h1><p>Ground Control Station Registration</p></div><div class="form-container"><div id="success-message" class="success"></div><div id="error-message" class="error"></div><div id="loading" class="loading"><h3>Processing Registration...</h3><p>Please wait while we create your account.</p></div><form id="registrationForm"><div class="form-group"><label for="name">Full Name *</label><input type="text" id="name" name="name" required><div class="validation-hint">Name must be unique and contain only letters and spaces (minimum 2 characters)</div></div><div class="form-group"><label for="email">Email Address *</label><input type="email" id="email" name="email" required><div class="validation-hint">Email must be unique and in valid format</div></div><div class="form-group"><label for="organization">Organization *</label><input type="text" id="organization" name="organization" required></div><div class="form-group"><label for="department">Department</label><input type="text" id="department" name="department"></div><div class="form-group"><label for="phone">Phone Number *</label><input type="tel" id="phone" name="phone" required></div><div class="form-group"><label for="role">Role *</label><select id="role" name="role" required><option value="">Select Role</option><option value="pilot">Pilot</option><option value="operator">Operator</option><option value="supervisor">Supervisor</option><option value="admin">Administrator</option><option value="researcher">Researcher</option></select></div><div class="form-group"><label for="purpose">Purpose of Use *</label><select id="purpose" name="purpose" required><option value="">Select Purpose</option><option value="research">Research</option><option value="training">Training</option><option value="operations">Operations</option><option value="testing">Testing</option><option value="development">Development</option></select></div><button type="submit" class="submit-btn">Create Account</button></form></div></div><script>// Form validation functions
function validateName(name) {
    const nameRegex = /^[a-zA-Z\s\'-\.]+$/;
    return name.trim().length >= 2 && nameRegex.test(name.trim());
}

function validateEmail(email) {
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return emailRegex.test(email.trim());
}

// Real-time validation
document.getElementById('name').addEventListener('input', function() {
    const nameField = this;
    const name = nameField.value.trim();
    
    if (name && !validateName(name)) {
        nameField.classList.add('error-field');
    } else {
        nameField.classList.remove('error-field');
    }
});

document.getElementById('email').addEventListener('input', function() {
    const emailField = this;
    const email = emailField.value.trim();
    
    if (email && !validateEmail(email)) {
        emailField.classList.add('error-field');
    } else {
        emailField.classList.remove('error-field');
    }
});

document.getElementById('registrationForm').addEventListener('submit', function(e) {
    e.preventDefault();
    
    const formData = new FormData(this);
    const data = Object.fromEntries(formData);
    
    // Client-side validation
    if (!validateName(data.name)) {
        document.getElementById('error-message').innerHTML = '<h3>Validation Error</h3><p>Please enter a valid name (only letters and spaces, minimum 2 characters)</p>';
        document.getElementById('error-message').style.display = 'block';
        return;
    }
    
    if (!validateEmail(data.email)) {
        document.getElementById('error-message').innerHTML = '<h3>Validation Error</h3><p>Please enter a valid email address</p>';
        document.getElementById('error-message').style.display = 'block';
        return;
    }
    
    document.getElementById('loading').style.display = 'block';
    document.getElementById('registrationForm').style.display = 'none';
    document.getElementById('success-message').style.display = 'none';
    document.getElementById('error-message').style.display = 'none';
    
    fetch('/register', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
    })
    .then(response => response.json())
    .then(data => {
        document.getElementById('loading').style.display = 'none';
        if (data.success) {
            document.getElementById('success-message').innerHTML = `
                <h3>Registration Successful!</h3>
                <div class="credentials-box">
                    <h4>🎉 Your Login Credentials</h4>
                    <div class="credential-item">
                        <strong>User ID:</strong>
                        <div class="value">${data.user_id}</div>
                    </div>
                    <div class="credential-item">
                        <strong>Password:</strong>
                        <div class="value">${data.password}</div>
                    </div>
                </div>
                <p><strong>📝 Important:</strong> Please save these simple credentials securely. You will need them to login.</p>
                <p><strong>🚀 The application will now launch automatically...</strong></p>
            `;
            document.getElementById('success-message').style.display = 'block';
            setTimeout(() => {
                window.close();
            }, 15000);
        } else {
            document.getElementById('error-message').innerHTML = `<h3>Registration Failed</h3><p>${data.message}</p>`;
            document.getElementById('error-message').style.display = 'block';
            document.getElementById('registrationForm').style.display = 'block';
        }
    })
    .catch(error => {
        document.getElementById('loading').style.display = 'none';
        document.getElementById('error-message').innerHTML = `<h3>Registration Failed</h3><p>An error occurred: ${error.message}</p>`;
        document.getElementById('error-message').style.display = 'block';
        document.getElementById('registrationForm').style.display = 'block';
    });
});</script></body></html>"""
            self.wfile.write(html_content.encode('utf-8'))
    
    def do_POST(self):
        if self.path == '/register':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            try:
                data = json.loads(post_data.decode('utf-8'))
                mac_address = SystemUtils.get_mac_address()
                
                user_data = {
                    'name': data['name'],
                    'email': data['email'],
                    'organization': data['organization'],
                    'department': data.get('department', ''),
                    'phone': data['phone'],
                    'role': data['role'],
                    'purpose': data['purpose'],
                    'mac_address': mac_address
                }
                
                result = self.db_manager.create_user(user_data)
                
                if result['success']:
                    response_data = {
                        'success': True,
                        'user_id': result['user_id'],
                        'password': result['password'],
                        'message': 'Registration successful'
                    }
                    if self.callback:
                        self.callback(result['user_id'], result['password'])
                else:
                    response_data = {
                        'success': False,
                        'message': result['message']
                    }
                
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(response_data).encode('utf-8'))
                
            except Exception as e:
                response_data = {'success': False, 'message': f'Registration failed: {str(e)}'}
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(response_data).encode('utf-8'))

class SystemUtils:
    @staticmethod
    def get_mac_address():
        try:
            mac = uuid.UUID(int=uuid.getnode()).hex[-12:]
            formatted_mac = ":".join([mac[e:e+2] for e in range(0, 12, 2)]).upper()
            return formatted_mac
        except Exception as e:
            return "00:00:00:00:00:00"

class PasswordLineEdit(QLineEdit):
    def __init__(self):
        super().__init__()
        self.setEchoMode(QLineEdit.Password)
        self.eye_btn = QPushButton("👁")
        self.eye_btn.setFixedSize(30, 25)
        self.eye_btn.setStyleSheet("border:none; background:transparent; font-size:14px;")
        self.eye_btn.clicked.connect(self.toggle_visibility)
        layout = QHBoxLayout(self)
        layout.addStretch()
        layout.addWidget(self.eye_btn)
        layout.setContentsMargins(0, 0, 5, 0)
        
    def toggle_visibility(self):
        if self.echoMode() == QLineEdit.Password:
            self.setEchoMode(QLineEdit.Normal)
            self.eye_btn.setText("🙈")
        else:
            self.setEchoMode(QLineEdit.Password)
            self.eye_btn.setText("👁")

class LoadingDialog(QDialog):
    def __init__(self, parent=None, message="Processing..."):
        super().__init__(parent)
        self.setWindowTitle("Please Wait")
        self.setFixedSize(300, 120)
        self.setModal(True)
        layout = QVBoxLayout(self)
        self.loading_label = QLabel("⏳")
        self.loading_label.setAlignment(Qt.AlignCenter)
        self.loading_label.setStyleSheet("font-size: 24px; color: #00d4ff;")
        layout.addWidget(self.loading_label)
        msg_label = QLabel(message)
        msg_label.setAlignment(Qt.AlignCenter)
        msg_label.setStyleSheet("font-size: 14px; color: #333; margin: 10px;")
        layout.addWidget(msg_label)
        self.timer = QTimer()
        self.timer.timeout.connect(self.animate)
        self.timer.start(500)
        self.animation_state = 0
        
    def animate(self):
        animations = ["⏳", "⌛", "⏳", "⌛"]
        self.loading_label.setText(animations[self.animation_state])
        self.animation_state = (self.animation_state + 1) % len(animations)
        
    def closeEvent(self, event):
        self.timer.stop()
        event.accept()

class RegistrationDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.registered_user_id = None
        self.registered_password = None
        self.server = None
        self.server_thread = None
        self.db_manager = DatabaseManager()
        self.setWindowTitle("TiHAN Fly GCS - Registration")
        self.setFixedSize(400, 200)
        self.setModal(True)
        self.setup_ui()
        
    def setup_ui(self):
        layout = QVBoxLayout(self)
        title = QLabel("TiHAN Fly GCS Registration")
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet("font-size: 18px; font-weight: bold; margin: 20px;")
        layout.addWidget(title)
        info_label = QLabel("Click 'Start Registration' to open the registration form in your browser.")
        info_label.setAlignment(Qt.AlignCenter)
        info_label.setWordWrap(True)
        info_label.setStyleSheet("margin: 10px;")
        layout.addWidget(info_label)
        btn_layout = QHBoxLayout()
        register_btn = QPushButton("Start Registration")
        register_btn.clicked.connect(self.start_registration)
        register_btn.setStyleSheet("QPushButton {background: #007bff; color: white; border: none; padding: 10px 20px; border-radius: 5px; font-weight: bold;} QPushButton:hover {background: #0056b3;}")
        btn_layout.addWidget(register_btn)
        skip_btn = QPushButton("Skip Registration")
        skip_btn.clicked.connect(self.reject)
        skip_btn.setStyleSheet("QPushButton {background: #6c757d; color: white; border: none; padding: 10px 20px; border-radius: 5px; font-weight: bold;} QPushButton:hover {background: #5a6268;}")
        btn_layout.addWidget(skip_btn)
        layout.addLayout(btn_layout)
        self.status_label = QLabel("")
        self.status_label.setAlignment(Qt.AlignCenter)
        self.status_label.setStyleSheet("margin: 10px; color: #007bff;")
        layout.addWidget(self.status_label)
        
    def start_registration(self):
        QApplication.processEvents()
        try:
            port = 8080
            handler = lambda *args, **kwargs: RegistrationServer(*args, db_manager=self.db_manager, callback=self.on_registration_complete, **kwargs)
            self.server = HTTPServer(('localhost', port), handler)
            self.server_thread = threading.Thread(target=self.server.serve_forever)
            self.server_thread.daemon = True
            self.server_thread.start()
            webbrowser.open(f'http://localhost:{port}')
            self.status_label.setText("Registration form opened in browser.\nPlease complete the form.")
        except Exception as e:
            self.status_label.setText(f"Error starting registration: {str(e)}")
    
    def on_registration_complete(self, user_id, password):
        self.registered_user_id = user_id
        self.registered_password = password
        QTimer.singleShot(2000, self.accept)
    
    def get_registered_credentials(self):
        return self.registered_user_id, self.registered_password
    
    def closeEvent(self, event):
        if self.server:
            self.server.shutdown()
        event.accept()

class AuthenticationDialog(QDialog):
    def __init__(self):
        super().__init__()
        self.db_manager = DatabaseManager()
        self.current_user = None
        self.mac_address = SystemUtils.get_mac_address()
        self.setWindowTitle("TiHAN Fly GCS - Authentication")
        self.setWindowFlags(Qt.FramelessWindowHint)
        self.setWindowState(Qt.WindowMaximized)
        self.setup_ui()
        self.apply_styling()
    
    def get_current_user(self):
        return self.current_user
        
    def setup_ui(self):
        main_layout = QHBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        left_panel = QFrame()
        left_panel.setObjectName("brandPanel")
        left_layout = QVBoxLayout(left_panel)
        left_layout.setAlignment(Qt.AlignCenter)
        title = QLabel("TiHAN FLY")
        title.setObjectName("mainTitle")
        title.setAlignment(Qt.AlignCenter)
        left_layout.addWidget(title)
        subtitle = QLabel("GROUND CONTROL STATION")
        subtitle.setObjectName("subtitle")
        subtitle.setAlignment(Qt.AlignCenter)
        left_layout.addWidget(subtitle)
        features = ["🛡️ Military-Grade Security", "🌐 Real-time Control", "📊 Advanced Analytics"]
        for feature in features:
            label = QLabel(feature)
            label.setObjectName("featureItem")
            label.setAlignment(Qt.AlignCenter)
            left_layout.addWidget(label)
        db_status = "🟢 Connected" if self.db_manager.users_collection is not None else "🔴 Disconnected"
        db_label = QLabel(f"Database: {db_status}")
        db_label.setObjectName("systemInfo")
        db_label.setAlignment(Qt.AlignCenter)
        left_layout.addWidget(db_label)
        right_panel = QFrame()
        right_panel.setObjectName("authPanel")
        right_layout = QVBoxLayout(right_panel)
        header_layout = QHBoxLayout()
        header_layout.addStretch()
        close_btn = QPushButton("✕")
        close_btn.setObjectName("closeBtn")
        close_btn.clicked.connect(self.close)
        close_btn.setFixedSize(45, 45)
        header_layout.addWidget(close_btn)
        right_layout.addLayout(header_layout)
        right_layout.addWidget(self.create_login_page())
        main_layout.addWidget(left_panel, 1)
        main_layout.addWidget(right_panel, 1)
        
    def create_login_page(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setAlignment(Qt.AlignCenter)
        form = QFrame()
        form.setObjectName("authForm")
        form_layout = QVBoxLayout(form)
        header = QLabel("SECURE ACCESS")
        header.setObjectName("formHeader")
        header.setAlignment(Qt.AlignCenter)
        form_layout.addWidget(header)
        
        # Add simple login instructions
        instructions = QLabel("Use simple credentials like:\nUser ID: user001\nPassword: abc123")
        instructions.setObjectName("loginInstructions")
        instructions.setAlignment(Qt.AlignCenter)
        form_layout.addWidget(instructions)
        
        self.login_id = QLineEdit()
        self.login_id.setPlaceholderText("User ID (e.g., user001)")
        self.login_id.setObjectName("inputField")
        form_layout.addWidget(self.login_id)
        self.login_pass = PasswordLineEdit()
        self.login_pass.setPlaceholderText("Password")
        self.login_pass.setObjectName("inputField")
        form_layout.addWidget(self.login_pass)
        login_btn = QPushButton("AUTHENTICATE")
        login_btn.setObjectName("primaryBtn")
        login_btn.clicked.connect(self.handle_login)
        form_layout.addWidget(login_btn)
        register_btn = QPushButton("NEW USER REGISTRATION")
        register_btn.setObjectName("secondaryBtn")
        register_btn.clicked.connect(self.handle_registration)
        form_layout.addWidget(register_btn)
        layout.addWidget(form)
        return widget
    
    def handle_registration(self):
        registration_dialog = RegistrationDialog(self)
        if registration_dialog.exec_() == QDialog.Accepted:
            user_id, password = registration_dialog.get_registered_credentials()
            if user_id and password:
                self.login_id.setText(user_id)
                self.login_pass.setText(password)
                QMessageBox.information(self, "Registration Complete", f"Registration successful!\n\nUser ID: {user_id}\nPassword: {password}\n\nCredentials have been filled in the login form.")
    
    def handle_login(self):
        user_id = self.login_id.text().strip()
        password = self.login_pass.text().strip()
        if not user_id or not password:
            QMessageBox.warning(self, "Error", "Please enter credentials!")
            return
        if self.db_manager.users_collection is None:
            QMessageBox.critical(self, "Error", "Database connection failed!")
            return
        loading = LoadingDialog(self, "Authenticating...")
        loading.show()
        QApplication.processEvents()
        try:
            hashed_password = hashlib.sha256(password.encode()).hexdigest()
            if self.db_manager.authenticate_user(user_id, hashed_password, self.mac_address):
                user = self.db_manager.find_user_by_id(user_id)
                if user:
                    self.db_manager.update_user(user_id, {'last_login': datetime.now().isoformat(), 'login_count': user.get('login_count', 0) + 1})
                    loading.close()
                    self.current_user = user
                    QMessageBox.information(self, "Success", f"Welcome, {user['name']}!")
                    self.accept()
                else:
                    loading.close()
                    QMessageBox.critical(self, "Error", "User data not found!")
            else:
                loading.close()
                QMessageBox.critical(self, "Error", "Invalid credentials or unauthorized device!")
        except Exception as e:
            loading.close()
            QMessageBox.critical(self, "Error", f"Authentication failed: {str(e)}")
    
    def apply_styling(self):
        self.setStyleSheet("""
            QDialog {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:1, 
                    stop:0 #0f1419, stop:0.5 #1a252f, stop:1 #2c3e50);
            }
            #brandPanel {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                    stop:0 rgba(0,0,0,0.95), stop:1 rgba(0,0,0,0.85));
                border-right: 4px solid #00d4ff;
            }
            #authPanel {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                    stop:0 rgba(255,255,255,0.98), stop:1 rgba(248,249,250,0.98));
            }
            #mainTitle {
                font-size: 42px;
                font-weight: bold;
                color: #ffffff;
                margin: 20px;
            }
            #subtitle {
                font-size: 16px;
                color: #00d4ff;
                font-weight: bold;
                margin: 10px;
            }
            #featureItem {
                font-size: 14px;
                color: #ecf0f1;
                margin: 8px 0;
            }
            #systemInfo {
                font-size: 11px;
                color: #95a5a6;
                margin: 10px;
            }
            #formHeader {
                font-size: 24px;
                font-weight: bold;
                color: #2c3e50;
                margin: 20px 0;
            }
            #authForm {
                max-width: 450px;
                padding: 40px;
                background: rgba(255,255,255,0.95);
                border-radius: 15px;
                border: 1px solid rgba(0,212,255,0.2);
            }
            #inputField {
                padding: 15px;
                border: 2px solid #bdc3c7;
                border-radius: 10px;
                font-size: 14px;
                margin: 8px 0;
            }
            #inputField:focus {
                border-color: #00d4ff;
            }
            #primaryBtn {
                padding: 15px;
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #00d4ff, stop:1 #0099cc);
                color: white;
                border: none;
                border-radius: 10px;
                font-size: 16px;
                font-weight: bold;
                margin: 15px 0;
            }
            #primaryBtn:hover {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #0099cc, stop:1 #007399);
            }
            #secondaryBtn {
                padding: 12px;
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #28a745, stop:1 #20c997);
                color: white;
                border: none;
                border-radius: 10px;
                font-size: 14px;
                font-weight: bold;
                margin: 8px 0;
            }
            #secondaryBtn:hover {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #218838, stop:1 #1e7e34);
            }
            #closeBtn {
                background: #e74c3c;
                color: white;
                border: none;
                border-radius: 22px;
                font-size: 18px;
                margin: 10px;
            }
            #closeBtn:hover {
                background: #c0392b;
            }
        """)

def main():
    app = QApplication(sys.argv)
    app.setFont(QFont("Segoe UI", 10))
    app.setStyle("Fusion")
    
    # Create and show authentication dialog
    auth_dialog = AuthenticationDialog()
    
    if auth_dialog.exec_() == QDialog.Accepted:
        user = auth_dialog.get_current_user()
        if user:
            QMessageBox.information(None, "Success", "Launching TiHAN Fly GCS...")
            
            # Here you would launch your main application
            # main_window = MainWindow(user)
            # main_window.show()
    
    sys.exit()

if __name__ == "__main__":
    main()