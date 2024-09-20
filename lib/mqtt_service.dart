import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  final String broker =
      '<eba1575c50534835aaf7901fe9abeda5.s1.eu.hivemq.cloud>'; // Add your broker URL here
  final int port = 8883; // Secure port for MQTT
  final String clientIdentifier = 'flutter_client';
  final String username = '<RowanFayez>'; // Add your username here
  final String password = '<Rory2610>'; // Add your password here
  MqttServerClient? client;

  Future<void> connect() async {
    client = MqttServerClient(broker, clientIdentifier);
    client!.port = port;
    client!.logging(on: true);
    client!.secure = true;
    client!.setProtocolV311();
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean()
        .authenticateAs(username, password)
        .withWillQos(MqttQos.atLeastOnce);
    client!.connectionMessage = connMessage;

    try {
      await client!.connect();
      print('Connected to MQTT broker');
    } catch (e) {
      print('Connection failed: $e');
      client!.disconnect();
    }
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    print('Published message: $message to topic: $topic');
  }

  void disconnect() {
    client!.disconnect();
    print('Disconnected from MQTT broker');
  }
}
