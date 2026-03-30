import 'package:flutter/material.dart';
import '../../core/models/sale_model.dart';
import '../../core/services/sale_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SaleService _saleService = SaleService();
  List<SaleModel> _todaySales = [];
  List<SaleModel> _weeklySales = [];
  List<Map<String, dynamic>> _topProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final todaySales = await _saleService.getSalesForToday();
    final weeklySales = await _saleService.getSalesByDateRange(weekStart, today);
    final topProducts = await _saleService.getTopSellingProducts();
    if (mounted) {
      setState(() {
        _todaySales = todaySales;
        _weeklySales = weeklySales;
        _topProducts = topProducts;
        _isLoading = false;
      });
    }
  }

  double _totalOf(List<SaleModel> sales) => sales.fold(0, (sum, s) => sum + s.grandTotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'This Week'),
            Tab(text: 'Top Products'),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(_todaySales),
                _buildSalesTab(_weeklySales),
                _buildTopProductsTab(),
              ],
            ),
    );
  }

  Widget _buildSalesTab(List<SaleModel> sales) {
    final total = _totalOf(sales);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.indigo.shade50,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Orders', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('${sales.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Revenue', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('\u20B9${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: sales.isEmpty
              ? const Center(child: Text('No sales found'))
              : ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (_, i) {
                    final s = sales[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.receipt, color: Colors.white, size: 18)),
                        title: Text(s.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('${s.customerName ?? 'Walk-in'} | ${s.paymentMethod.toUpperCase()} | ${s.createdAt.substring(0, 16)}', style: const TextStyle(fontSize: 11)),
                        trailing: Text('\u20B9${s.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTopProductsTab() {
    return _topProducts.isEmpty
        ? const Center(child: Text('No sales data'))
        : ListView.builder(
            itemCount: _topProducts.length,
            itemBuilder: (_, i) {
              final p = _topProducts[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: i < 3 ? Colors.amber : Colors.grey.shade200,
                  child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: i < 3 ? Colors.white : Colors.grey.shade600)),
                ),
                title: Text(p['product_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Qty Sold: ${p['total_qty']}'),
                trailing: Text('\u20B9${(p['total_amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              );
            },
          );
  }
}
