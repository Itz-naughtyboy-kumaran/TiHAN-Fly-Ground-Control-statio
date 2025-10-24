import math
from PyQt5.QtCore import QObject, pyqtSignal, pyqtProperty
from pymavlink import mavutil


class Telemetry(QObject):
    rollChanged = pyqtSignal()
    pitchChanged = pyqtSignal()
    yawChanged = pyqtSignal()
    groundspeedChanged = pyqtSignal()
    airspeedChanged = pyqtSignal()
    altitudeChanged = pyqtSignal()
    latitudeChanged = pyqtSignal()  # Added for GPS
    longitudeChanged = pyqtSignal()  # Added for GPS

    def __init__(self):
        super().__init__()
        self._roll = 0.0
        self._pitch = 0.0
        self._yaw = 0.0
        self._groundspeed = 0.0
        self._airspeed = 0.0
        self._altitude = 0.0
        self._latitude = 0.0  # Added for GPS
        self._longitude = 0.0  # Added for GPS

    @pyqtProperty(float, notify=rollChanged)
    def roll(self):
        return self._roll
    
    @roll.setter
    def roll(self, val):
        if self._roll != val:
            self._roll = val
            self.rollChanged.emit()

    @pyqtProperty(float, notify=pitchChanged)
    def pitch(self):
        return self._pitch
    
    @pitch.setter
    def pitch(self, val):
        if self._pitch != val:
            self._pitch = val
            self.pitchChanged.emit()

    @pyqtProperty(float, notify=yawChanged)
    def yaw(self):
        return self._yaw
    
    @yaw.setter
    def yaw(self, val):
        if self._yaw != val:
            self._yaw = val
            self.yawChanged.emit()

    @pyqtProperty(float, notify=groundspeedChanged)
    def groundspeed(self):
        return self._groundspeed
    
    @groundspeed.setter
    def groundspeed(self, val):
        if self._groundspeed != val:
            self._groundspeed = val
            self.groundspeedChanged.emit()

    @pyqtProperty(float, notify=airspeedChanged)
    def airspeed(self):
        return self._airspeed
    
    @airspeed.setter
    def airspeed(self, val):
        if self._airspeed != val:
            self._airspeed = val
            self.airspeedChanged.emit()

    @pyqtProperty(float, notify=altitudeChanged)
    def altitude(self):
        return self._altitude
    
    @altitude.setter
    def altitude(self, val):
        if self._altitude != val:
            self._altitude = val
            self.altitudeChanged.emit()

    @pyqtProperty(float, notify=latitudeChanged)
    def latitude(self):
        return self._latitude
    
    @latitude.setter
    def latitude(self, val):
        if self._latitude != val:
            self._latitude = val
            self.latitudeChanged.emit()

    @pyqtProperty(float, notify=longitudeChanged)
    def longitude(self):
        return self._longitude
    
    @longitude.setter
    def longitude(self, val):
        if self._longitude != val:
            self._longitude = val
            self.longitudeChanged.emit()
    
   

#class MAVLinkThread(QThread):
    telemetryUpdated = pyqtSignal(dict)
    statusTextChanged = pyqtSignal(str)

    def __init__(self, drone):
        super().__init__()
        self.drone = drone
        self.running = True
        self.current_telemetry_components = {
            'mode': "UNKNOWN", 'armed': False,
            'lat': None, 'lon': None, 'alt': None, 'rel_alt': None,
            'roll': None, 'pitch': None, 'yaw': None,
            'heading': None,
            'groundspeed': 0.0, 'airspeed': 0.0
        }
        print("[MAVLinkThread] Initialized (Event-driven).")

    def run(self):
        print("[MAVLinkThread] Thread started. Continuously listening for MAVLink messages...")
        while self.running:
            # Try to receive a message without blocking, or with a very minimal timeout
            msg = self.drone.recv_match(blocking=False, timeout=1)
            
            if msg:
                msg_type = msg.get_type()
                msg_dict = msg.to_dict()
                
                telemetry_component_changed = False

                if msg_type == "HEARTBEAT":
                    mode_map = self.drone.mode_mapping()
                    inv_mode_map = {v: k for k, v in mode_map.items()}
                    new_mode = inv_mode_map.get(msg_dict['custom_mode'], "UNKNOWN")
                    new_armed_status = bool(msg_dict['base_mode'] & mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED)
                    if self.current_telemetry_components['mode'] != new_mode:
                        self.current_telemetry_components['mode'] = new_mode
                        telemetry_component_changed = True
                    if self.current_telemetry_components['armed'] != new_armed_status:
                        self.current_telemetry_components['armed'] = new_armed_status
                        telemetry_component_changed = True

                elif msg_type == "GLOBAL_POSITION_INT":
                    new_lat = msg_dict['lat'] / 1e7
                    new_lon = msg_dict['lon'] / 1e7
                    new_alt = msg_dict['alt'] / 1000.0
                    new_rel_alt = msg_dict['relative_alt'] / 1000.0

                    if (self.current_telemetry_components['lat'] != new_lat or
                        self.current_telemetry_components['lon'] != new_lon or
                        self.current_telemetry_components['alt'] != new_alt or
                        self.current_telemetry_components['rel_alt'] != new_rel_alt):
                        
                        self.current_telemetry_components.update({
                            'lat': new_lat,
                            'lon': new_lon,
                            'alt': new_alt,
                            'rel_alt': new_rel_alt
                        })
                        telemetry_component_changed = True

                elif msg_type == "ATTITUDE":
                    new_roll = math.degrees(msg_dict['roll'])
                    new_pitch = math.degrees(msg_dict['pitch'])
                    new_yaw = math.degrees(msg_dict['yaw'])
                    if (self.current_telemetry_components['roll'] != new_roll or
                        self.current_telemetry_components['pitch'] != new_pitch or
                        self.current_telemetry_components['yaw'] != new_yaw):
                        self.current_telemetry_components.update({
                            'roll': new_roll,
                            'pitch': new_pitch,
                            'yaw': new_yaw,
                        })
                        telemetry_component_changed = True

                elif msg_type == "VFR_HUD":
                    new_heading = msg_dict['heading']
                    new_groundspeed = msg_dict['groundspeed']
                    new_airspeed = msg_dict['airspeed']
                    
                    if (self.current_telemetry_components['heading'] != new_heading or
                        self.current_telemetry_components['groundspeed'] != new_groundspeed or
                        self.current_telemetry_components['airspeed'] != new_airspeed):
                        self.current_telemetry_components.update({
                            'heading': new_heading,
                            'groundspeed': new_groundspeed,
                            'airspeed': new_airspeed,
                        })
                        telemetry_component_changed = True

                elif msg_type == "STATUSTEXT":
                    self.statusTextChanged.emit(msg.text)

                if telemetry_component_changed:
                    self.telemetryUpdated.emit(self.current_telemetry_components.copy())

            

            else:
                self.msleep(250) # Yield control briefly

    def stop(self):
        print("[MAVLinkThread] Stopping thread...")
        self.running = False
        self.quit()
        self.wait()
        print("[MAVLinkThread] Thread stopped.")

