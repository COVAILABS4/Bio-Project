import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:heal_anemia/global_state.dart';
import 'package:provider/provider.dart';
import 'GlobalState.dart';

class DeviceConnectionDialog extends StatefulWidget {
  @override
  _DeviceConnectionDialogState createState() => _DeviceConnectionDialogState();
}

class _DeviceConnectionDialogState extends State<DeviceConnectionDialog> {
  List<BluetoothDevice> devicesList = [];
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    FlutterBluetoothSerial.instance.getBondedDevices().then((List<BluetoothDevice> bondedDevices) {
      setState(() {
        devicesList = bondedDevices;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        "Connect to a Device",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
      ),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: devicesList.length,
          itemBuilder: (context, index) {
            BluetoothDevice device = devicesList[index];
            bool isConnected = connectedDevice?.address == device.address;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: isConnected ? Colors.green : Colors.grey.shade300),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.bluetooth,
                  color: isConnected ? Colors.green : Colors.blue,
                  size: 30,
                ),
                title: Text(
                  "${device.name ?? 'Unknown device'}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isConnected ? Colors.green : Colors.black,
                  ),
                ),
                subtitle: Text(
                  device.address,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: isConnected
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.circle_outlined, color: Colors.grey[400]),
                onTap: () {
                  _connect(device);
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            "Close",
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  void _connect(BluetoothDevice device) async {
    try {
      final connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        connectedDevice = device;
      });
      Provider.of<GlobalState>(context, listen: false)
          .setBluetoothConnection(true, device.address, device.name ?? 'Unknown', device.address, connection);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Cannot connect, exception occurred: $e")));
    }
  }
}
