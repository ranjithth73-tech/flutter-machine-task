import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/error/exceptions.dart';
import 'package:smart_task_manager/core/network/connectivity_service.dart';
import 'package:smart_task_manager/core/utils/constants.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return DioClient(connectivityService);
});

class DioClient {
  final ConnectivityService _connectivityService;
  late final Dio _dio;

  DioClient(this._connectivityService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!await _connectivityService.isConnected) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: const NetworkException('No internet connection'),
                type: DioExceptionType.connectionError,
              ),
            );
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          final error = _handleDioError(e);
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: error,
              type: e.type,
              response: e.response,
            ),
          );
        },
      ),
    );
  }

  Dio get dio => _dio;

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Connection timeout');
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);
      case DioExceptionType.cancel:
        return const NetworkException('Request cancelled');
      case DioExceptionType.connectionError:
        return const NetworkException('No internet connection');
      case DioExceptionType.unknown:
        return const ServerException('Unexpected error occurred');
      default:
        return const ServerException('Something went wrong');
    }
  }

  Exception _handleBadResponse(Response? response) {
    if (response == null) return const ServerException('Unknown server error');
    
    final statusCode = response.statusCode;
    final message = response.data?['message'] ?? response.statusMessage ?? 'Error';

    if (statusCode != null) {
      if (statusCode >= 400 && statusCode < 500) {
        return ClientException(message, statusCode.toString());
      } else if (statusCode >= 500) {
        return ServerException(message, statusCode.toString());
      }
    }
    
    return ServerException(message);
  }
}

class ClientException extends AppException {
  const ClientException(super.message, [super.code]);
}
