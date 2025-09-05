import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

const platform = MethodChannel('ble_utils');

Future<void> clearBluetoothCache(String deviceId) async {
  try {
    await platform.invokeMethod('clearBluetoothCache', {'deviceId': deviceId});
    print("✅ Cleared BLE cache for $deviceId");
  } on PlatformException catch (e) {
    print("❌ Failed to clear BLE cache: ${e.message}");
  }
}

Future<void> _requestPermissions() async {
  // Request all necessary permissions
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.bluetooth,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
  ].request();

  if (!statuses[Permission.location]!.isGranted) {
    print("Location permission denied");
  }
  if (!statuses[Permission.bluetooth]!.isGranted) {
    print("Bluetooth permission denied");
  }
  if (!statuses[Permission.bluetoothConnect]!.isGranted) {
    print("Bluetooth Connect permission denied");
  }
  if (!statuses[Permission.bluetoothScan]!.isGranted) {
    print("Bluetooth Scan permission denied");
  }
}

// Use the same UUIDs as your ESP32
final String customService = "12345678-1234-1234-1234-123456789abc";
final String customCharacteristic = "12345678-1234-1234-1234-123456789def";
final String crashCharacteristic = "12345678-1234-1234-1234-123456789aaa";

StreamSubscription<List<ScanResult>>? _scanSub;
BluetoothDevice? _connectedDevice;
StreamSubscription<List<int>>? _notifySub;
StreamSubscription<List<int>>? _crashSub;
bool _isConnected = false;

void startScan(Function(BluetoothDevice) onDeviceFound) {
  print("Starting scan for custom service: $customService");

  // Stop any existing scan
  FlutterBluePlus.stopScan();
  _scanSub?.cancel();

  _scanSub = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
    for (var result in results) {
      print(
          "Discovered device: ${result.device.remoteId}, name: ${result.device.advName}");
      if (result.device.advName == "ESP32_SimpleInt" ||
          result.device.remoteId.toString().contains("ESP32_SimpleInt")) {
        print("✅ Found ESP32_SimpleInt! Stopping scan...");
        FlutterBluePlus.stopScan();
        onDeviceFound(result.device);
        break;
      }
    }
  }, onError: (e) => print("❌ Scan error: $e"));

  // Start scanning with filters
  FlutterBluePlus.startScan(
    withServices: [Guid(customService)],
    timeout: Duration(seconds: 15),
  );
}

void connectAndSubscribe(BluetoothDevice device, Function(int) onIntUpdate,
    Function(String) onStatus, Function onCrashDetected) {
  onStatus("Connecting...");

  // Cancel any existing connection first
  _notifySub?.cancel();
  _crashSub?.cancel();

  // Listen to connection state changes
  device.connectionState.listen((state) {
    print("Connection state: $state");
    if (state == BluetoothConnectionState.connected) {
      _isConnected = true;
      onStatus("Connected");

      // Discover services after connection
      discoverServices(device, onIntUpdate, onStatus, onCrashDetected);
    } else if (state == BluetoothConnectionState.disconnected) {
      _isConnected = false;
      onStatus("Disconnected");
      _notifySub?.cancel();
      _crashSub?.cancel();
    }
  }, onError: (e) {
    print("❌ Connection state error: $e");
    onStatus("Connection Error");
  });

  // Connect to device with timeout
  device.connect(timeout: Duration(seconds: 10)).catchError((e) {
    print("❌ Connection error: $e");
    onStatus("Connection Failed");
  });
}

void discoverServices(BluetoothDevice device, Function(int) onIntUpdate,
    Function(String) onStatus, Function onCrashDetected) {
  device.discoverServices().then((services) {
    print("✅ Discovered ${services.length} services");

    // Find our service and characteristic
    for (var service in services) {
      print("Service: ${service.uuid}");

      if (service.uuid.toString().toLowerCase() ==
          customService.toLowerCase()) {
        print("Found our service: ${service.uuid}");

        for (var characteristic in service.characteristics) {
          print(
              "Characteristic: ${characteristic.uuid}, properties: ${characteristic.properties}");

          // Handle regular integer characteristic
          if (characteristic.uuid.toString().toLowerCase() ==
              customCharacteristic.toLowerCase()) {
            print("Found our characteristic: ${characteristic.uuid}");

            // Check if characteristic supports notify
            if (characteristic.properties.notify) {
              // Subscribe to notifications
              _notifySub = characteristic.value.listen((data) {
                print("📨 Received ${data.length} bytes: $data");
                if (data.isNotEmpty) {
                  final intValue = data[0];
                  print("🔢 Value: $intValue");
                  onIntUpdate(intValue);
                }
              });

              // Enable notifications
              characteristic.setNotifyValue(true).then((_) {
                print("✅ Notifications enabled");
              }).catchError((e) {
                print("❌ Failed to enable notifications: $e");
                onStatus("Notification Error");
              });
            } else {
              print("❌ Characteristic does not support notifications");
              onStatus("Characteristic not supported");
            }
          }

          // Handle crash detection characteristic
          if (characteristic.uuid.toString().toLowerCase() ==
              crashCharacteristic.toLowerCase()) {
            print("Found crash characteristic: ${characteristic.uuid}");

            // Check if characteristic supports notify
            if (characteristic.properties.notify) {
              // Subscribe to crash notifications
              _crashSub = characteristic.value.listen((data) {
                print("🚨 Crash detected! Data: $data");
                if (data.isNotEmpty && data[0] == 1) {
                  // Trigger crash response UI
                  onCrashDetected();
                }
              });

              // Enable notifications
              characteristic.setNotifyValue(true).then((_) {
                print("✅ Crash notifications enabled");
              }).catchError((e) {
                print("❌ Failed to enable crash notifications: $e");
              });
            }
          }
        }
        break;
      }
    }
  }).catchError((e) {
    print("❌ Service discovery failed: $e");
    onStatus("Service discovery failed");
  });
}

