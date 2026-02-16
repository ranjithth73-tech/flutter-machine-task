import 'package:fpdart/fpdart.dart';
import 'package:smart_task_manager/core/error/failures.dart';
import 'package:smart_task_manager/features/auth/domain/entities/user_entity.dart';
import 'package:smart_task_manager/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call() async {
    return await repository.getCurrentUser();
  }
}
