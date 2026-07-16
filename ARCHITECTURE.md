# Architecture Documentation

## System Architecture

### Overview
The Digital Legacy Vault follows a clean, feature-based architecture with clear separation of concerns. The app is organized into three main layers:

1. **Presentation Layer** (`features/`)
2. **Data Layer** (`data/`)
3. **Core Layer** (`core/`)

## Layer Breakdown

### 1. Presentation Layer
Located in `features/`, this layer contains all UI components organized by feature.

#### Structure
```
features/
├── auth/           # Authentication screens
├── home/           # Dashboard
├── banks/          # Bank accounts feature
├── retirement/     # Retirement accounts feature
├── investments/    # Investments feature
├── properties/     # Properties feature
└── vehicles/       # Vehicles feature
```

#### Pattern
Each feature follows a consistent pattern:
- **List Screen**: Displays all items in a category
- **Form Screen**: Add/edit items
- **Shared Logic**: Uses DatabaseHelper for data operations

#### Key Components
- **AuthScreen**: Biometric authentication gateway
- **HomeScreen**: Central dashboard with category overview
- **List Screens**: CRUD operations with pull-to-refresh
- **Form Screens**: Validated input forms with sections

### 2. Data Layer
Located in `data/`, this layer handles all data operations.

#### Models (`data/models/`)
All models extend `BaseAsset` for consistency:
- **BaseAsset**: Abstract base class with common fields
- **BankAccount**: Bank account data model
- **RetirementAccount**: Retirement account data model
- **Investment**: Investment data model
- **Property**: Property data model
- **Vehicle**: Vehicle data model

Each model includes:
- Constructor with optional parameters
- `toMap()`: Converts to database-friendly map
- `fromMap()`: Creates instance from database map
- Field validation

#### Database (`data/database/`)
**DatabaseHelper** is a singleton that manages:
- Database creation and versioning
- CRUD operations for all asset types
- Automatic encryption/decryption
- Transaction management

##### Database Design
- **Single database file**: `legacy_vault.db`
- **One table per category**: Optimized queries
- **Encrypted fields**: Sensitive data encrypted at rest
- **Indexed queries**: Fast retrieval

### 3. Core Layer
Located in `core/`, this layer contains shared utilities and configurations.

#### Constants (`core/constants/`)
**AppConstants**: Centralized constants for:
- App name and version
- Database configuration
- Security settings
- Category names

#### Theme (`core/theme/`)
**AppTheme**: Comprehensive theme configuration
- Color palette (primary, secondary, accent)
- Typography system (Google Fonts)
- Component themes (buttons, cards, inputs)
- Gradients and shadows
- Material Design 3 compliance

#### Utilities (`core/utils/`)

##### EncryptionHelper
- **Singleton pattern**: One instance app-wide
- **AES-256-CBC encryption**: Industry standard
- **Key Management**: Secure key generation and storage
- **IV Generation**: Unique IV per encryption
- **Methods**:
  - `initialize()`: Sets up encryption key
  - `encryptData()`: Encrypts plaintext
  - `decryptData()`: Decrypts ciphertext
  - `resetEncryption()`: Clears keys (for reset)

##### BiometricHelper
- **Singleton pattern**: Consistent authentication
- **Platform Detection**: Checks device capabilities
- **Authentication Types**: Fingerprint, Face ID, PIN
- **Methods**:
  - `canCheckBiometrics()`: Checks availability
  - `isDeviceSupported()`: Device capability check
  - `getAvailableBiometrics()`: Lists available methods
  - `authenticate()`: Performs authentication

## Data Flow

### 1. App Initialization
```
main() 
  → Initialize encryption
  → Set system UI
  → Launch app
  → Navigate to AuthScreen
```

### 2. Authentication Flow
```
AuthScreen
  → Check biometric availability
  → Prompt for authentication
  → On success → HomeScreen
  → On failure → Show error & retry
```

### 3. Data Read Flow
```
List Screen
  → Call DatabaseHelper.getAll*()
  → DatabaseHelper queries database
  → Decrypt sensitive fields
  → Convert to model objects
  → Update UI
```

