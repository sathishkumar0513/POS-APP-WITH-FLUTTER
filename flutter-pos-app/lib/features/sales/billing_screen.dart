import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/product_model.dart';
import '../../core/models/cart_item_model.dart';
import '../../core/models/customer_model.dart';
import '../../core/models/sale_model.dart';
import '../../core/services/product_service.dart';
import '../../core/services/customer_service.dart';
import '../../core/services/sale_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/store_service.dart';
import '../../core/services/printer_service.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final ProductService _productService = ProductService();
  final SaleService _saleService = SaleService();
  final AuthService _authService = AuthService();
  final StoreService _storeService = StoreService();

  List<ProductModel> _products = [];
  List<ProductModel> _filtered = [];
  List<CartItemModel> _cart = [];
  CustomerModel? _selectedCustomer;
  double _discount = 0.0;
  String _paymentMethod = 'cash';
  final _searchController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await _productService.getAllProducts();
    if (mounted) setState(() { _products = products; _filtered = products; });
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? _products : _products.where((p) =>
        p.name.toLowerCase().contains(q) || (p.barcode?.contains(q) ?? false)
      ).toList();
    });
  }

  void _addToCart(ProductModel product) {
    final existing = _cart.indexWhere((ci) => ci.product.id == product.id);
    setState(() {
      if (existing >= 0) {
        _cart[existing].quantity++;
      } else {
        _cart.add(CartItemModel(product: product));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() { _cart.removeAt(index); });
  }

  void _updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _removeFromCart(index);
    } else {
      setState(() { _cart[index].quantity = quantity; });
    }
  }

  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.subtotal);
  double get _taxTotal => _cart.fold(0, (sum, item) => sum + item.taxAmount);
  double get _grandTotal => _subtotal + _taxTotal - _discount;

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty'), backgroundColor: Colors.orange));
      return;
    }
    double amountPaid = _grandTotal;
    final payResult = await _showPaymentDialog();
    if (payResult == null) return;
    amountPaid = payResult;

    setState(() { _isLoading = true; });
    try {
      final user = await _authService.getCurrentUser();
      final saleItems = _cart.map((ci) => SaleItemModel(
        productId: ci.product.id!,
        productName: ci.product.name,
        price: ci.product.sellingPrice,
        quantity: ci.quantity,
        taxPercent: ci.product.taxPercent,
        total: ci.total,
      )).toList();

      final sale = SaleModel(
        invoiceNumber: _saleService.generateInvoiceNumber(),
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
        subtotal: _subtotal,
        taxAmount: _taxTotal,
        discountAmount: _discount,
        grandTotal: _grandTotal,
        paymentMethod: _paymentMethod,
        amountPaid: amountPaid,
        changeAmount: amountPaid - _grandTotal,
        createdAt: DateTime.now().toIso8601String(),
        userId: user?.id,
        items: saleItems,
      );

      final saleId = await _saleService.insertSale(sale);
      final savedSale = sale.copyWith(id: saleId);

      if (mounted) {
        final printResult = await _showPrintDialog(savedSale);
      }

      setState(() {
        _cart.clear();
        _discount = 0;
        _discountController.text = '0';
        _selectedCustomer = null;
        _paymentMethod = 'cash';
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale completed successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<double?> _showPaymentDialog() async {
    final amountController = TextEditingController(text: _grandTotal.toStringAsFixed(2));
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Grand Total: \u20B9${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
              ],
              onChanged: (v) { if (v != null) setState(() { _paymentMethod = v; }); },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount Received', border: OutlineInputBorder(), prefixText: '\u20B9'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? _grandTotal;
              Navigator.pop(ctx, amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrintDialog(SaleModel sale) async {
    final print = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Print Receipt?'),
        content: const Text('Do you want to print the receipt?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)), child: const Text('Print', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (print == true) {
      final store = await _storeService.getStore();
      if (store != null) {
        await PrinterService.instance.printReceipt(sale, store);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildProductPanel()),
        const VerticalDivider(width: 1),
        Expanded(flex: 2, child: _buildCartPanel()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [Tab(text: 'Products'), Tab(text: 'Cart')],
            labelColor: Color(0xFF1A237E),
          ),
          Expanded(
            child: TabBarView(
              children: [_buildProductPanel(), _buildCartPanel()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products or scan barcode...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final p = _filtered[i];
              return _ProductCard(product: p, onTap: () => _addToCart(p));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCartPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            onTap: _selectCustomer,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_selectedCustomer?.name ?? 'Walk-in Customer', style: const TextStyle(fontSize: 14))),
                  if (_selectedCustomer != null) IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() { _selectedCustomer = null; })),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _cart.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey), SizedBox(height: 8), Text('Cart is empty', style: TextStyle(color: Colors.grey))]))
              : ListView.builder(
                  itemCount: _cart.length,
                  itemBuilder: (_, i) {
                    final item = _cart[i];
                    return _CartItemTile(
                      item: item,
                      onRemove: () => _removeFromCart(i),
                      onQtyChanged: (qty) => _updateQuantity(i, qty),
                    );
                  },
                ),
        ),
        _buildCartSummary(),
      ],
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text('\u20B9${_subtotal.toStringAsFixed(2)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax:'),
              Text('\u20B9${_taxTotal.toStringAsFixed(2)}'),
            ],
          ),
          Row(
            children: [
              const Text('Discount: \u20B9'),
              const SizedBox(width: 4),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _discountController,
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => setState(() { _discount = double.tryParse(v) ?? 0; }),
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('\u20B9${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A237E))),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkout,
              icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.payment),
              label: const Text('CHECKOUT'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectCustomer() async {
    final customers = await CustomerService().getAllCustomers();
    if (!mounted) return;
    final selected = await showDialog<CustomerModel>(
      context: context,
      builder: (ctx) => _CustomerSelectDialog(customers: customers),
    );
    if (selected != null) setState(() { _selectedCustomer = selected; });
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2, size: 32, color: Colors.indigo),
            const SizedBox(height: 4),
            Text(product.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('\u20B9${product.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.bold)),
            Text('Qty: ${product.stockQuantity}', style: TextStyle(fontSize: 10, color: product.stockQuantity > 0 ? Colors.grey : Colors.red)),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChanged;

  const _CartItemTile({required this.item, required this.onRemove, required this.onQtyChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('\u20B9${item.product.sellingPrice.toStringAsFixed(2)} x ${item.quantity} = \u20B9${item.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () => onQtyChanged(item.quantity - 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => onQtyChanged(item.quantity + 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: onRemove, padding: const EdgeInsets.only(left: 4), constraints: const BoxConstraints()),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerSelectDialog extends StatefulWidget {
  final List<CustomerModel> customers;
  const _CustomerSelectDialog({required this.customers});

  @override
  State<_CustomerSelectDialog> createState() => _CustomerSelectDialogState();
}

class _CustomerSelectDialogState extends State<_CustomerSelectDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty ? widget.customers : widget.customers.where((c) => c.name.toLowerCase().contains(_query.toLowerCase()) || (c.phone?.contains(_query) ?? false)).toList();
    return AlertDialog(
      title: const Text('Select Customer'),
      content: SizedBox(
        width: 320,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Search customer...', prefixIcon: Icon(Icons.search), isDense: true, border: OutlineInputBorder()),
              onChanged: (v) => setState(() { _query = v; }),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No customers'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: CircleAvatar(child: Text(filtered[i].name[0])),
                        title: Text(filtered[i].name),
                        subtitle: Text(filtered[i].phone ?? ''),
                        onTap: () => Navigator.pop(context, filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}

extension SaleModelCopyWith on SaleModel {
  SaleModel copyWith({int? id}) => SaleModel(
    id: id ?? this.id,
    invoiceNumber: invoiceNumber,
    customerId: customerId,
    customerName: customerName,
    subtotal: subtotal,
    taxAmount: taxAmount,
    discountAmount: discountAmount,
    grandTotal: grandTotal,
    paymentMethod: paymentMethod,
    amountPaid: amountPaid,
    changeAmount: changeAmount,
    createdAt: createdAt,
    userId: userId,
    items: items,
  );
}
