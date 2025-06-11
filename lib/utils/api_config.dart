// lib/config/api_config.dart
class ApiConfig {
  // Change this single line to update the IP across your entire app
  static const String baseUrl = 'http://192.168.107.72:8000';

  //   // You can also define different endpoints
  //   static const String apiVersion = '/api/v1';
  //   static const String fullBaseUrl = '$baseUrl$apiVersion';

  //   // Define your endpoints
  //   static const String loginEndpoint = '$fullBaseUrl/auth/login';
  //   static const String userEndpoint = '$fullBaseUrl/users';
  //   static const String productsEndpoint = '$fullBaseUrl/products';

  //   // For different environments
  //   static const bool isProduction = false;
  //   static String get environmentUrl => isProduction
  //     ? 'https://yourproductionserver.com/api/v1'
  //     : fullBaseUrl;
}
