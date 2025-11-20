# WisdomWalk - Christian Women's Community App

A comprehensive social platform designed for Christian women to connect, share, pray, and support each other through various community features.

## 📱 Project Overview

WisdomWalk is a full-stack application consisting of three main components:
- **Backend API** - Node.js/Express REST API with Socket.IO for real-time features
- **Mobile App** - Flutter/Dart cross-platform mobile application
- **Admin Dashboard** - Next.js/React TypeScript web dashboard for administration

## ✨ Key Features

### User Features
- **Two-Step Verification System**
  - Email verification with OTP codes
  - Admin verification with live photo and national ID upload
  - Secure account access control

- **Community Groups**
  - Single & Purposeful
  - Marriage & Ministry
  - Healing & Forgiveness
  - Motherhood in Christ
  - Group-specific content and discussions

- **Content Sharing**
  - Prayer requests with prayer responses
  - Anonymous sharing (testimonies, confessions, struggles)
  - Virtual hugs with scripture verses
  - Post likes, comments, and engagement

- **Real-Time Chat**
  - Direct messaging between users
  - Group chat rooms
  - Message reactions and replies
  - File attachments (images, videos, documents)
  - Online status indicators

- **Events & Bookings**
  - Virtual events (Zoom/Google Meet integration)
  - Event booking system
  - Event notifications

- **Her Move Feature**
  - Location-based requests
  - Search and connect with nearby users
  - Location sharing functionality

### Admin Features
- User verification management
- Content moderation (posts, comments, messages)
- Report handling system
- User management (block, ban, unblock)
- Group administration
- Notification broadcasting
- Dashboard analytics and statistics

## 🛠️ Tech Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT (JSON Web Tokens)
- **Real-time**: Socket.IO
- **File Storage**: Cloudinary
- **Email Service**: Resend/Nodemailer
- **Security**: Helmet, CORS, Rate Limiting, bcrypt

### Frontend (Mobile)
- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Provider
- **Routing**: GoRouter
- **HTTP Client**: http package
- **Local Storage**: shared_preferences, flutter_secure_storage
- **Real-time**: socket_io_client
- **Image Handling**: cached_network_image, image_picker

### Admin Dashboard
- **Framework**: Next.js 15
- **Language**: TypeScript
- **UI Library**: React 19
- **Styling**: Tailwind CSS
- **Components**: Radix UI, shadcn/ui
- **Charts**: Chart.js, Recharts
- **Forms**: React Hook Form with Zod validation

## 📁 Project Structure

```
Wisdom-Walk-App/
├── Backend/                 # Node.js/Express API
│   ├── config/             # Database, Cloudinary, Multer configs
│   ├── controllers/        # Route controllers
│   ├── middleware/         # Auth, validation, upload middleware
│   ├── models/             # MongoDB schemas
│   ├── routes/             # API routes
│   ├── socket/             # Socket.IO handlers
│   ├── utils/              # Helper functions, email service
│   └── server.js           # Entry point
│
├── Frontend/               # Flutter mobile app
│   └── wisdomwalk/
│       ├── lib/
│       │   ├── models/     # Data models
│       │   ├── providers/  # State management
│       │   ├── services/   # API services
│       │   ├── views/      # UI screens
│       │   ├── widgets/    # Reusable widgets
│       │   ├── routing/    # Navigation
│       │   └── themes/     # App theming
│       └── pubspec.yaml    # Dependencies
│
└── admin-dashboard/        # Next.js admin panel
    ├── app/                # Next.js app directory
    │   ├── api/            # API routes
    │   ├── dashboard/      # Dashboard pages
    │   └── login/          # Admin login
    ├── components/         # React components
    └── lib/                # Utilities, API helpers
```

## 🚀 Getting Started

### Prerequisites

- **Node.js** (v18 or higher)
- **MongoDB** (local or cloud instance)
- **Flutter SDK** (v3.7.2 or higher)
- **npm** or **yarn**
- **Cloudinary account** (for file storage)
- **Email service** (Resend API key or SMTP credentials)

### Backend Setup

1. Navigate to the Backend directory:
```bash
cd Backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file in the Backend directory:
```env
# Server
PORT=5000
NODE_ENV=development

