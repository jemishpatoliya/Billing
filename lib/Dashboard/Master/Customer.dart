import 'package:flutter/material.dart';
import '../../Database/UserRepository.dart';
import 'package:intl/intl.dart';

class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController poCtrl = TextEditingController();

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return rawDate;
    }
  }

  List<Map<String, dynamic>> customers = [];

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _fetchCustomers(); // initial load
  }

  void _setupListeners() {
    nameCtrl.addListener(_fetchCustomers);
    mobileCtrl.addListener(_fetchCustomers);
    poCtrl.addListener(_fetchCustomers);
  }

  Future<void> _fetchCustomers() async {
    final result = await UserRepository().getAllCustomersFromInvoices(
      name: nameCtrl.text.trim(),
      mobile: mobileCtrl.text.trim(),
      poNumber: poCtrl.text.trim(),
    );
    setState(() {
      customers = result;
    });
  }

  Widget _buildSearchFields() {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile No',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: poCtrl,
                decoration: const InputDecoration(
                  labelText: 'PO Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                nameCtrl.clear();
                mobileCtrl.clear();
                poCtrl.clear();
                _fetchCustomers();  // refresh the list with cleared filters
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerTable() {
    return customers.isEmpty
        ? const Center(child: Text("No customers found."))
        : SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Address')),
          DataColumn(label: Text('GSTIN')),
          DataColumn(label: Text('Mobile')),
          DataColumn(label: Text('PO Number')),
          DataColumn(label: Text('Invoice No')),
          DataColumn(label: Text('Total Amount')),
          DataColumn(label: Text('Total Paid')),
          DataColumn(label: Text('Total Unpaid')),
          DataColumn(label: Text('Current Date')),
        ],
        rows: customers.map((customer) {
          return DataRow(cells: [
            DataCell(Text(customer['buyer_name'] ?? '-')),
            DataCell(Text(customer['buyer_address'] ?? '-')),
            DataCell(Text(customer['gstin_buyer'] ?? '-')),
            DataCell(Text(customer['mobile_no'] ?? '-')),
            DataCell(Text(customer['po_number'] ?? '-')),
            DataCell(Text(customer['invoice_no'] ?? '-')),
            DataCell(Text('₹ ${customer['total_amount']?.toStringAsFixed(2) ?? '0.00'}')),
            DataCell(Text('₹ ${customer['total_paid']?.toStringAsFixed(2) ?? '0.00'}')),
            DataCell(Text('₹ ${customer['total_unpaid']?.toStringAsFixed(2) ?? '0.00'}')),
            DataCell(Text(formatDate(customer['invoice_date']))),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    mobileCtrl.dispose();
    poCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer List')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchFields(),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildCustomerTable(),
            ),
          ),
        ],
      ),
    );
  }
}
