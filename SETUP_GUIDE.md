# 🚀 Football Tournament Manager - Setup Guide

## ✅ Trạng thái hiện tại

**App đã sẵn sàng chạy!** Chỉ cần setup Firebase và Cloudinary.

## 📋 Yêu cầu

- Flutter SDK 3.5.0+
- Dart 3.5.0+
- Firebase project
- Cloudinary account (optional, cho upload ảnh)

## 🔧 Các bước setup

### 1. Cài đặt Dependencies

```bash
flutter pub get
```

### 2. Setup Firebase

#### A. Tạo Firebase Project
1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Tạo project mới hoặc sử dụng project có sẵn
3. Enable Authentication (Email/Password)
4. Enable Firestore Database
5. Enable Cloud Messaging (optional)
6. Enable Storage (optional)

#### B. Configure Firebase cho Flutter

```bash
# Cài FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (chọn project của bạn)
flutterfire configure
```

Lệnh này sẽ tự động:
- Tạo/update file `lib/firebase_options.dart`
- Configure cho Android, iOS, và Web
- Setup Firebase trong project

#### C. Tạo Admin User

1. Firebase Console → Authentication → Users → Add User
   - Email: `admin@example.com`
   - Password: `Admin@123` (hoặc password của bạn)

2. Firestore Database → Start collection `admins`
   - Document ID: Copy UID từ Authentication
   - Fields:
     ```json
     {
       "email": "admin@example.com",
       "displayName": "Admin",
       "photoUrl": null,
       "createdAt": [Timestamp now],
       "lastLoginAt": [Timestamp now]
     }
     ```

#### D. Setup Firestore Rules

File `firestore.rules` đã có sẵn. Deploy rules:

```bash
firebase deploy --only firestore:rules
```

Hoặc copy nội dung từ `firestore.rules` vào Firebase Console → Firestore → Rules.

### 3. Setup Cloudinary (Optional - cho upload ảnh)

