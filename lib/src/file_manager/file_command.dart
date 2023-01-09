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

  FileCommandResponse.successful({
    this.data,
    this.message = 'ok',
  }) : successful = true;

  FileCommandResponse.failed({
    this.data,
    required this.message,
  }) : successful = false;

  @override
  String toString() {
    return 'FileCommandResponse(was successful: $successful,message: $message,contains data: ${data != null})';
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
          return FileCommandResponse.successful();
        } catch (e) {
          return FileCommandResponse.failed(
            message: e.toString(),
          );
        }
      case FileAction.write:
        if (params == null) {
          return FileCommandResponse.failed(
            message: 'cannot execute write operation with no params',
          );
        }
        try {
          await file.writeAsBytes(
            params!,
            mode: FileMode.writeOnly,
          );
          return FileCommandResponse.successful();
        } catch (e) {
          return FileCommandResponse.failed(
            message: e.toString(),
          );
        }

      case FileAction.append:
        if (params == null) {
          return FileCommandResponse.failed(
            message: 'cannot execute write operation with no params',
          );
        }
        try {
          await file.writeAsBytes(
            params!,
            mode: FileMode.writeOnlyAppend,
          );
          return FileCommandResponse.successful();
        } catch (e) {
          return FileCommandResponse.failed(
            message: e.toString(),
          );
        }

      case FileAction.create:
        try {
          await file.create(recursive: true);
          return FileCommandResponse.successful();
        } catch (e) {
          return FileCommandResponse.failed(
            message: e.toString(),
          );
        }
      case FileAction.read:
        try {
          final result = await file.readAsBytes();
          return FileCommandResponse.successful(
            data: result,
          );
        } catch (e) {
          return FileCommandResponse.failed(
            message: e.toString(),
          );
        }
    }
  }
}
