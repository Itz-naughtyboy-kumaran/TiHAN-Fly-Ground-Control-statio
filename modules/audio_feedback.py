# audio_feedback.py - ArduPilot Audio Feedback Handler
from PyQt5.QtCore import QObject, pyqtSlot
import sys

# Try to import audio libraries (install with: pip install playsound pygame)
try:
    import pygame
    pygame.mixer.init()
    PYGAME_AVAILABLE = True
except ImportError:
    PYGAME_AVAILABLE = False
    print("pygame not available - using console audio feedback")

try:
    from playsound import playsound
    PLAYSOUND_AVAILABLE = True
except ImportError:
    PLAYSOUND_AVAILABLE = False

class AudioFeedbackHandler(QObject):
    """
    Handles audio feedback for ArduPilot compass calibration
    Supports multiple audio backends and fallback to console output
    """
    
    def __init__(self):
        super().__init__()
        self.audio_enabled = True
        self.volume = 0.7
        
        # Initialize audio system
        self._initialize_audio()
        
        # Sound file paths (you would add actual .wav/.mp3 files here)
        self.sound_files = {
            "startup": "sounds/startup_tone.wav",      # Single tone
            "beep": "sounds/progress_beep.wav",        # Short beep 
            "success": "sounds/success_tones.wav",     # 3 rising tones
            "failure": "sounds/failure_tone.wav",      # Unhappy tone
            "cancelled": "sounds/cancel_tone.wav"      # Cancellation tone
        }
        
        print(f"Audio feedback initialized - pygame: {PYGAME_AVAILABLE}, playsound: {PLAYSOUND_AVAILABLE}")

    def _initialize_audio(self):
        """Initialize the audio system"""
        if PYGAME_AVAILABLE:
            try:
                pygame.mixer.set_num_channels(8)  # Allow multiple simultaneous sounds
                pygame.mixer.set_reserved(1)     # Reserve channel for important sounds
                print("Pygame audio system initialized")
            except Exception as e:
                print(f"Failed to initialize pygame audio: {e}")

    @pyqtSlot(str)
    def play_sound(self, sound_type):
        """
        Play audio feedback sound
        
        Args:
            sound_type (str): Type of sound ('startup', 'beep', 'success', 'failure', 'cancelled')
        """
        if not self.audio_enabled:
            return
            
        print(f"🔊 Playing audio: {sound_type}")
        
        # Try different audio backends
        if self._play_with_pygame(sound_type):
            return
        elif self._play_with_playsound(sound_type):
            return
        else:
            self._play_console_feedback(sound_type)

    def _play_with_pygame(self, sound_type):
        """Try to play sound using pygame"""
        if not PYGAME_AVAILABLE:
            return False
            
        try:
            # For demonstration, generate tones programmatically
            # In real implementation, you would load .wav files
            
            if sound_type == "startup":
                self._generate_tone(800, 0.5)  # 800Hz for 0.5 seconds
                
            elif sound_type == "beep":
                self._generate_tone(1000, 0.1)  # 1000Hz for 0.1 seconds
                
            elif sound_type == "success":
                # Three rising tones
                self._generate_tone(600, 0.3)
                pygame.time.wait(100)
                self._generate_tone(800, 0.3)  
                pygame.time.wait(100)
                self._generate_tone(1000, 0.3)
                
            elif sound_type == "failure":
                # Descending unhappy tone
                self._generate_tone(400, 0.8)
                
            elif sound_type == "cancelled":
                # Quick descending tone
                self._generate_tone(600, 0.2)
                pygame.time.wait(50)
                self._generate_tone(400, 0.2)
                
            return True
            
        except Exception as e:
            print(f"Pygame audio failed: {e}")
            return False

    def _generate_tone(self, frequency, duration):
        """Generate a tone using pygame"""
        if not PYGAME_AVAILABLE:
            return
            
        try:
            import numpy as np
            
            # Generate sine wave
            sample_rate = 22050
            frames = int(duration * sample_rate)
            arr = np.zeros((frames, 2))
            
            for i in range(frames):
                time_point = float(i) / sample_rate
                wave = 4096 * np.sin(frequency * 2 * np.pi * time_point)
                arr[i] = [wave, wave]
            
            # Convert to pygame sound
            arr = arr.astype(np.int16)
            sound = pygame.sndarray.make_sound(arr)
            sound.set_volume(self.volume)
            
            # Play sound
            channel = pygame.mixer.find_channel()
            if channel:
                channel.play(sound)
                pygame.time.wait(int(duration * 1000))
            
        except Exception as e:
            print(f"Tone generation failed: {e}")

    def _play_with_playsound(self, sound_type):
        """Try to play sound using playsound library"""
        if not PLAYSOUND_AVAILABLE:
            return False
            
        try:
            sound_file = self.sound_files.get(sound_type)
            if sound_file:
                # Check if file exists
                import os
                if os.path.exists(sound_file):
                    playsound(sound_file, block=False)
                    return True
                else:
                    print(f"Sound file not found: {sound_file}")
                    return False
            
        except Exception as e:
            print(f"Playsound failed: {e}")
            return False

    def _play_console_feedback(self, sound_type):
        """Fallback console audio feedback"""
        console_sounds = {
            "startup": "♪ BEEP (Calibration Started)",
            "beep": "♪ beep",
            "success": "♪♪♪ BEEP-BEEP-BEEP (Success!)",
            "failure": "♪ bwaaah (Failed)", 
            "cancelled": "♪ beep-boop (Cancelled)"
        }
        
        sound_text = console_sounds.get(sound_type, f"♪ {sound_type}")
        print(f"🔊 AUDIO: {sound_text}")
        
        # On Windows, try to use system beep
        if sys.platform == "win32":
            try:
                import winsound
                if sound_type == "startup":
                    winsound.Beep(800, 500)
                elif sound_type == "beep":
                    winsound.Beep(1000, 100)
                elif sound_type == "success":
                    winsound.Beep(600, 300)
                    winsound.Beep(800, 300)
                    winsound.Beep(1000, 300)
                elif sound_type == "failure":
                    winsound.Beep(400, 800)
                elif sound_type == "cancelled":
                    winsound.Beep(600, 200)
                    winsound.Beep(400, 200)
            except ImportError:
                pass  # winsound not available

    def set_volume(self, volume):
        """Set audio volume (0.0 to 1.0)"""
        self.volume = max(0.0, min(1.0, volume))
        print(f"Audio volume set to: {self.volume * 100:.0f}%")

    def set_enabled(self, enabled):
        """Enable or disable audio feedback"""
        self.audio_enabled = enabled
        print(f"Audio feedback {'enabled' if enabled else 'disabled'}")

    def test_all_sounds(self):
        """Test all available sounds"""
        print("Testing all audio feedback sounds...")
        
        sounds = ["startup", "beep", "success", "failure", "cancelled"]
        
        for sound in sounds:
            print(f"Testing: {sound}")
            self.play_sound(sound)
            
            # Wait between sounds
            if PYGAME_AVAILABLE:
                pygame.time.wait(1000)
            else:
                import time
                time.sleep(1)

