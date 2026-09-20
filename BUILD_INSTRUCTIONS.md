# Comity - Committee Savings App

## Quick Build (No Local Android SDK Needed)

### Option 1: GitHub Actions (Recommended for your laptop)
1. Push to GitHub:
   ```bash
   cd C:\src\comity
   git init && git add . && git commit -m "Initial commit"
   # Create repo at github.com/new → name it "comity"
   git remote add origin https://github.com/YOUR_USERNAME/comity.git
   git push -u origin main
   ```
2. Go to your repo → **Actions** tab → wait for "Build Release APK" to complete
3. Click the run → **Artifacts** → download `release-apks.zip`
4. Extract → install `app-arm64-v8a-release.apk` on your phone

### Option 2: USB Debug (if you have cable + phone)
```bash
# Enable USB debugging on phone (Settings → About → Tap Build 7x → Developer Options → USB Debugging)
flutter devices  # Should show your phone
flutter run      # Installs debug app directly
```

## Project Status
✅ Complete Flutter app with Firebase backend
- Auth: Phone + OTP
- Organizer: Create committees, add members, record payments
- Member: View position, payment history, progress
- Material 3 theme, responsive UI

## Tech Stack
- Flutter 3.24 / Dart
- Firebase Auth + Firestore
- Provider state management