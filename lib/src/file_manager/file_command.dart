library file_logging.file_command;

import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

enum FileAction {
  delete,
  write,
  append,
  create,
  read,
  ;
}

@immutable
class FileCommandResponse {
  final bool successful;
  final Uint8List? data;
  final String message;
  final FileAction action;
  FileCommandResponse.successful({
    this.data,
    this.message = 'ok',
    required this.action,
  }) : successful = true;

  FileCommandResponse.failed({
    this.data,
    required this.message,
    required this.action,
  }) : successful = false;

  @override
  String toString() {
    return 'FileCommandResponse(action: ${action.name},successful: $successful, message: $message, contains-data: ${data != null})';
  }
}

@immutable
class FileCommand {
  final FileAction action;
  final List<int>? params;

  FileCommand.create()
      : action = FileAction.create,
        params = null;
  FileCommand.delete()
      : action = FileAction.delete,
        params = null;
  FileCommand.write(
    List<int> this.params,
  ) : action = FileAction.write;
  FileCommand.read()
      : action = FileAction.read,
        params = null;
  FileCommand.append(
    List<int> this.params,
  ) : action = FileAction.append;

  Future<FileCommandResponse> act(File file) async {
    switch (action) {
      case FileAction.delete:
        try {
          await file.delete();
          return FileCommandResponse.successful(action: action);
        } catch (e) {
          return FileCommandResponse.failed(
            message: e.toString(),
            action: action,
          );
        }
      case FileAction.write:
        if (params == null) {
          return FileCommandResponse.failed(
            message: 'cannot execute write operation with no params',
            action: action,
          );
        }
        try {
          await file.writeAsBytes(
            params!,
            mode: FileMode.writeOnly,
          );
          return FileCommandResponse.successful(
            action: action,
          );
        } catch (e) {
          return FileCommandResponse.failed(
            action: action,
            message: e.toString(),
          );
        }

      case FileAction.append:
        if (params == null) {
          return FileCommandResponse.failed(
            action: action,
            message: 'cannot execute write operation with no params',
          );
        }
        try {
          await file.writeAsBytes(
            params!,
            mode: FileMode.writeOnlyAppend,
          );
          return FileCommandResponse.successful(
            action: action,
          );
        } catch (e) {
          return FileCommandResponse.failed(
            action: action,
            message: e.toString(),
          );
        }

      case FileAction.create:
        try {
          await file.create(recursive: true);
          return FileCommandResponse.successful(
            action: action,
          );
        } catch (e) {
          return FileCommandResponse.failed(
            action: action,
            message: e.toString(),
          );
        }
      case FileAction.read:
        try {
          final result = await file.readAsBytes();
          return FileCommandResponse.successful(
            action: action,
            data: result,
          );
        } catch (e) {
          return FileCommandResponse.failed(
            action: action,
            message: e.toString(),
          );
        }
    }
  }
}