### 4. Data Write Flow
```
Form Screen
  → Validate input
  → Create/update model
  → Call DatabaseHelper.insert*/update*()
  → Encrypt sensitive fields
  → Write to database
  → Navigate back
  → Refresh list
```

## Security Architecture

### Multi-Layer Security

#### Layer 1: Device Security
- Biometric authentication
- Device PIN/pattern fallback
- No cloud storage

#### Layer 2: Encryption
- AES-256-CBC encryption
- Unique IV per encryption
- Secure key storage (Keychain/KeyStore)

#### Layer 3: Field-Level Protection
- Only sensitive fields encrypted
- Non-sensitive data unencrypted (for queries)
- Granular control

### Encryption Process
```
Plaintext
  → Generate random IV (16 bytes)
  → Encrypt with AES-256-CBC
  → Combine: base64(IV) + ':' + base64(ciphertext)
  → Store in database
```

### Decryption Process
```
Encrypted String
  → Split by ':'
  → Decode IV from base64
  → Decode ciphertext from base64
  → Decrypt with AES-256-CBC
  → Return plaintext
```

## UI/UX Architecture

### Design System

#### Color System
- **Primary**: Deep Blue (#1A237E) - Trust, security
- **Secondary**: Blue (#0D47A1) - Professionalism
- **Accent**: Light Blue (#00B0FF) - Modern touch
- **Background**: Light Gray (#F5F7FA) - Clean, minimal
- **Error**: Red (#D32F2F) - Clear warnings
- **Success**: Green (#388E3C) - Positive feedback

#### Typography
- **Font Family**: Inter (Google Fonts)
- **Scale**: 6 levels (Display, Headline, Title, Body, Label)
- **Weights**: Regular (400), Medium (500), Semibold (600), Bold (700)

#### Spacing System
- **Base Unit**: 4px
- **Common Spacing**: 8, 12, 16, 20, 24, 32px
- **Consistent Padding**: 16px standard, 24px for sections

#### Component Design
- **Cards**: Rounded corners (16px), subtle shadows
- **Buttons**: Large touch targets (48px min height)
- **Forms**: Clear labels, helpful hints, inline validation
- **Icons**: Consistent size (24px standard)

### Navigation Patterns

#### Primary Navigation
```
AuthScreen → HomeScreen → Category List → Item Details
```

#### Modal Navigation
```
List Screen → Form Screen (push)
           ← Back (pop)
```

### User Feedback
- **Loading States**: Progress indicators
- **Empty States**: Helpful messaging with icons
- **Error States**: Clear error messages
- **Success States**: Snackbar notifications
- **Confirmation Dialogs**: For destructive actions

## Performance Considerations

### Database Optimization
- Indexed primary keys (UUID)
- Query only needed fields
- Lazy loading for large datasets
- Efficient data types

### Memory Management
- Dispose controllers properly
- Close database connections
- Clear cached data
- Efficient list rendering

### UI Performance
- ListView.builder for lists
- Const constructors where possible
- Minimize rebuilds
- Efficient state management

## Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Encryption/decryption logic
- Database CRUD operations
- Validation logic

### Integration Tests
- End-to-end workflows
- Database transactions
- Security features

### UI Tests
- Screen navigation
- Form validation
- User interactions

## Scalability

### Current Limits
- Local SQLite database: 1000s of records
- Single user per device
- No cloud sync

### Growth Path
1. **Phase 1**: Current implementation
2. **Phase 2**: Add cloud backup
3. **Phase 3**: Multi-device sync
4. **Phase 4**: Family sharing features

## Maintenance

### Code Organization
- Feature-based folders
- Single responsibility principle
- DRY (Don't Repeat Yourself)
- Consistent naming conventions

### Documentation
- Inline comments for complex logic
- README for setup
- This architecture doc for structure
- API documentation for public methods

## Deployment

### Build Process
```bash
# Development
flutter run

# Production (Android)
flutter build apk --release

# Production (iOS)
flutter build ios --release
```

### Version Management
- Semantic versioning (MAJOR.MINOR.PATCH)
- Version in pubspec.yaml
- Build number auto-increment

---

This architecture provides a solid foundation for a secure, maintainable, and scalable mobile application.
