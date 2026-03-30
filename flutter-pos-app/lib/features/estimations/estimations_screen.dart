import 'package:flutter/material.dart';
import '../../core/models/estimation_model.dart';
import '../../core/models/product_model.dart';
import '../../core/models/cart_item_model.dart';
import '../../core/models/customer_model.dart';
import '../../core/services/estimation_service.dart';
import '../../core/services/product_service.dart';
import '../../core/services/customer_service.dart';
import '../../core/services/store_service.dart';
import '../../core/services/printer_service.dart';
import '../../core/services/auth_service.dart';

class EstimationsScreen extends StatefulWidget {
  const EstimationsScreen({super.key});

  @override
  State<EstimationsScreen> createState() => _EstimationsScreenState();
}

class _EstimationsScreenState extends State<EstimationsScreen> {
  final EstimationService _service = EstimationService();
  List<EstimationModel> _estimations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEstimations();
  }

  Future<void> _loadEstimations() async {
    final estimations = await _service.getAllEstimations();
    if (mounted) setState(() { _estimations = estimations; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimations'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const EstimationFormScreen()));
          _loadEstimations();
        },
        label: const Text('New Estimation'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _estimations.isEmpty
              ? const Center(child: Text('No estimations found'))
              : ListView.builder(
                  itemCount: _estimations.length,
                  itemBuilder: (_, i) {
                    final e = _estimations[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.request_quote, color: Colors.white, size: 20)),
                        title: Text(e.estimationNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (e.customerName != null) Text(e.customerName!),
                            Text('Total: \u20B9${e.grandTotal.toStringAsFixed(2)} | ${e.createdAt.substring(0, 10)}'),
                          ],
                        ),
                        isThreeLine: e.customerName != null,
                        trailing: _buildStatusChip(e.status),
                        onTap: () => _showActions(e),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'converted': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.orange; break;
    }
    return Chip(
      label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  Future<void> _showActions(EstimationModel est) async {
    final fullEst = await _service.getEstimationById(est.id!);
    if (fullEst == null || !mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Print Estimation'),
            onTap: () async {
              Navigator.pop(ctx);
              final store = await StoreService().getStore();
              if (store != null) await PrinterService.instance.printEstimation(fullEst, store);
            },
          ),
          if (fullEst.status == 'pending')
            ListTile(
              leading: const Icon(Icons.point_of_sale, color: Colors.green),
              title: const Text('Convert to Sale', style: TextStyle(color: Colors.green)),
              onTap: () async {
                Navigator.pop(ctx);
                await _convertToSale(fullEst);
              },
            ),
          if (fullEst.status == 'pending')
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancel', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await _service.updateStatus(fullEst.id!, 'cancelled');
                _loadEstimations();
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(ctx);
              await _service.deleteEstimation(fullEst.id!);
              _loadEstimations();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _convertToSale(EstimationModel est) async {
    String method = 'cash';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convert to Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: \u20B9${est.grandTotal.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
              ],
              onChanged: (v) { if (v != null) method = v; },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Convert', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.convertToSale(est, method, est.grandTotal);
      _loadEstimations();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Converted to sale!'), backgroundColor: Colors.green));
    }
  }
}

class EstimationFormScreen extends StatefulWidget {
  const EstimationFormScreen({super.key});

  @override
  State<EstimationFormScreen> createState() => _EstimationFormScreenState();
}

class _EstimationFormScreenState extends State<EstimationFormScreen> {
  final EstimationService _estService = EstimationService();
  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();

  List<ProductModel> _products = [];
  List<CartItemModel> _cart = [];
  CustomerModel? _selectedCustomer;
  double _discount = 0.0;
  final _searchController = TextEditingController();
  List<ProductModel> _filtered = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(() {
      final q = _searchController.text.toLowerCase();
      setState(() { _filtered = q.isEmpty ? _products : _products.where((p) => p.name.toLowerCase().contains(q)).toList(); });
    });
  }

  Future<void> _loadProducts() async {
    final products = await _productService.getAllProducts();
    if (mounted) setState(() { _products = products; _filtered = products; });
  }

  void _addToCart(ProductModel p) {
    final idx = _cart.indexWhere((ci) => ci.product.id == p.id);
    setState(() {
      if (idx >= 0) { _cart[idx].quantity++; }
      else { _cart.add(CartItemModel(product: p)); }
    });
  }

  double get _subtotal => _cart.fold(0, (s, i) => s + i.subtotal);
  double get _tax => _cart.fold(0, (s, i) => s + i.taxAmount);
  double get _total => _subtotal + _tax - _discount;

  Future<void> _saveEstimation() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one product'), backgroundColor: Colors.orange));
      return;
    }
    setState(() { _isLoading = true; });
    final user = await _authService.getCurrentUser();
    final items = _cart.map((ci) => EstimationItemModel(
      productId: ci.product.id!,
      productName: ci.product.name,
      price: ci.product.sellingPrice,
      quantity: ci.quantity,
      taxPercent: ci.product.taxPercent,
      total: ci.total,
    )).toList();
    final estimation = EstimationModel(
      estimationNumber: _estService.generateEstimationNumber(),
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.name,
      subtotal: _subtotal,
      taxAmount: _tax,
      discountAmount: _discount,
      grandTotal: _total,
      createdAt: DateTime.now().toIso8601String(),
      userId: user?.id,
      items: items,
    );
    await _estService.insertEstimation(estimation);
    if (mounted) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estimation saved!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Estimation'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEstimation,
            child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(hintText: 'Search products...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.9),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final p = _filtered[i];
                      return InkWell(
                        onTap: () => _addToCart(p),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2, size: 28, color: Colors.indigo),
                              Text(p.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              Text('\u20B9${p.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          SizedBox(
            width: 280,
            child: Column(
              children: [
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text('No items added'))
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (_, i) {
                            final item = _cart[i];
                            return ListTile(
                              dense: true,
                              title: Text(item.product.name, style: const TextStyle(fontSize: 12)),
                              subtitle: Text('\u20B9${item.product.sellingPrice.toStringAsFixed(2)} x ${item.quantity}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('\u20B9${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.red), onPressed: () => setState(() { _cart.removeAt(i); }), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, border: const Border(top: BorderSide(color: Colors.grey))),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal:'), Text('\u20B9${_subtotal.toStringAsFixed(2)}')]),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tax:'), Text('\u20B9${_tax.toStringAsFixed(2)}')]),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('\u20B9${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
