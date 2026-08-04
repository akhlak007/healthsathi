# HealthSathi 🏥

**Apnar Shastho, Apnar Hathe** — Your Health, In Your Hands

HealthSathi is a production-ready Flutter mobile application designed for secure clinical health records management and emergency healthcare coordination. Built with modern architecture and robust security practices, HealthSathi empowers users to maintain their medical history digitally while ensuring complete privacy and quick access during emergencies.

## ✨ Key Features

### 📋 Health Records Management
- **Digital Health Records**: Securely store and organize your clinical health documents
- **OCR Technology**: Automatically extract text from medical documents using ML Kit
- **Document Management**: Upload, view, and organize health documents with ease
- **Record Organization**: Categorize and search through your medical history

### 🔐 Security & Privacy
- **Biometric Authentication**: Secure your health data with fingerprint/face recognition
- **Firebase Security**: Enterprise-grade authentication and data encryption
- **App Check Verification**: Prevent unauthorized access with Firebase App Check
- **Privacy First**: Your data stays with you under your complete control

### 🚨 Emergency Management
- **Quick Access**: One-tap emergency access to critical health information
- **Emergency Contacts**: Store and manage emergency contact information
- **Location Services**: Share location during emergencies when needed

### 🌍 Multilingual Support
- **Bangla & English**: Full support for Bengali (bn) and English (en) languages
- **Localization**: Complete UI localization for seamless multilingual experience
- **Regional Customization**: Built with South Asian healthcare context in mind

### 📱 Modern UI/UX
- **Material Design**: Modern, intuitive user interface
- **Smooth Animations**: Shimmer effects and smooth transitions
- **Responsive Design**: Optimized for various device sizes
- **Custom Fonts**: Google Fonts integration for beautiful typography

## 🛠 Technology Stack

### Framework & Language
- **Dart 3.0+** (80.8% of codebase)
- **Flutter** - Cross-platform mobile framework
- **HTML** (19.1% of codebase) - Web components support

### State Management
- **Flutter Riverpod 2.4.9** - Reactive state management
- **Riverpod Annotation** - Type-safe state definitions

### Backend & Database
- **Firebase Core 3.10.0** - Firebase platform
- **Firebase Authentication 5.3.0** - Secure user authentication
- **Cloud Firestore 5.6.0** - Real-time cloud database
- **Firebase App Check 0.3.2** - App verification and security
- **Google Sign-In 6.2.1** - OAuth authentication

### UI & Design
- **Material Design 3** - Modern design system
- **Google Fonts 6.1.0** - Beautiful typography
- **Flutter SVG 2.0.9** - SVG asset support
- **Badges 3.1.2** - Badge notifications
- **Shimmer 3.0.0** - Loading animations

### AI & Machine Learning
- **Google ML Kit Text Recognition 0.15.1** - OCR capabilities
- **Image Cropper 12.2.1** - Image processing
- **Flutter Image Compress 2.0.3** - Image optimization

### Native Features
- **Local Auth 2.1.8** - Biometric authentication
- **Image Picker 1.0.7** - Camera & gallery access
- **File Picker 8.0.0** - File selection
- **Permission Handler 12.0.3** - Permission management
- **Shared Preferences 2.2.2** - Local data storage

### Navigation & Routing
- **Go Router 12.1.3** - Declarative routing with type safety
- **URL Launcher 6.2.2** - Deep linking support

### Additional Libraries
- **Cached Network Image 3.3.1** - Image caching
- **HTTP 1.6.0** - Network requests
- **UUID 4.5.3** - Unique identifier generation
- **Flutter Local Notifications 17.0.0** - Push notifications
- **Syncfusion PDF Viewer 31.1.19** - PDF viewing
- **Flutter Timezone 5.1.0** - Timezone handling
- **Share Plus 12.0.2** - System share functionality

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart 3.0.0 or higher
- Android SDK (for Android development)
- Xcode (for iOS development)
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/akhlak007/healthsathi.git
   cd healthsathi
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   - Create a `.env` file in the project root
   - Add your Firebase configuration and API keys

4. **Generate localization files**
   ```bash
   flutter gen-l10n
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password and Google Sign-In)
3. Create a Firestore database
4. Enable Firebase App Check
5. Download and integrate Firebase configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS

## 📁 Project Structure

```
lib/
├── l10n/                    # Localization files (English & Bengali)
├── models/                  # Data models
├── providers/              # Riverpod providers
├── screens/                # UI screens
├── widgets/                # Reusable widgets
├── services/               # Business logic & services
└── main.dart              # Application entry point
```

## 🔐 Security Features

- **Biometric Authentication**: Touch ID / Face ID support
- **Encrypted Storage**: Sensitive data encrypted locally
- **Firebase Security**: Server-side encryption and access controls
- **App Verification**: Firebase App Check prevents unauthorized access
- **HTTPS Only**: All network communications encrypted

## 🌐 Localization

The app supports multiple languages with complete UI localization:
- **English (en)** - Default language
- **Bengali (bn)** - Native language support

Add more languages by extending the `l10n` directory and updating `pubspec.yaml`.

## 📦 Build & Distribution

### Android Build
```bash
flutter build apk       # APK build
flutter build appbundle # Play Store bundle
```

### iOS Build
```bash
flutter build ios       # iOS app
```

## 📚 Documentation

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Go Router Documentation](https://pub.dev/packages/go_router)

## 🤝 Contributing

We welcome contributions! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📝 License

This project is currently unlicensed. Please see the repository for license information.

## 📞 Support & Contact

For questions or support, please:
- Open an issue on GitHub
- Contact: [Your Contact Information]
- Email: [Your Email]

## 🎯 Roadmap

- [ ] Telemedicine consultation integration
- [ ] AI-powered health insights
- [ ] Wearable device integration
- [ ] Advanced appointment scheduling
- [ ] Insurance claim management
- [ ] Multi-device synchronization

## 📊 Statistics

- **Repository Created**: May 27, 2026
- **Primary Language**: Dart (80.8%)
- **Secondary Language**: HTML (19.1%)
- **Platform**: Flutter (Cross-platform)
- **Architecture**: Production-ready

## ⭐ Acknowledgments

- Flutter team for the amazing framework
- Firebase for robust backend infrastructure
- Google ML Kit for OCR capabilities
- All contributors and users of HealthSathi

---

**HealthSathi** - Empowering you to take control of your health. Made with ❤️ for better healthcare management.

*Last Updated: August 2026*