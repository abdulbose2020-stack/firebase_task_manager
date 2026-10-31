# Firebase Task Manager

A Flutter task management application powered by Firebase. It allows users to manage their tasks, organize their workload, and securely access their own data through Firebase Authentication and Cloud Firestore.

## Features

- **Anonymous Authentication:** Users can access the application as guests.
- **Task Management:** Create, view, edit, complete, and delete tasks.
- **Task Priorities:** Organize tasks by High, Medium, and Low priority.
- **Task Filtering:** Filter tasks by All, Pending, and Completed.
- **Pagination:** Load tasks in pages to avoid fetching the entire collection at once.
- **Real-time Updates:** Receive task updates through Firestore streams.
- **User Profiles:** Manage user profile information.
- **Profile Image Upload:** Firebase Storage upload implementation is included; activating this feature requires the Blaze plan and a configured Storage bucket.
- **Email Verification:** Support for email verification.
- **Firebase App Check:** Add an application-integrity verification layer.
- **Crash Reporting:** Capture application crashes and errors with Firebase Crashlytics.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Programming language |
| Firebase Authentication | User authentication |
| Cloud Firestore | Cloud database |
| Firebase Storage | Profile image storage |
| Firebase App Check | Application verification |
| Firebase Crashlytics | Crash monitoring |
| Firebase Emulator Suite | Local development and testing |
| Node.js | Firestore security rules testing |
| Git and GitHub | Version control |

## Security

The application uses Firebase Authentication and Firestore Security Rules to protect user data.

The Firestore rules enforce ownership checks so that authenticated users can access and modify only their own tasks.

Automated security tests cover:

- Reading an authenticated user's own task.
- Preventing another user from reading that task.
- Preventing unauthorized updates and deletions.
- Preventing users from creating tasks under another user's ownership.
- Blocking unauthenticated reads.

## Project Structure

```text
lib/
|-- models/
|-- screens/
|-- services/
|-- widgets/
|-- firebase_options.dart
|-- main.dart

tests/
|-- firestore.rules.test.js

android/
firebase.json
firestore.rules
package.json
pubspec.yaml
```

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or another supported IDE
- Node.js and npm
- A Firebase project

### Installation

1. Clone the repository:

```bash
git clone https://github.com/abdulbose2020-stack/firebase_task_manager.git
```

2. Enter the project directory:

```bash
cd firebase_task_manager
```

3. Install Flutter dependencies:

```bash
flutter pub get
```

4. Configure your own Firebase project using FlutterFire CLI:

```bash
flutterfire configure
```

5. Install the Node.js testing dependencies:

```bash
npm install
```

6. Start the Firebase emulators:

```bash
firebase emulators:start
```

7. In another terminal, run the application:

```bash
flutter run
```

**Note:** Configure Firebase Authentication, Firestore, Storage, and App Check in your own Firebase project before running the application. Use your own Firebase configuration rather than committing private credentials or debug tokens.

## Running Security Tests

Start the Firebase Emulator Suite, then run:

```bash
npm test
```

The automated tests verify the Firestore security rules using authenticated and unauthenticated test users.

## Screenshots and Demo

Screenshots and a demonstration video will be added here.

## Known Limitations

- Authentication currently supports anonymous guest access; additional sign-in methods may be added.
- Production release configuration and deployment still require final verification.
- App Check production enforcement must be configured and verified before release.
- Firebase usage and billing limits depend on the selected Firebase plan and actual application usage.

## Future Improvements

- Additional authentication providers.
- Push notifications for task reminders.
- More advanced task organization and search.
- Improved production monitoring and analytics.

## Author

**Abdullahi Ahmad Bose**

Flutter Developer | Computer and Communication Engineering Student

GitHub: [abdulbose2020-stack](https://github.com/abdulbose2020-stack)

---

Built as part of a hands-on Flutter and Firebase learning journey.