from PyQt5.QtCore import QObject, QThread, pyqtSignal
from PyQt5.QtWidgets import QApplication, QLabel, QPushButton, QVBoxLayout, QWidget
import time

class Worker(QObject):
    progress = pyqtSignal(str)

    def do_work(self):
        for i in range(5):
            time.sleep(1)
            self.progress.emit(f"Progress {i + 1}")

class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("moveToThread Example")

        self.label = QLabel("Press start")
        self.button = QPushButton("Start Work")
        self.button.clicked.connect(self.start_work)

        layout = QVBoxLayout()
        layout.addWidget(self.label)
        layout.addWidget(self.button)
        self.setLayout(layout)

    def start_work(self):
        self.thread = QThread()
        self.worker = Worker()
        self.worker.moveToThread(self.thread)

        # connect signals
        self.thread.started.connect(self.worker.do_work)
        self.worker.progress.connect(self.label.setText)
        self.thread.start()

app = QApplication([])
window = MainWindow()
window.show()
app.exec_()
