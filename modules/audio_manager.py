class AudioManager:
    """Handles audio playback for trial warnings"""
    def __init__(self):
        try:
            import pygame
            pygame.mixer.init()
            self.audio_enabled = True
            self.pygame = pygame
        except ImportError:
            print("Pygame not available - continuing without audio")
            self.audio_enabled = False
    
    def play_trial_warning(self, seconds_left):
        """Play trial warning message"""
        if not self.audio_enabled:
            return
        
        try:
            # Create a simple beep sound
            frequency = 800  # Hz
            duration = 0.5   # seconds
            sample_rate = 22050
            frames = int(duration * sample_rate)
            arr = []
            for i in range(frames):
                wave = 4096 * math.sin(frequency * 2 * math.pi * i / sample_rate)
                arr.append([int(wave), int(wave)])
            
            sound = self.pygame.sndarray.make_sound(arr)
            sound.play()
            
            print(f"⚠️ TRIAL WARNING: Your trial version will expire in {seconds_left} seconds!")
            print("Please subscribe to continue using the application.")
            
        except Exception as e:
            print(f"Audio playback error: {e}")