# Example usage and integration class
class CompassCalibrationAudioManager(QObject):
    """
    Manager class that integrates audio feedback with compass calibration
    """
    
    def __init__(self, compass_model):
        super().__init__()
        self.compass_model = compass_model
        self.audio_handler = AudioFeedbackHandler()
        
        # Connect to compass calibration signals
        if compass_model:
            compass_model.audioFeedbackRequested.connect(self.audio_handler.play_sound)
            print("Audio feedback connected to compass calibration model")
    
    def setup_audio_preferences(self):
        """Setup audio preferences from settings"""
        # In a real application, you would load these from settings
        self.audio_handler.set_volume(0.7)
        self.audio_handler.set_enabled(True)
    
    def test_audio_system(self):
        """Test the audio system"""
        print("Testing ArduPilot compass calibration audio system...")
        self.audio_handler.test_all_sounds()

# Sound file creation helper (for development)
def create_demo_sound_files():
    """
    Create demo sound files using pygame/numpy
    This would be run once to generate the sound files
    """
    if not PYGAME_AVAILABLE:
        print("Cannot create sound files - pygame not available")
        return
    
    try:
        import numpy as np
        import os
        
        # Create sounds directory
        os.makedirs("sounds", exist_ok=True)
        
        sample_rate = 22050
        
        def save_tone(filename, frequency, duration, fade_in=0, fade_out=0):
            """Save a tone to a WAV file"""
            frames = int(duration * sample_rate)
            arr = np.zeros((frames, 2))
            
            for i in range(frames):
                time_point = float(i) / sample_rate
                amplitude = 4096
                
                # Apply fade in/out
                if fade_in > 0 and time_point < fade_in:
                    amplitude *= time_point / fade_in
                if fade_out > 0 and time_point > (duration - fade_out):
                    amplitude *= (duration - time_point) / fade_out
                
                wave = amplitude * np.sin(frequency * 2 * np.pi * time_point)
                arr[i] = [wave, wave]
            
            # Convert to int16 and save
            arr = arr.astype(np.int16)
            sound = pygame.sndarray.make_sound(arr)
            
            # Save as WAV file
            pygame.mixer.save(sound, filename)
            print(f"Created: {filename}")
        
        # Create startup tone (single tone)
        save_tone("sounds/startup_tone.wav", 800, 0.5, fade_out=0.1)
        
        # Create progress beep (short beep)
        save_tone("sounds/progress_beep.wav", 1000, 0.1, fade_in=0.01, fade_out=0.01)
        
        # Create failure tone (descending)
        frames = int(0.8 * sample_rate)
        arr = np.zeros((frames, 2))
        for i in range(frames):
            time_point = float(i) / sample_rate
            frequency = 600 - (200 * time_point / 0.8)  # Descend from 600 to 400 Hz
            amplitude = 4096 * (1 - time_point / 0.8) * 0.5  # Fade out
            wave = amplitude * np.sin(frequency * 2 * np.pi * time_point)
            arr[i] = [wave, wave]
        
        arr = arr.astype(np.int16)
        sound = pygame.sndarray.make_sound(arr)
        pygame.mixer.save(sound, "sounds/failure_tone.wav")
        print("Created: sounds/failure_tone.wav")
        
        # Create cancellation tone (quick descending)
        save_tone("sounds/cancel_tone.wav", 600, 0.2, fade_out=0.05)
        
        # Create success tones (three rising tones) - this would be more complex
        # For now, just create a simple ascending tone
        frames = int(0.9 * sample_rate)
        arr = np.zeros((frames, 2))
        for i in range(frames):
            time_point = float(i) / sample_rate
            # Three distinct frequency regions
            if time_point < 0.3:
                frequency = 600
            elif time_point < 0.6:
                frequency = 800  
            else:
                frequency = 1000
            
            amplitude = 4096 * 0.7
            wave = amplitude * np.sin(frequency * 2 * np.pi * time_point)
            arr[i] = [wave, wave]
        
        arr = arr.astype(np.int16)
        sound = pygame.sndarray.make_sound(arr)
        pygame.mixer.save(sound, "sounds/success_tones.wav")
        print("Created: sounds/success_tones.wav")
        
        print("\nDemo sound files created successfully!")
        print("You can now use the audio feedback system with actual sound files.")
        
    except Exception as e:
        print(f"Failed to create demo sound files: {e}")

# Usage example
if __name__ == "__main__":
    # This would be called from your main application
    
    # Test audio system
    audio = AudioFeedbackHandler()
    audio.test_all_sounds()
    
    # Optionally create demo sound files
    # create_demo_sound_files()
    
    print("\nArduPilot Audio Feedback System Ready!")
    print("Connect this to your compass calibration model using:")
    print("compass_model.audioFeedbackRequested.connect(audio_handler.play_sound)")
