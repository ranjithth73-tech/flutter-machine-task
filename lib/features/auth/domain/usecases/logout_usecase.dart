import 'package:fpdart/fpdart.dart';
import 'package:smart_task_manager/core/error/failures.dart';
import 'package:smart_task_manager/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}
