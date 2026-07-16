# Digital Legacy Vault

A secure Flutter mobile application for storing and managing information about your movable and immovable assets for legacy planning.

## Overview

Digital Legacy Vault is a professional, secure, and user-friendly mobile application that helps you organize and store critical information about your assets. This information can be accessed by your beneficiaries or estate executors after your passing.

## Features

### 🔐 Security
- **Biometric Authentication**: Fingerprint/Face ID authentication on supported devices
- **AES-256 Encryption**: All sensitive data is encrypted using industry-standard AES-256 encryption
- **Secure Storage**: Encryption keys stored in device's secure storage (Keychain on iOS, KeyStore on Android)
- **Field-level Encryption**: Critical fields like account numbers, passwords, and VINs are individually encrypted

### 📊 Asset Categories

1. **Banks**
   - Account information (checking, savings, etc.)
   - Online banking credentials
   - Beneficiary information
   - Balance tracking

2. **Retirement Accounts**
   - 401(k), Roth IRA, Traditional IRA
   - Employer information
   - Vesting dates and matching
   - Provider access details

3. **Investments**
   - Stocks, bonds, mutual funds
   - Vanguard, Fidelity, and other providers
   - Ticker symbols and share counts
   - Purchase history

4. **Properties**
   - Houses, apartments, land, commercial
   - Deed locations
   - Mortgage information
   - Insurance details

5. **Vehicles**
   - Cars, motorcycles, boats, RVs
   - VIN and registration
   - Title locations
   - Loan and insurance details

### 🎨 User Interface
- **Professional Design**: Clean, modern UI with Material Design 3
- **Beautiful Typography**: Google Fonts (Inter) for excellent readability
- **Intuitive Navigation**: Easy-to-use category-based organization
- **Responsive**: Optimized for various screen sizes

## Architecture

### Project Structure
```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart       # App-wide constants
│   ├── theme/
│   │   └── app_theme.dart           # Theme configuration
│   └── utils/
│       ├── encryption_helper.dart   # Encryption utilities
│       └── biometric_helper.dart    # Biometric authentication
├── data/
│   ├── models/                      # Data models
│   │   ├── base_asset.dart
│   │   ├── bank_account.dart
│   │   ├── retirement_account.dart
│   │   ├── investment.dart
│   │   ├── property.dart
│   │   └── vehicle.dart
│   └── database/
│       └── database_helper.dart     # SQLite database operations
├── features/
│   ├── auth/
│   │   └── auth_screen.dart         # Biometric authentication
│   ├── home/
│   │   └── home_screen.dart         # Dashboard
│   ├── banks/
│   │   ├── banks_list_screen.dart
│   │   └── bank_form_screen.dart
│   ├── retirement/
│   │   ├── retirement_list_screen.dart
│   │   └── retirement_form_screen.dart
│   ├── investments/
│   │   ├── investments_list_screen.dart
│   │   └── investment_form_screen.dart
│   ├── properties/
│   │   ├── properties_list_screen.dart
│   │   └── property_form_screen.dart
│   └── vehicles/
│       ├── vehicles_list_screen.dart
│       └── vehicle_form_screen.dart
└── main.dart                        # Application entry point
```

### Technology Stack
- **Framework**: Flutter 3.12+
- **Database**: SQLite (via sqflite package)
- **Security**: 
  - AES encryption (encrypt package)
  - Secure storage (flutter_secure_storage)
  - Biometric auth (local_auth)
- **UI**: 
  - Material Design 3
  - Google Fonts
- **State Management**: Provider pattern (ready for scaling)

## Getting Started

### Prerequisites
- Flutter SDK 3.12 or higher
- Dart 3.0 or higher
- Android SDK (for Android development)
- Xcode (for iOS development)

### Installation

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### iOS
Add the following to `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>Authenticate to access your Digital Legacy Vault</string>
```

#### Android
The biometric authentication is already configured in the manifest.

## Security Features

### Encryption Flow
1. **Initialization**: On first launch, a random 256-bit encryption key is generated
2. **Key Storage**: The key is stored in the device's secure storage
3. **Data Encryption**: Sensitive fields are encrypted before database insertion
4. **Data Decryption**: Data is decrypted when retrieved from database
5. **IV Usage**: Each encryption uses a unique initialization vector (IV)

### Protected Fields
- Account numbers
- Routing numbers
- VINs
- Policy numbers
- Usernames
- Password hints
- Loan account numbers

## Privacy & Data

- **Local-Only Storage**: All data is stored locally on your device
- **No Cloud Upload**: Data never leaves your device unless you explicitly export it
- **No Analytics**: No tracking or analytics
- **No Third Parties**: No data shared with third parties

## Best Practices

### For Users
1. **Regular Backups**: Export your data regularly
2. **Password Hints**: Use hints, not actual passwords
3. **Document Locations**: Specify where physical documents are stored
4. **Update Beneficiaries**: Keep beneficiary information current
5. **Trusted Access**: Share vault access with trusted individuals

---

**Note**: This application is designed to help with legacy planning but should not be considered a replacement for professional legal or financial advice. Always consult with qualified professionals for estate planning.
