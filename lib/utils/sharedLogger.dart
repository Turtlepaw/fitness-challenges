import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:icons_launcher/cli_commands.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SharedLogger {
  final Logger _logger = Logger();
  List<String> _logs = []; // Store logs in memory

  // Add logs to in-memory list
  void log(String message) {
    _logger.i(message); // Logs to console
    String timestamp = DateTime.now().toIso8601String();
    _logs.add('[$timestamp] $message'); // Add log to memory
  }

  void debug(String message){
    _logger.d(message);
    String timestamp = DateTime.now().toIso8601String();
    _logs.add('Debug [$timestamp]: $message'); // Add log to memory
  }

  void error(String message){
    _logger.e(message);
    String timestamp = DateTime.now().toIso8601String();
    _logs.add('ERROR [$timestamp]: $message'); // Add log to memory
  }

  // Export logs to a file when requested
  Future<File?> exportLogsToFile(String fileName) async {
    var info = await DeviceInfoPlugin().androidInfo;
    final properties = {
      'brand': info.brand,
      'device': info.device,
      'model': info.model,
      'product': info.product,
      'version.baseOS': info.version.baseOS,
      'version.codename': info.version.codename,
      'version.incremental': info.version.incremental,
      'version.previewSdkInt': info.version.previewSdkInt,
      'version.release': info.version.release,
      'version.sdkInt': info.version.sdkInt,
      'version.securityPatch': info.version.securityPatch,
      'tags': info.tags,
      'board': info.board,
    };

    for (var entry in properties.entries) {
      debug('${entry.key.capitalize()}: ${entry.value}');
    }

    // Request storage permissions
    String content = _logs.join('\n');
    try {
      Directory? downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory != null) {
        return await saveFileToDownloads("fc_debug_log.txt", content);
      } else {
        print('Could not access the Downloads directory.');
      }
    } catch (e) {
      print('Error saving file: $e');
    }
    return null;
  }

  // Optionally clear logs from memory after exporting
  void clearLogs() {
    _logs.clear();
  }
}

Future<File> saveFileToDownloads(String filename, String content) async {
  if (Platform.isAndroid) {
    // For Android 10+, use MANAGE_EXTERNAL_STORAGE or download-specific permissions
    var status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      throw Exception('Manage External Storage permission not granted');
    }
  }

  // Get the public Downloads directory
  Directory? downloadsDirectory = Directory('/storage/emulated/0/Download');

  // Ensure the Downloads folder exists
  if (!downloadsDirectory.existsSync()) {
    downloadsDirectory.createSync(recursive: true);
  }

  String filePath = '${downloadsDirectory.path}/$filename';

  // Write the file to the Downloads folder
  File file = File(filePath);
  await file.writeAsString(content);

  print('File saved to Downloads at: $filePath');
  return file;
}