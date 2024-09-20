import 'MQTT.dart';
import 'mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatelessWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn'); // Reset the login status
              Navigator.pushReplacementNamed(context, '/signin');
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Welcome to the future of firefighting, $userName!',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Expanded(
            child: SmartDevicesScreen(userName: userName),
          ),
        ],
      ),
    );
  }
}

class SmartDevicesScreen extends StatefulWidget {
  final String userName;

  const SmartDevicesScreen({super.key, required this.userName});

  @override
  State<SmartDevicesScreen> createState() => _SmartDevicesScreenState();
}

class _SmartDevicesScreenState extends State<SmartDevicesScreen> {
  bool isWaterPumpOn = false; // Water pump state
  late MQTTClientWrapper mqttClientWrapper;

  @override
  void initState() {
    super.initState();
    mqttClientWrapper = MQTTClientWrapper();
    mqttClientWrapper.prepareMqttClient();
  }

  void _onDeviceStateChanged(bool isOn, String device) {
    setState(() {
      if (device == 'Water Pump') {
        isWaterPumpOn = isOn;
      }
    });

    // Publish the state to MQTT
    final topic = 'home/waterpump';
    final message = isOn ? 'on' : 'off';
    mqttClientWrapper.publishMessage(topic, message);
    print('Publishing to topic: $topic with message: $message');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to the start
        children: [
          const SizedBox(height: 20),
          const Text(
            'Smart Devices',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                SmartDeviceControl(
                  label: 'Water Pump',
                  isOn: isWaterPumpOn,
                  onStateChanged: (value) {
                    _onDeviceStateChanged(value, 'Water Pump');
                  },
                ),
                const SizedBox(height: 20), // Add some space between controls
                ServoControl(), // Add the servo control directly here
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SmartDeviceControl extends StatefulWidget {
  final String label;
  final bool isOn;
  final Function(bool) onStateChanged;

  const SmartDeviceControl({
    super.key,
    required this.label,
    required this.isOn,
    required this.onStateChanged,
  });

  @override
  _SmartDeviceControlState createState() => _SmartDeviceControlState();
}

class _SmartDeviceControlState extends State<SmartDeviceControl> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.isOn;
  }

  @override
  void didUpdateWidget(SmartDeviceControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    isOn = widget.isOn;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isOn ? Colors.redAccent : Colors.grey[300],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10.0,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOn ? Icons.fire_extinguisher : Icons.fire_extinguisher_outlined,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 15),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Switch(
              value: isOn,
              onChanged: (value) {
                setState(() {
                  isOn = value;
                  widget.onStateChanged(isOn);
                });
              },
              activeColor: Colors.yellow,
              inactiveTrackColor: Colors.grey[400],
              inactiveThumbColor: Colors.white,
            ),
            Text(
              isOn ? "On" : "Off",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServoControl extends StatefulWidget {
  @override
  _ServoControlState createState() => _ServoControlState();
}

class _ServoControlState extends State<ServoControl> {
  double _servoAngle = 90;
  late MQTTClientWrapper mqttClient;

  @override
  void initState() {
    super.initState();
    mqttClient = MQTTClientWrapper();
    mqttClient.prepareMqttClient();
  }

  void _publishServoAngle() {
    // Check if the MQTT client is connected
    if (mqttClient.isConnected) {
      mqttClient.publishMessage('servo/control', _servoAngle.toString());
      print('Publishing angle: $_servoAngle');
    } else {
      print('MQTT client is not connected. Cannot publish angle.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Servo Control',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Slider(
          value: _servoAngle,
          min: 0,
          max: 180,
          divisions: 180,
          label: _servoAngle.round().toString(),
          activeColor: Colors.yellow,
          inactiveColor: Colors.grey,
          onChanged: (value) {
            setState(() {
              _servoAngle = value;
            });
          },
          onChangeEnd: (value) {
            _publishServoAngle(); // Publish when slider adjustment ends
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Current Angle: ${_servoAngle.round()}'),
        ),
      ],
    );
  }
}
