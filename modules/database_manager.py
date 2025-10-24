import pymongo
import uuid
from datetime import datetime
import subprocess
import platform
import re

class DatabaseManager:
    def __init__(self):
        # MongoDB connection string
        self.connection_string = "mongodb+srv://Tihanfly:tihanfly123@tihanfly0.botdqn3.mongodb.net/?retryWrites=true&w=majority&appName=Tihanfly0"
        self.client = None
        self.db = None
        self.users_collection = None
        self.connect_to_database()
    
    def connect_to_database(self):
        """Connect to MongoDB database"""
        try:
            self.client = pymongo.MongoClient(self.connection_string)
            self.db = self.client['tihanfly_db']
            self.users_collection = self.db['users']
            
            # Test connection
            self.client.admin.command('ping')
            print("Successfully connected to MongoDB!")
            
        except Exception as e:
            print(f"Error connecting to MongoDB: {e}")
            raise e
    
    def get_mac_address(self):
        """Get system MAC address"""
        try:
            if platform.system() == "Windows":
                # Windows
                result = subprocess.run(['getmac', '/fo', 'csv', '/nh'], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    mac = result.stdout.strip().split(',')[0].strip('"')
                    return mac.replace('-', ':').upper()
            
            elif platform.system() == "Darwin":
                # macOS
                result = subprocess.run(['ifconfig'], capture_output=True, text=True)
                if result.returncode == 0:
                    mac_match = re.search(r'ether ([a-fA-F0-9:]{17})', result.stdout)
                    if mac_match:
                        return mac_match.group(1).upper()
            
            else:
                # Linux
                result = subprocess.run(['cat', '/sys/class/net/*/address'], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    macs = result.stdout.strip().split('\n')
                    for mac in macs:
                        if mac != '00:00:00:00:00:00' and ':' in mac:
                            return mac.upper()
            
            # Fallback method using uuid
            mac = ':'.join(re.findall('..', '%012x' % uuid.getnode()))
            return mac.upper()
            
        except Exception as e:
            print(f"Error getting MAC address: {e}")
            # Fallback to uuid method
            mac = ':'.join(re.findall('..', '%012x' % uuid.getnode()))
            return mac.upper()
    
    def generate_user_id(self):
        """Generate unique user ID"""
        return str(uuid.uuid4())[:8].upper()
    
    def generate_password(self):
        """Generate random password"""
        return str(uuid.uuid4())[:12]
    
    def signup_user(self, username, email=None):
        """Sign up a new user"""
        try:
            # Check if username already exists
            if self.users_collection.find_one({"username": username}):
                return {"success": False, "message": "Username already exists"}
            
            # Generate user ID and password
            user_id = self.generate_user_id()
            password = self.generate_password()
            mac_address = self.get_mac_address()
            
            # Create user document
            user_data = {
                "user_id": user_id,
                "username": username,
                "password": password,
                "email": email,
                "mac_address": mac_address,
                "created_at": datetime.utcnow(),
                "last_login": None,
                "is_active": True
            }
            
            # Insert user into database
            result = self.users_collection.insert_one(user_data)
            
            if result.inserted_id:
                return {
                    "success": True,
                    "user_id": user_id,
                    "password": password,
                    "message": "User created successfully"
                }
            else:
                return {"success": False, "message": "Failed to create user"}
                
        except Exception as e:
            print(f"Error during signup: {e}")
            return {"success": False, "message": f"Signup failed: {str(e)}"}
    
    def login_user(self, user_id, password):
        """Login user with MAC address verification"""
        try:
            # Find user by user_id and password
            user = self.users_collection.find_one({
                "user_id": user_id,
                "password": password,
                "is_active": True
            })
            
            if not user:
                return {"success": False, "message": "Invalid user ID or password"}
            
            # Get current MAC address
            current_mac = self.get_mac_address()
            
            # Check if MAC address matches
            if user["mac_address"] != current_mac:
                return {
                    "success": False, 
                    "message": "MAC address mismatch. Please login from registered device."
                }
            
            # Update last login
            self.users_collection.update_one(
                {"_id": user["_id"]},
                {"$set": {"last_login": datetime.utcnow()}}
            )
            
            return {
                "success": True,
                "message": "Login successful",
                "user_data": {
                    "user_id": user["user_id"],
                    "username": user["username"],
                    "email": user.get("email"),
                    "last_login": user.get("last_login")
                }
            }
            
        except Exception as e:
            print(f"Error during login: {e}")
            return {"success": False, "message": f"Login failed: {str(e)}"}
    
    def get_user_by_id(self, user_id):
        """Get user information by user ID"""
        try:
            user = self.users_collection.find_one({"user_id": user_id})
            if user:
                return {
                    "success": True,
                    "user_data": {
                        "user_id": user["user_id"],
                        "username": user["username"],
                        "email": user.get("email"),
                        "mac_address": user["mac_address"],
                        "created_at": user["created_at"],
                        "last_login": user.get("last_login")
                    }
                }
            else:
                return {"success": False, "message": "User not found"}
        except Exception as e:
            print(f"Error getting user: {e}")
            return {"success": False, "message": f"Error: {str(e)}"}
    
    def close_connection(self):
        """Close database connection"""
        if self.client:
            self.client.close()
            print("Database connection closed")