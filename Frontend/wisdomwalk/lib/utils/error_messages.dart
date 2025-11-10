/// User-friendly error messages for the app
class ErrorMessages {
  // Authentication errors
  static const String authenticationRequired = 'Please log in to continue';
  static const String loginFailed = 'Unable to sign in. Please check your email and password';
  static const String registrationFailed = 'Unable to create account. Please try again';
  static const String invalidCredentials = 'Invalid email or password';
  static const String sessionExpired = 'Your session has expired. Please log in again';
  static const String tokenMissing = 'Authentication required. Please log in again';

  // Network errors
  static const String noInternetConnection = 'No internet connection. Please check your network';
  static const String connectionTimeout = 'Connection timeout. Please try again';
  static const String serverError = 'Server error. Please try again later';
  static const String serverUnavailable = 'Service temporarily unavailable. Please try again later';
  static const String requestFailed = 'Request failed. Please try again';
  static const String unknownError = 'Something went wrong. Please try again';

  // Profile errors
  static const String profileUpdateFailed = 'Unable to update profile. Please try again';
  static const String profileLoadFailed = 'Unable to load profile. Please try again';
  static const String imageUploadFailed = 'Unable to upload image. Please try again';
  static const String imageTooLarge = 'Image is too large. Please choose a smaller image';
  static const String imageCompressionFailed = 'Unable to process image. Please try another image';

  // Chat errors
  static const String chatLoadFailed = 'Unable to load chats. Please try again';
  static const String messageSendFailed = 'Unable to send message. Please try again';
  static const String messageLoadFailed = 'Unable to load messages. Please try again';
  static const String chatCreateFailed = 'Unable to start chat. Please try again';
  static const String userSearchFailed = 'Unable to search users. Please try again';
  static const String usersLoadFailed = 'Unable to load users. Please try again';

  // Circle errors
  static const String circlesLoadFailed = 'Unable to load circles. Please try again';
  static const String circleJoinFailed = 'Unable to join circle. Please try again';
  static const String circleLeaveFailed = 'Unable to leave circle. Please try again';
  static const String circleDetailsFailed = 'Unable to load circle details. Please try again';
  static const String circleMessageSendFailed = 'Unable to send message. Please try again';
  static const String circleMessageLoadFailed = 'Unable to load messages. Please try again';

  // Prayer errors
  static const String prayerPostFailed = 'Unable to post prayer. Please try again';
  static const String prayerLoadFailed = 'Unable to load prayers. Please try again';
  static const String prayerLikeFailed = 'Unable to update prayer. Please try again';
  static const String prayerCommentFailed = 'Unable to add comment. Please try again';
  static const String prayerReportFailed = 'Unable to report prayer. Please try again';

  // Share/Post errors
  static const String sharePostFailed = 'Unable to share. Please try again';
  static const String shareLoadFailed = 'Unable to load shares. Please try again';
  static const String shareLikeFailed = 'Unable to update share. Please try again';
  static const String shareCommentFailed = 'Unable to add comment. Please try again';
  static const String shareReportFailed = 'Unable to report post. Please try again';

  // Location/Her Move errors
  static const String locationRequestFailed = 'Unable to share location request. Please try again';
  static const String locationLoadFailed = 'Unable to load location requests. Please try again';
  static const String helpOfferFailed = 'Unable to offer help. Please try again';

  // Event errors
  static const String eventsLoadFailed = 'Unable to load events. Please try again';
  static const String eventBookingFailed = 'Unable to book event. Please try again';

  // Notification errors
  static const String notificationsLoadFailed = 'Unable to load notifications. Please try again';

  // General errors
  static const String dataLoadFailed = 'Unable to load data. Please try again';
  static const String actionFailed = 'Unable to complete action. Please try again';
  static const String validationFailed = 'Please check your input and try again';

  /// Convert technical error to user-friendly message
  static String getFriendlyMessage(String? error) {
    if (error == null || error.isEmpty) {
      return unknownError;
    }

    final errorLower = error.toLowerCase();

    // Network errors
    if (errorLower.contains('timeout') || errorLower.contains('timed out')) {
      return connectionTimeout;
    }
    if (errorLower.contains('network') || errorLower.contains('internet') || errorLower.contains('connection')) {
      return noInternetConnection;
    }
    if (errorLower.contains('401') || errorLower.contains('unauthorized') || errorLower.contains('authentication')) {
      return authenticationRequired;
    }
    if (errorLower.contains('403') || errorLower.contains('forbidden')) {
      return 'Access denied. Please check your permissions';
    }
    if (errorLower.contains('404') || errorLower.contains('not found')) {
      return 'Resource not found. Please try again';
    }
    if (errorLower.contains('500') || errorLower.contains('server error')) {
      return serverError;
    }
    if (errorLower.contains('503') || errorLower.contains('service unavailable')) {
      return serverUnavailable;
    }

    // Specific error patterns
    if (errorLower.contains('token') || errorLower.contains('session')) {
      return sessionExpired;
    }
    if (errorLower.contains('invalid') || errorLower.contains('validation')) {
      return validationFailed;
    }
    if (errorLower.contains('upload') || errorLower.contains('image') || errorLower.contains('photo')) {
      if (errorLower.contains('large') || errorLower.contains('size')) {
        return imageTooLarge;
      }
      return imageUploadFailed;
    }

    // If no match, return generic message
    return unknownError;
  }

  /// Get user-friendly error message from exception
  static String fromException(dynamic exception) {
    if (exception == null) {
      return unknownError;
    }

    final errorString = exception.toString();
    return getFriendlyMessage(errorString);
  }

  /// Get user-friendly error message from HTTP status code
  static String fromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return validationFailed;
      case 401:
        return authenticationRequired;
      case 403:
        return 'Access denied. Please check your permissions';
      case 404:
        return 'Resource not found. Please try again';
      case 408:
        return connectionTimeout;
      case 500:
        return serverError;
      case 502:
      case 503:
      case 504:
        return serverUnavailable;
      default:
        return requestFailed;
    }
  }
}

