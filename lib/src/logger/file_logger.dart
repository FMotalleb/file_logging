library file_logging.logger;

import 'dart:async' //
    show
        Future,
        Zone;
import 'dart:developer' //
    show
        log;

import 'package:file_logging/src/file_manager/file_command.dart';
import 'package:file_logging/src/file_manager/file_isolate.dart';
import 'package:file_logging/src/models/record_model.dart';
import 'package:logging/logging.dart' //
    show
        Level,
        LogRecord,
        Logger;

class FileLogger {
  final Logger logger;

  final String Function(String loggerName) filePathGetter;
  final void Function(FileCommandResponse response)? fileEventListener;

  /// attach [Logger] to [FileLogger] so every time you log anything using
  /// [logger] it will be recorded into file
  ///
  /// * calling this method at start of application is mandatory
  /// * you can use [Logger.root] so logging using any instance of [Logger]
  /// will be recorded into file
  /// * you can use [Logger.detached(<Name>)] to encapsulate [FileLogger] from
  /// other loggers
  FileLogger.init(
    this.logger, {
    required this.filePathGetter,
    this.fileEventListener,
  }) {
    logger.onRecord
        .map(
          _modelParser,
        )
        .listen(
          _record,
        );
  }

  /// a metadata that will be passed to any log
  Map<String, dynamic> metaData = {};
  final Map<String, FileIsolate> _isolateMap = {};
  Future<FileIsolate> _isolateOf(String loggerName) async {
    final presentInMap = _isolateMap[loggerName] != null;
    final isolate = _isolateMap[loggerName] ??= await FileIsolate.init(
      filePathGetter(
        loggerName,
      ),
    );
    if (!presentInMap && fileEventListener != null) {
      isolate.listenToIsolate(fileEventListener!);
    }
    isolate.create();
    return isolate;
  }

  @pragma("vm:prefer-inline")
  LogRecordModel _modelParser(
    LogRecord record,
  ) =>
      LogRecordModel.fromLogRecord(
        record,
        metaData: metaData,
      );

  @pragma("vm:prefer-inline")
  Future<void> _record(LogRecordModel record) async {
    try {
      final isolate = await _isolateOf(record.loggerName);
      final text = record.toFormattedString();
      isolate.write(text);
    } catch (e, st) {
      log(
        'Error in FileLogger',
        error: e,
        stackTrace: st,
        level: Level.SHOUT.value,
        name: 'SocketLogger',
        time: DateTime.now(),
        zone: Zone.current,
      );
    }
  }

  void readAll() {
    if (fileEventListener == null) {
      throw Exception('you must provide `file event listener` to file logger');
    }
    for (final i in _isolateMap.values) {
      i.read();
    }
  }

  void terminateAllIsolates() {
    for (final i in _isolateMap.values) {
      i.isolate.kill();
    }
    _isolateMap.clear();
  }
}
