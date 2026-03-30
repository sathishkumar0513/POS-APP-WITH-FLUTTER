import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sale_service.dart';
import '../../core/services/store_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/store_model.dart';
import '../auth/login_screen.dart';
import '../products/products_screen.dart';
import '../customers/customers_screen.dart';
import '../sales/billing_screen.dart';
import '../estimations/estimations_screen.dart';
import '../reports/reports_screen.dart';
import '../users/users_screen.dart';
import '../printer/printer_settings_screen.dart';
import '../store/store_setup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _currentUser;
  StoreModel? _store;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = AuthService();
    final saleService = SaleService();
    final storeService = StoreService();
    final user = await authService.getCurrentUser();
    final store = await storeService.getStore();
    final stats = await saleService.getDashboardStats();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _store = store;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().logout();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUser?.role == 'admin';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_store?.name ?? 'FlutterPOS'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(icon: const Icon(Icons.store), onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreSetupScreen()));
              _loadData();
            }),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(),
                    const SizedBox(height: 16),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildQuickActions(isAdmin),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${_currentUser?.name ?? ''}!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_currentUser?.role.toUpperCase() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Text(
            _formatDate(DateTime.now()),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: "Today's Sales",
            value: _formatCurrency(_stats['today_total'] ?? 0.0),
            subtitle: '${_stats['today_count'] ?? 0} orders',
            icon: Icons.today,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Total Sales',
            value: _formatCurrency(_stats['total_amount'] ?? 0.0),
            subtitle: '${_stats['total_count'] ?? 0} orders',
            icon: Icons.bar_chart,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(bool isAdmin) {
    final actions = [
      _ActionItem('New Sale', Icons.point_of_sale, Colors.indigo, () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingScreen()));
        _loadData();
      }),
      _ActionItem('Products', Icons.inventory_2, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()))),
      _ActionItem('Customers', Icons.people, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen()))),
      _ActionItem('Estimation', Icons.request_quote, Colors.purple, () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const EstimationsScreen()));
        _loadData();
      }),
      if (isAdmin) _ActionItem('Reports', Icons.assessment, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
      if (isAdmin) _ActionItem('Users', Icons.manage_accounts, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()))),
      _ActionItem('Printer', Icons.print, Colors.brown, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()))),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) => _buildActionCard(actions[i]),
        );
      },
    );
  }

  Widget _buildActionCard(_ActionItem action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: action.color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(action.icon, color: action.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(action.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '\u20B9${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionItem(this.label, this.icon, this.color, this.onTap);
}
