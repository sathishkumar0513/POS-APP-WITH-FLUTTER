import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/store_model.dart';
import '../../core/services/store_service.dart';
import '../dashboard/dashboard_screen.dart';

class StoreSetupScreen extends StatefulWidget {
  final bool isFirstTime;
  const StoreSetupScreen({super.key, this.isFirstTime = false});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final StoreService _service = StoreService();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();
  String? _logoPath;
  bool _isLoading = false;
  StoreModel? _existingStore;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    final store = await _service.getStore();
    if (store != null && mounted) {
      setState(() {
        _existingStore = store;
        _nameController.text = store.name;
        _addressController.text = store.address;
        _phoneController.text = store.phone;
        _gstController.text = store.gstNumber ?? '';
        _logoPath = store.logoPath;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile != null) setState(() { _logoPath = xFile.path; });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final store = StoreModel(
        id: _existingStore?.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
        logoPath: _logoPath,
      );
      await _service.saveStore(store);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store saved successfully'), backgroundColor: Colors.green));
        if (widget.isFirstTime) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstTime ? 'Store Setup' : 'Store Settings'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !widget.isFirstTime,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isFirstTime)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(child: Text('Welcome! Please set up your store before continuing.', style: TextStyle(color: Colors.blue))),
                    ],
                  ),
                ),
              if (widget.isFirstTime) const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: _logoPath != null
                        ? ClipOval(child: Image.file(File(_logoPath!), fit: BoxFit.cover))
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.store, size: 40, color: Colors.grey), Text('Store Logo', style: TextStyle(color: Colors.grey, fontSize: 12))],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Store Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.store)),
                validator: (v) => v == null || v.isEmpty ? 'Store name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gstController,
                decoration: const InputDecoration(labelText: 'GST Number (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.receipt_long)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                  label: const Text('SAVE STORE', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
