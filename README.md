# 🏌️ Smart Golf Assistant

An intelligent golf analytics and training system that combines a Flutter mobile app with a GPS-enabled rover to help golfers measure, analyze, and improve their short-game performance.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🎯 Overview

**Smart Golf Assistant** transforms traditional golf practice into a measurable, data-powered experience. The system consists of:

- **📱 Flutter Mobile App**: Real-time shot tracking, club recommendations, voice coaching, and analytics
- **🤖 GPS Rover**: Raspberry Pi-based device that captures ball location after each shot (up to 100 yards)
- **📊 Analytics Engine**: Mark Broadie-inspired "Strokes Gained" metrics for performance insights

---

## ✨ Key Features

### 🎯 **Real-Time Shot Tracking**
- Automatic ball detection via GPS rover
- Distance and direction calculation
- Voice feedback for hands-free operation
- Shot history with detailed metrics

### 🏌️ **Intelligent Club Recommendations**
- Personalized club selection based on distance
- Custom yardage profiles per club
- Real-time suggestions during practice

### 📊 **Advanced Analytics**
- **Strokes Gained Analysis**: Compare your performance to benchmarks
- **Shot Dispersion Visualization**: See your accuracy patterns
- **Consistency Metrics**: Track standard deviation and spread
- **Club Performance**: Identify strengths and weaknesses
- **Practice Trends**: Monitor improvement over time

### 🎙️ **Voice Coach (Accessibility-First)**
- Text-to-Speech announcements for all actions
- Screen reader-friendly navigation
- Designed for blind and visually impaired golfers
- Hands-free operation during practice

### 📝 **Practice Session Management**
- Start/end practice sessions
- Track shots per session
- Session-based analytics
- Historical session review

### 🎯 **Goal Setting & Tracking**
- Set accuracy and consistency goals
- Automatic progress tracking
- Goal achievement notifications
- Personalized recommendations

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.0 or higher
- **Dart SDK**: 3.0 or higher
- **iOS**: Xcode 14+ (for iOS development)
- **Android**: Android Studio with SDK 21+
- **Raspberry Pi**: 5B or compatible (for rover)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/smart-golf-assistant.git
   cd smart-golf-assistant
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

---

## 🤖 Rover Setup

The rover is a Raspberry Pi equipped with GPS that tracks ball location.

### Hardware Requirements
- Raspberry Pi 5B (or compatible)
- GPS module (UART/Serial)
- WiFi connectivity

### Software Setup

1. **Install Python dependencies**
   ```bash
   pip3 install pyserial pynmea2
   ```

2. **Run the GPS server**
   ```bash
   python3 rover_gps_server.py
   ```

3. **Configure the app**
   - Connect phone and rover to same WiFi network
   - Enter rover IP in app (default: `172.20.10.4`)
   - Click "Find Rover" to auto-detect port

### GPS Data Format
The rover sends JSON data via TCP socket:
```json
{
  "lat": 12.971606,
  "lon": 77.594516
}
```

For detailed setup instructions, see [ROVER_FILE_GPS_SETUP.md](ROVER_FILE_GPS_SETUP.md)

---

## 📱 App Screens

| Screen | Description |
|--------|-------------|
| **Distance** | Real-time distance to ball, club recommendation, shot saving |
| **Club** | View and edit personalized club yardages |
| **History** | Browse all saved shots with filters |
| **Analytics** | Mark Broadie metrics, shot dispersion, trends |
| **Sessions** | Manage practice sessions |
| **Goals** | Set and track performance goals |

---

## 🎨 Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile framework
- **Provider**: State management
- **fl_chart**: Data visualization
- **flutter_tts**: Text-to-Speech for accessibility

### Backend
- **sqflite**: Local database for shot storage
- **shared_preferences**: User settings persistence
- **geolocator**: GPS positioning
- **flutter_compass**: Compass heading

### Rover
- **Python**: Server scripting
- **pyserial**: GPS module communication
- **pynmea2**: NMEA sentence parsing

---

## 📊 Analytics Methodology

### Strokes Gained (Simplified)
Based on Mark Broadie's groundbreaking work in golf analytics:
- Compare your shots to expected performance
- Identify clubs that gain/lose strokes
- Focus practice on high-impact areas

### Consistency Metrics
- **Standard Deviation**: Measure shot dispersion
- **Spread**: Track accuracy range
- **Trend Analysis**: Monitor improvement over time

### Shot Dispersion
- Visual scatter plot of shot patterns
- Color-coded by club type
- Identify accuracy issues

---

## 🎯 Use Cases

### ⛳ **Recreational Golfers**
- Track improvement over time
- Understand which clubs to use
- Build confidence with data

### 🏆 **Competitive Players**
- Identify weaknesses in short game
- Optimize club selection strategy
- Measure practice effectiveness

### ♿ **Visually Impaired Golfers**
- Full voice guidance
- Hands-free operation
- Accessible analytics

---

## 🛠️ Development

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── shot.dart
│   ├── practice_session.dart
│   └── goal.dart
├── screens/                  # UI screens
│   ├── distance_screen.dart
│   ├── recommend_screen.dart
│   ├── history_screen.dart
│   ├── analytics_screen.dart
│   ├── practice_sessions_screen.dart
│   └── goals_screen.dart
├── services/                 # Business logic
│   ├── db_service.dart
│   ├── club_service.dart
│   ├── file_gps_service.dart
│   ├── voice_coach.dart
│   ├── practice_session_service.dart
│   └── goal_service.dart
└── widgets/                  # Reusable components
```

### Key Services

**DbService**: SQLite database management for shots
**ClubService**: User club configuration
**FileGpsService**: GPS data polling from rover
**VoiceCoach**: Text-to-Speech accessibility layer
**PracticeSessionService**: Session tracking
**GoalService**: Goal management and progress tracking

---

## 🔧 Configuration

### iOS Setup
Add permissions to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to calculate distance to the ball</string>
<key>NSLocalNetworkUsageDescription</key>
<string>Connect to GPS rover on local network</string>
```

### Android Setup
Add permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Mark Broadie**: For pioneering golf analytics methodology
- **Flutter Team**: For the amazing cross-platform framework
- **Golf Community**: For inspiration and feedback

---

## 📧 Contact

**Project Maintainer**: Your Name
- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com

---

## 🎉 Demo

[Add screenshots or video demo here]

---

## 🗺️ Roadmap

- [ ] Course mapping integration
- [ ] Multi-player comparison
- [ ] Cloud sync for cross-device access
- [ ] Advanced ML-based recommendations
- [ ] Braille display integration
- [ ] Apple Watch companion app

---

**Made with ❤️ for golfers who love data**
