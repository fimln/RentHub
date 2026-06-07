import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  void connect(String serverUrl, String token) {
    _socket?.disconnect();
    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
    _socket!.onConnect((_) => print('[Socket] connected'));
    _socket!.onDisconnect((_) => print('[Socket] disconnected'));
    _socket!.onConnectError((e) => print('[Socket] connect error: $e'));
  }

  void on(String event, Function(dynamic) handler) => _socket?.on(event, handler);

  void off(String event) => _socket?.off(event);

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}
