import 'dart:typed_data';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sale_model.dart';
import '../models/store_model.dart';

class PrinterService {
  static final PrinterService instance = PrinterService._init();
  PrinterService._init();

  PrinterBluetoothManager printerManager = PrinterBluetoothManager();
  PrinterBluetooth? _selectedPrinter;
  bool _isConnected = false;

  static const String _keyPrinterAddress = 'printer_mac_address';
  static const String _keyPrinterName = 'printer_name';
  static const String _keyPaperSize = 'paper_size'; // '58' or '80'

  bool get isConnected => _isConnected;
  PrinterBluetooth? get selectedPrinter => _selectedPrinter;

  Future<void> startScan(Function(List<PrinterBluetooth>) onDevicesFound) async {
    printerManager.startScan(const Duration(seconds: 4));
    printerManager.scanResults.listen((devices) {
      onDevicesFound(devices);
    });
  }

  Future<void> stopScan() async {
    printerManager.stopScan();
  }

  Future<void> selectPrinter(PrinterBluetooth printer, String paperSize) async {
    _selectedPrinter = printer;
    printerManager.selectPrinter(printer);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrinterAddress, printer.address ?? '');
    await prefs.setString(_keyPrinterName, printer.name ?? 'Unknown');
    await prefs.setString(_keyPaperSize, paperSize);
  }

  Future<String?> getSavedPrinterAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPrinterAddress);
  }

  Future<String?> getSavedPrinterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPrinterName);
  }

  Future<String> getPaperSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPaperSize) ?? '80';
  }

  Future<PosPrintResult> printReceipt(SaleModel sale, StoreModel store) async {
    final paperSize = await getPaperSize();
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperSize == '58' ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );

    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.setStyles(PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text(store.name);
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    bytes += generator.text(store.address);
    bytes += generator.text('Tel: ${store.phone}');
    if (store.gstNumber != null && store.gstNumber!.isNotEmpty) {
      bytes += generator.text('GST: ${store.gstNumber}');
    }
    bytes += generator.hr();
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('SALES RECEIPT');
    bytes += generator.setStyles(const PosStyles());
    bytes += generator.text('Invoice: ${sale.invoiceNumber}');
    bytes += generator.text('Date: ${sale.createdAt.substring(0, 16)}');
    if (sale.customerName != null && sale.customerName!.isNotEmpty) {
      bytes += generator.text('Customer: ${sale.customerName}');
    }
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'ITEM', width: 5, styles: const PosStyles(bold: true)),
      PosColumn(text: 'QTY', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(text: 'PRICE', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: 'TOTAL', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr(ch: '-');

    for (final item in sale.items) {
      bytes += generator.row([
        PosColumn(text: item.productName, width: 5),
        PosColumn(text: '${item.quantity}', width: 2, styles: const PosStyles(align: PosAlign.center)),
        PosColumn(text: item.price.toStringAsFixed(2), width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: item.total.toStringAsFixed(2), width: 3, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 8, styles: const PosStyles()),
      PosColumn(text: sale.subtotal.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Tax:', width: 8, styles: const PosStyles()),
      PosColumn(text: sale.taxAmount.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (sale.discountAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 8, styles: const PosStyles()),
        PosColumn(text: '-${sale.discountAmount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'GRAND TOTAL:', width: 8, styles: const PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size1)),
      PosColumn(text: sale.grandTotal.toStringAsFixed(2), width: 4, styles: const PosStyles(bold: true, align: PosAlign.right, height: PosTextSize.size2, width: PosTextSize.size1)),
    ]);
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Payment (${sale.paymentMethod.toUpperCase()}):', width: 8),
      PosColumn(text: sale.amountPaid.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Change:', width: 8),
      PosColumn(text: sale.changeAmount.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr();
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    bytes += generator.text('*** THANK YOU ***');
    bytes += generator.text('Please come again!');
    bytes += generator.feed(3);
    bytes += generator.cut();

    return await printerManager.printTicket(bytes);
  }

  Future<PosPrintResult> printTestPage(String printerName) async {
    final paperSize = await getPaperSize();
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperSize == '58' ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );

    List<int> bytes = [];
    bytes += generator.reset();
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('=== TEST PRINT ===');
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    bytes += generator.text('Printer: $printerName');
    bytes += generator.text('Status: CONNECTED');
    bytes += generator.text('Paper: ${paperSize}mm');
    bytes += generator.hr();
    bytes += generator.setStyles(const PosStyles(align: PosAlign.left));
    bytes += generator.text('Left aligned text');
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    bytes += generator.text('Center aligned text');
    bytes += generator.setStyles(const PosStyles(align: PosAlign.right));
    bytes += generator.text('Right aligned text');
    bytes += generator.hr();
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    bytes += generator.text('--- Sample Receipt ---');
    bytes += generator.text('Item A   x2    100.00');
    bytes += generator.text('Item B   x1     50.00');
    bytes += generator.hr(ch: '-');
    bytes += generator.setStyles(const PosStyles(align: PosAlign.right, bold: true));
    bytes += generator.text('TOTAL:  150.00');
    bytes += generator.hr();
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    bytes += generator.text('Printer test successful!');
    bytes += generator.feed(3);
    bytes += generator.cut();

    return await printerManager.printTicket(bytes);
  }

  Future<PosPrintResult> printEstimation(dynamic estimation, StoreModel store) async {
    final paperSize = await getPaperSize();
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperSize == '58' ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );

    List<int> bytes = [];
    bytes += generator.reset();
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text(store.name);
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    bytes += generator.text(store.address);
    bytes += generator.text('Tel: ${store.phone}');
    bytes += generator.hr();
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('QUOTATION / ESTIMATION');
    bytes += generator.setStyles(const PosStyles());
    bytes += generator.text('Ref: ${estimation.estimationNumber}');
    bytes += generator.text('Date: ${estimation.createdAt.substring(0, 16)}');
    if (estimation.customerName != null && estimation.customerName!.isNotEmpty) {
      bytes += generator.text('To: ${estimation.customerName}');
    }
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'ITEM', width: 5, styles: const PosStyles(bold: true)),
      PosColumn(text: 'QTY', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(text: 'PRICE', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: 'TOTAL', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr(ch: '-');
    for (final item in estimation.items) {
      bytes += generator.row([
        PosColumn(text: item.productName, width: 5),
        PosColumn(text: '${item.quantity}', width: 2, styles: const PosStyles(align: PosAlign.center)),
        PosColumn(text: item.price.toStringAsFixed(2), width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: item.total.toStringAsFixed(2), width: 3, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'GRAND TOTAL:', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(text: estimation.grandTotal.toStringAsFixed(2), width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.hr();
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    bytes += generator.text('This is a quotation only.');
    bytes += generator.text('Subject to change without notice.');
    bytes += generator.feed(3);
    bytes += generator.cut();

    return await printerManager.printTicket(bytes);
  }
}
