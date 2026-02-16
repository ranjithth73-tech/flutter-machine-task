import 'package:fpdart/fpdart.dart';
import 'package:smart_task_manager/core/error/failures.dart';
import 'package:smart_task_manager/core/network/connectivity_service.dart';
import 'package:smart_task_manager/core/utils/error_mapper.dart';
import 'package:smart_task_manager/features/task/data/datasources/task_local_datasource.dart';
import 'package:smart_task_manager/features/task/data/datasources/task_remote_datasource.dart';
import 'package:smart_task_manager/features/task/data/models/task_model.dart';
import 'package:smart_task_manager/features/task/domain/entities/task_entity.dart';
import 'package:smart_task_manager/features/task/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;
  final ConnectivityService connectivityService;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivityService,
  });

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasks(String userId, {int skip = 0, int limit = 10}) async {
    if (await connectivityService.isConnected) {
      try {
        final taskModels = await remoteDataSource.getTasks(userId: userId, skip: skip, limit: limit);
        if (skip == 0) {
          // If fetching the first page, replace cache for fresh start? Or handle sync differently.
          // For simplicity, we cache what we get.
          await localDataSource.cacheTasks(taskModels);
        } else {
          // Add subsequent pages to cache
          for (var task in taskModels) {
            await localDataSource.addTask(task);
          }
        }
        return Right(taskModels);
      } catch (e) {
        // If remote fails, try local
        try {
          final localTasks = await localDataSource.getLastTasks();
          // Filter local tasks based on skip/limit locally?
          // Since Hive returns all, we might slice it.
          // But remote pagination logic might differ. 
          // For now, return all local tasks if remote fails.
          if (localTasks.isNotEmpty) {
            return Right(localTasks);
          }
           return Left(mapExceptionToFailure(e));
        } catch (_) {
          return Left(mapExceptionToFailure(e));
        }
      }
    } else {
      try {
        final localTasks = await localDataSource.getLastTasks();
        return Right(localTasks);
      } catch (e) {
        return Left(mapExceptionToFailure(e));
      }
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> createTask(String userId, TaskEntity task) async {
    if (await connectivityService.isConnected) {
      try {
        final createdTask = await remoteDataSource.createTask(userId: userId, task: TaskModel.fromEntity(task));
        await localDataSource.addTask(createdTask); // Sync local
        return Right(createdTask);
      } catch (e) {
        return Left(mapExceptionToFailure(e));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> updateTask(String userId, TaskEntity task) async {
    if (await connectivityService.isConnected) {
      try {
        final updatedTask = await remoteDataSource.updateTask(userId: userId, task: TaskModel.fromEntity(task));
        await localDataSource.updateTask(updatedTask); // Sync local
        return Right(updatedTask);
      } catch (e) {
        return Left(mapExceptionToFailure(e));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String userId, String taskId) async {
    if (await connectivityService.isConnected) {
      try {
        await remoteDataSource.deleteTask(userId: userId, taskId: taskId);
        await localDataSource.deleteTask(taskId); // Sync local
        return const Right(null);
      } catch (e) {
        return Left(mapExceptionToFailure(e));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
