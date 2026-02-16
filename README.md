# Smart Task Manager (Release Mode) 🚀

A production-ready Flutter application built with Clean Architecture, following best practices for state management, offline support, and API integration. This project is fully optimized and verified in **Release Mode**.

## ✨ Key Features
- **Task Management**: CRUD operations with REST API integration.
- **Infinite Scrolling**: Smooth pagination for large task lists.
- **Offline First**: Local caching with Hive for offline accessibility.
- **Authentication**: Secure Firebase Auth integration.
- **Profile & Settings**: User profile management and theme customization (Light/Dark mode).
- **Material 3 Design**: Modern, premium UI/UX.

## 🛠️ Tech Stack
- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Local Database**: [Hive](https://pub.dev/packages/hive)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **Backend Services**: Firebase Auth & Firestore (Profile), Custom REST API (Tasks)
- **Architecture**: Clean Architecture (Data, Domain, Presentation layers)

## 📦 Production Release
The application has been built and verified in release mode.
- **Release APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **Optimization**: All debug flags (like `debugShowCheckedModeBanner`) are disabled for the best performance.
- **Pure Dart Focus**: The project has been cleaned of non-essential platform code (Swift, C++, etc.) to maintain a pure Dart/Flutter logic base.

## 🚀 Getting Started
1. **Clone the repository**:
   ```bash
   git clone https://github.com/ranjithth73-tech/flutter-machine-task.git
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run in Release Mode**:
   ```bash
   flutter run --release
   ```
