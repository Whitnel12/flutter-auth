class AppConfig {
  // Konfigurasi server berdasarkan environment
  static const bool isDevelopment = true;

  // Pilih environment yang sesuai:
  // 1 = Emulator Android
  // 2 = Device Fisik
  // 3 = Testing di komputer yang sama
  static const int environment = 2; // Ganti ke 2 untuk device fisik

  // URL Server - pilih salah satu sesuai environment
  static String get serverUrl {
    if (isDevelopment) {
      switch (environment) {
        case 1:
          return 'http://10.0.2.2:3000'; // Emulator Android
        case 2:
          return 'http://10.165.206.19:3000'; // Device fisik dengan IP komputer Anda
        case 3:
          return 'http://localhost:3000'; // Testing di komputer yang sama
        default:
          return 'http://10.0.2.2:3000'; // Default untuk emulator
      }
    } else {
      // Untuk production
      return 'https://your-production-server.com';
    }
  }

  // Timeout untuk HTTP requests
  static const int requestTimeout = 30; // seconds

  // Midtrans configuration
  static const bool isMidtransProduction = false; // false untuk sandbox

  // Debug mode
  static const bool enableDebugLogs = true;

  // Print debug info
  static void log(String message) {
    if (enableDebugLogs) {
      print('🔍 [AppConfig] $message');
    }
  }

  // Print current configuration
  static void printConfig() {
    log('Environment: $environment');
    log('Server URL: $serverUrl');
    log('Timeout: ${requestTimeout}s');
    log('Midtrans Production: $isMidtransProduction');
  }
}
