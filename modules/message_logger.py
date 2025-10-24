"""
Enhanced Message Logger Backend for QML Integration
Captures ALL terminal messages (print, errors, warnings) and forwards them to QML MessagesPanel
Similar to Mission Planner's message console
"""

import sys
import traceback
from io import StringIO
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer
from datetime import datetime


class MessageLogger(QObject):
    """Backend for logging messages to QML - Mission Planner style"""
    
    # Signal to send messages to QML
    messageAdded = pyqtSignal(str, str, arguments=['message', 'severity'])
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._original_stdout = sys.stdout
        self._original_stderr = sys.stderr
        self._capturing = False
        self._message_buffer = []
        
    def start_capture(self):
        """Start capturing stdout/stderr"""
        if not self._capturing:
            sys.stdout = StreamCapture(self._original_stdout, self, "info")
            sys.stderr = StreamCapture(self._original_stderr, self, "error")
            self._capturing = True
            self.log_success("✅ Message capture started - All terminal output will appear here")
    
    def stop_capture(self):
        """Stop capturing and restore original streams"""
        if self._capturing:
            sys.stdout = self._original_stdout
            sys.stderr = self._original_stderr
            self._capturing = False
            print("🛑 Message capture stopped")
    
    @pyqtSlot(str, str)
    def logMessage(self, message, severity="info"):
        """Log a message from Python or QML"""
        if message and message.strip():
            self.messageAdded.emit(message.strip(), severity)
    
    def log_info(self, message):
        """Log info message"""
        self.messageAdded.emit(message, "info")
    
    def log_success(self, message):
        """Log success message"""
        self.messageAdded.emit(message, "success")
    
    def log_warning(self, message):
        """Log warning message"""
        self.messageAdded.emit(message, "warning")
    
    def log_error(self, message):
        """Log error message"""
        self.messageAdded.emit(message, "error")
    
    def log_exception(self, exc_info=None):
        """Log exception with traceback"""
        if exc_info is None:
            exc_info = sys.exc_info()
        
        if exc_info[0] is not None:
            error_msg = ''.join(traceback.format_exception(*exc_info))
            self.messageAdded.emit(f"Exception occurred:\n{error_msg}", "error")
    
    def cleanup(self):
        """Cleanup resources"""
        print("🧹 Cleaning up MessageLogger...")
        self.stop_capture()


class StreamCapture:
    """Captures output from stdout/stderr and forwards to MessageLogger"""
    
    def __init__(self, original_stream, logger, default_severity):
        self.original_stream = original_stream
        self.logger = logger
        self.default_severity = default_severity
        self.buffer = ""
        
    def write(self, text):
        """Capture written text"""
        # Write to original stream (terminal) - always keep terminal output
        self.original_stream.write(text)
        self.original_stream.flush()
        
        # Buffer and process complete lines
        self.buffer += text
        
        # Process complete lines
        while '\n' in self.buffer:
            line, self.buffer = self.buffer.split('\n', 1)
            if line.strip():  # Only send non-empty lines
                # Determine severity from message content
                severity = self._determine_severity(line)
                self.logger.messageAdded.emit(line.strip(), severity)
    
    def _determine_severity(self, message):
        """Determine message severity from content - Mission Planner style"""
        msg_lower = message.lower()
        
        # Critical/Fatal errors (highest priority)
        if any(x in msg_lower for x in ['fatal', 'critical', 'exception occurred']):
            return "error"
        
        # Error indicators
        if any(x in msg_lower for x in ['❌', 'error', 'failed', 'failure', 'exception', 'traceback']):
            return "error"
        
        # Warning indicators
        if any(x in msg_lower for x in ['⚠️', 'warning', 'warn', 'caution', 'deprecated']):
            return "warning"
        
        # Success indicators
        if any(x in msg_lower for x in ['✅', 'success', 'completed', 'initialized', 'connected', 'started']):
            return "success"
        
        # Info indicators (default)
        return "info"
    
    def flush(self):
        """Flush any remaining buffered content"""
        if self.buffer.strip():
            severity = self._determine_severity(self.buffer)
            self.logger.messageAdded.emit(self.buffer.strip(), severity)
            self.buffer = ""
        self.original_stream.flush()
    
    def isatty(self):
        """Check if stream is a TTY"""
        return self.original_stream.isatty()


# Global exception hook for uncaught exceptions
def setup_exception_hook(message_logger):
    """Setup global exception hook to catch all uncaught exceptions"""
    
    def exception_hook(exc_type, exc_value, exc_traceback):
        """Handle uncaught exceptions"""
        # Log to message logger
        error_msg = ''.join(traceback.format_exception(exc_type, exc_value, exc_traceback))
        message_logger.log_error(f"UNCAUGHT EXCEPTION:\n{error_msg}")
        
        # Also print to stderr for debugging
        sys.__stderr__.write(f"\nUNCAUGHT EXCEPTION:\n{error_msg}\n")
        sys.__stderr__.flush()
    
    # Set the exception hook
    sys.excepthook = exception_hook
    message_logger.log_info("🛡️ Global exception handler installed")


# Wrapper functions for easy logging from anywhere
_global_logger = None

def set_global_logger(logger):
    """Set the global logger instance"""
    global _global_logger
    _global_logger = logger
    setup_exception_hook(logger)

def log_info(message):
    """Log info message using global logger"""
    if _global_logger:
        _global_logger.log_info(message)
    else:
        print(f"[INFO] {message}")

def log_success(message):
    """Log success message using global logger"""
    if _global_logger:
        _global_logger.log_success(message)
    else:
        print(f"[SUCCESS] {message}")

def log_warning(message):
    """Log warning message using global logger"""
    if _global_logger:
        _global_logger.log_warning(message)
    else:
        print(f"[WARNING] {message}")

def log_error(message):
    """Log error message using global logger"""
    if _global_logger:
        _global_logger.log_error(message)
    else:
        print(f"[ERROR] {message}")

def log_exception(exc_info=None):
    """Log exception using global logger"""
    if _global_logger:
        _global_logger.log_exception(exc_info)
    else:
        traceback.print_exc()