import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/product_model.dart';
import '../../core/services/product_service.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _service = ProductService();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();
  final _taxController = TextEditingController();
  final _stockController = TextEditingController();
  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _barcodeController.text = p.barcode ?? '';
      _categoryController.text = p.category ?? '';
      _costController.text = p.costPrice.toStringAsFixed(2);
      _priceController.text = p.sellingPrice.toStringAsFixed(2);
      _taxController.text = p.taxPercent.toStringAsFixed(2);
      _stockController.text = p.stockQuantity.toString();
      _imagePath = p.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _taxController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile != null) {
      setState(() { _imagePath = xFile.path; });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final product = ProductModel(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        costPrice: double.tryParse(_costController.text) ?? 0,
        sellingPrice: double.tryParse(_priceController.text) ?? 0,
        taxPercent: double.tryParse(_taxController.text) ?? 0,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        imagePath: _imagePath,
      );
      if (widget.product == null) {
        await _service.insertProduct(product);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully'), backgroundColor: Colors.green));
      } else {
        await _service.updateProduct(product);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully'), backgroundColor: Colors.green));
      }
      if (mounted) Navigator.pop(context);
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
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_imagePath!), fit: BoxFit.cover))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey), Text('Add Image', style: TextStyle(color: Colors.grey))],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              _buildField(_nameController, 'Product Name', required: true),
              const SizedBox(height: 12),
              _buildField(_barcodeController, 'Barcode'),
              const SizedBox(height: 12),
              _buildField(_categoryController, 'Category'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildField(_costController, 'Cost Price', isNumber: true, required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(_priceController, 'Selling Price', isNumber: true, required: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildField(_taxController, 'Tax %', isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(_stockController, 'Stock Qty', isInteger: true, required: true)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE PRODUCT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, {bool required = false, bool isNumber = false, bool isInteger = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      keyboardType: isNumber || isInteger ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isInteger ? [FilteringTextInputFormatter.digitsOnly] : [],
      validator: required ? (v) => v == null || v.isEmpty ? '$label is required' : null : null,
    );
  }
}
