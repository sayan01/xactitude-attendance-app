import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(const MaterialApp(home: MyHome()));

class MyHome extends StatelessWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xactitude Attendance App')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const QRViewExample(),
                ));
              },
              child: const Text('SCAN'),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const QRViewExample(),
                ));
              },
              child: const Text('HISTORY'),
            ),
          ),
        ],
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  String? result;
  String message = "Start scanning to take attendance";
  late List<String> resultArr = <String>[];
  late QRViewController controller;
  Color? scanStatus;
  bool cameraPaused = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pauseCamera();
    }
    controller.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 1, child: _buildQrView(context)),
          Expanded(flex: 2, child: _buildAttListView(context)),
        ],
      ),
    );
  }

  Widget _buildAttListView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ElevatedButton(
          child: Text('${cameraPaused ? "Resume" : "Pause"} Camera'),
          onPressed: () async {
            await (cameraPaused
                ? controller.resumeCamera()
                : controller.pauseCamera());
            setState(() {
              cameraPaused = !cameraPaused;
            });
          },
        ),
        // MESSAGE GRAY
        Expanded(
          flex: 1,
          child: Text(
            message,
            style: const TextStyle(fontSize: 32, color: Colors.grey),
          ),
        ),
        // CODE LIST
        Expanded(
          flex: 5,
          child: Scrollbar(
            child: ListView.separated(
              itemBuilder: (context, index) => Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: Center(
                      child: Text(
                        resultArr[index],
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          message = "${resultArr[index]} Deleted";
                          scanStatus = Colors.red;
                          resultArr.removeAt(index);
                        });
                      },
                    ),
                  ),
                ],
              ),
              separatorBuilder: (context, index) => const Divider(),
              itemCount: resultArr.length,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              "END",
              style: TextStyle(fontSize: 32),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how wide or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: scanStatus ?? Colors.red,
          borderRadius: 10,
          borderLength: 50,
          borderWidth: 30,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != result) {
        setState(() {
          result = scanData.code;
          if (!resultArr.contains(result)) {
            resultArr.add(result!);
            scanStatus = Colors.green;
            message = "Attendance Taken";
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (BuildContext context, _, __) =>
                    const ScanOverlay(),
              ),
            );
          } else {
            scanStatus = Colors.orange;
            message = "$result already exists";
          }
        });
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.85),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
              child: Text(
            "Attendance Taken",
            style: TextStyle(fontSize: 32),
          )),
          ElevatedButton(
            autofocus: true,
            clipBehavior: Clip.antiAlias,
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
