import 'package:hive/hive.dart';
import 'package:smart_task_manager/core/error/exceptions.dart';
import 'package:smart_task_manager/core/utils/constants.dart';
import 'package:smart_task_manager/features/task/data/models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getLastTasks();
  Future<void> cacheTasks(List<TaskModel> tasks);
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String taskId);
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final Box<TaskModel> taskBox;

  TaskLocalDataSourceImpl(this.taskBox);

  @override
  Future<List<TaskModel>> getLastTasks() async {
    try {
      return taskBox.values.toList();
    } catch (e) {
      throw const CacheException('Failed to retrieve cached tasks');
    }
  }

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    try {
      await taskBox.clear(); 
      for (var task in tasks) {
        await taskBox.put(task.id, task);
      }
    } catch (e) {
      throw const CacheException('Failed to cache tasks');
    }
  }

  @override
  Future<void> addTask(TaskModel task) async {
    try {
      await taskBox.put(task.id, task);
    } catch (e) {
      throw const CacheException('Failed to add task to cache');
    }
  }
  
  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      await taskBox.put(task.id, task);
    } catch (e) {
      throw const CacheException('Failed to update task in cache');
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await taskBox.delete(taskId);
    } catch (e) {
      throw const CacheException('Failed to delete task from cache');
    }
  }
}
