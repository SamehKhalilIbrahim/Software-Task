import 'package:dio/dio.dart';

class Failure {
  final String error;

  Failure({required this.error});

  // -------------------------
  // DIO ERRORS
  // -------------------------
  factory Failure.fromDioError(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return Failure(error: "Connection timeout with server.");
      case DioExceptionType.sendTimeout:
        return Failure(error: "Send timeout with server.");
      case DioExceptionType.receiveTimeout:
        return Failure(error: "Receive timeout with server.");
      case DioExceptionType.badCertificate:
        return Failure(error: "Bad certificate (incorrect certificate).");
      case DioExceptionType.badResponse:
        return Failure._fromBadResponse(
          statusCode: dioException.response?.statusCode,
          response: dioException.response?.data,
        );
      case DioExceptionType.cancel:
        return Failure(error: "Request was canceled.");
      case DioExceptionType.connectionError:
        return Failure(error: "No internet connection.");
      case DioExceptionType.unknown:
        if (dioException.message?.contains("SocketException") ?? false) {
          return Failure(error: "No internet connection.");
        }
        return Failure(error: "Unexpected error. Please try again.");
    }
  }

  factory Failure._fromBadResponse({
    required int? statusCode,
    dynamic response,
  }) {
    if (statusCode == null) {
      return Failure(error: "Unexpected server error.");
    }

    if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
      return Failure(
        error: response?["error"]["message"] ?? "Unauthorized request.",
      );
    } else if (statusCode == 404) {
      return Failure(error: "Your request was not found.");
    } else if (statusCode == 409) {
      return Failure(error: "There is a conflict with the current data.");
    } else if (statusCode == 500) {
      return Failure(error: "Internal server error. Please try again.");
    } else {
      return Failure(error: "Oops, something went wrong. Please try again.");
    }
  }

  // -------------------------
  // AUTO DETECT
  // -------------------------
  factory Failure.fromException(dynamic exception) {
    if (exception is DioException) {
      return Failure.fromDioError(exception);
    } else {
      return Failure(error: "Unexpected error. Please try again.");
    }
  }
}
