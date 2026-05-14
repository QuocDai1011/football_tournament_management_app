# ⚽ Football Tournament Manager

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.5.0+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.5.0+-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green)

**Professional Football Tournament Management System**

[Features](#-features) • [Screenshots](#-screenshots) • [Setup](#-quick-setup) • [Documentation](#-documentation)

</div>

---

## 📖 Overview

Football Tournament Manager là một ứng dụng quản lý giải đấu bóng đá chuyên nghiệp được xây dựng với Flutter. App hỗ trợ đầy đủ các tính năng quản lý giải đấu, đội bóng, cầu thủ, trận đấu, và tự động tính toán bảng xếp hạng.

### 🎯 Mục đích

- Quản lý giải đấu bóng đá một cách chuyên nghiệp
- Tự động hóa việc tính toán bảng xếp hạng
- Theo dõi trận đấu real-time
- Quản lý đội bóng và cầu thủ
- Hỗ trợ nhiều loại giải đấu (League, Knockout, Hybrid)

### 🏗️ Architecture

- **Clean Architecture** với feature-first structure
- **SOLID Principles**
- **Riverpod** state management
- **GoRouter** navigation
- **Firebase** backend (Auth + Firestore)
- **Material 3** design system

---

## ✨ Features

### 🔐 Authentication
- ✅ Firebase Authentication (Email/Password)
- ✅ Admin-only access
- ✅ Session persistence
- ✅ Secure login flow

### 🏆 Tournament Management
- ✅ Create/Edit/Delete tournaments
- ✅ Tournament types: League, Knockout, Hybrid
- ✅ Tournament status: Upcoming, Ongoing, Finished
- ✅ Custom scoring system (Win/Draw/Loss points)
- ✅ Banner upload support
- ✅ Progress tracking

### 📅 Season Management
- ✅ Create/Edit/Delete seasons
- ✅ Registration deadline tracking
- ✅ Season status management
- ✅ Max teams configuration

### 👥 Team Management
- ✅ Create/Edit/Delete teams
- ✅ Team logo upload
- ✅ Team colors, coach, city info
- ✅ Team statistics
- ✅ Team detail page

### ⚽ Player Management
- ✅ Create/Edit/Delete players
- ✅ Player positions (GK, DF, MF, FW)
- ✅ Shirt numbers
- ✅ Captain designation
- ✅ Player statistics (goals, assists, cards, appearances)
- ✅ Avatar upload support
- ✅ Position filtering

### 🎮 Match Management
- ✅ Create/Edit/Delete matches
- ✅ Match types (Group Stage, Knockout, Semi-Final, Final)
- ✅ Match status (Scheduled, Live, Finished)
- ✅ Live match tracking
- ✅ Match events (goals, cards, substitutions)
- ✅ Event timeline
- ✅ Score updates
- ✅ Venue and scheduling

### 📝 Registration Management
- ✅ Team registration
- ✅ Registration approval/rejection
- ✅ Group assignment
- ✅ Duplicate prevention
- ✅ Registration status tracking

### 📊 Standings & Statistics
- ✅ **Automatic standings calculation**
- ✅ Sorting: Points → Goal Difference → Goals For → Name
- ✅ Group-based standings
- ✅ Real-time updates
- ✅ Tournament selector

### 🏅 Awards System
- ✅ Champion
- ✅ Runner-Up
- ✅ Top Scorer
- ✅ Best Goalkeeper
- ✅ Fair Play Award

### 📱 Dashboard
- ✅ Animated summary cards
- ✅ Live matches section
- ✅ Recent matches
- ✅ Active tournaments
- ✅ Statistics overview
- ✅ Quick actions

### 🎨 UI/UX
- ✅ **Material 3 Dark Theme**
- ✅ Glassmorphism effects
- ✅ Smooth animations
- ✅ Responsive design (Mobile/Tablet/Web)
- ✅ Adaptive navigation (Sidebar/Bottom Nav)
- ✅ Shimmer loading
- ✅ Empty states
- ✅ Error handling

### 🔧 Technical Features
- ✅ Clean Architecture
- ✅ Riverpod state management
- ✅ GoRouter navigation
- ✅ Firebase integration
- ✅ Firestore real-time updates
- ✅ Either pattern for error handling
- ✅ Null-safety
- ✅ Cloudinary integration (ready)
- ✅ Offline persistence (Firestore)

---

## 🚀 Quick Setup

### Prerequisites
- Flutter SDK 3.5.0+
- Dart 3.5.0+
- Firebase account
- Cloudinary account (optional)

### Installation

```bash
# 1. Clone repository
git clone <repository-url>
cd football_tournament_manager_app

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase
dart pub global activate flutterfire_cli
flutterfire configure

# 4. Run the app
flutter run
```

### Firebase Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create new project
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Enable Cloud Messaging (optional)

2. **Create Admin User**
   - Firebase Console → Authentication → Add User
   - Email: `admin@example.com`
   - Password: your-password

3. **Add Admin to Firestore**
   - Firestore → Create collection `admins`
   - Document ID: Copy UID from Authentication
   - Fields:
     ```json
     {
       "email": "admin@example.com",
       "displayName": "Admin",
       "createdAt": [Timestamp],
       "lastLoginAt": [Timestamp]
     }
     ```

4. **Deploy Firestore Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

### Cloudinary Setup (Optional)

Edit `lib/core/services/cloudinary_service.dart`:
```dart
static const String cloudName = 'YOUR_CLOUD_NAME';
static const String apiKey = 'YOUR_API_KEY';
static const String apiSecret = 'YOUR_API_SECRET';
static const String uploadPreset = 'football_manager';
```

---

## 📸 Screenshots

### Mobile
- Dashboard với live matches
- Tournament list với search
- Team grid layout
- Player list với filters
- Match detail với events
- Standings table
- Responsive forms

### Tablet/Web
- Sidebar navigation
- Multi-column layouts
- Dashboard analytics
- Admin panel

---

## 📚 Documentation

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Detailed setup instructions
- **[PROJECT_STATUS.md](PROJECT_STATUS.md)** - Complete feature list and status
- **[firestore.rules](firestore.rules)** - Firestore security rules

### Project Structure

```
lib/
├── core/
│   ├── algorithms/          # Fixture generator, standings engine
│   ├── error/              # Failure classes, exceptions
│   ├── providers/          # Firebase providers
│   ├── routing/            # GoRouter configuration
│   ├── services/           # Firestore, Cloudinary services
│   ├── theme/              # App theme, colors, typography
│   └── utils/              # Result types, extensions
├── features/
│   ├── auth/               # Authentication
│   ├── awards/             # Awards management
│   ├── dashboard/          # Dashboard & statistics
│   ├── matches/            # Match management
│   ├── players/            # Player management
│   ├── registrations/      # Registration management
│   ├── seasons/            # Season management
│   ├── standings/          # Standings & rankings
│   ├── teams/              # Team management
│   └── tournaments/        # Tournament management
└── shared/
    ├── presentation/       # Main shell, navigation
    └── widgets/            # Reusable widgets
```

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** 3.5.0+
- **Dart** 3.5.0+
- **Material 3** design

### State Management
- **Riverpod** 2.5.1
- **Riverpod Annotation** 2.3.5

### Backend
- **Firebase Auth** 5.3.1
- **Cloud Firestore** 5.4.4
- **Firebase Messaging** 15.1.3
- **Firebase Storage** 12.3.2

### Navigation
- **GoRouter** 14.2.7

### UI Libraries
- **Shimmer** 3.0.0
- **Flutter Animate** 4.5.0
- **Lottie** 3.1.2
- **FL Chart** 0.69.0
- **Google Fonts** 6.2.1
- **Cached Network Image** 3.4.1

### Utilities
- **Dartz** 0.10.1 (Either pattern)
- **UUID** 4.5.1
- **Intl** 0.19.0
- **Logger** 2.4.0
- **Dio** 5.7.0

---

## 🎯 Algorithms

### Fixture Generator
- **Round-robin**: Each team plays every other team once
- **Double round-robin**: Home and away matches
- **Knockout**: Elimination bracket
- **Group assignment**: Automatic group distribution

### Standings Engine
- **Automatic calculation** from match results
- **Sorting logic**: Points → Goal Difference → Goals For → Team Name
- **Real-time updates** when matches finish
- **Group support** for group stage tournaments

---

## 🔒 Security

- **Firestore Security Rules** implemented
- **Admin-only write access**
- **Public read access** (for web display)
- **Authentication required** for admin operations
- **Input validation** on all forms

---

## 📊 Database Schema

### Collections
- `admins` - Admin users
- `tournaments` - Tournaments
- `seasons` - Seasons
- `teams` - Teams
- `players` - Players
- `matches` - Matches
  - `events` (subcollection) - Match events
  - `lineups` (subcollection) - Match lineups
- `standings` - Standings
- `awards` - Awards
- `registrations` - Team registrations
- `notifications` - Notifications
- `player_statistics` - Player stats
- `team_statistics` - Team stats

---

## 🚧 Roadmap

### Completed ✅
- Core architecture
- All main features
- Responsive UI
- Firebase integration
- Algorithms

### In Progress 🔄
- Image upload integration
- Cloud Functions
- Push notifications

### Planned 📋
- Export to PDF/Excel
- Advanced statistics
- Charts & graphs
- Offline support
- Unit tests
- Integration tests

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

Built with ❤️ using Flutter

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Material Design for UI guidelines
- Community packages and contributors

---

<div align="center">

**⭐ Star this repo if you find it helpful!**

Made with Flutter 💙

</div>
