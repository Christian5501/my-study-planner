
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_planner/main.dart';
import 'package:study_planner/database_helper.dart';

// Create a mock database helper
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockDatabaseHelper mockDatabase;

  setUp(() {
    mockDatabase = MockDatabaseHelper();

    // Provide sample goals when the dashboard loads
    when(() => mockDatabase.getGoals()).thenAnswer(
      (_) async => [
        {
          'id': 1,
          'subject': 'Mobile Development',
          'hours': 3,
          'done': true,
        },
        {
          'id': 2,
          'subject': 'Database Systems',
          'hours': 2,
          'done': false,
        },
      ],
    );
  });

  testWidgets(
    'Dashboard displays goals and correct statistics',
    (tester) async {
      await tester.pumpWidget(
        MyApp(database: mockDatabase),
      );

      // Wait for the database loading operation
      await tester.pumpAndSettle();

      // Check dashboard title and heading
      expect(find.text('My Study Planner'), findsOneWidget);
      expect(find.text('My Study Goals'), findsOneWidget);

      // Check sample goals
      expect(find.text('Mobile Development'), findsOneWidget);
      expect(find.text('Database Systems'), findsOneWidget);

      // Check study hours
      expect(find.text('3 hours'), findsOneWidget);
      expect(find.text('2 hours'), findsOneWidget);

      // Check statistics
      expect(find.text('5'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));

      // Check statistic labels
      expect(find.text('Total Hours'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);

      // Verify the database was called
      verify(() => mockDatabase.getGoals()).called(1);
    },
  );
}
