import 'package:dio/dio.dart';
import 'package:smart_task_manager/core/error/exceptions.dart';
import 'package:smart_task_manager/features/task/data/models/task_model.dart';
import 'package:smart_task_manager/core/network/dio_client.dart'; // For ClientException if needed, or re-export

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks({required String userId, int skip = 0, int limit = 10});
  Future<TaskModel> createTask({required String userId, required TaskModel task});
  Future<TaskModel> updateTask({required String userId, required TaskModel task});
  Future<void> deleteTask({required String userId, required String taskId});
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final Dio _dio;

  TaskRemoteDataSourceImpl(this._dio);

  @override
  Future<List<TaskModel>> getTasks({required String userId, int skip = 0, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/tasks/',
        queryParameters: {
          'user_id': userId,
          'skip': skip,
          'limit': limit,
        },
      );
      
      final data = response.data['data'];
      if (data == null) return [];
      
      return (data as List)
          .map((json) => TaskModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to fetch tasks');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<TaskModel> createTask({required String userId, required TaskModel task}) async {
    try {
      // The API expects TaskCreate schema (no id)
      final taskData = {
        'title': task.title,
        'description': task.description,
        'priority': _capitalize(task.priority),
        'category': _capitalize(task.category),
        'due_date': task.dueDate.toIso8601String(),
        'is_completed': task.isCompleted,
      };

      final response = await _dio.post(
        '/tasks/',
        queryParameters: {'user_id': userId},
        data: taskData,
      );

      final responseData = response.data['data'];
      if (responseData == null) throw const ServerException('Invalid response from server');
      
      return TaskModel.fromJson(responseData);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to create task');
    } catch (e) {
       throw ServerException(e.toString());
    }
  }

  @override
  Future<TaskModel> updateTask({required String userId, required TaskModel task}) async {
    try {
      final taskData = {
        'title': task.title,
        'description': task.description,
        'priority': _capitalize(task.priority),
        'category': _capitalize(task.category),
        'due_date': task.dueDate.toIso8601String(),
        'is_completed': task.isCompleted,
      };

      final response = await _dio.put(
        '/tasks/${task.id}',
        queryParameters: {'user_id': userId},
        data: taskData,
      );

      final responseData = response.data['data'];
      if (responseData == null) throw const ServerException('Invalid response from server');

      return TaskModel.fromJson(responseData);
    } on DioException catch (e) {
       throw ServerException(e.message ?? 'Failed to update task');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteTask({required String userId, required String taskId}) async {
    try {
      // task_id in path must be integer
      final intId = int.tryParse(taskId);
      if (intId == null) throw const ServerException('Invalid task ID format');

      await _dio.delete(
        '/tasks/$intId',
        queryParameters: {'user_id': userId},
      );
    } on DioException catch (e) {
       throw ServerException(e.message ?? 'Failed to delete task');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
