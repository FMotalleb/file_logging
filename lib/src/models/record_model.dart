library file_logging.record_model;

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

@immutable
class LogRecordModel implements LogRecord {
  @override
  final Object? error;

  @override
  final Level level;

  @override
  final String loggerName;

  @override
  final String message;

  @override
  final Object? object;

  @override
  final int sequenceNumber;

  @override
  final StackTrace? stackTrace;

  @override
  final DateTime time;

  @override
  final Zone? zone;
  final Map<String, dynamic> metaData;
  LogRecordModel({
    this.error,
    required this.level,
    required this.loggerName,
    required this.message,
    this.object,
    required this.sequenceNumber,
    this.stackTrace,
    required this.time,
    this.zone,
    this.metaData = const {},
  });
  LogRecordModel.fromLogRecord(
    LogRecord record, {
    this.metaData = const {},
  })  : error = record.error,
        object = record.object,
        level = record.level,
        loggerName = record.loggerName,
        message = record.message,
        sequenceNumber = record.sequenceNumber,
        stackTrace = record.stackTrace,
        time = record.time,
        zone = record.zone;
  LogRecordModel copyWith({
    Object? error,
    Level? level,
    String? loggerName,
    String? message,
    Object? object,
    int? sequenceNumber,
    StackTrace? stackTrace,
    DateTime? time,
    Zone? zone,
  }) {
    return LogRecordModel(
      error: error ?? this.error,
      level: level ?? this.level,
      loggerName: loggerName ?? this.loggerName,
      message: message ?? this.message,
      object: object ?? this.object,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      stackTrace: stackTrace ?? this.stackTrace,
      time: time ?? this.time,
      zone: zone ?? this.zone,
    );
  }

  LogRecord toLogRecord() => LogRecord(
        level,
        message,
        loggerName,
        error,
        stackTrace,
        zone,
        object,
      );

  Map<String, dynamic>? _tryToMap(Object? item) {
    if (item == null) return null;

    try {
      final dyn = item as dynamic;
      return dyn.toMap();
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level.name,
      'logger_name': loggerName,
      'message': message,
      'error': _tryToMap(error) ?? error?.toString(),
      'object': _tryToMap(object) ?? object?.toString(),
      'sequence_number': sequenceNumber,
      'stack_trace': stackTrace?.toString(),
      'time': time.millisecondsSinceEpoch,
      'zone': zone?.toString(),
      'meta_data': metaData,
    };
  }

  String toJson() => json.encode(toMap());

  String toFormattedString() {
    final divider = String.fromCharCodes(List.filled(25, '='.codeUnits.first));
    final buffer = StringBuffer('$divider\n');
    buffer.writeln('Record Time: ${time.toIso8601String()}');
    buffer.write('[$level]');
    if (loggerName.isNotEmpty == true) {
      buffer.write('<$loggerName>');
    }
    buffer.write(':\n\t');
    buffer.writeln(message.replaceAll('\n', '\n\t'));
    final map = toMap();
    for (final key in [
      'object',
      'error',
      'stack_trace',
      'sequence_number',
      'zone',
    ]) {
      final effectiveValue = (map[key] ?? '').toString();
      if (effectiveValue.isNotEmpty) {
        buffer.writeln(
          'Attached $key:\n\t${effectiveValue.replaceAll('\n', '\n\t')}',
        );
      }
    }

    if (metaData.isNotEmpty) {
      buffer.writeln('MetaData:');
      for (final i in metaData.entries) {
        buffer.writeln(
          '\t#${i.key}: \t${i.value.toString().replaceAll('\n', '\n\t\t')}',
        );
      }
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return 'RecordModel(error: $error, level: $level, loggerName: $loggerName, message: $message, object: $object, sequenceNumber: $sequenceNumber, stackTrace: $stackTrace, time: $time, zone: $zone, metaData: $metaData)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LogRecordModel &&
        other.error == error &&
        other.level == level &&
        other.loggerName == loggerName &&
        other.message == message &&
        other.object == object &&
        other.sequenceNumber == sequenceNumber &&
        other.stackTrace == stackTrace &&
        other.time == time &&
        other.metaData == metaData &&
        other.zone == zone;
  }

  @override
  int get hashCode {
    return error.hashCode ^
        level.hashCode ^
        loggerName.hashCode ^
        message.hashCode ^
        object.hashCode ^
        sequenceNumber.hashCode ^
        stackTrace.hashCode ^
        time.hashCode ^
        metaData.hashCode ^
        zone.hashCode;
  }
}
