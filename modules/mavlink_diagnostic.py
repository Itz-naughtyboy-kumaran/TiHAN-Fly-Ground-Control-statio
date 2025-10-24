# mavlink_diagnostic.py - Check what messages your drone sends
import time
from collections import defaultdict

def diagnose_mavlink_messages(drone_connection, duration=10):
    """
    Diagnose what MAVLink messages are being received from the drone
    """
    print(f"[MAVLink Diagnostic] Monitoring messages for {duration} seconds...")
    
    message_counts = defaultdict(int)
    magnetometer_sources = []
    
    start_time = time.time()
    
    while time.time() - start_time < duration:
        try:
            # Get any message
            msg = drone_connection.recv_match(blocking=False, timeout=0.1)
            
            if msg:
                msg_type = msg.get_type()
                message_counts[msg_type] += 1
                
                # Check for magnetometer data in various message types
                if msg_type == 'RAW_IMU':
                    if hasattr(msg, 'xmag') and hasattr(msg, 'ymag') and hasattr(msg, 'zmag'):
                        magnetometer_sources.append({
                            'type': 'RAW_IMU',
                            'x': msg.xmag,
                            'y': msg.ymag,
                            'z': msg.zmag,
                            'timestamp': time.time()
                        })
                        
                elif msg_type == 'SCALED_IMU':
                    if hasattr(msg, 'xmag') and hasattr(msg, 'ymag') and hasattr(msg, 'zmag'):
                        magnetometer_sources.append({
                            'type': 'SCALED_IMU',
                            'x': msg.xmag,
                            'y': msg.ymag,
                            'z': msg.zmag,
                            'timestamp': time.time()
                        })
                        
                elif msg_type == 'SCALED_IMU2':
                    if hasattr(msg, 'xmag') and hasattr(msg, 'ymag') and hasattr(msg, 'zmag'):
                        magnetometer_sources.append({
                            'type': 'SCALED_IMU2',
                            'x': msg.xmag,
                            'y': msg.ymag,
                            'z': msg.zmag,
                            'timestamp': time.time()
                        })
                        
                elif msg_type == 'SCALED_IMU3':
                    if hasattr(msg, 'xmag') and hasattr(msg, 'ymag') and hasattr(msg, 'zmag'):
                        magnetometer_sources.append({
                            'type': 'SCALED_IMU3',
                            'x': msg.xmag,
                            'y': msg.ymag,
                            'z': msg.zmag,
                            'timestamp': time.time()
                        })
                        
                elif msg_type == 'HIGHRES_IMU':
                    if hasattr(msg, 'xmag') and hasattr(msg, 'ymag') and hasattr(msg, 'zmag'):
                        magnetometer_sources.append({
                            'type': 'HIGHRES_IMU',
                            'x': msg.xmag,
                            'y': msg.ymag,
                            'z': msg.zmag,
                            'timestamp': time.time()
                        })
                        
                elif msg_type == 'ATTITUDE':
                    # Some systems provide compass heading in ATTITUDE message
                    if hasattr(msg, 'yaw'):
                        print(f"[MAVLink Diagnostic] ATTITUDE yaw: {msg.yaw} radians ({msg.yaw * 57.3:.1f} degrees)")
                        
        except Exception as e:
            print(f"[MAVLink Diagnostic] Error: {e}")
            time.sleep(0.01)
    
    # Print results
    print(f"\n[MAVLink Diagnostic] Results after {duration} seconds:")
    print("=" * 50)
    
    print(f"Total message types received: {len(message_counts)}")
    print("\nMessage counts:")
    for msg_type, count in sorted(message_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"  {msg_type}: {count}")
    
    print(f"\nMagnetometer data sources found: {len(magnetometer_sources)}")
    if magnetometer_sources:
        print("\nMagnetometer data samples:")
        for i, sample in enumerate(magnetometer_sources[-5:]):  # Show last 5 samples
            print(f"  {sample['type']}: X={sample['x']:.1f}, Y={sample['y']:.1f}, Z={sample['z']:.1f}")
    else:
        print("❌ NO MAGNETOMETER DATA FOUND!")
        print("\nPossible solutions:")
        print("1. Check if your drone has a compass/magnetometer")
        print("2. Enable magnetometer in autopilot parameters")
        print("3. Check MAVLink stream rates")
        print("4. Try requesting specific messages")
    
    return message_counts, magnetometer_sources

# Add this method to your CompassCalibrationModel class
def run_diagnostic(self):
    """Run MAVLink diagnostic to find magnetometer data"""
    if not self.isDroneConnected or not self._drone_model.drone_connection:
        print("[CompassCalibrationModel] Cannot run diagnostic - drone not connected")
        return
    
    print("[CompassCalibrationModel] Running MAVLink diagnostic...")
    message_counts, mag_sources = diagnose_mavlink_messages(self._drone_model.drone_connection)
    
    if mag_sources:
        # Found magnetometer data - update the reading method
        best_source = max(set(s['type'] for s in mag_sources), 
                         key=lambda x: sum(1 for s in mag_sources if s['type'] == x))
        print(f"[CompassCalibrationModel] Best magnetometer source: {best_source}")
        
        # Update the magnetometer reading method to use the found source
        self._magnetometer_message_type = best_source
    else:
        print("[CompassCalibrationModel] No magnetometer data found - checking alternatives...")
        self._check_alternative_sources(message_counts)