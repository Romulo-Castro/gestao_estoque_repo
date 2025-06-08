# OpenAI Codex Configuration Script
# Sistema de Gestão de Estoque PRO - Flutter/Node.js

## Project Overview
This is a complete inventory management system with Flutter frontend and Node.js backend using Clean Architecture principles.

### Project Structure
```
gestao_estoque_repo/
├── backend/           # Node.js Express API with Clean Architecture
├── frontend/          # Flutter mobile app with Provider state management  
├── docs/             # Project documentation
└── scripts/          # Utility and test scripts
```

### Technology Stack
**Backend:**
- Node.js 18+ with Express.js
- SQLite database
- JWT authentication
- Clean Architecture (Controllers, Use Cases, Repositories)
- Security: Rate limiting, Helmet, attack detection
- File uploads with Multer

**Frontend:**
- Flutter 3.0+ with Dart 3.7+
- Provider for state management
- HTTP client for API communication
- Image picker, camera, barcode scanner
- PDF generation and printing
- Excel/CSV export capabilities

### Key Dependencies
**Frontend (pubspec.yaml):**
```yaml
dependencies:
  flutter: sdk
  http: ^0.13.5
  provider: ^6.1.2
  camera: ^0.10.0
  image_picker: ^1.0.0
  mobile_scanner: ^7.0.1
  flutter_secure_storage: ^9.2.2
  file_picker: ^10.1.9
  pdf: ^3.10.8
  printing: ^5.12.0
  excel: ^4.0.6
  csv: ^6.0.0
  get_it: ^7.6.4
  equatable: ^2.0.5
```

**Backend (package.json):**
```json
{
  "dependencies": {
    "express": "^4.21.2",
    "sqlite3": "^5.1.7",
    "bcryptjs": "^3.0.2",
    "jsonwebtoken": "^9.0.2",
    "cors": "^2.8.5",
    "helmet": "^8.0.0",
    "express-rate-limit": "^7.5.0",
    "express-validator": "^7.2.1",
    "multer": "^1.4.5-lts.1",
    "mime-types": "^2.1.35"
  }
}
```

## Architecture Patterns

### Backend Clean Architecture
```
src/
├── core/
│   ├── domain/         # Entities and business rules
│   ├── usecases/       # Application business logic
│   └── interfaces/     # Repository and service contracts
├── data/
│   ├── repositories/   # Data access implementations
│   ├── datasources/    # External data sources (SQLite)
│   └── models/         # Data models and DTOs
├── presentation/
│   ├── controllers/    # Route handlers
│   ├── middleware/     # Authentication, validation, security
│   └── routes/         # API route definitions
└── shared/
    ├── utils/          # Utility functions
    └── config/         # Configuration management
```

### Frontend Clean Architecture
```
lib/
├── core/
│   ├── domain/         # Entities and use cases
│   ├── data/           # Repositories and data sources
│   └── presentation/   # Screens, widgets, and providers
├── shared/
│   ├── utils/          # Utility functions
│   ├── widgets/        # Reusable UI components
│   └── constants/      # App constants
└── main.dart           # App entry point
```

## Core Features

### 1. Authentication & Authorization
- JWT-based authentication
- User registration and login
- Token refresh mechanism
- Role-based access control
- Secure storage with flutter_secure_storage

### 2. Stock Management
- CRUD operations for stock items
- Multi-store support
- Image upload and management
- Barcode scanning and generation
- Property-based item categorization
- Quantity tracking with decimal precision

### 3. Document Processing
- Entry/Exit document creation
- Item quantity adjustments
- Document validation and processing
- PDF report generation
- Document history tracking

### 4. Reporting & Analytics
- Dashboard with real-time statistics
- Stock level monitoring
- Low stock alerts
- PDF report generation
- Excel/CSV data export

### 5. Multi-Store Support
- Store selection and management
- Per-store inventory tracking
- Store-specific user access

## API Endpoints Structure

### Authentication
```
POST /api/auth/register    # User registration
POST /api/auth/login       # User login
POST /api/auth/refresh     # Token refresh
```

### Stock Items
```
GET    /api/stores/:storeId/stock-items          # List items
POST   /api/stores/:storeId/stock-items          # Create item
GET    /api/stores/:storeId/stock-items/:id      # Get item
PUT    /api/stores/:storeId/stock-items/:id      # Update item
DELETE /api/stores/:storeId/stock-items/:id      # Delete item
POST   /api/stores/:storeId/stock-items/:id/image # Upload image
DELETE /api/stores/:storeId/stock-items/:id/image # Delete image
```

### Documents
```
GET    /api/stores/:storeId/documents            # List documents
POST   /api/stores/:storeId/documents            # Create document
GET    /api/stores/:storeId/documents/:id        # Get document
PUT    /api/stores/:storeId/documents/:id        # Update document
DELETE /api/stores/:storeId/documents/:id        # Delete document
POST   /api/stores/:storeId/documents/:id/process # Process document
```

### Stores & Dashboard
```
GET /api/stores                    # List user stores
GET /api/stores/:id/dashboard      # Store dashboard data
```