void disposeBle() {
  _isConnected = false;
  _notifySub?.cancel();
  _crashSub?.cancel();
  _scanSub?.cancel();

  // Disconnect if connected
  if (_connectedDevice != null) {
    _connectedDevice!.disconnect();
    _connectedDevice = null;
  }
}

// ---------------- HeartbeatPanel Widget ----------------

class HeartbeatPanel extends StatefulWidget {
  const HeartbeatPanel({super.key});

  @override
  State<HeartbeatPanel> createState() => _HeartbeatPanelState();
}

class _HeartbeatPanelState extends State<HeartbeatPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  int _value = 0;
  String _status = "Disconnected";
  bool _isScanning = false;
  bool _crashDetected = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.94, end: 1.08)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 1.08, end: 0.96)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.06)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 1.06, end: 0.94)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 25),
    ]).animate(_controller);

    // Initialize BLE and request permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBle();
    });
  }

  void _initBle() async {
    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      setState(() {
        _status = "Bluetooth not supported";
      });
      return;
    }

    // Listen to adapter state
    FlutterBluePlus.adapterState.listen((state) {
      print("Bluetooth adapter state: $state");
      if (state == BluetoothAdapterState.on) {
        _startScanning();
      } else {
        setState(() {
          _status = "Bluetooth is off";
        });
        // Try to turn on Bluetooth on Android
        if (Platform.isAndroid) {
          FlutterBluePlus.turnOn();
        }
      }
    });

    // Request permissions
    await _requestPermissions();

    // Start scanning if Bluetooth is on
    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
      _startScanning();
    }
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _status = "Scanning...";
    });

    startScan((device) {
      setState(() => _isScanning = false);
      _connectedDevice = device;
      connectAndSubscribe(device, (value) {
        setState(() => _value = value);
      }, (status) {
        setState(() => _status = status);
      }, _onCrashDetected);
    });
  }

  void _onCrashDetected() {
    setState(() {
      _crashDetected = true;
    });

    // Show alert dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Crash Detected!"),
          content: const Text("A potential crash has been detected."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _crashDetected = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _reconnect() async {
    if (_connectedDevice != null) {
      await clearBluetoothCache(_connectedDevice!.id.id);
    }
    disposeBle();
    _startScanning();
  }

  @override
  void dispose() {
    disposeBle();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _crashDetected
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.06),
            border: Border.all(
              color: _crashDetected
                  ? Colors.red
                  : Colors.white12,
              width: _crashDetected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _crashDetected
                  ? [
                Colors.red.withOpacity(0.15),
                Colors.orange.withOpacity(0.1),
              ]
                  : [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.02),
              ],
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Crash alert indicator
              if (_crashDetected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.red[100], size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'CRASH DETECTED',
                        style: TextStyle(
                          color: Colors.red[100],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_crashDetected) const SizedBox(height: 10),

              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _crashDetected
                            ? Colors.red.withOpacity(0.5)
                            : Colors.tealAccent.withOpacity(0.35),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _crashDetected ? Icons.warning : Icons.favorite,
                    color: _crashDetected
                        ? Colors.red
                        : _isConnected
                        ? Colors.tealAccent.shade400
                        : Colors.grey,
                    size: 68,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _crashDetected ? 'CRASH ALERT!' : 'Heartbeat',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _crashDetected
                      ? Colors.red
                      : const Color.fromARGB(255, 231, 7, 7),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _status,
                style: TextStyle(
                  color: _isConnected ? Colors.green : Colors.grey,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _crashDetected
                        ? Colors.red
                        : Colors.white10,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monitor_heart_rounded,
                      color: _crashDetected
                          ? Colors.red
                          : _isConnected
                          ? Colors.tealAccent.shade400
                          : Colors.grey,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_value',
                      style: TextStyle(
                        color: _crashDetected
                            ? Colors.red
                            : _isConnected
                            ? Colors.tealAccent.shade400
                            : Colors.grey,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!_isConnected)
                ElevatedButton(
                  onPressed: _reconnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.shade400,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Reconnect'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}