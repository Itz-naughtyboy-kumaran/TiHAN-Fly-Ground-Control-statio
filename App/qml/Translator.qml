import QtQuick 2.0

QtObject {
    property string currentLanguage: "en"

    readonly property var translations: {
        "en": {
            "connect": "Connect",
            "disconnect": "Disconnect",
            "altitude": "Altitude",
            "speed": "Speed"
        },
        "ta": {
            "connect": "இணை",
            "disconnect": "தடுப்பு",
            "altitude": "உயரம்",
            "speed": "வேகம்"
        },
        "ml": {
            "connect": "ചേർക്കുക",
            "disconnect": "ഡിസ്കണെക്ട്",
            "altitude": "ഉയരം",
            "speed": "വേഗം"
        },
        "kn": {
            "connect": "ಸಂಪರ್ಕಿಸಿ",
            "disconnect": "ಡಿಸ್ಕನೆಕ್ಟ್",
            "altitude": "ಎತ್ತರ",
            "speed": "ವೇಗ"
        },
        "te": {
            "connect": "కనెక్ట్",
            "disconnect": "డిస్కనెక్ట్",
            "altitude": "ఎత్తు",
            "speed": "వేగం"
        },
        "hi": {
            "connect": "कनेक्ट करें",
            "disconnect": "डिस्कनेक्ट करें",
            "altitude": "ऊंचाई",
            "speed": "गति"
        }
    }

    function translate(key) {
        return translations[currentLanguage][key] || key;
    }
}
