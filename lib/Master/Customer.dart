import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Database/UserRepository.dart';
import '../../Model/InvoiceModel.dart';

class Customeras extends StatefulWidget {
  const Customeras({super.key});

  @override
  State<Customeras> createState() => _CustomerasState();
}

class _CustomerasState extends State<Customeras> {
  final repo = UserRepository();
  List<InvoiceModel> allInvoices = [];
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> displayedCustomers = [];

  bool _isLoading = true;

  final nameController = TextEditingController();
  final mobileController = TextEditingController();

  int itemsPerPage = 10;
  int currentMaxIndex = 10;

  @override
  void initState() {
    super.initState();
    // loadData();
    nameController.addListener(filterCustomers);
    mobileController.addListener(filterCustomers);
  }

  // Future<void> loadData() async {
  //   setState(() => _isLoading = true);
  //   await repo.init();
  //   allInvoices = await repo.getAllInvoices();
  //
  //   final grouped = <String, List<InvoiceModel>>{};
  //   for (var invoice in allInvoices) {
  //     final key = invoice.customerMobile;
  //     grouped.putIfAbsent(key, () => []).add(invoice);
  //   }
  //
  //   customers = grouped.entries.map((entry) {
  //     final invoices = entry.value;
  //     final first = invoices.first;
  //
  //     final totalAmount = invoices.fold<double>(0, (sum, inv) => sum + (inv.total ?? 0));
  //     final totalPaid = invoices.fold<double>(0, (sum, inv) => sum + (inv.paidAmount ?? 0));
  //     final totalUnpaid = invoices.fold<double>(0, (sum, inv) => sum + (inv.unpaidAmount ?? 0));
  //
  //     return {
  //       "name": first.customerName,
  //       "firm": first.customerFirm,
  //       "mobile": first.customerMobile,
  //       "address": first.customerAddress,
  //       "count": invoices.length,
  //       "total": totalAmount,
  //       "paid": totalPaid,
  //       "unpaid": totalUnpaid,
  //     };
  //   }).toList();
  //
  //   filterCustomers();
  // }

  void filterCustomers() {
    final name = nameController.text.toLowerCase();
    final mobile = mobileController.text.toLowerCase();

    final filtered = customers.where((c) {
      return (name.isEmpty || c['name'].toLowerCase().contains(name)) &&
          (mobile.isEmpty || c['mobile'].toLowerCase().contains(mobile));
    }).toList();

    setState(() {
      // Reset pagination on filter
      currentMaxIndex = itemsPerPage;
      displayedCustomers = filtered.take(currentMaxIndex).toList();
      _isLoading = false;
    });
  }

  void resetFilters() {
    nameController.clear();
    mobileController.clear();
    filterCustomers();
  }

  void showMore() {
    setState(() {
      currentMaxIndex += itemsPerPage;
      if (currentMaxIndex > customers.length) {
        currentMaxIndex = customers.length;
      }
      final name = nameController.text.toLowerCase();
      final mobile = mobileController.text.toLowerCase();

      final filtered = customers.where((c) {
        return (name.isEmpty || c['name'].toLowerCase().contains(name)) &&
            (mobile.isEmpty || c['mobile'].toLowerCase().contains(mobile));
      }).toList();

      displayedCustomers = filtered.take(currentMaxIndex).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canShowMore = displayedCustomers.length < customers.where((c) {
      final name = nameController.text.toLowerCase();
      final mobile = mobileController.text.toLowerCase();
      return (name.isEmpty || c['name'].toLowerCase().contains(name)) &&
          (mobile.isEmpty || c['mobile'].toLowerCase().contains(mobile));
    }).length;

    return Scaffold(
      appBar: AppBar(title: const Text("Customer List")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Search Customers", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: "Customer Name", border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: mobileController,
                            decoration: const InputDecoration(labelText: "Mobile No", border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(onPressed: filterCustomers, child: const Text("Search")),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: resetFilters, style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text("Reset")),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedCustomers.isEmpty
                  ? const Center(child: Text('No customers found'))
                  : SizedBox(
                height: double.infinity,

                child: SingleChildScrollView(
                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Firm")),
                        DataColumn(label: Text("Mobile")),
                        DataColumn(label: Text("Address")),
                        DataColumn(label: Text("Invoices")),
                        DataColumn(label: Text("Total ₹")),
                        DataColumn(label: Text("Paid ₹")),
                        DataColumn(label: Text("Unpaid ₹")),
                      ],
                      rows: displayedCustomers.map((c) {
                        return DataRow(cells: [
                          DataCell(Text(c['name'])),
                          DataCell(Text(c['firm'] ?? '')),
                          DataCell(
                            GestureDetector(
                              onTap: () async {
                                final phone = c['mobile'].replaceAll(RegExp(r'\D'), '');
                                final url = Uri.parse("https://wa.me/$phone");
                                try {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open WhatsApp')),
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  Text(c['mobile'], style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.call, color: Colors.green, size: 20),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Text(c['address'] ?? '')),
                          DataCell(Text("${c['count']}")),
                          DataCell(Text("₹${(c['total'] ?? 0).toStringAsFixed(2)}")),
                          DataCell(Text("₹${(c['paid'] ?? 0).toStringAsFixed(2)}")),
                          DataCell(Text("₹${(c['unpaid'] ?? 0).toStringAsFixed(2)}")),
                        ]);
                      }).toList(),
                                        ),
                                      ),
                    ),
                  ),
            ),
            if (!_isLoading && canShowMore)
              ElevatedButton(
                onPressed: showMore,
                child: const Text("Show More"),
              ),
          ],
        ),
      ),
    );
  }
}
