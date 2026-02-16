import 'package:dio/dio.dart';
import 'package:smart_task_manager/core/error/exceptions.dart';
import 'package:smart_task_manager/core/network/dio_client.dart';
import 'package:smart_task_manager/features/task/data/models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks({required String userId, int skip = 0, int limit = 10});
  Future<TaskModel> createTask({required String userId, required TaskModel task});
  Future<TaskModel> updateTask({required String userId, required TaskModel task});
  Future<void> deleteTask({required String userId, required String taskId});
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final DioClient _dioClient;

  TaskRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<TaskModel>> getTasks({required String userId, int skip = 0, int limit = 10}) async {
    try {
      final response = await _dioClient.dio.get(
        '/tasks/',
        queryParameters: {
          'user_id': userId,
          'skip': skip,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data;
      return data.map((json) => TaskModel.fromJson(json)).toList();
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        throw const NetworkException('No internet connection');
      }
      rethrow; // Let repository handle mapping
    }
  }

  @override
  Future<TaskModel> createTask({required String userId, required TaskModel task}) async {
    try {
      final response = await _dioClient.dio.post(
        '/tasks/',
        queryParameters: {'user_id': userId},
        data: task.toJson(),
      );
      return TaskModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TaskModel> updateTask({required String userId, required TaskModel task}) async {
     try {
      final response = await _dioClient.dio.put(
        '/tasks/${task.id}',
        queryParameters: {'user_id': userId},
        data: task.toJson(),
      );
      return TaskModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteTask({required String userId, required String taskId}) async {
     try {
      await _dioClient.dio.delete(
        '/tasks/$taskId',
        queryParameters: {'user_id': userId},
      );
    } catch (e) {
      rethrow;
    }
  }
}
