import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ttc_ble/flutter_ttc_ble.dart';

import 'package:test_app/ble_manager.dart';
import 'package:test_app/oad_screen.dart';
// import 'log_util.dart';


class CommPage extends StatefulWidget {
  final BLEDevice device;

  const CommPage({Key? key, required this.device}) : super(key: key);

  @override
  State<CommPage> createState() => _CommPageState();
}

class _CommPageState extends State<CommPage> with BleCallback2 {
  static const tag = 'CommPage';
  final _txDataController = TextEditingController(text: '123456');
  final _textStyle = const TextStyle(
      color: Color.fromARGB(0xff, 0, 0, 0),
      fontSize: 18,
      fontWeight: FontWeight.normal);

  late String _deviceId;
  String _connectionState = "Not connected";
  String _rxData = "";
  bool _disposed = false;

  @override
  void onBluetoothStateChanged(BluetoothState state) {
    print('onBluetoothStateChanged() - state=$state');
  }

  @override
  void onConnected(String deviceId) {
    BleManager().enableNotification(deviceId: deviceId);
    if (!_disposed) {
      setState(() {
        _connectionState = "Connected";
      });
    }
  }

  @override
  void onDisconnected(String deviceId) {
    if (!_disposed) {
      setState(() {
        _connectionState = "Disconnected";
      });
    }
  }

  @override
  void onMtuChanged(String deviceId, int mtu) {
    print('onMtuChanged() - $deviceId, mtu=$mtu');
  }

  @override
  void onConnectTimeout(String deviceId) {
    print('onConnectTimeout() - $deviceId');
  }

  @override
  void onNotificationStateChanged(String deviceId, String serviceUuid,
      String characteristicUuid, bool enabled, String? error) {
    print(
        'onNotificationStateChanged() - $serviceUuid/$characteristicUuid enabled=$enabled, error=$error');
  }

  @override
  void onConnectionUpdated(
      String deviceId, int interval, int latency, int timeout, int status) {
    print(
        'onConnectionUpdated() - interval=$interval, latency=$latency, timeout=$timeout, status=$status');
  }

  @override
  void onDataReceived(String deviceId, String serviceUuid,
      String characteristicUuid, Uint8List data) {
// https://docs.flutter.io/flutter/services/StandardMessageCodec-class.html

    String utf8String = "";
    try {
      utf8String = utf8.decode(data);
    } on Exception catch (e) {
      print(e);
    }

    String hexString = data.toHex();

    print('<- utf8String=$utf8String, hexString=$hexString');

    if (!_disposed) {
      setState(() {
        _rxData = "${DateTime.now()}\nHEX: $hexString\nString: $utf8String";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    print('CommPage initState()');
    _deviceId = widget.device.deviceId;
    //连接设备
    bleProxy.connect(deviceId: _deviceId);

    //TODO 监听平台消息
    bleProxy.addBleCallback(this);
  }

  @override
  void dispose() {
    print('CommPage -> dispose()');
    _disposed = true;
    bleProxy.removeBleCallback(this);
    bleProxy.disconnect(deviceId: _deviceId); //断开连接
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope 监听左上角返回和实体返回
    return WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.device.name ?? 'Unknown Device',
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              children: <Widget>[
                const SizedBox(height: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, //子控件靠左
                  children: <Widget>[
                    Text(
                      _deviceId,
                      style: _textStyle,
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      _connectionState,
                      style: _textStyle,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      "RX",
                      style: _textStyle,
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      _rxData,
                      style: _textStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Text(
                  "TX",
                  style: _textStyle,
                ),
                TextField(
                  controller: _txDataController,
                ),
                const SizedBox(height: 6.0),
                ElevatedButton(
                  child: const Text('SEND'),
                  onPressed: () {
                    ///发送数据
                    BleManager().sendData(
                        deviceId: _deviceId,
                        data: _stringToData(_txDataController.text));
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ElevatedButton(
                      child: const Text('CONNECT'),
                      onPressed: () {
                        ///连接设备
                        bleProxy.connect(deviceId: _deviceId);
                      },
                    ),
                    const SizedBox(width: 12.0),
                    ElevatedButton(
                      child: const Text('DISCONNECT'),
                      onPressed: () {
                        ///断开连接
                        bleProxy.disconnect(deviceId: _deviceId);
                      },
                    ),
                    const SizedBox(width: 12.0),
                    ElevatedButton(
                      child: const Text('READ'),
                      onPressed: () {
                        ///读取数据
                        // https://www.bluetooth.com/specifications/gatt/characteristics
                        // Generic Access: 00001800-0000-1000-8000-00805f9b34fb
                        // Device Name: 00002a00-0000-1000-8000-00805f9b34fb
                        bleProxy.read(
                            deviceId: _deviceId,
                            serviceUuid: Uuids.deviceInformation,
                            characteristicUuid: Uuids.softwareRevision);
                      },
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    ElevatedButton(
                      child: const Text('CONNECTION SATE'),
                      onPressed: () {
                        ///获取连接状态
                        _getConnectionState();
                      },
                    ),
                    const SizedBox(width: 12.0),
                    ElevatedButton(
                      child: const Text('REQUEST MTU'),
                      onPressed: () {
                        ///更新MTU
                        bleProxy.requestMtu(deviceId: _deviceId, mtu: 251);
                      },
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    ElevatedButton(
                      child: const Text('CONNECTION PRIORITY'),
                      onPressed: () {
                        ///更新链接参数
                        bleProxy.requestConnectionPriority(
                            deviceId: _deviceId,
                            priority: ConnectionPriority.high);
                      },
                    ),
                    const SizedBox(width: 12.0),
                    ElevatedButton(
                      child: const Text('GET SERVICES'),
                      onPressed: () {
                        ///获取GATT服务
                        bleProxy
                            .getGattServices(deviceId: _deviceId)
                            .then((services) => _printGattServices(services));
                      },
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                OADScreen(deviceId: _deviceId)));
                  },
                  child: const Text('OAD'),
                ),
              ],
            ),
          ),
        ));
  }

  void _printGattServices(List<GattService> services) {
    // print() 打印的字符串长度最大是1K，所以这里使用循环打印
    for (var service in services) {
      print('$tag 服务: ${service.uuid}, isPrimary=${service.isPrimary}');
      for (var characteristic in service.characteristics) {
        print('$tag\t特征: ${jsonEncode(characteristic)}');
      }
    }
  }

  void _getConnectionState() async {
    final bool connected = await bleProxy.isConnected(deviceId: _deviceId);
    print('是否已连接：$connected');
  }

  Future<bool> _onBackPressed() {
    //用户点击了左上角返回按钮或实体返回建
    print('用户点击了左上角返回按钮或实体返回建');
    Navigator.pop(context, "I'm back!");
    return Future.value(false);
  }

  /// 将 String 转化为 Uint8List
  Uint8List _stringToData(String hexValue) {
    Uint8List data;
    try {
      data = hexValue.toData();
    } on Exception catch (e) {
      print(e);
      //HEX转化异常时按照字符转化
      //hexValue.codeUnits 的类型为 CodeUnits，需要转化一下
      data = Uint8List.fromList(hexValue.codeUnits);
    }
    return data;
  }
}