## Database Schema

### Core Tables
```sql
users (id, username, email, password_hash, created_at, updated_at)
stores (id, name, description, owner_id, created_at, updated_at)
user_stores (user_id, store_id, role, created_at)
stock_items (id, store_id, name, quantity, image_url, properties, group_id, created_at, updated_at)
item_groups (id, store_id, name, description, created_at, updated_at)
documents (id, store_id, type, status, total_items, created_by, created_at, updated_at)
document_items (id, document_id, stock_item_id, quantity, description)
customers (id, store_id, name, email, phone, address, created_at, updated_at)
suppliers (id, store_id, name, email, phone, address, created_at, updated_at)
```

## Security Features

### Rate Limiting
- Authentication endpoints: 5 requests per 15 minutes
- General API: 100 requests per 15 minutes
- Upload endpoints: 10 requests per minute

### Input Validation
- Express-validator for request validation
- SQL injection prevention
- XSS protection with helmet
- File upload restrictions (type, size)

### Error Handling
- Centralized error handling middleware
- Security-aware error responses
- Attack detection and logging

## State Management (Flutter)

### Provider Pattern
```dart
// Main providers used in the app
AuthProvider          # Authentication state and user management
StockItemProvider     # Stock items CRUD and state
DocumentProvider      # Document management
ItemGroupProvider     # Item groups/categories
StoreProvider         # Multi-store management
```

### Data Flow
1. UI triggers action through Provider
2. Provider calls Repository/DataSource
3. Repository makes HTTP request to API
4. Response updates Provider state
5. UI rebuilds automatically via Consumer/Selector

## Common Patterns & Best Practices

### Error Handling
```dart
// Frontend error handling pattern
try {
  final result = await apiService.someOperation();
  // Handle success
} catch (e) {
  ErrorHandler.handleError(e); // Centralized error handling
  showErrorSnackbar(context, ErrorHandler.getErrorMessage(e));
}
```

### API Response Format
```json
{
  "success": true,
  "data": { /* response data */ },
  "message": "Operation completed successfully",
  "timestamp": "2025-06-07T10:30:00Z"
}
```

### Loading States
```dart
// Common loading state pattern
bool _isLoading = false;

Future<void> _performOperation() async {
  setState(() => _isLoading = true);
  try {
    // Perform operation
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

## Development Workflow

### Setup Commands
```bash
# Backend setup
cd backend
npm install
npm run dev

# Frontend setup  
cd frontend
flutter pub get
flutter run
```

### Testing
```bash
# Backend testing
npm test
npm run test:security

# Frontend testing
flutter test
flutter test integration_test/
```

## File Upload Handling

### Backend (Multer + Content-Type Detection)
```javascript
// Proper MIME type detection for uploaded files
const getContentType = (filename) => {
  const ext = path.extname(filename).toLowerCase();
  const mimeTypes = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg', 
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.bmp': 'image/bmp',
    '.webp': 'image/webp'
  };
  return mimeTypes[ext] || 'application/octet-stream';
};
```

### Frontend (Image Picker + File Upload)
```dart
// Image upload with proper content type
final contentType = getContentTypeFromExtension(file.path);
final multipartFile = await http.MultipartFile.fromPath(
  'image',
  file.path,
  contentType: MediaType.parse(contentType),
);
```

## Navigation & UI Patterns

### Screen Navigation
```dart
// Safe navigation patterns to avoid Navigator locks
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => SomeScreen()),
);

// With result handling
final result = await Navigator.push<ResultType>(
  context,
  MaterialPageRoute(builder: (_) => EditScreen()),
);
if (result != null) {
  // Handle result
}
```

### Form Validation
```dart
final _formKey = GlobalKey<FormState>();

// Validation pattern
TextFormField(
  validator: (value) {
    if (value?.trim().isEmpty ?? true) return 'Field is required';
    // Additional validation
    return null;
  },
)
```

## Performance Considerations

### Image Optimization
- Automatic image compression on upload
- Thumbnail generation for galleries
- Lazy loading for image lists
- Cache management with appropriate headers

### State Optimization
- Selector widgets to prevent unnecessary rebuilds
- Proper dispose() methods for controllers
- Memory leak prevention with mounted checks

## Deployment Notes

### Backend Deployment
- Environment variables for configuration
- SQLite database with proper permissions
- File upload directory configuration
- Security headers and CORS setup

### Frontend Deployment
- Build configurations for different environments
- API endpoint configuration
- Secure storage configuration
- Platform-specific permissions

## Troubleshooting Common Issues

### Navigator Lock Errors
- Use `addPostFrameCallback` for state updates during build
- Check `mounted` before navigation operations
- Avoid nested Navigator operations

### Image Upload Issues  
- Ensure proper MIME type detection
- Check file size limits
- Validate file extensions
- Handle network errors gracefully

### Authentication Issues
- Token expiration handling
- Secure storage fallbacks
- Login state persistence
- API token refresh logic

This configuration provides comprehensive context for understanding and working with the Flutter/Node.js inventory management system with Clean Architecture principles.
