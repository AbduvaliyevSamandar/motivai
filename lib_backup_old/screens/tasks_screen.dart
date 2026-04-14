import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../provider/data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';
import '../widgets/custom_button.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String? _selectedCategory;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = null);
                        Provider.of<TaskProvider>(context, listen: false)
                            .filterByCategory(null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...['learning', 'health', 'productivity', 'creativity', 'social', 'exercise']
                        .map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(cat),
                            selected: _selectedCategory == cat,
                            onSelected: (selected) {
                              setState(() => _selectedCategory = selected ? cat : null);
                              Provider.of<TaskProvider>(context, listen: false)
                                  .filterByCategory(selected ? cat : null);
                            },
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Difficulty Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Levels'),
                      selected: _selectedDifficulty == null,
                      onSelected: (selected) {
                        setState(() => _selectedDifficulty = null);
                        Provider.of<TaskProvider>(context, listen: false)
                            .filterByDifficulty(null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...['easy', 'medium', 'hard'].map((diff) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(diff),
                        selected: _selectedDifficulty == diff,
                        onSelected: (selected) {
                          setState(() => _selectedDifficulty = selected ? diff : null);
                          Provider.of<TaskProvider>(context, listen: false)
                              .filterByDifficulty(selected ? diff : null);
                        },
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tasks List
              Consumer<TaskProvider>(
                builder: (context, taskProvider, _) {
                  if (taskProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (taskProvider.tasks.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No tasks available', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: taskProvider.tasks.length,
                    itemBuilder: (context, index) {
                      final task = taskProvider.tasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TaskCard(
                          task: task,
                          onTap: () => context.go('/tasks/${task.id}'),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
