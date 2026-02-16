import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/network/connectivity_service.dart';
import 'package:smart_task_manager/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_task_manager/features/task/data/datasources/task_local_datasource.dart';
import 'package:smart_task_manager/features/task/data/datasources/task_remote_datasource.dart';
import 'package:smart_task_manager/features/task/data/repositories/task_repository_impl.dart';
import 'package:smart_task_manager/features/task/domain/entities/task_entity.dart';
import 'package:smart_task_manager/features/task/domain/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:smart_task_manager/core/utils/constants.dart';
import 'package:smart_task_manager/features/task/data/models/task_model.dart';
import 'package:smart_task_manager/core/network/dio_client.dart';

// --- Providers ---
final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>((ref) {
  return TaskLocalDataSourceImpl(Hive.box<TaskModel>(ApiConstants.taskBox));
});

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return TaskRemoteDataSourceImpl(dio);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(
    remoteDataSource: ref.read(taskRemoteDataSourceProvider),
    localDataSource: ref.read(taskLocalDataSourceProvider),
    connectivityService: ref.read(connectivityServiceProvider),
  );
});

// --- State ---
enum TaskFilter { all, completed, pending }
enum TaskSort { dueDate, priority, createdAt }

class TaskState extends Equatable {
  final List<TaskEntity> tasks;
  final bool isLoading;
  final bool isMoreLoading;
  final String? error;
  final TaskFilter filter;
  final TaskSort sort;
  final String searchQuery;
  final bool hasMore;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.isMoreLoading = false,
    this.error,
    this.filter = TaskFilter.all,
    this.sort = TaskSort.createdAt,
    this.searchQuery = '',
    this.hasMore = true,
  });

  TaskState copyWith({
    List<TaskEntity>? tasks,
    bool? isLoading,
    bool? isMoreLoading,
    String? error,
    TaskFilter? filter,
    TaskSort? sort,
    String? searchQuery,
    bool? hasMore,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isMoreLoading: isMoreLoading ?? this.isMoreLoading,
      error: error,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
    );
  }
  
  // Get filtered and sorted tasks for UI
  List<TaskEntity> get processedTasks {
    // Create a mutable copy to avoid modifying unmodifiable lists
    var result = List<TaskEntity>.from(tasks);

    // Filter
    if (filter == TaskFilter.completed) {
      result = result.where((t) => t.isCompleted).toList();
    } else if (filter == TaskFilter.pending) {
      result = result.where((t) => !t.isCompleted).toList();
    }

    // Search
    if (searchQuery.isNotEmpty) {
      result = result.where((t) => t.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    // Sort
    result.sort((a, b) {
      switch (sort) {
        case TaskSort.dueDate:
          return a.dueDate.compareTo(b.dueDate);
        case TaskSort.priority:
          // High > Medium > Low
          final pA = _priorityValue(a.priority);
          final pB = _priorityValue(b.priority);
          return pB.compareTo(pA); // Descending
        case TaskSort.createdAt:
          return b.createdAt.compareTo(a.createdAt); // Newest first
      }
    });

    return result;
  }

  int _priorityValue(String priority) {
    if (priority.toLowerCase() == 'high') return 3;
    if (priority.toLowerCase() == 'medium') return 2;
    return 1;
  }

  @override
  List<Object?> get props => [tasks, isLoading, isMoreLoading, error, filter, sort, searchQuery, hasMore];
}

// --- Notifier ---
class TaskNotifier extends StateNotifier<TaskState> {
  final TaskRepository _repository;
  final Ref _ref;
  final _uuid = const Uuid();
  int _skip = 0;
  final int _limit = 10;

  TaskNotifier(this._repository, this._ref) : super(const TaskState());

  Future<void> fetchTasks({bool refresh = false}) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    if (refresh) {
      _skip = 0;
      state = state.copyWith(isLoading: true, hasMore: true, error: null);
    } else {
      if (!state.hasMore || state.isMoreLoading) return;
      state = state.copyWith(isMoreLoading: true, error: null);
    }

    final result = await _repository.getTasks(user.id, skip: _skip, limit: _limit);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          isMoreLoading: false,
          error: failure.message,
        );
      },
      (newTasks) {
        if (refresh) {
          state = state.copyWith(
            isLoading: false,
            tasks: newTasks,
            hasMore: newTasks.length == _limit,
          );
        } else {
          state = state.copyWith(
            isMoreLoading: false,
            tasks: [...state.tasks, ...newTasks],
            hasMore: newTasks.length == _limit,
          );
        }
        _skip += newTasks.length;
      },
    );
  }

  Future<void> addTask(String title, String description, String priority, String category, DateTime dueDate) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    final newTask = TaskEntity(
      id: _uuid.v4(), // Temp ID
      title: title,
      description: description,
      priority: priority,
      category: category,
      dueDate: dueDate,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    // Optimistic Update
    final previousTasks = state.tasks;
    state = state.copyWith(tasks: [newTask, ...state.tasks]);

    final result = await _repository.createTask(user.id, newTask);

    result.fold(
      (failure) {
        // Rollback
        state = state.copyWith(tasks: previousTasks, error: failure.message);
      },
      (createdTask) {
        // Replace temp task with real one (if server generates ID, we swap)
        // Since we put custom ID in request, server might use it or ignore it.
        // Assuming server matches ID or returns new one.
        // We replace based on our temp ID.
        final tasks = state.tasks.map((t) => t.id == newTask.id ? createdTask : t).toList();
        state = state.copyWith(tasks: tasks);
      },
    );
  }

  Future<void> updateTask(TaskEntity updatedTask) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    final index = state.tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index == -1) return;

    final previousTask = state.tasks[index];
    final previousList = [...state.tasks];
    
    // Optimistic Update
    final newTasks = [...state.tasks];
    newTasks[index] = updatedTask;
    state = state.copyWith(tasks: newTasks);

    final result = await _repository.updateTask(user.id, updatedTask);

    result.fold(
      (failure) {
        // Rollback
        state = state.copyWith(tasks: previousList, error: failure.message);
      },
      (serverTask) {
        // Confirm update (optional if identical)
         final tasks = state.tasks.map((t) => t.id == updatedTask.id ? serverTask : t).toList();
        state = state.copyWith(tasks: tasks);
      },
    );
  }

  Future<void> deleteTask(String taskId) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    final index = state.tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final previousList = [...state.tasks];

    // Optimistic Update
    final newTasks = [...state.tasks]..removeAt(index);
    state = state.copyWith(tasks: newTasks);

    final result = await _repository.deleteTask(user.id, taskId);

    result.fold(
      (failure) {
        // Rollback
        state = state.copyWith(tasks: previousList, error: failure.message);
      },
      (_) {},
    );
  }

  void setFilter(TaskFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSort(TaskSort sort) {
    state = state.copyWith(sort: sort);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  final repository = ref.read(taskRepositoryProvider);
  return TaskNotifier(repository, ref);
});
