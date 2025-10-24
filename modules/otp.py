# mongo_test.py

from PyQt5.QtCore import QThread, pyqtSignal
from pymongo import MongoClient

print("✅ QThread and pyqtSignal imported successfully!")

uri = "mongodb+srv://Tihanfly:tihanfly123@tihanfly0.botdqn3.mongodb.net/?retryWrites=true&w=majority&appName=Tihanfly0"

try:
    client = MongoClient(uri)
    db = client["user_db"]
    print("✅ Connected successfully to MongoDB Atlas!")
    print("📦 Collections:", db.list_collection_names())
except Exception as e:
    print("❌ Connection failed:", e)
