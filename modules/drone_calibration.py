from enum import Enum, auto
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot
from pymavlink import mavutil
#Final Accel Calibration Model

class CalibrationModel(QObject):
    """
    Accelerometer Calibration Model
    Ported from APM Planner AccelCalibrationConfig
    (NON-LEGACY / MODERN FLOW)
    """

    instructionUpdated = pyqtSignal(str)
    finished = pyqtSignal(bool)
    progressUpdated = pyqtSignal(int)
    error = pyqtSignal(str)

    class State(Enum):
        IDLE = auto()
        IN_PROGRESS = auto()

    def __init__(self, mav):
        super().__init__()
        self.mav = mav
        self.state = self.State.IDLE

        self.target_system = 1
        self.target_component = 1
        
        self.current_position = None  # ACCELCAL_VEHICLE_POS_*

    # -------------------------------------------------
    # PUBLIC API (QML)
    # -------------------------------------------------

    @pyqtSlot(int, int)
    def start(self, sysid, compid):
        if self.state != self.State.IDLE:
            self.error.emit("Calibration already running")
            return

        self.target_system = sysid
        self.target_component = compid
        self.state = self.State.IN_PROGRESS
        self.step_count = 0
        # Start full 3D accel calibration
        self.mav.mav.command_long_send(
            sysid, compid,
            mavutil.mavlink.MAV_CMD_PREFLIGHT_CALIBRATION,
            0,
            0, 0, 0, 0,
            1,  # param5 = full accel cal
            0, 0
        )

        self.instructionUpdated.emit(
            "Accelerometer calibration started.\nWaiting for instructions..."
        )

    @pyqtSlot()
    def user_next(self):
        """
        Equivalent to pressing SPACEBAR in APM Planner
        """
        if self.state != self.State.IN_PROGRESS:
            return

        if self.current_position is None:
            return

        # Send ACK for current orientation
        self.mav.mav.command_long_send(
            self.target_system,
            self.target_component,
            mavutil.mavlink.MAV_CMD_ACCELCAL_VEHICLE_POS,
            1,
            float(self.current_position),  # param1 = position enum
           0 0, 0, 0, 0, 0, 0
        )
        self.progressUpdated.emit(self.step_count + 1)  # 6 steps total
        self.step_count += 1

    @pyqtSlot()
    def cancel(self):
        """
        APM Planner style cancel:
        - Stop state machine
        - Send ACKs if needed
        """
        if self.state == self.State.IDLE:
            return

        self.state = self.State.IDLE
        self.current_position = None
        self.finished.emit(False)

    # -------------------------------------------------
    # MAVLINK HANDLING
    # -------------------------------------------------
    pyqtSlot(object)
    def handle_mavlink_message(self, msg):
        """
        Handle COMMAND_LONG from autopilot
        """
        if msg.get_type() != "COMMAND_LONG":
            return

        cmd = msg.command

        if cmd != mavutil.mavlink.MAV_CMD_ACCELCAL_VEHICLE_POS:
            return

        position = int(msg.param1)
        self.current_position = position

        # SUCCESS
        if position == mavutil.mavlink.ACCELCAL_VEHICLE_POS_SUCCESS:
            self.instructionUpdated.emit("SUCCESS: Calibration complete.")
            self._finish(True)
            return

        # FAILED
        if position == mavutil.mavlink.ACCELCAL_VEHICLE_POS_FAILED:
            self.instructionUpdated.emit("FAILED: Calibration failed.")
            self._finish(False)
            return

        # Instruction
        self.instructionUpdated.emit(
            f"Place vehicle {self._position_text(position)} and press Next"
        )

    # -------------------------------------------------
    # INTERNAL
    # -------------------------------------------------

    def _finish(self, success):
        self.state = self.State.IDLE
        self.current_position = None
        self.finished.emit(success)

    def startLevelCalibration(self):
        """
        Start a level (2D) accelerometer calibration
        """
        

        # Start level accel calibration
        self.mav.mav.command_long_send(
            self.target_system,
            self.target_component,
            mavutil.mavlink.MAV_CMD_PREFLIGHT_CALIBRATION,
            0,
            0, 0, 0, 0,
            2, 0, 0
        )

        
    def _position_text(self, pos):
        return {
            mavutil.mavlink.ACCELCAL_VEHICLE_POS_LEVEL: "LEVEL",
            mavutil.mavlink.ACCELCAL_VEHICLE_POS_LEFT: "on its LEFT",
            mavutil.mavlink.ACCELCAL_VEHICLE_POS_RIGHT: "on its RIGHT",
            mavutil.mavlink.ACCELCAL_VEHICLE_POS_NOSEDOWN: "NOSE DOWN",
            mavutil.mavlink.ACCELCAL_VEHICLE_POS_NOSEUP: "NOSE UP",
            mavutil.mavlink.ACCELCAL_VEHICLE_POS_BACK: "on its BACK",
        }.get(pos, "UNKNOWN")
