import 'package:material_ui/material_ui.dart';
import 'package:firebase_core/firebase_core.dart';

import 'database_helper.dart';
import 'firebase_options.dart';

// LOGIC: Initialize Firebase and the local database
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize storage for Android and web
  await DatabaseHelper.instance.initialize();

  runApp(const MyApp());
}

// STATIC: Main application widget
class MyApp extends StatelessWidget {
  final DatabaseHelper? database;

  const MyApp({super.key, this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Study Planner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StudyPlannerHome(database: database),
    );
  }
}

// LOGIC: Main study planner screen
class StudyPlannerHome extends StatefulWidget {
  final DatabaseHelper? database;

  const StudyPlannerHome({super.key, this.database});

  @override
  State<StudyPlannerHome> createState() => _StudyPlannerHomeState();
}

class _StudyPlannerHomeState extends State<StudyPlannerHome> {
  // LOGIC: Select the database used by this screen
  DatabaseHelper get database => widget.database ?? DatabaseHelper.instance;

  // LOGIC: Store goals loaded from the database
  List<Map<String, dynamic>> goals = [];

  bool isLoading = true;

  // LOGIC: Calculate total study hours
  int get totalHours {
    return goals.fold<int>(0, (sum, goal) => sum + (goal['hours'] as int));
  }

  // LOGIC: Count completed goals
  int get completedGoals {
    return goals.where((goal) => goal['done'] == true).length;
  }

  // LOGIC: Count remaining goals
  int get remainingGoals {
    return goals.where((goal) => goal['done'] == false).length;
  }

  // LOGIC: Load saved goals when the screen starts
  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  Future<void> loadGoals() async {
    try {
      final savedGoals = await database.getGoals();

      if (!mounted) return;

      setState(() {
        goals = savedGoals;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load study goals.')),
      );
    }
  }

  // LOGIC: Open the Add Goal screen and save its result
  Future<void> openAddGoalScreen() async {
    final newGoal = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const AddGoalScreen()),
    );

    if (!mounted || newGoal == null) return;

    try {
      // CONNECTION: Insert the new goal into SQLite
      final id = await database.insertGoal(newGoal);

      if (!mounted) return;

      // CONNECTION: Add the saved goal to the screen
      setState(() {
        goals.add({...newGoal, 'id': id});
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the study goal.')),
      );
    }
  }

  // LOGIC: Update completion status in SQLite
  Future<void> toggleGoal(int index, bool? value) async {
    final updatedGoal = {...goals[index], 'done': value ?? false};

    try {
      // CONNECTION: Update the database
      await database.updateGoal(updatedGoal);

      if (!mounted) return;

      setState(() {
        goals[index] = updatedGoal;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the study goal.')),
      );
    }
  }

  // LOGIC: Delete a goal from SQLite
  Future<void> deleteGoal(int index) async {
    final goal = goals[index];

    try {
      // CONNECTION: Delete the goal from the database
      await database.deleteGoal(goal['id'] as int);

      if (!mounted) return;

      setState(() {
        goals.removeAt(index);
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the study goal.')),
      );
    }
  }

  // STATIC: Build the main dashboard screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Study Planner'), centerTitle: true),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // STATIC: Dashboard heading
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'My Study Goals',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),

                // STATIC: Statistics cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Hours',
                          value: totalHours.toString(),
                          icon: Icons.access_time,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          title: 'Completed',
                          value: completedGoals.toString(),
                          icon: Icons.check_circle,
                        ),
                      ),
                      Expanded(
                        child: StatCard(
                          title: 'Remaining',
                          value: remainingGoals.toString(),
                          icon: Icons.pending_actions,
                        ),
                      ),
                    ],
                  ),
                ),

                // STATIC: Display goals or empty state
                Expanded(
                  child: goals.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No study goals yet.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Tap the + button to add your first goal.'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: goals.length,
                          itemBuilder: (context, index) {
                            final goal = goals[index];
                            final isDone = goal['done'] == true;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: Checkbox(
                                  value: isDone,
                                  onChanged: (value) {
                                    toggleGoal(index, value);
                                  },
                                ),
                                title: Text(
                                  goal['subject'],
                                  style: TextStyle(
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                subtitle: Text('${goal['hours']} hours'),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    deleteGoal(index);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

      // CONNECTION: Open the Add Goal screen
      floatingActionButton: FloatingActionButton(
        onPressed: openAddGoalScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// STATIC: Reusable statistics card
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            Icon(icon, size: 25, color: Colors.blue),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// LOGIC: Screen for entering a new study goal
class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  // LOGIC: Controllers for the input fields
  final TextEditingController subjectController = TextEditingController();

  final TextEditingController hoursController = TextEditingController();

  // LOGIC: Validate and return the new goal
  void saveGoal() {
    final subject = subjectController.text.trim();
    final hours = int.tryParse(hoursController.text.trim());

    if (subject.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a subject.')));
      return;
    }

    if (hours == null || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of hours.')),
      );
      return;
    }

    // CONNECTION: Return the goal to the main screen
    Navigator.pop(context, {'subject': subject, 'hours': hours, 'done': false});
  }

  // LOGIC: Release controllers when the screen is removed
  @override
  void dispose() {
    subjectController.dispose();
    hoursController.dispose();
    super.dispose();
  }

  // STATIC: Build the Add Goal screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Study Goal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Study Hours',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveGoal,
                child: const Text('Save Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
