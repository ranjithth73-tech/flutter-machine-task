import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/features/profile/presentation/pages/profile_page.dart';
import 'package:smart_task_manager/features/task/presentation/pages/task_form_page.dart';
import 'package:smart_task_manager/features/task/presentation/providers/task_provider.dart';
import 'package:smart_task_manager/features/task/presentation/widgets/empty_state.dart';
import 'package:smart_task_manager/features/task/presentation/widgets/offline_banner.dart';
import 'package:smart_task_manager/features/task/presentation/widgets/task_card.dart';

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).fetchTasks(refresh: true);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(taskProvider.notifier).fetchTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);
    final processedTasks = taskState.processedTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Task Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    ref.read(taskProvider.notifier).setSearchQuery(value);
                  },
                ),
                const SizedBox(height: 16),
                // Filters & Sort
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: taskState.filter == TaskFilter.all,
                        onSelected: (_) => ref.read(taskProvider.notifier).setFilter(TaskFilter.all),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pending'),
                        selected: taskState.filter == TaskFilter.pending,
                        onSelected: (_) => ref.read(taskProvider.notifier).setFilter(TaskFilter.pending),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Completed'),
                        selected: taskState.filter == TaskFilter.completed,
                        onSelected: (_) => ref.read(taskProvider.notifier).setFilter(TaskFilter.completed),
                      ),
                      const SizedBox(width: 16),
                      // Sort
                      PopupMenuButton<TaskSort>(
                        icon: const Icon(Icons.sort),
                        onSelected: (sort) => ref.read(taskProvider.notifier).setSort(sort),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: TaskSort.createdAt, child: Text('Created Date')),
                          const PopupMenuItem(value: TaskSort.dueDate, child: Text('Due Date')),
                          const PopupMenuItem(value: TaskSort.priority, child: Text('Priority')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(taskProvider.notifier).fetchTasks(refresh: true);
              },
              child: taskState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : processedTasks.isEmpty
                      ? const EmptyState(message: 'No tasks found')
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: processedTasks.length + (taskState.isMoreLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == processedTasks.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final task = processedTasks[index];
                            return TaskCard(
                              task: task,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TaskFormPage(task: task),
                                  ),
                                );
                              },
                              onDelete: () {
                                ref.read(taskProvider.notifier).deleteTask(task.id);
                              },
                              onCheckboxChanged: (value) {
                                final updatedTask = task.copyWith(isCompleted: value ?? false);
                                ref.read(taskProvider.notifier).updateTask(updatedTask);
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.of(context).push(
             MaterialPageRoute(
               builder: (context) => const TaskFormPage(),
             ),
           );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
