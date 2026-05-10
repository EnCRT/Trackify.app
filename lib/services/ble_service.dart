import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class TrackFile {
  final String name;
  final int sizeBytes;

  TrackFile(this.name, this.sizeBytes);

  double get sizeMb => sizeBytes / (1024 * 1024);
}

class BleService extends ChangeNotifier {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  final String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String cmdCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String dataCharUuid = "2c27702b-a010-4ea5-a228-4efb7965aa1b";

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? _cmdChar;
  BluetoothCharacteristic? _dataChar;
  StreamSubscription? _dataSubscription;

  bool isScanning = false;
  bool isConnected = false;
  String statusMessage = "Disconnected";

  List<TrackFile> trackFiles = [];
  bool isListing = false;

  bool isDownloading = false;
  double downloadProgress = 0.0;
  String? downloadingFileName;

  // Internal buffers
  String _listBuffer = "";
  List<int> _fileBuffer = [];
  int _expectedFileSize = 0;
  Completer<File?>? _downloadCompleter;

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    } else if (Platform.isIOS) {
      return await Permission.bluetooth.request().isGranted;
    }
    return false;
  }

  Future<void> scanAndConnect() async {
    bool hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      _updateStatus("Permissions denied");
      return;
    }

    if (isConnected) {
      await disconnect();
    }

    _updateStatus("Scanning for Trackify...");
    isScanning = true;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (r.device.platformName == "Trackify" || r.device.advName == "Trackify") {
            await FlutterBluePlus.stopScan();
            isScanning = false;
            await _connectToDevice(r.device);
            break;
          }
        }
      });

      await Future.delayed(const Duration(seconds: 15));
      if (isScanning) {
        await FlutterBluePlus.stopScan();
        isScanning = false;
        if (!isConnected) {
          _updateStatus("Device not found");
        }
      }
    } catch (e) {
      isScanning = false;
      _updateStatus("Scan failed: $e");
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _updateStatus("Connecting...");
    try {
      await device.connect(autoConnect: false);
      connectedDevice = device;
      isConnected = true;
      
      device.connectionState.listen((BluetoothConnectionState state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      // Request MTU for faster transfer
      if (Platform.isAndroid) {
        await device.requestMtu(512);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _updateStatus("Discovering services...");
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString() == cmdCharUuid) {
              _cmdChar = c;
            } else if (c.uuid.toString() == dataCharUuid) {
              _dataChar = c;
            }
          }
        }
      }

      if (_cmdChar != null && _dataChar != null) {
        await _dataChar!.setNotifyValue(true);
        _dataSubscription = _dataChar!.lastValueStream.listen(_onDataReceived);
        _updateStatus("Connected");
        await fetchFileList();
      } else {
        _updateStatus("Service not found");
        await disconnect();
      }
    } catch (e) {
      _updateStatus("Connection failed");
      await disconnect();
    }
  }

  void _onDataReceived(List<int> data) {
    if (isListing) {
      _listBuffer += utf8.decode(data, allowMalformed: true);
      if (_listBuffer.contains("END_LIST\n")) {
        _parseListBuffer();
        isListing = false;
        notifyListeners();
      }
    } else if (isDownloading) {
      if (data.isEmpty) {
        // EOF marker
        _finishDownload();
      } else {
        String possibleError = utf8.decode(data, allowMalformed: true);
        if (possibleError.startsWith("ERROR:")) {
           _failDownload(possibleError);
           return;
        }
        
        _fileBuffer.addAll(data);
        if (_expectedFileSize > 0) {
          downloadProgress = _fileBuffer.length / _expectedFileSize;
          notifyListeners();
        }
      }
    }
  }

  Future<void> fetchFileList() async {
    if (_cmdChar == null || isDownloading || isListing) return;
    
    _listBuffer = "";
    trackFiles.clear();
    isListing = true;
    notifyListeners();

    await _cmdChar!.write(utf8.encode("LIST"), withoutResponse: true);
  }

  void _parseListBuffer() {
    List<String> lines = _listBuffer.split('\n');
    trackFiles.clear();
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty || line == "END_LIST") continue;
      if (line.startsWith("ERROR:")) {
        _updateStatus(line);
        continue;
      }
      List<String> parts = line.split(';');
      if (parts.length == 2) {
        String name = parts[0];
        int size = int.tryParse(parts[1]) ?? 0;
        // Only show .txt files
        if (name.toLowerCase().endsWith('.txt')) {
          trackFiles.add(TrackFile(name, size));
        }
      }
    }
  }

  Future<File?> downloadFile(TrackFile trackFile) async {
    if (_cmdChar == null || isDownloading || isListing) return null;
    
    isDownloading = true;
    downloadingFileName = trackFile.name;
    downloadProgress = 0.0;
    _fileBuffer.clear();
    _expectedFileSize = trackFile.sizeBytes;
    _downloadCompleter = Completer<File?>();
    notifyListeners();

    await _cmdChar!.write(utf8.encode("GET ${trackFile.name}"), withoutResponse: true);

    return _downloadCompleter!.future;
  }

  Future<void> _finishDownload() async {
    isDownloading = false;
    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/$downloadingFileName';
      final file = File(path);
      await file.writeAsBytes(_fileBuffer);
      _downloadCompleter?.complete(file);
    } catch (e) {
      _downloadCompleter?.completeError(e);
    }
    _fileBuffer.clear();
    downloadProgress = 0.0;
    downloadingFileName = null;
    notifyListeners();
  }

  void _failDownload(String error) {
    isDownloading = false;
    _downloadCompleter?.completeError(Exception(error));
    _fileBuffer.clear();
    downloadProgress = 0.0;
    downloadingFileName = null;
    _updateStatus(error);
  }

  void _handleDisconnect() {
    isConnected = false;
    connectedDevice = null;
    _cmdChar = null;
    _dataChar = null;
    _dataSubscription?.cancel();
    isListing = false;
    if (isDownloading) {
      _failDownload("Device disconnected");
    }
    _updateStatus("Disconnected");
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }
    _handleDisconnect();
  }

  void _updateStatus(String msg) {
    statusMessage = msg;
    notifyListeners();
  }
}
