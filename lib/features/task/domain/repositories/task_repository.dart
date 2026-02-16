import 'package:fpdart/fpdart.dart';
import 'package:smart_task_manager/core/error/failures.dart';
import 'package:smart_task_manager/features/task/domain/entities/task_entity.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<TaskEntity>>> getTasks(String userId, {int skip = 0, int limit = 10});
  Future<Either<Failure, TaskEntity>> createTask(String userId, TaskEntity task);
  Future<Either<Failure, TaskEntity>> updateTask(String userId, TaskEntity task);
  Future<Either<Failure, void>> deleteTask(String userId, String taskId);
}
