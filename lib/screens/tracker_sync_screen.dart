import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ble_service.dart';

class TrackerSyncScreen extends StatefulWidget {
  const TrackerSyncScreen({super.key});

  @override
  State<TrackerSyncScreen> createState() => _TrackerSyncScreenState();
}

class _TrackerSyncScreenState extends State<TrackerSyncScreen> {
  final BleService _bleService = BleService();

  @override
  void initState() {
    super.initState();
    _bleService.addListener(_onBleUpdate);
    // Start scan on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bleService.scanAndConnect();
    });
  }

  @override
  void dispose() {
    _bleService.removeListener(_onBleUpdate);
    _bleService.disconnect();
    super.dispose();
  }

  void _onBleUpdate() {
    setState(() {});
  }

  void _downloadFile(TrackFile file) async {
    try {
      File? downloadedFile = await _bleService.downloadFile(file);
      if (downloadedFile != null && mounted) {
        // Return the downloaded file back to root_screen for parsing
        Navigator.of(context).pop(downloadedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sync Tracker"),
        actions: [
          if (!_bleService.isConnected && !_bleService.isScanning)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _bleService.scanAndConnect(),
            )
        ],
      ),
      body: Column(
        children: [
          _buildStatusHeader(),
          const Divider(),
          Expanded(child: _buildFileList()),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            _bleService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
            color: _bleService.isConnected ? Colors.blue : Colors.grey,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Status: ${_bleService.statusMessage}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_bleService.isDownloading && _bleService.downloadingFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Downloading: ${_bleService.downloadingFileName} (${(_bleService.downloadProgress * 100).toStringAsFixed(1)}%)",
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
              ],
            ),
          ),
          if (_bleService.isScanning) const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (_bleService.isListing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_bleService.trackFiles.isEmpty) {
      if (_bleService.isConnected) {
        return const Center(child: Text("No files found on tracker."));
      } else {
        return const Center(child: Text("Connect to tracker to view files."));
      }
    }

    return ListView.builder(
      itemCount: _bleService.trackFiles.length,
      itemBuilder: (context, index) {
        final file = _bleService.trackFiles[index];
        final isThisDownloading = _bleService.isDownloading && _bleService.downloadingFileName == file.name;

        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(file.name),
          subtitle: Text("${file.sizeMb.toStringAsFixed(2)} MB"),
          trailing: isThisDownloading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(value: _bleService.downloadProgress),
                )
              : IconButton(
                  icon: const Icon(Icons.download),
                  color: Colors.deepPurple,
                  onPressed: _bleService.isDownloading ? null : () => _downloadFile(file),
                ),
        );
      },
    );
  }
}
