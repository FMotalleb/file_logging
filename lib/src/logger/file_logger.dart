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
  /// internal instance holder for [FileLogger]
  static FileLogger? _instance;

  ///
  /// instance of file logger
  /// * only accessible after calling [init] factory
  static FileLogger get instance {
    if (_instance == null) {
      throw Exception(
        'Please initialize file logger first then try to access its instance',
      );
    }
    return _instance!;
  }

  static FileLogger get I => instance;
  final Logger logger;

  final String Function(String loggerName) filePathGetter;
  final void Function(FileCommandResponse response)? fileEventListener;

  FileLogger._(
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

  /// attach [Logger] to [FileLogger] so every time you log anything using
  /// [logger] it will be recorded into file
  ///
  /// * calling this method at start of application is mandatory
  /// * you can use [Logger.root] so logging using any instance of [Logger]
  /// will be recorded into file
  /// * you can use [Logger.detached(<Name>)] to encapsulate [FileLogger] from
  /// other loggers
  /// * this method will return an instance of [FileLogger] it will create
  /// it for first time then after first call it will return (first and last)
  /// instance created by it no matter what inputs are
  factory FileLogger.init(
    Logger logger, {
    required String Function(String loggerName) filePathGetter,
    void Function(FileCommandResponse response)? fileEventListener,
  }) {
    if (_instance != null) {
      return _instance!;
    }
    final instance = FileLogger._(
      logger,
      filePathGetter: filePathGetter,
      fileEventListener: fileEventListener,
    );
    _instance = instance;
    return instance;
  }

  /// a metadata that will be passed to any log
  Map<String, dynamic> metaData = {};
  final Map<String, FileIsolate> _isolateMap = {};

  /// asynchronously spawns an isolate for logger by [loggerName]
  Future<void> initFileSlaveFor(String loggerName) async {
    final presentInMap = _isolateMap[loggerName] != null;
    if (presentInMap) {
      return;
    }
    _isolateMap[loggerName] = await FileIsolate.init(
      filePathGetter(
        loggerName,
      ),
    );

    final fileIsolate = _isolateMap[loggerName]!;
    fileIsolate.create();
    if (fileEventListener != null) {
      fileIsolate.listenToIsolate(fileEventListener!);
    }
  }

  /// Initialize File isolates for attached loggers
  Future<void> initFileIsolateForAttachedLoggers() async {
    await initFileSlaveFor(logger.name);
    for (final logger in logger.children.keys) {
      await initFileSlaveFor(logger);
    }
  }

  Future<FileIsolate> _isolateOf(String loggerName) async {
    final presentInMap = _isolateMap[loggerName] != null;
    if (!presentInMap) {
      throw Exception(
        'no file isolate initialized for $loggerName make sure you call `initFileSlaveFor` for logger first',
      );
    }

    final fileIsolate = _isolateMap[loggerName]!;
    if (!presentInMap) {
      fileIsolate.create();
      if (fileEventListener != null) {
        fileIsolate.listenToIsolate(fileEventListener!);
      }
    }

    return fileIsolate;
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
