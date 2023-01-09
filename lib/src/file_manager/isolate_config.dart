part of 'file_isolate.dart';

@immutable
class _IsolateConfig {
  final String fileAddress;
  final SendPort majorIsolatePort;
  final SendPort fileEvents;

  _IsolateConfig({
    required this.fileAddress,
    required this.majorIsolatePort,
    required this.fileEvents,
  });
}
