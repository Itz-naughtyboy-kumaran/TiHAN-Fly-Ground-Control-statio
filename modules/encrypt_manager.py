from cryptography.fernet import Fernet

class EncryptionManager:
    def __init__(self):
        # Hardcoded 32-byte key (base64 URL-safe)
        self.key = b'd53nGXeAYoFaBEDWmXP-8PmpYT--ign3tY1licMccp0='
        self.cipher = Fernet(self.key)

    def encrypt(self, data: str) -> str:
        return self.cipher.encrypt(data.encode()).decode()

    def decrypt(self, token: str) -> str:
        return self.cipher.decrypt(token.encode()).decode()