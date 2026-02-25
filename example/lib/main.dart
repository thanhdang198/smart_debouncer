import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_debouncer/smart_debouncer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartDebouncer Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const AddressSearchPage(),
    );
  }
}

/// Example page demonstrating SmartDebouncer for address autocomplete.
class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({super.key});

  @override
  State<AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  final SmartDebouncer _debouncer = SmartDebouncer();
  final TextEditingController _controller = TextEditingController();

  List<String> _results = [];
  bool _isLoading = false;
  int _apiCallCount = 0;

  @override
  void dispose() {
    // IMPORTANT: Always dispose the debouncer to prevent memory leaks
    _debouncer.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Simulates an API call for address autocomplete.
  Future<List<String>> _mockSearchApi(String query) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock address results
    final addresses = [
      '123 Nguyễn Huệ, Quận 1, TP.HCM',
      '456 Lê Lợi, Quận 1, TP.HCM',
      '789 Trần Hưng Đạo, Quận 5, TP.HCM',
      '101 Điện Biên Phủ, Quận Bình Thạnh, TP.HCM',
      '202 Võ Văn Tần, Quận 3, TP.HCM',
      '303 Hai Bà Trưng, Quận 1, TP.HCM',
      '404 Nguyễn Thị Minh Khai, Quận 3, TP.HCM',
      '505 Cách Mạng Tháng 8, Quận 10, TP.HCM',
    ];

    return addresses
        .where((addr) => addr.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _debouncer.run(() async {
      _apiCallCount++;
      final results = await _mockSearchApi(query);

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Address Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search input
            TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm địa chỉ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            // Debug info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'API calls: $_apiCallCount  |  '
                'Current delay: ${_debouncer.currentDelay}ms  |  '
                'EMA: ${_debouncer.currentEma.toStringAsFixed(1)}ms',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

            const SizedBox(height: 16),

            // Results
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _controller.text.isEmpty
                            ? 'Nhập địa chỉ để tìm kiếm'
                            : 'Không tìm thấy kết quả',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(_results[index]),
                          onTap: () {
                            _controller.text = _results[index];
                            setState(() => _results = []);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
