import 'package:fpdart/fpdart.dart';
import 'package:smart_task_manager/core/error/exceptions.dart';
import 'package:smart_task_manager/core/error/failures.dart';
import 'package:smart_task_manager/core/network/connectivity_service.dart';
import 'package:smart_task_manager/core/utils/error_mapper.dart';
import 'package:smart_task_manager/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smart_task_manager/features/auth/domain/entities/user_entity.dart';
import 'package:smart_task_manager/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.connectivityService,
  });

  @override
  Stream<UserEntity?> get authStateChanges => 
      remoteDataSource.authStateChanges.map((userModel) => userModel?.toEntity());

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    if (!await connectivityService.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final userModel = await remoteDataSource.login(email, password);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(String email, String password) async {
    if (!await connectivityService.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final userModel = await remoteDataSource.register(email, password);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
