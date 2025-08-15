import 'package:flutter/material.dart';
import '../../Database/UserRepository.dart';
import '../../Library/backup.dart';

class ProductList extends StatefulWidget {
  const ProductList({Key? key}) : super(key: key);

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  final TextEditingController searchController = TextEditingController();
  final repo = UserRepository();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
    searchController.addListener(onSearchTextChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onSearchTextChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = allProducts.where((prod) {
        final name = (prod['product'] ?? '').toString().toLowerCase();
        final desc = (prod['desc'] ?? '').toString().toLowerCase();
        final hsnSac = (prod['hsnSac'] ?? '').toString().toLowerCase();
        final invoiceNo = (prod['invoice_no'] ?? '').toString().toLowerCase();
        return name.contains(query) ||
            desc.contains(query) ||
            hsnSac.contains(query) ||
            invoiceNo.contains(query);
      }).toList();
    });
  }

  Future<void> loadProducts() async {
    setState(() => isLoading = true);
    final products = await repo.getAllProducts();
    setState(() {
      allProducts = products;
      filteredProducts = products;
      isLoading = false;
    });
  }

  Widget buildProductItem(Map<String, dynamic> product, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Add onTap functionality if needed
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product['product'] ?? 'Unknown Product',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              if ((product['desc'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    product['desc'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Product details row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailItem('Price', '₹${_formatDouble(product['price'])}', Icons.attach_money),
                  _buildDetailItem('Quantity', '${product['qty'] ?? '0'}', Icons.inventory_2),
                  if ((product['hsnSac'] ?? '').toString().isNotEmpty)
                    _buildDetailItem('HSN/SAC', product['hsnSac'], Icons.code),
                ],
              ),

              const Divider(height: 24, thickness: 1),

              // Invoice information
              _buildInvoiceSection(product),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceSection(Map<String, dynamic> product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      const Text(
      'Invoice Details',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Colors.blueGrey,
      ),
    ),
    const SizedBox(height: 8),
    _buildInvoiceRow('Invoice No:', product['invoice_no'] ?? '-'),
    _buildInvoiceRow('Buyer:', product['buyer_name'] ?? '-'),
    _buildInvoiceRow('Mobile:', product['mobile_no'] ?? '-'),
    _buildInvoiceRow('Date:', product['invoice_date'] ?? '-'),

    const SizedBox(height: 12),

    // Amount summary
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    _buildAmountChip('Subtotal', _formatDouble(product['subtotal_invoice'])),
    _buildAmountChip('Total', _formatDouble(product['total_invoice'])),
    ],
    ),

    const SizedBox(height: 8),

    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    _buildAmountChip('Paid', _formatDouble(product['paid_amount']),
    ),
    ],
    )]);
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountChip(String label, String amount, [Color? color]) {
    return Chip(
      backgroundColor: color?.withOpacity(0.1) ?? Colors.grey.shade100,
      label: Text(
        '$label: ₹$amount',
        style: TextStyle(
          color: color ?? Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: color?.withOpacity(0.3) ?? Colors.grey.shade300,
        ),
      ),
    );
  }

  String _formatDouble(dynamic value) {
    if (value == null) return '0.00';
    if (value is double) return value.toStringAsFixed(2);
    if (value is int) return value.toString();
    try {
      return double.parse(value.toString()).toStringAsFixed(2);
    } catch (_) {
      return '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Inventory'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.backup),
            label: Text('Backup Database'),
            onPressed: () => backupDatabaseDesktop(context),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    searchController.clear();
                    onSearchTextChanged();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            )
                : filteredProducts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    searchController.text.isEmpty
                        ? 'No products available'
                        : 'No products found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: () {
                          searchController.clear();
                          onSearchTextChanged();
                        },
                        child: const Text(
                          'Clear search',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) =>
                  buildProductItem(filteredProducts[index], index),
            ),
          ),
        ],
      ),
    );
  }
}