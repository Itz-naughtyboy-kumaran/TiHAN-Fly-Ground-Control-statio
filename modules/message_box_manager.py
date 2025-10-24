import os
from PyQt5.QtWidgets import QMessageBox

class MessageBoxManager:
    def __init__(self, parent=None):
        self.parent = parent
        self.current_warning = None

    def show_trial_warning(self, days_left):
        if self.current_warning and self.current_warning.isVisible():
            return

        self.current_warning = QMessageBox()
        self.current_warning.setWindowTitle("⏰ Trial Period Warning")
        self.current_warning.setIcon(QMessageBox.Warning)
        self.current_warning.setText(f"""
⚠️ Your trial period is limited.

Days Remaining: {days_left} day(s)

Please purchase a license to continue using the software.
        """.strip())
        self.current_warning.setStandardButtons(QMessageBox.Ok)
        self.current_warning.setStyleSheet("""
            QMessageBox {
                background-color: #fff3cd;
                color: #856404;
                font-size: 12px;
            }
            QMessageBox QPushButton {
                background-color: #007bff;
                color: white;
                padding: 8px 16px;
                font-weight: bold;
                border-radius: 4px;
            }
        """)
        self.current_warning.show()