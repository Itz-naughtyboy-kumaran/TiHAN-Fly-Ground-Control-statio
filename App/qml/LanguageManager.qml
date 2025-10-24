// Complete Updated LanguageManager.qml with all translations
import QtQuick 2.15
import QtQuick.Controls 2.15

QtObject {
    id: languageManager
    
    // Current language property
    property string currentLanguage: "en"
    
    // Available languages
    property var availableLanguages: [
        { code: "en", name: "English", nativeName: "English" },
        { code: "ta", name: "Tamil", nativeName: "தமிழ்" },
        { code: "hi", name: "Hindi", nativeName: "हिन्दी" },
        { code: "te", name: "Telugu", nativeName: "తెలుగు" }
    ]
    
    // Translation strings object
    property var translations: ({
        // Connection Bar
        "CONNECT": {
            "en": "CONNECT",
            "ta": "இணைக்க",
            "hi": "कनेक्ट",
            "te": "కనెక్ట్"
        },
        "DISCONNECT": {
            "en": "DISCONNECT",
            "ta": "துண்டிக்க",
            "hi": "डिस्कनेक्ट",
            "te": "డిస్‌కనెక్ట్"
        },
        "CONNECTED": {
            "en": "CONNECTED",
            "ta": "இணைக்கப்பட்டது",
            "hi": "जुड़ा हुआ",
            "te": "కనెక్ట్ చేయబడింది"
        },
        "DISCONNECTED": {
            "en": "DISCONNECTED",
            "ta": "துண்டிக்கப்பட்டது",
            "hi": "डिस्कनेक्ट किया गया",
            "te": "డిస్‌కనెక్ట్ చేయబడింది"
        },
        
        // Control Buttons
        "TAKEOFF": {
            "en": "TAKEOFF",
            "ta": "புறப்பாடு",
            "hi": "टेकऑफ",
            "te": "టేకాఫ్"
        },
        "LAND": {
            "en": "LAND",
            "ta": "தரையிறங்கு",
            "hi": "लैंड",
            "te": "ల్యాండ్"
        },
        "SETTINGS": {
            "en": "SETTINGS",
            "ta": "அமைப்புகள்",
            "hi": "सेटिंग्स",
            "te": "సెట్టింగ్స్"
        },
        "Ti-NARI": {
            "en": "Ti-NARI",
            "ta": "டி-நாரி",
            "hi": "टी-नारी",
            "te": "టి-నారి"
        },
        
        // ARM/DISARM States
        "ARMED": {
            "en": "ARMED",
            "ta": "ஆயுதம் கொண்ட",
            "hi": "सशस्त्र",
            "te": "ఆయుధధారి"
        },
        "Flight Mode": {
            "en": "Flight Mode",
            "ta": "பறக்கும் முறை",
            "hi": "फ्लाइट मोड",
            "te": "ఫ్లైట్ మోడ్"
        },
        "DISARMED": {
            "en": "DISARMED",
            "ta": "ஆயுதம் இல்லாத",
            "hi": "निरस्त्र",
            "te": "నిరాయుధ"
        },
        "ERROR": {
            "en": "ERROR",
            "ta": "பிழை",
            "hi": "त्रुटि",
            "te": "దోషం"
        },
        "Message": {
            "en": "Message",
            "ta": "செய்தி",
            "hi": "संदेश",
            "te": "సందేశం"
        },
        "Mode Changed": {
            "en": "Mode Changed",
            "ta": "பயன்முறை மாற்றப்பட்டது",
            "hi": "मोड बदला गया",
            "te": "మోడ్ మార్చబడింది"
        },
        "Mode changed to": {
            "en": "Mode changed to",
            "ta": "பயன்முறை மாற்றப்பட்டது",
            "hi": "मोड में बदल गया",
            "te": "మోడ్ కు మార్చబడింది"
        },
        "Drone Armed Successfully": {
            "en": "Drone Armed Successfully",
            "ta": "ட்ரோன் வெற்றிகரமாக ஆயுதம் செய்யப்பட்டது",
            "hi": "ड्रोन सफलतापूर्वक सशस्त्र",
            "te": "డ్రోన్ విజయవంతంగా ఆయుధధారిగా చేయబడింది"
        },
        "Drone Disarmed Successfully": {
            "en": "Drone Disarmed Successfully",
            "ta": "ட்ரோன் வெற்றிகரமாக ஆयுதம் நீக்கப்பட்டது",
            "hi": "ड्रोन सफलतापूर्वक निरस्त्र",
            "te": "డ్రోన్ విజయవంతంగా నిరాయుధీకరించబడింది"
        },
        "Select flight mode": {
            "en": "Select flight mode",
            "ta": "பறக்கும் பயன்முறையைத் தேர்ந்தெடுக்கவும்",
            "hi": "फ्लाइट मोड चुनें",
            "te": "ఫ్లైట్ మోడ్‌ను ఎంచుకోండి"
        },
        "Connect to drone first": {
            "en": "Connect to drone first",
            "ta": "முதலில் ட்ரோனுடன் இணைக்கவும்",
            "hi": "पहले ड्रोन से कनेक्ट करें",
            "te": "మొదట డ్రోన్‌కు కనెక్ట్ చేయండి"
        },
        
        // Menu Items
        "Waypoints": {
            "en": "Waypoints",
            "ta": "வழிப்புள்ளிகள்",
            "hi": "वेपॉइंट्स",
            "te": "వేపాయింట్స్"
        },
        "Parameters": {
            "en": "Parameters",
            "ta": "அளவுருக்கள்",
            "hi": "पैरामीटर",
            "te": "పారామీటర్లు"
        },
        "Calibrations": {
            "en": "Calibrations",
            "ta": "அளவீட்டுகள்",
            "hi": "कैलिब्रेशन",
            "te": "కాలిబ్రేషన్స్"
        },
        
        // Mission Upload Section
        "Mission Upload": {
            "en": "Mission Upload",
            "ta": "பணி பதிவேற்றம்",
            "hi": "मिशन अपलोड",
            "te": "మిషన్ అప్‌లోడ్"
        },
        "Add": {
            "en": "Add",
            "ta": "சேர்க்க",
            "hi": "जोड़ना",
            "te": "జోడించు"
        },
        "Send": {
            "en": "Send",
            "ta": "அனுப்ப",
            "hi": "भेजना",
            "te": "పంపు"
        },
        "Clear": {
            "en": "Clear",
            "ta": "அழி",
            "hi": "साफ़ करना",
            "te": "క్లియర్"
        },
        
        // Weather Dashboard
        "Weather Info": {
            "en": "Weather Info",
            "ta": "வானிலை தகவல்",
            "hi": "मौसम की जानकारी",
            "te": "వాతావరణ సమాచారం"
        },
        "Unknown Location": {
            "en": "Unknown Location",
            "ta": "அறியப்படாத இடம்",
            "hi": "अज्ञात स्थान",
            "te": "తెలియని ప్రాంతం"
        },
        "Loading weather data...": {
            "en": "Loading weather data...",
            "ta": "வானிலை தரவுகளை ஏற்றுகிறது...",
            "hi": "मौसम डेटा लोड हो रहा है...",
            "te": "వాతావరణ డేటా లోడ్ అవుతోంది..."
        },
        "Loading...": {
            "en": "Loading...",
            "ta": "ஏற்றுகிறது...",
            "hi": "लोड हो रहा है...",
            "te": "లోడ్ అవుతోంది..."
        },
        "Wind": {
            "en": "Wind",
            "ta": "காற்று",
            "hi": "हवा",
            "te": "గాలి"
        },
        "Humidity": {
            "en": "Humidity",
            "ta": "ஈரப்பதம்",
            "hi": "आर्द्रता",
            "te": "తేమ"
        },
        "Pressure": {
            "en": "Pressure",
            "ta": "அழுத்தம்",
            "hi": "दबाव",
            "te": "ఒత్తిడి"
        },
        "Visibility": {
            "en": "Visibility",
            "ta": "தெரிவுநிலை",
            "hi": "दृश्यता",
            "te": "దృశ్యత"
        },
        "UV Index": {
            "en": "UV Index",
            "ta": "UV குறியீடு",
            "hi": "UV इंडेक्स",
            "te": "UV ఇండెక్స్"
        },
        "Cloud Cover": {
            "en": "Cloud Cover",
            "ta": "மேகத்திருத்து",
            "hi": "बादल",
            "te": "మేఘ కవచం"
        },
        "Close": {
            "en": "Close",
            "ta": "மூடு",
            "hi": "बंद करें",
            "te": "మూసివేయి"
        },
        "Weather Warning": {
            "en": "Weather Warning",
            "ta": "வானிலை எச்சரிக்கை",
            "hi": "मौसम चेतावनी",
            "te": "వాతావరణ హెచ్చరిక"
        },
        "High Temperature Warning": {
            "en": "High Temperature Warning",
            "ta": "அதிக வெப்பநிலை எச்சரிக்கை",
            "hi": "उच्च तापमान चेतावनी",
            "te": "అధిక ఉష్ణోగ్రత హెచ్చరిక"
        },
        "High Wind Warning": {
            "en": "High Wind Warning",
            "ta": "அதிக காற்று எச்சரிக்கை",
            "hi": "तेज़ हवा चेतावनी",
            "te": "అధిక గాలి హెచ్చరిక"
        },
        
        // Waypoint Dashboard
        "Command Editor": {
            "en": "Command Editor",
            "ta": "கட்டளை திருத்தி",
            "hi": "कमांड एडिटर",
            "te": "కమాండ్ ఎడిటర్"
        },
        "Mission Start": {
            "en": "Mission Start",
            "ta": "பணி தொடக்கம்",
            "hi": "मिशन शुरू",
            "te": "మిషన్ ప్రారంభం"
        },
        "Edit Waypoint": {
            "en": "Edit Waypoint",
            "ta": "வழிப்புள்ளி திருத்து",
            "hi": "वेपॉइंट संपादित करें",
            "te": "వేపాయింట్ సవరించండి"
        },
        "Command": {
            "en": "Command",
            "ta": "கட்டளை",
            "hi": "कमांड",
            "te": "కమాండ్"
        },
        "Waypoint": {
            "en": "Waypoint",
            "ta": "வழிப்புள்ளி",
            "hi": "वेपॉइंट",
            "te": "వేపాయింట్"
        },
        "Takeoff": {
            "en": "Takeoff",
            "ta": "புறப்பாடு",
            "hi": "टेकऑफ",
            "te": "టేకాఫ్"
        },
        "Land": {
            "en": "Land",
            "ta": "தரையிறங்கு",
            "hi": "लैंड",
            "te": "ల్యాండ్"
        },
        "Return to Launch": {
            "en": "Return to Launch",
            "ta": "ஏவுதலுக்கு திரும்பு",
            "hi": "लॉन्च पर वापसी",
            "te": "లాంచ్‌కు తిరిగి రండి"
        },
        "Loiter": {
            "en": "Loiter",
            "ta": "நிறுத்தி வை",
            "hi": "धीमी गति",
            "te": "లోయిటర్"
        },
        "Circle": {
            "en": "Circle",
            "ta": "வட்டம்",
            "hi": "सर्कल",
            "te": "వృత్తం"
        },
        "Follow Me": {
            "en": "Follow Me",
            "ta": "என்னைப் பின்பற்று",
            "hi": "मेरा अनुसरण करें",
            "te": "నన్ను అనుసరించండి"
        },
        "Home": {
            "en": "Home",
            "ta": "வீடு",
            "hi": "घर",
            "te": "హోమ్"
        },
        "Altitude": {
            "en": "Altitude",
            "ta": "உயரம்",
            "hi": "ऊंचाई",
            "te": "ఎత్తు"
        },
        "Speed": {
            "en": "Speed",
            "ta": "வேகம்",
            "hi": "गति",
            "te": "వేగం"
        },
        "Camera": {
            "en": "Camera",
            "ta": "கேமிரா",
            "hi": "कैमरा",
            "te": "కెమెరా"
        },
        "None": {
            "en": "None",
            "ta": "ஏதுமில்லை",
            "hi": "कोई नहीं",
            "te": "ఏమీ లేదు"
        },
        "Photo": {
            "en": "Photo",
            "ta": "புகைப்படம்",
            "hi": "फोटो",
            "te": "ఫోటో"
        },
        "Video": {
            "en": "Video",
            "ta": "வீடியோ",
            "hi": "वीडियो",
            "te": "వీడియో"
        },
        "Survey": {
            "en": "Survey",
            "ta": "ஆய்வு",
            "hi": "सर्वेक्षण",
            "te": "సర్వే"
        },
        "Delete": {
            "en": "Delete",
            "ta": "நீக்கு",
            "hi": "डिलीट",
            "te": "తొలగించు"
        },
        "Apply": {
            "en": "Apply",
            "ta": "பயன்படுத்து",
            "hi": "लागू करें",
            "te": "వర్తింపజేయండి"
        },
        "Mission Command List": {
            "en": "Mission Command List",
            "ta": "பணி கட்டளை பட்டியல்",
            "hi": "मिशन कमांड सूची",
            "te": "మిషన్ కమాండ్ జాబితా"
        },
        
        // Status Panel
        "Ground Speed": {
            "en": "Ground Speed",
            "ta": "தரை வேகம்",
            "hi": "ग्राउंड स्पीड",
            "te": "గ్రౌండ్ స్పీడ్"
        },
        "Yaw": {
            "en": "Yaw",
            "ta": "சுழற்சி",
            "hi": "यॉ",
            "te": "యా"
        },
        "Distance to WP": {
            "en": "Distance to WP",
            "ta": "WP க்கு தூரம்",
            "hi": "WP तक की दूरी",
            "te": "WP కు దూరం"
        },
        "Vertical Speed": {
            "en": "Vertical Speed",
            "ta": "செங்குத்து வேகம்",
            "hi": "वर्टिकल स्पीड",
            "te": "వర్టికల్ స్పీడ్"
        },
        "Distance to MAV": {
            "en": "Distance to MAV",
            "ta": "MAV க்கு தூரம்",
            "hi": "MAV तक की दूरी",
            "te": "MAV కు దూరం"
        },
        
        // Units
        "m": {
            "en": "m",
            "ta": "மீ",
            "hi": "मी",
            "te": "మీ"
        },
        "m/s": {
            "en": "m/s",
            "ta": "மீ/விநாடி",
            "hi": "मी/से",
            "te": "మీ/సె"
        },
        "deg": {
            "en": "deg",
            "ta": "டிகிரி",
            "hi": "डिग्री",
            "te": "డిగ్రీ"
        },

        // Additional Labels
        "RTL": {
            "en": "RTL",
            "ta": "திரும்ப",
            "hi": "वापस",
            "te": "ఆటో రిటర్న్"
        },
        "Battery": {
            "en": "Battery",
            "ta": "மின்கலம்",
            "hi": "बैटरी",
            "te": "బ్యాటరీ"
        },
        "Voltage": {
            "en": "Voltage",
            "ta": "மின்னழுத்தம்",
            "hi": "वोल्टेज",
            "te": "వోల్టేజ్"
        },
        "Flightmode": {
            "en": "Flight Mode",
            "ta": "பறக்கும் முறை",
            "hi": "फ़्लाइट मोड",
            "te": "ఫ్లైట్ మోడ్"
        },
        "Disarmed": {
            "en": "Disarmed",
            "ta": "செயலிழக்கப்பட்டது",
            "hi": "निष्क्रिय",
            "te": "నిరాయుధం"
        },

        // Flight Modes - All modes with translations
        "STABILIZE": {
            "en": "STABILIZE",
            "ta": "நிலைப்படுத்து",
            "hi": "स्टेबलाइज़",
            "te": "స్టెబిలైజ్"
        },
        "ACRO": {
            "en": "ACRO",
            "ta": "ஆக்ரோ",
            "hi": "एक्रो",
            "te": "ఆక్రో"
        },
        "ALT_HOLD": {
            "en": "ALT HOLD",
            "ta": "உயரம் நிலை",
            "hi": "ऊंचाई पकड़",
            "te": "ఎత్తు నిలుపు"
        },
        "AUTO": {
            "en": "AUTO",
            "ta": "தானியங்கு",
            "hi": "ऑटो",
            "te": "ఆటో"
        },
        "GUIDED": {
            "en": "GUIDED",
            "ta": "வழிகாட்டல்",
            "hi": "गाइडेड",
            "te": "గైడెడ్"
        },
        "LOITER": {
            "en": "LOITER",
            "ta": "நிறுத்து",
            "hi": "लॉइटर",
            "te": "లోయిటర్"
        },
        "CIRCLE": {
            "en": "CIRCLE",
            "ta": "வட்டம்",
            "hi": "सर्कल",
            "te": "వృత్తం"
        },
        "POSITION": {
            "en": "POSITION",
            "ta": "நிலைப்படுத்து",
            "hi": "पोजीशन",
            "te": "పొజిషన్"
        },
        "OF_LOITER": {
            "en": "OF LOITER",
            "ta": "ஆப்டிக்கல் லாய்ட்டர்",
            "hi": "ऑप्टिकल लॉइटर",
            "te": "ఆప్టికల్ లాయిటర్"
        },
        "DRIFT": {
            "en": "DRIFT",
            "ta": "சறுக்கல்",
            "hi": "ड्रिफ्ट",
            "te": "డ్రిఫ్ట్"
        },
        "SPORT": {
            "en": "SPORT",
            "ta": "விளையாட்டு",
            "hi": "स्पोर्ट",
            "te": "స్పోర్ట్"
        },
        "FLIP": {
            "en": "FLIP",
            "ta": "புரట்டு",
            "hi": "फ्लिप",
            "te": "ఫ్లిప్"
        },
        "AUTOTUNE": {
            "en": "AUTOTUNE",
            "ta": "தானியங்கி ட்யூன்",
            "hi": "ऑटोट्यून",
            "te": "ఆటోట్యూన్"
        },
        "POSHOLD": {
            "en": "POSHOLD",
            "ta": "நிலை வைத்து",
            "hi": "पोसहोल्ड",
            "te": "పోస్‌హోల్డ్"
        },
        "BRAKE": {
            "en": "BRAKE",
            "ta": "நிறுத்து",
            "hi": "ब्रेक",
            "te": "బ్రేక్"
        },
        "THROW": {
            "en": "THROW",
            "ta": "எறி",
            "hi": "थ्रो",
            "te": "త్రో"
        },
        "AVOID_ADSB": {
            "en": "AVOID ADSB",
            "ta": "ADSB தவির்",
            "hi": "एडीएसबी बचें",
            "te": "ADSB ఎవాయిడ్"
        },
        "GUIDED_NOGPS": {
            "en": "GUIDED NO GPS",
            "ta": "GPS இல्லামल् வழిகாட्டल्",
            "hi": "गाइडेड बिना जीपीएस",
            "te": "GPS లేకుండా గైడెడ్"
        },
        "SMART_RTL": {
            "en": "SMART RTL",
            "ta": "ஸ்மார்ட் RTL",
            "hi": "स्मार्ट आरटीएल",
            "te": "స్మార్ట్ RTL"
        },
        "FLOWHOLD": {
            "en": "FLOWHOLD",
            "ta": "ஃப்लோ ஹோல்ட்",
            "hi": "फ्लोहोल्ड",
            "te": "ఫ్లోహోల్డ్"
        },
        "FOLLOW": {
            "en": "FOLLOW",
            "ta": "பின்பற்று",
            "hi": "फॉलो",
            "te": "ఫాలో"
        },
        "ZIGZAG": {
            "en": "ZIGZAG",
            "ta": "ஜிக்ஜாக்",
            "hi": "जिगजैग",
            "te": "జిగ్‌జాగ్"
        },
        "SYSTEMID": {
            "en": "SYSTEM ID",
            "ta": "அமைப்பு ID",
            "hi": "सिस्टम आईडी",
            "te": "సిస్టమ్ ID"
        },
        "AUTOROTATE": {
            "en": "AUTOROTATE",
            "ta": "தானியங்கி சுழற்சி",
            "hi": "ऑटोरोटेट",
            "te": "ఆటో రొటేట్"
        },
        "AUTO_RTL": {
            "en": "AUTO RTL",
            "ta": "தானியங்கு RTL",
            "hi": "ऑटो आरटीएल",
            "te": "ఆటో RTL"
        },

        // Takeoff Dialog
        "Takeoff Configuration": {
            "en": "Takeoff Configuration",
            "ta": "புறப்பாடு உள்ளமைவு",
            "hi": "टेकऑफ कॉन्फ़िगरेशन",
            "te": "టేకాఫ్ కాన్ఫిగరేషన్"
        },
        "Set the altitude for drone takeoff": {
            "en": "Set the altitude for drone takeoff",
            "ta": "ட்ரோன் புறப்பாட்டிற்கு உயரம் அமைக்கவும்",
            "hi": "ड्रोन टेकऑफ के लिए ऊंचाई सेट करें",
            "te": "డ్రోన్ టేకాఫ్ కోసం ఎత్తును సెట్ చేయండి"
        },
        "Altitude (meters)": {
            "en": "Altitude (meters)",
            "ta": "உயரம் (மீட்டர்)",
            "hi": "ऊंचाई (मीटर)",
            "te": "ఎత్తు (మీటర్లు)"
        },
        "Range: 1.0 - 500.0 meters": {
            "en": "Range: 1.0 - 500.0 meters",
            "ta": "வரம்பு: 1.0 - 500.0 மீட்டர்",
            "hi": "रेंज: 1.0 - 500.0 मीटर",
            "te": "పరిధి: 1.0 - 500.0 మీటర్లు"
        },
        "Cancel": {
            "en": "Cancel",
            "ta": "ரத்து செய்",
            "hi": "रद्द करें",
            "te": "రద్దు చేయండి"
        },
        "Start Takeoff": {
            "en": "Start Takeoff",
            "ta": "புறப்பாடு தொடங்கு",
            "hi": "टेकऑफ शुरू करें",
            "te": "టేకాఫ్ ప్రారంభించండి"
        }
    })
    
    // Function to get translated text
    function getText(key) {
        if (translations[key] && translations[key][currentLanguage]) {
            return translations[key][currentLanguage];
        }
        // Fallback to English if translation not found
        return translations[key] ? translations[key]["en"] : key;
    }
    
    // Function to change language
    function changeLanguage(languageCode) {
        if (availableLanguages.some(lang => lang.code === languageCode)) {
            currentLanguage = languageCode;
            // Save to local storage or settings
            console.log("Language changed to:", languageCode);
        }
    }
    
    // Function to get language name
    function getLanguageName(code) {
        var lang = availableLanguages.find(lang => lang.code === code);
        return lang ? lang.nativeName : code;
    }
}