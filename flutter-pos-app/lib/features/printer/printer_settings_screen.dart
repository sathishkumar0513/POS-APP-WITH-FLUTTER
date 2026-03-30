import 'package:flutter/material.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/printer_service.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printerService = PrinterService.instance;
  List<PrinterBluetooth> _devices = [];
  bool _isScanning = false;
  String? _savedPrinterName;
  String? _savedPrinterAddress;
  String _paperSize = '80';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
  }

  Future<void> _loadSavedPrinter() async {
    final name = await _printerService.getSavedPrinterName();
    final address = await _printerService.getSavedPrinterAddress();
    final paperSize = await _printerService.getPaperSize();
    if (mounted) {
      setState(() {
        _savedPrinterName = name;
        _savedPrinterAddress = address;
        _paperSize = paperSize;
      });
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  Future<void> _startScan() async {
    await _requestPermissions();
    setState(() { _isScanning = true; _devices = []; });
    await _printerService.startScan((devices) {
      if (mounted) setState(() { _devices = devices; });
    });
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) setState(() { _isScanning = false; });
    await _printerService.stopScan();
  }

  Future<void> _selectPrinter(PrinterBluetooth printer) async {
    await _printerService.selectPrinter(printer, _paperSize);
    if (mounted) {
      setState(() {
        _savedPrinterName = printer.name;
        _savedPrinterAddress = printer.address;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Printer "${printer.name}" selected'), backgroundColor: Colors.green));
    }
  }

  Future<void> _testPrint() async {
    if (_savedPrinterName == null || _savedPrinterAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No printer selected'), backgroundColor: Colors.orange));
      return;
    }
    try {
      final result = await _printerService.printTestPage(_savedPrinterName!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result == PosPrintResult.success ? 'Test print successful!' : 'Print failed: ${result.msg}'),
          backgroundColor: result == PosPrintResult.success ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_savedPrinterName != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.print, color: Colors.green),
                title: Text(_savedPrinterName ?? 'Unknown'),
                subtitle: Text(_savedPrinterAddress ?? ''),
                trailing: Chip(label: const Text('Selected', style: TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: Colors.green),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paper Size', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          value: '58',
                          groupValue: _paperSize,
                          onChanged: (v) => setState(() { _paperSize = v!; }),
                          title: const Text('58mm'),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          value: '80',
                          groupValue: _paperSize,
                          onChanged: (v) => setState(() { _paperSize = v!; }),
                          title: const Text('80mm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: _isScanning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.bluetooth_searching),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan Devices'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _savedPrinterName != null ? _testPrint : null,
                  icon: const Icon(Icons.print),
                  label: const Text('Test Print'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_devices.isNotEmpty)
            const Text('Available Bluetooth Devices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (_devices.isNotEmpty) const SizedBox(height: 8),
          ..._devices.map((device) => Card(
            child: ListTile(
              leading: const Icon(Icons.bluetooth, color: Colors.blue),
              title: Text(device.name ?? 'Unknown Device'),
              subtitle: Text(device.address ?? ''),
              trailing: ElevatedButton(
                onPressed: () => _selectPrinter(device),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                child: const Text('Select', style: TextStyle(fontSize: 12)),
              ),
            ),
          )),
          if (_devices.isEmpty && !_isScanning && _savedPrinterName == null)
            Container(
              padding: const EdgeInsets.all(24),
              child: const Column(
                children: [
                  Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No devices found', style: TextStyle(color: Colors.grey)),
                  Text('Tap "Scan Devices" to search for nearby Bluetooth printers', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
