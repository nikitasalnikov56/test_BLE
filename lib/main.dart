// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:uuid/uuid.dart' as uid;

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   String _counter = '0';
//   static const uuid = uid.Uuid(); // не работает с FlutterReactiveBle
//   final ble = FlutterReactiveBle();

//   void startScan() {
//     ble.scanForDevices(withServices: []).listen((event) {
//       print(event);
//     });
//   }

//   // Future<String> getDeviceUUID() async {
//   //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//   //   if (Platform.isAndroid) {
//   //     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//   //     return _counter = androidInfo.id; // UUID устройства на Android
//   //   } else if (Platform.isIOS) {
//   //     IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
//   //     return _counter =
//   //         iosInfo.identifierForVendor ?? ''; // UUID устройства на iOS
//   //   }

//   //   return _counter;
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: startScan,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }

//пример 2

// import 'dart:async';
// import 'dart:io' show Platform;

// import 'package:flutter/services.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:uuid/uuid.dart' as uid;

// void main() {
//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//     ),
//   );
//   return runApp(
//     const MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()),
//   );
// }

// class HomePage extends StatefulWidget {
//   const HomePage({Key? key}) : super(key: key);

//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   // Some state management stuff
//   bool _foundDeviceWaitingToConnect = false;
//   bool _scanStarted = false;
//   bool _connected = false;
// // Bluetooth related variables
//   late DiscoveredDevice _ubiqueDevice;
//   final flutterReactiveBle = FlutterReactiveBle();
//   late StreamSubscription<DiscoveredDevice> _scanStream;
//   late QualifiedCharacteristic _rxCharacteristic;
// // These are the UUIDs of your device
//   final Uuid serviceUuid = Uuid.parse("75C276C3-8F97-20BC-A143-B354244886D4");
//   final Uuid characteristicUuid =
//       Uuid.parse("6ACF4F08-CC9D-D495-6B41-AA7E60C4E8A6");

//   void _startScan() async {
// // Platform permissions handling stuff
//     bool permGranted = false;
//     setState(() {
//       _scanStarted = true;
//     });
//     PermissionStatus permission;
//     if (Platform.isAndroid) {
//       permission = await Permission.location.request();
//       if (permission == PermissionStatus.granted) permGranted = true;
//     } else if (Platform.isIOS) {
//       permGranted = true;
//     }
// // Main scanning logic happens here ⤵️
//     if (permGranted) {
//       _scanStream = flutterReactiveBle
//           .scanForDevices(withServices: [serviceUuid]).listen((device) {
//         // Change this string to what you defined in Zephyr
//         if (device.name == 'UBIQUE') {
//           setState(() {
//             _ubiqueDevice = device;
//             _foundDeviceWaitingToConnect = true;
//           });
//         }
//       });
//     }
//   }

//   void _connectToDevice() {
//     // We're done scanning, we can cancel it
//     _scanStream.cancel();
//     // Let's listen to our connection so we can make updates on a state change
//     Stream<ConnectionStateUpdate> _currentConnectionStream = flutterReactiveBle
//         .connectToAdvertisingDevice(
//             id: _ubiqueDevice.id,
//             prescanDuration: const Duration(seconds: 1),
//             withServices: [serviceUuid, characteristicUuid]);
//     _currentConnectionStream.listen((event) {
//       switch (event.connectionState) {
//         // We're connected and good to go!
//         case DeviceConnectionState.connected:
//           {
//             _rxCharacteristic = QualifiedCharacteristic(
//                 serviceId: serviceUuid,
//                 characteristicId: characteristicUuid,
//                 deviceId: event.deviceId);
//             setState(() {
//               _foundDeviceWaitingToConnect = false;
//               _connected = true;
//             });
//             break;
//           }
//         // Can add various state state updates on disconnect
//         case DeviceConnectionState.disconnected:
//           {
//             break;
//           }
//         default:
//       }
//     });
//   }

//   void _partyTime() {
//     if (_connected) {
//       flutterReactiveBle
//           .writeCharacteristicWithResponse(_rxCharacteristic, value: [
//         0xff,
//       ]);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Container(),
//       persistentFooterButtons: [
//         // We want to enable this button if the scan has NOT started
//         // If the scan HAS started, it should be disabled.
//         _scanStarted
//             // True condition
//             ? ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   primary: Colors.grey, // background
//                   onPrimary: Colors.white, // foreground
//                 ),
//                 onPressed: () {},
//                 child: const Icon(Icons.search),
//               )
//             // False condition
//             : ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   primary: Colors.blue, // background
//                   onPrimary: Colors.white, // foreground
//                 ),
//                 onPressed: _startScan,
//                 child: const Icon(Icons.search),
//               ),
//         _foundDeviceWaitingToConnect
//             // True condition
//             ? ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   primary: Colors.blue, // background
//                   onPrimary: Colors.white, // foreground
//                 ),
//                 onPressed: _connectToDevice,
//                 child: const Icon(Icons.bluetooth),
//               )
//             // False condition
//             : ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   primary: Colors.grey, // background
//                   onPrimary: Colors.white, // foreground
//                 ),
//                 onPressed: () {},
//                 child: const Icon(Icons.bluetooth),
//               ),
//         _connected
//             // True condition
//             ? ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   primary: Colors.blue, // background
//                   onPrimary: Colors.white, // foreground
//                 ),
//                 onPressed: _partyTime,
//                 child: const Icon(Icons.celebration_rounded),
//               )
//             // False condition
//             : ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   primary: Colors.grey, // background
//                   onPrimary: Colors.white, // foreground
//                 ),
//                 onPressed: () {},
//                 child: const Icon(Icons.celebration_rounded),
//               ),
//       ],
//     );
//   }
// }

//пример 3
import 'package:flutter/material.dart';
import 'package:flutter_ttc_ble/flutter_ttc_ble.dart';
import 'package:flutter_ttc_ble/scan_screen.dart';
import 'package:test_app/comm_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ScanScreen(
        title: 'TTC Flutter BLE Demo',
        onDeviceClick: (BuildContext context, BLEDevice device) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CommPage(device: device)));
        },
      ),
    );
  }
}
