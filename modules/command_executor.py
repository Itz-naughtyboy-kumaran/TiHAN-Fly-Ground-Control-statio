import os
import subprocess
import sys
from PyQt5.QtCore import QObject, pyqtSignal, QTimer, pyqtSlot

class CommandExecutor(QObject):
    # Signals for UI feedback
    commandStarted = pyqtSignal()
    commandFinished = pyqtSignal(bool, str)  # success, message
    commandOutput = pyqtSignal(str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._is_running = False
        self._process = None
        
        # Configure APM Planner path
        self.apm_planner_base_path = self._get_apm_planner_path()
        
    def _get_apm_planner_path(self):
        """Determine the APM Planner installation path"""
        # Get the directory where main.py is located
        if getattr(sys, 'frozen', False):
            # If running as compiled executable
            app_dir = os.path.dirname(sys.executable)
        else:
            # If running as script, go up two levels from modules/command_executor.py
            current_file_dir = os.path.dirname(os.path.abspath(__file__))  # modules/
            app_dir = os.path.dirname(current_file_dir)  # project root
        
        # Option 1: Place in the same directory as your main application
        apm_path_option1 = os.path.join(app_dir, "apmplanner")
        
        # Option 2: Place in a dedicated tools directory
        tools_dir = os.path.join(app_dir, "tools", "apmplanner")
        
        # Check paths in order of preference
        for path in [apm_path_option1, tools_dir]:
            if os.path.exists(path):
                print(f"Found APM Planner at: {path}")
                return path
        
        # Default to the first option if none found
        print(f"APM Planner not found, will use default path: {apm_path_option1}")
        return apm_path_option1
    
    @pyqtSlot(result=bool)
    def isTiNariRunning(self):
        """Check if Ti-NARI (APM Planner) is currently running"""
        return self._is_running
    
    @pyqtSlot()
    def executeTiNariCommands(self):
        """Execute the Ti-NARI commands (APM Planner startup)"""
        if self._is_running:
            self.commandOutput.emit("Ti-NARI is already running!")
            return
        
        # Check if APM Planner exists
        apm_executable = self._get_apm_executable_path()
        if not os.path.exists(apm_executable):
            error_msg = f"APM Planner executable not found at: {apm_executable}"
            print(error_msg)
            self.commandOutput.emit(error_msg)
            self.commandFinished.emit(False, error_msg)
            return
        
        # Start the execution
        self._execute_commands()
    
    def _get_apm_executable_path(self):
        """Get the full path to the APM Planner executable"""
        build_release_dir = os.path.join(self.apm_planner_base_path, "build-release")
        return os.path.join(build_release_dir, "release", "apmplanner2")
    
    def _execute_commands(self):
        """Execute APM Planner commands"""
        self._is_running = True
        self.commandStarted.emit()
        
        try:
            # Store original directory
            original_cwd = os.getcwd()
            
            # Step 1: cd apmplanner
            apm_dir = self.apm_planner_base_path
            self.commandOutput.emit(f"Changing to directory: {apm_dir}")
            os.chdir(apm_dir)
            
            # Step 2: cd build-release
            build_release_dir = os.path.join(apm_dir, "build-release")
            self.commandOutput.emit(f"Changing to build-release directory: {build_release_dir}")
            os.chdir(build_release_dir)
            
            # Step 3: ./release/apmplanner2
            executable_path = "./release/apmplanner2"
            self.commandOutput.emit(f"Starting APM Planner: {executable_path}")
            
            # Start APM Planner process
            self._process = subprocess.Popen(
                [executable_path],
                cwd=build_release_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                start_new_session=True  # This prevents the process from being killed when parent exits
            )
            
            # Restore original directory
            os.chdir(original_cwd)
            
            # Wait a moment to see if it starts successfully
            QTimer.singleShot(2000, self._check_process_status)
            
        except FileNotFoundError as e:
            error_msg = f"APM Planner executable not found: {str(e)}"
            print(error_msg)
            self.commandOutput.emit(error_msg)
            self._cleanup_and_finish(False, error_msg)
            try:
                os.chdir(original_cwd)
            except:
                pass
            
        except PermissionError as e:
            error_msg = f"Permission denied executing APM Planner: {str(e)}\nTry running: chmod +x {self._get_apm_executable_path()}"
            print(error_msg)
            self.commandOutput.emit(error_msg)
            self._cleanup_and_finish(False, error_msg)
            try:
                os.chdir(original_cwd)
            except:
                pass
            
        except Exception as e:
            error_msg = f"Error starting APM Planner: {str(e)}"
            print(error_msg)
            self.commandOutput.emit(error_msg)
            self._cleanup_and_finish(False, error_msg)
            try:
                os.chdir(original_cwd)
            except:
                pass
    
    def _check_process_status(self):
        """Check if the process started successfully"""
        if self._process is None:
            self._cleanup_and_finish(False, "Process failed to start")
            return
        
        # Check if process is still running
        poll_result = self._process.poll()
        
        if poll_result is None:
            # Process is still running - success!
            success_msg = "APM Planner started successfully"
            print(success_msg)
            self.commandOutput.emit(success_msg)
            self._cleanup_and_finish(True, success_msg)
        else:
            # Process exited - check exit code
            if poll_result == 0:
                success_msg = "APM Planner completed successfully"
                print(success_msg)
                self.commandOutput.emit(success_msg)
                self._cleanup_and_finish(True, success_msg)
            else:
                error_msg = f"APM Planner exited with code: {poll_result}"
                print(error_msg)
                self.commandOutput.emit(error_msg)
                
                # Try to get error output
                try:
                    stderr_output = self._process.stderr.read().decode('utf-8')
                    if stderr_output:
                        print(f"Error output: {stderr_output}")
                        self.commandOutput.emit(f"Error output: {stderr_output}")
                except:
                    pass
                
                self._cleanup_and_finish(False, error_msg)
    
    def _cleanup_and_finish(self, success, message):
        """Clean up and emit finished signal"""
        self._is_running = False
        if success:
            # Don't clear the process reference if successful, as APM Planner should keep running
            pass
        else:
            self._process = None
        self.commandFinished.emit(success, message)
    
    @pyqtSlot()
    def stopExecution(self):
        """Stop the current execution"""
        if self._process and self._process.poll() is None:
            try:
                self._process.terminate()
                self.commandOutput.emit("APM Planner process terminated")
            except:
                pass
        
        self._cleanup_and_finish(False, "Execution stopped by user")
    
    def cleanup(self):
        """Clean up resources"""
        if self._process and self._process.poll() is None:
            try:
                self._process.terminate()
            except:
                pass
        self._process = None
        self._is_running = False