# Database
MONGO_URI=your_mongodb_connection_string

# JWT
JWT_SECRET=your_jwt_secret_key

# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Email (Resend)
RESEND_API_KEY=your_resend_api_key
ADMIN_EMAIL=admin@wisdomwalk.com

# CORS
FRONTEND_URL=http://localhost:3000
MOBILE_APP_URL=http://localhost
```

4. Start MongoDB (if running locally)

5. Seed the database (optional):
```bash
npm run seed
```

6. Start the development server:
```bash
npm run dev
```

The API will be available at `http://localhost:5000`

### Frontend (Mobile App) Setup

1. Navigate to the Frontend directory:
```bash
cd Frontend/wisdomwalk
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update the API base URL in `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://your-backend-url/api';
```

4. Run the app:
```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For specific device
flutter devices
flutter run -d <device-id>
```

### Admin Dashboard Setup

1. Navigate to the admin-dashboard directory:
```bash
cd admin-dashboard
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env.local` file:
```env
NEXT_PUBLIC_API_URL=http://localhost:5000/api
```

4. Start the development server:
```bash
npm run dev
```

The admin dashboard will be available at `http://localhost:3000`

## 📚 API Documentation

### Base URL
```
http://localhost:5000/api
```

### Authentication Endpoints
- `POST /api/auth/register` - Register new user (requires live photo and national ID)
- `POST /api/auth/login` - User login
- `POST /api/auth/verify` - Verify email with OTP code
- `POST /api/auth/resend-verification` - Resend verification email
- `POST /api/auth/forgot-password` - Request password reset
- `POST /api/auth/reset-password` - Reset password with code
- `POST /api/auth/change-password` - Change password (authenticated)
- `POST /api/auth/logout` - Logout user

### User Endpoints
- `GET /api/users/profile` - Get current user profile
- `PUT /api/users/profile` - Update profile
- `POST /api/users/profile-photo` - Update profile photo
- `GET /api/users/search?q=query` - Search users
- `GET /api/users/recent` - Get recent active users
- `GET /api/users/:userId` - Get user by ID
- `POST /api/users/block` - Block a user
- `POST /api/users/unblock` - Unblock a user
- `PUT /api/users/online-status` - Update online status

### Post Endpoints
- `GET /api/posts` - Get all posts (with filters: type, category)
- `POST /api/posts` - Create new post
- `GET /api/posts/:postId` - Get single post
- `PUT /api/posts/:postId` - Update post
- `DELETE /api/posts/:postId` - Delete post
- `POST /api/posts/:postId/like` - Like/unlike post
- `POST /api/posts/:postId/prayer` - Add prayer response
- `POST /api/posts/:postId/virtual-hug` - Send virtual hug
- `GET /api/posts/:postId/comments` - Get post comments

### Chat Endpoints
- `GET /api/chats` - Get user's chats
- `POST /api/chats/direct` - Create direct chat
- `GET /api/chats/:chatId/messages` - Get chat messages
- `POST /api/chats/:chatId/messages` - Send message
- `PUT /api/chats/messages/:messageId` - Edit message
- `DELETE /api/chats/messages/:messageId` - Delete message
- `POST /api/chats/messages/:messageId/reaction` - Add reaction

### Group Endpoints
- `GET /api/groups` - Get user's groups
- `POST /api/groups/join` - Join a group
- `POST /api/groups/leave` - Leave a group
- `GET /api/groups/:groupType/info` - Get group information
- `GET /api/groups/:groupType/posts` - Get group posts
- `GET /api/groups/:groupType/members` - Get group members
- `GET /api/groups/:groupType/stats` - Get group statistics
- `GET /api/groups/:groupType/chats` - Get group chats
- `POST /api/groups/:groupType/chats/:chatId/messages` - Send group message

### Event Endpoints
- `GET /api/events` - Get all events
- `POST /api/events` - Create event (admin)
- `GET /api/events/:id` - Get single event
- `PUT /api/events/:id` - Update event (admin)
- `DELETE /api/events/:id` - Delete event (admin)

