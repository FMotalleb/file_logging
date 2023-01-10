import 'package:file_logging/file_logging.dart';
import 'package:file_logging/src/file_manager/file_command.dart';
import 'package:logging/logging.dart';

void main() async {
  final fLogger = FileLogger.init(
    Logger.root,
    filePathGetter: (logger) => '$logger.log',
    fileEventListener: (FileCommandResponse response) {
      print(response);
      if (response.data != null) {
        print(String.fromCharCodes(response.data!));
      }
    },
  );
  final logger = Logger('temp');
  await fLogger.initFileIsolateForAttachedLoggers();
  // fLogger.readAll();
  for (int i = 0; i <= 100; i++) {
    logger.info('Log no.$i');
    Future.delayed(const Duration(milliseconds: 20));
  }
  fLogger.readAll();
  // fLogger.terminateAllIsolates();
}
