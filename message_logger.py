import sys
import io
from datetime import datetime
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer


class MessageLogger(QObject):
    """
    Message Logger for capturing and displaying system messages in the UI.
    Captures stdout/stderr and provides a logging interface.
    """
    
    # Signal to emit new messages to QML
    messageReceived = pyqtSignal(str, str, str)  # message, severity, timestamp
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._capturing = False
        self._original_stdout = None
        self._original_stderr = None
        self._message_buffer = []
        self._max_buffer_size = 1000
        
        # Create custom stream redirector
        self._stdout_redirector = StreamRedirector(self._on_stdout_write)
        self._stderr_redirector = StreamRedirector(self._on_stderr_write)
        
        print("📨 MessageLogger initialized")
    
    def start_capture(self):
        """Start capturing stdout and stderr"""
        if self._capturing:
            return
        
        try:
            self._original_stdout = sys.stdout
            self._original_stderr = sys.stderr
            
            sys.stdout = self._stdout_redirector
            sys.stderr = self._stderr_redirector
            
            self._capturing = True
            self.logMessage("📨 Message capture started", "info")
            print("✅ Terminal output capture active")
        except Exception as e:
            print(f"Error starting capture: {e}")
    
    def stop_capture(self):
        """Stop capturing stdout and stderr"""
        if not self._capturing:
            return
        
        try:
            if self._original_stdout:
                sys.stdout = self._original_stdout
            if self._original_stderr:
                sys.stderr = self._original_stderr
            
            self._capturing = False
            print("📨 Message capture stopped")
        except Exception as e:
            print(f"Error stopping capture: {e}")
    
    def _on_stdout_write(self, text):
        """Handle stdout write"""
        if self._original_stdout:
            self._original_stdout.write(text)
            self._original_stdout.flush()
        
        # Log non-empty lines
        text = text.strip()
        if text:
            self._process_message(text, "info")
    
    def _on_stderr_write(self, text):
        """Handle stderr write"""
        if self._original_stderr:
            self._original_stderr.write(text)
            self._original_stderr.flush()
        
        # Log non-empty lines
        text = text.strip()
        if text:
            self._process_message(text, "error")
    
    def _process_message(self, message, default_severity):
        """Process and categorize message"""
        # Auto-detect severity from message content
        severity = default_severity
        message_lower = message.lower()
        
        if any(marker in message_lower for marker in ['error', '❌', 'critical', 'fatal']):
            severity = "error"
        elif any(marker in message_lower for marker in ['warning', '⚠️', 'warn']):
            severity = "warning"
        elif any(marker in message_lower for marker in ['success', '✅', 'completed', 'initialized']):
            severity = "success"
        elif any(marker in message_lower for marker in ['debug', '🔧', 'trace']):
            severity = "debug"
        
        # Create timestamp
        timestamp = datetime.now().strftime("%H:%M:%S")
        
        # Emit signal to QML
        self.messageReceived.emit(message, severity, timestamp)
        
        # Add to buffer with size limit
        self._message_buffer.append({
            'message': message,
            'severity': severity,
            'timestamp': timestamp
        })
        
        if len(self._message_buffer) > self._max_buffer_size:
            self._message_buffer.pop(0)
    
    @pyqtSlot(str, str)
    def logMessage(self, message, severity="info"):
        """
        Log a message with specified severity.
        
        Args:
            message: The message text
            severity: One of "info", "success", "warning", "error", "debug"
        """
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.messageReceived.emit(message, severity, timestamp)
        
        # Add to buffer
        self._message_buffer.append({
            'message': message,
            'severity': severity,
            'timestamp': timestamp
        })
        
        if len(self._message_buffer) > self._max_buffer_size:
            self._message_buffer.pop(0)
    
    @pyqtSlot(result=str)
    def getMessagesJson(self):
        """Get all buffered messages as JSON"""
        import json
        try:
            return json.dumps(self._message_buffer)
        except Exception as e:
            print(f"Error getting messages JSON: {e}")
            return "[]"
    
    @pyqtSlot()
    def clearMessages(self):
        """Clear all buffered messages"""
        self._message_buffer.clear()
        self.logMessage("Messages cleared", "info")
    
    def cleanup(self):
        """Cleanup method called on application exit"""
        print("📨 Cleaning up MessageLogger...")
        self.stop_capture()
        self._message_buffer.clear()


class StreamRedirector(io.TextIOBase):
    """Custom stream redirector for capturing stdout/stderr"""
    
    def __init__(self, callback):
        super().__init__()
        self.callback = callback
        self._buffer = ""
    
    def write(self, text):
        """Write text to the stream"""
        if text and text != '\n':
            self.callback(text)
        return len(text)
    
    def flush(self):
        """Flush the stream"""
        pass
    
    def isatty(self):
        """Check if stream is a TTY"""
        return False