#### A. Tạo Cloudinary Account
1. Truy cập [Cloudinary](https://cloudinary.com/)
2. Sign up miễn phí
3. Lấy credentials từ Dashboard

#### B. Configure Cloudinary

Edit file `lib/core/services/cloudinary_service.dart`:

```dart
class CloudinaryConfig {
  static const String cloudName = 'YOUR_CLOUD_NAME'; // Thay bằng cloud name của bạn
  static const String apiKey = 'YOUR_API_KEY';       // Thay bằng API key
  static const String apiSecret = 'YOUR_API_SECRET'; // Thay bằng API secret
  static const String uploadPreset = 'football_manager'; // Tạo unsigned preset
}
```

#### C. Tạo Upload Preset
1. Cloudinary Dashboard → Settings → Upload
2. Add upload preset:
   - Name: `football_manager`
   - Signing Mode: **Unsigned**
   - Folder: `football_manager` (optional)

### 4. Chạy App

```bash
# Android
flutter run

# iOS (cần Mac)
flutter run -d ios

# Web
flutter run -d chrome

# Hoặc chọn device trong VS Code/Android Studio
```

## 🎯 Test App

### 1. Login
- Email: `admin@example.com`
- Password: password bạn đã tạo

### 2. Tạo dữ liệu test

#### A. Tạo Teams
1. Vào Teams → Add Team
2. Tạo ít nhất 4-8 teams

#### B. Tạo Players
1. Vào Players → Add Player
2. Chọn team
3. Chọn position (GK, DF, MF, FW)
4. Nhập shirt number

#### C. Tạo Tournament
1. Vào Tournaments → Create Tournament
2. Nhập tên, chọn type (League/Knockout/Hybrid)
3. Set max teams
4. Configure scoring system

#### D. Tạo Season (Optional)
1. Vào Seasons → Add Season
2. Chọn tournament
3. Set dates và registration deadline

#### E. Register Teams
1. Vào Registrations
2. Register teams vào tournament
3. Approve registrations
4. Assign groups (nếu cần)

#### F. Tạo Matches
1. Vào Matches → Create Match
2. Chọn tournament
3. Chọn home team và away team
4. Set date/time và venue

#### G. Start Match
1. Vào Match Detail
2. Click "Start" để bắt đầu match
3. Add events (goals, cards, substitutions)
4. Click "End Match" khi xong

#### H. Xem Standings
1. Vào Standings
2. Chọn tournament
3. Xem bảng xếp hạng tự động

## 📱 Các màn hình chính

1. **Dashboard** - Tổng quan, stats, live matches
2. **Tournaments** - Quản lý giải đấu
3. **Seasons** - Quản lý mùa giải
4. **Teams** - Quản lý đội bóng
5. **Players** - Quản lý cầu thủ
6. **Matches** - Quản lý trận đấu
7. **Registrations** - Đăng ký tham gia
8. **Standings** - Bảng xếp hạng
9. **Awards** - Giải thưởng

## 🐛 Troubleshooting

### Lỗi Firebase
```
Error: Firebase not initialized
```
**Fix**: Chạy `flutterfire configure` lại

### Lỗi Login
```
Error: User not found in admins collection
```
**Fix**: Tạo document trong collection `admins` với UID từ Authentication

### Lỗi Cloudinary
```
Error: Upload failed
```
**Fix**: 
- Check credentials trong `cloudinary_service.dart`
- Đảm bảo upload preset là **unsigned**
- Check network connection

### Lỗi Build
```
Error: Package not found
```
**Fix**: 
```bash
flutter clean
flutter pub get
flutter run
```

## 🎨 Customization

### Thay đổi Theme
Edit `lib/core/theme/app_theme.dart`:
```dart
class AppColors {
  static const Color primary = Color(0xFF00D4AA); // Đổi màu primary
  static const Color secondary = Color(0xFFFF6B35); // Đổi màu secondary
  // ...
}
```

### Thay đổi Scoring System
Mặc định: Win = 3, Draw = 1, Loss = 0

Có thể thay đổi khi tạo tournament trong Tournament Form.

### Thay đổi Logo
Replace files trong `assets/icons/` và `assets/images/`

## 📊 Firestore Collections

App sử dụng các collections sau:

- `admins` - Admin users
- `tournaments` - Giải đấu
- `seasons` - Mùa giải
- `teams` - Đội bóng
- `players` - Cầu thủ
- `matches` - Trận đấu
  - `events` (subcollection) - Sự kiện trong trận
  - `lineups` (subcollection) - Đội hình
- `standings` - Bảng xếp hạng
- `awards` - Giải thưởng
- `registrations` - Đăng ký tham gia
- `notifications` - Thông báo
- `player_statistics` - Thống kê cầu thủ
- `team_statistics` - Thống kê đội

## 🔐 Security

- Firestore rules đã được setup
- Chỉ admin có thể write
- Public có thể read (cho web public)
- Auth required cho admin operations

## 📈 Performance Tips

1. **Pagination**: Repositories đã support pagination
2. **Caching**: Firestore offline persistence enabled
3. **Images**: Sử dụng cached_network_image
4. **Lazy Loading**: ListView.builder cho lists

## 🚀 Deploy

### Android
```bash
flutter build apk --release
# hoặc
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 📞 Support

Nếu gặp vấn đề:
1. Check `PROJECT_STATUS.md` để xem features nào đã implement
2. Check console logs
3. Check Firebase Console cho errors
4. Check Firestore rules

## ✨ Features Highlights

✅ **Đã hoàn thành**:
- Authentication
- Tournament Management
- Team Management
- Player Management
- Match Management (với live tracking)
- Season Management
- Registration Management
- Standings (tự động tính)
- Awards
- Dashboard với stats
- Responsive design (mobile/tablet/web)
- Dark theme
- Animations

⚠️ **Cần hoàn thiện**:
- Image upload (cần Cloudinary setup)
- Cloud Functions
- Push Notifications
- Export PDF/Excel
- Offline support
- Tests

---

**Chúc bạn thành công! 🎉**
