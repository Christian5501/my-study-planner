# My Study Planner

My Study Planner is a Flutter application developed to help students organize and manage their study goals.

## Features

- Add study goals with a subject and allocated study hours.
- View all saved study goals.
- Mark goals as completed or incomplete.
- Delete study goals.
- View study statistics, including total study hours, completed goals, and remaining goals.
- Store study goals locally using SQLite so that data remains available after closing and reopening the application.

## Technologies Used

- **Flutter** – Application development framework.
- **Dart** – Programming language.
- **SQLite** – Local database storage.
- **sqflite** – Flutter package for SQLite database operations.
- **Mocktail** – Mocking dependency for automated tests.

## Project Structure

```text
lib/
├── main.dart
└── database_helper.dart

test/
└── widget_test.dart
```

## Getting Started

### Requirements

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code

### Installation

1. Clone the repository.
2. Open the project directory.
3. Install dependencies:

```bash
flutter pub get
```

4. Run the application:

```bash
flutter run
```

## Testing

Run the automated tests:

```bash
flutter test
```

Check code quality:

```bash
flutter analyze
```

## Database

The application uses a local SQLite database named `goals.db`.

The `goals` table stores:

| Field | Description |
|---|---|
| id | Unique goal identifier |
| subject | Study subject |
| hours | Allocated study hours |
| done | Completion status |

## Developer

Christian Muhire

## Project Purpose

This project demonstrates Flutter application development, state management, navigation, form validation, reusable widgets, SQLite database integration, and asynchronous programming.
