library file_logging.file_isolate;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:file_logging/src/file_manager/file_command.dart';
import 'package:meta/meta.dart';
part 'isolate_config.dart';

@immutable
class FileIsolate {
  final Isolate isolate;
  final Stream<FileCommandResponse> _fromIsolate;
  final SendPort _toIsolate;

  void create() => _toIsolate.send(
        FileCommand.create(),
      );
  void delete() => _toIsolate.send(
        FileCommand.delete(),
      );
  void read() => _toIsolate.send(
        FileCommand.read(),
      );
  void write(String message) => _toIsolate.send(
        FileCommand.append(
          message.codeUnits,
        ),
      );
  StreamSubscription<FileCommandResponse> listenToIsolate(void Function(FileCommandResponse data) listener) {
    return _fromIsolate.listen(listener);
  }

  static Future<FileIsolate> init(final String fileAddress) async {
    final fromIsolate = ReceivePort('from-isolate:$fileAddress');
    final fileEvents = ReceivePort('from-isolate-fileEvent:$fileAddress');
    final config = _IsolateConfig(
      fileAddress: fileAddress,
      fileEvents: fileEvents.sendPort,
      majorIsolatePort: fromIsolate.sendPort,
    );
    final isolate = await Isolate.spawn(
      _fileCommandHandler,
      config,
      debugName: 'file-isolate:$fileAddress',
    );
    final com = (await fromIsolate.first);
    if (com is! SendPort) {
      throw Exception('UnExcepted result from file handler isolate.');
    }
    return FileIsolate._(
      isolate,
      com,
      fileEvents.map((event) {
        if (event is! FileCommandResponse) {
          throw Exception('Isolate is isolate cracked.');
        }
        return event;
      }),
    );
  }

  FileIsolate._(
    this.isolate,
    this._toIsolate,
    this._fromIsolate,
  );

  static Future<void> _fileCommandHandler(_IsolateConfig config) async {
    final toSource = config.majorIsolatePort;
    final fileEvents = config.fileEvents;
    final file = File(config.fileAddress);
    if ((await file.exists()) == false) {
      FileCommand.create().act(file);
    }
    ReceivePort com = ReceivePort();
    toSource.send(com.sendPort);
    await for (final command in com) {
      if (command is! FileCommand) {
        throw Exception(
          'this isolate is not made to handle anything other than [FileCommand]',
        );
      }
      final result = await command.act(file);
      fileEvents.send(result);
    }
  }
}
