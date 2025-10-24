import smtplib
import json
import urllib.request
import urllib.parse
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from PyQt5.QtCore import QObject, pyqtSlot, pyqtSignal
import threading

class EmailSender(QObject):
    """
    Multi-method email sender with fallback options
    Tries multiple methods to ensure feedback is delivered
    """
    
    emailSent = pyqtSignal(bool, str)
    
    def __init__(self):
        super().__init__()
        self.recipients = {
            'to': 's.syamnarayanan@tihaniith.in',
            'cc': ['j.mohankumar@tihaniith.in', 'ee24mtech12009@iith.ac.in']
        }
        
    @pyqtSlot(str, str, str)
    def sendFeedback(self, user_name, user_email, feedback_text):
        """Send feedback using the best available method"""
        thread = threading.Thread(
            target=self._send_with_fallback,
            args=(user_name, user_email, feedback_text)
        )
        thread.daemon = True
        thread.start()
    
    def _send_with_fallback(self, user_name, user_email, feedback_text):
        """Try multiple sending methods with fallback"""
        
        # Method 1: Try FormSubmit.co (No configuration needed!)
        if self._try_formsubmit(user_name, user_email, feedback_text):
            return
        
        # Method 2: Try local SMTP
        if self._try_local_smtp(user_name, user_email, feedback_text):
            return
        
        # Method 3: Save to local file as backup
        self._save_to_file(user_name, user_email, feedback_text)
    
    def _try_formsubmit(self, user_name, user_email, feedback_text):
        """Use FormSubmit.co - free service, no signup needed"""
        try:
            # FormSubmit endpoint (replace with your email)
            url = f"https://formsubmit.co/{self.recipients['to']}"
            
            # Prepare data
            data = {
                '_subject': 'TiHAN FLY-GCS Feedback',
                '_cc': ','.join(self.recipients['cc']),
                '_template': 'table',
                '_captcha': 'false',
                'name': user_name,
                'email': user_email,
                'feedback': feedback_text
            }
            
            # Encode and send
            data_encoded = urllib.parse.urlencode(data).encode('utf-8')
            req = urllib.request.Request(url, data=data_encoded, method='POST')
            
            with urllib.request.urlopen(req, timeout=10) as response:
                if response.status == 200:
                    self.emailSent.emit(True, "✅ Feedback sent successfully!")
                    return True
                    
        except Exception as e:
            print(f"FormSubmit error: {e}")
            return False
    
    def _try_local_smtp(self, user_name, user_email, feedback_text):
        """Try sending via local SMTP server"""
        try:
            msg = self._create_email_message(user_name, user_email, feedback_text)
            all_recipients = [self.recipients['to']] + self.recipients['cc']
            
            server = smtplib.SMTP('localhost', timeout=5)
            server.sendmail(user_email, all_recipients, msg.as_string())
            server.quit()
            
            self.emailSent.emit(True, "✅ Feedback sent successfully!")
            return True
            
        except Exception as e:
            print(f"Local SMTP error: {e}")
            return False
    
    def _save_to_file(self, user_name, user_email, feedback_text):
        """Save feedback to local file as backup"""
        try:
            import os
            from datetime import datetime
            
            # Create feedback directory if it doesn't exist
            feedback_dir = "feedback_submissions"
            os.makedirs(feedback_dir, exist_ok=True)
            
            # Generate filename with timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = os.path.join(feedback_dir, f"feedback_{timestamp}.txt")
            
            # Write feedback to file
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(f"TiHAN FLY-GCS Feedback Submission\n")
                f.write(f"{'='*50}\n\n")
                f.write(f"Date/Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"Name: {user_name}\n")
                f.write(f"Email: {user_email}\n")
                f.write(f"\nFeedback:\n{'-'*50}\n")
                f.write(f"{feedback_text}\n\n")
                f.write(f"Recipients:\n")
                f.write(f"To: {self.recipients['to']}\n")
                f.write(f"CC: {', '.join(self.recipients['cc'])}\n")
            
            self.emailSent.emit(
                True, 
                f"💾 Feedback saved locally!\nPlease email manually or check: {filename}"
            )
            return True
            
        except Exception as e:
            self.emailSent.emit(False, f"❌ Could not save feedback: {str(e)}")
            return False
    
    def _create_email_message(self, user_name, user_email, feedback_text):
        """Create properly formatted email message"""
        msg = MIMEMultipart()
        msg['From'] = f"{user_name} <{user_email}>"
        msg['To'] = self.recipients['to']
        msg['Cc'] = ", ".join(self.recipients['cc'])
        msg['Subject'] = "TiHAN FLY-GCS Feedback"
        msg['Reply-To'] = user_email
        
        body = f"""
Dear TiHAN Team,

A new feedback has been submitted from TiHAN FLY Ground Control Station.

Submitted by: {user_name}
Email: {user_email}

Feedback:
{feedback_text}

---
This is an automated message from TiHAN FLY-GCS Feedback System.
        """
        
        msg.attach(MIMEText(body, 'plain'))
        return msg


class GmailEmailSender(EmailSender):
    """
    Gmail SMTP sender for production use
    Requires one-time setup of app password
    """
    
    def __init__(self, gmail_address, app_password):
        super().__init__()
        self.smtp_server = "smtp.gmail.com"
        self.smtp_port = 587
        self.sender_email = gmail_address
        self.sender_password = app_password
    
    def _send_with_fallback(self, user_name, user_email, feedback_text):
        """Override to use Gmail first"""
        
        # Try Gmail SMTP
        if self._try_gmail_smtp(user_name, user_email, feedback_text):
            return
        
        # Fall back to parent methods
        super()._send_with_fallback(user_name, user_email, feedback_text)
    
    def _try_gmail_smtp(self, user_name, user_email, feedback_text):
        """Send via Gmail SMTP"""
        try:
            msg = self._create_email_message(user_name, user_email, feedback_text)
            all_recipients = [self.recipients['to']] + self.recipients['cc']
            
            server = smtplib.SMTP(self.smtp_server, self.smtp_port, timeout=10)
            server.starttls()
            server.login(self.sender_email, self.sender_password)
            server.sendmail(self.sender_email, all_recipients, msg.as_string())
            server.quit()
            
            self.emailSent.emit(True, "✅ Feedback sent successfully!")
            return True
            
        except Exception as e:
            print(f"Gmail SMTP error: {e}")
            self.emailSent.emit(False, f"Gmail error: {str(e)}")
            return False