import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final monochromeScheme = ColorScheme.fromSeed(
      seedColor: Colors.black,
      brightness: Brightness.light,
    ).copyWith(
      primary: Colors.black,
      onPrimary: Colors.white,
      inversePrimary: Colors.grey.shade300,
    );

    return MaterialApp(
      title: 'Lab 11 - Async Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: monochromeScheme,
        useMaterial3: true,
      ),
      home: const StoreScreen(),
    );
  }
}

class StoreService {
  Future getUser({bool simulateError = false}) async {
    await Future.delayed(const Duration(seconds: 2));
    if (simulateError) {
      throw Exception('Помилка сервера (503): не вдалося отримати профіль користувача');
    }
    return {
      'id': 'USR-1042',
      'name': 'Максим Кравчук',
      'email': 'm.kravchuk@example.com',
      'status': 'Premium клієнт',
    };
  }

  Future getProducts() async {
    await Future.delayed(const Duration(seconds: 3));
    return [
      {'title': 'Механічна клавіатура Keychron K2', 'price': 4200.0},
      {'title': 'Бездротова миша Logitech MX Master 3S', 'price': 4650.0},
      {'title': 'Монітор Dell UltraSharp 27"', 'price': 16800.0},
    ];
  }

  Future getOrders() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      {'orderId': '#ORD-881', 'date': '12.11.2026', 'total': 4200.0, 'state': 'Доставлено'},
      {'orderId': '#ORD-904', 'date': '18.11.2026', 'total': 16800.0, 'state': 'У дорозі'},
    ];
  }
}

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State createState() => _StoreScreenState();
}

class _StoreScreenState extends State {
  final StoreService _storeService = StoreService();

  bool _isLoading = false;
  String? _errorMessage;
  int? _elapsedMs;

  Map? _user;
  List _products = [];
  List _orders = [];

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future _loadStoreData({bool withError = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      final results = await Future.wait([
        _storeService.getUser(simulateError: withError),
        _storeService.getProducts(),
        _storeService.getOrders(),
      ]);

      stopwatch.stop();

      if (!mounted) return;
      setState(() {
        _user = results[0];
        _products = results[1];
        _orders = results[2];
        _elapsedMs = stopwatch.elapsedMilliseconds;
        _isLoading = false;
      });
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: const Text('Async Store (Lab 11)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : () => _loadStoreData(withError: false),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Завантажити дані'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _loadStoreData(withError: true),
                  icon: const Icon(Icons.error_outline),
                  label: const Text('Тест помилки'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Виконується паралельне завантаження через Future.wait...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Card(
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.black),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _loadStoreData(withError: false),
                  child: const Text('Спробувати знову'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      children: [
        if (_elapsedMs != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Усі 3 запити виконано конкурентно за ${(_elapsedMs! / 1000).toStringAsFixed(2)} с',
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        if (_user != null) ...[
          const Text('Профіль користувача (getUser)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text('${_user!['name']} (${_user!['id']})'),
              subtitle: Text('${_user!['email']} • ${_user!['status']}'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text('Доступні товари (getProducts)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ..._products.map(
              (item) => Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: Text(item['title']),
              trailing: Text('${item['price']} грн',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Історія замовлень (getOrders)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ..._orders.map(
              (order) => Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('Замовлення ${order['orderId']} від ${order['date']}'),
              subtitle: Text('Статус: ${order['state']}'),
              trailing: Text('${order['total']} грн',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}