### Notification Endpoints
- `GET /api/notifications` - Get user notifications
- `PUT /api/notifications/:id/read` - Mark notification as read
- `POST /api/notifications/reports` - Submit content report

### Admin Endpoints
- `GET /api/admin/verifications/pending` - Get pending verifications
- `POST /api/admin/users/:userId/verify` - Verify/reject user
- `GET /api/admin/users` - Get all users (with filters)
- `POST /api/admin/users/:userId/block` - Block/unblock user
- `POST /api/admin/users/:userId/ban` - Ban user
- `GET /api/admin/reports` - Get reported content
- `POST /api/admin/reports/:reportId/handle` - Handle report
- `POST /api/admin/notifications/send` - Send notifications
- `GET /api/admin/dashboard-stats` - Get dashboard statistics

## 🔐 Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

Tokens can also be sent via cookies (httpOnly, secure in production).

## 📱 Mobile App Features

### Screens
- Welcome/Onboarding
- Login/Registration (multi-step)
- OTP Verification
- Dashboard (main feed)
- Prayer Wall
- Anonymous Share
- Wisdom Circles
- Her Move (location features)
- Chat (direct & group)
- Profile
- Settings
- Notifications

### State Management
The app uses Provider for state management with the following providers:
- `AuthProvider` - Authentication state
- `UserProvider` - User data
- `PrayerProvider` - Prayer posts
- `WisdomCircleProvider` - Group management
- `ChatProvider` - Chat functionality
- `NotificationProvider` - Notifications
- `EventProvider` - Events

## 🎨 Admin Dashboard Features

### Pages
- Dashboard (overview statistics)
- User Management
- User Verifications
- Posts Management
- Groups Management
- Reports Management
- Events Management
- Bookings Management
- Notifications
- Settings

### Features
- Real-time statistics
- User verification workflow
- Content moderation tools
- Report handling system
- Bulk notification sending
- Analytics and insights

## 🔒 Security Features

- JWT-based authentication
- Password hashing with bcrypt (12 rounds)
- Rate limiting on API endpoints
- Input validation and sanitization
- File upload validation
- CORS protection
- Helmet.js security headers
- Secure cookie handling
- Two-factor verification system

## 📦 Database Models

### User Model
- Profile information
- Verification status (email & admin)
- Group memberships
- Preferences and settings
- Blocked users list
- Online status

### Post Model
- Content and media
- Post type (prayer/share)
- Category (testimony/confession/struggle)
- Anonymous flag
- Engagement metrics (likes, prayers, hugs)
- Comments count

### Chat & Message Models
- Direct and group chats
- Message content and attachments
- Read receipts
- Reactions
- Reply threads

### Group Models
- Single, Marriage, Healing, Motherhood groups
- Group-specific posts
- Member management
- Admin roles

## 🧪 Testing

### Backend
```bash
cd Backend
npm test
```

### Frontend
```bash
cd Frontend/wisdomwalk
flutter test
```

## 🚢 Deployment

### Backend
The backend can be deployed to:
- Render
- Heroku
- AWS EC2
- DigitalOcean
- Railway

Ensure environment variables are set in your hosting platform.

### Frontend (Mobile)
```bash
# Build Android APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

### Admin Dashboard
```bash
cd admin-dashboard
npm run build
npm start
```

Deploy to:
- Vercel (recommended for Next.js)
- Netlify
- AWS Amplify
- Any Node.js hosting platform

## 📝 Environment Variables

### Backend (.env)
```env
PORT=5000
NODE_ENV=production
MONGO_URI=mongodb://...
JWT_SECRET=your_secret
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
RESEND_API_KEY=...
ADMIN_EMAIL=...
FRONTEND_URL=...
MOBILE_APP_URL=...
```

### Admin Dashboard (.env.local)
```env
NEXT_PUBLIC_API_URL=https://your-api-url.com/api
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Support

For support, email bekelueshete@gmail.com or tommr2323@gmail.com or  create an issue in the repository.

## 🙏 Acknowledgments

- Built with love for the Christian women's community
- Special thanks to all contributors and testers

---

**WisdomWalk** - Walking in wisdom, growing in faith, connecting in love.
