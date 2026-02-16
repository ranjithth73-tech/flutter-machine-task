import 'package:smart_task_manager/core/error/exceptions.dart';
import 'package:smart_task_manager/core/error/failures.dart';

Failure mapExceptionToFailure(Object exception) {
  if (exception is ServerException) {
    return ServerFailure(exception.message, exception.code);
  } else if (exception is NetworkException) {
    return NetworkFailure(exception.message, exception.code);
  } else if (exception is CacheException) {
    return CacheFailure(exception.message, exception.code);
  } else if (exception is AuthException) {
    return AuthFailure(exception.message, exception.code);
  } else {
    return const ServerFailure('Unexpected error occurred');
  }
}
