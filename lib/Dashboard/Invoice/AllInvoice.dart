import 'package:flutter/material.dart';
import '../../Database/UserRepository.dart';
import '../../Model/InvoiceModel.dart';
import 'package:url_launcher/url_launcher.dart';

import 'AddInvoice.dart';

class InvoiceList extends StatefulWidget {
  const InvoiceList({Key? key}) : super(key: key);

  @override
  State<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  final repo = UserRepository();
  List<InvoiceModel> invoices = [];

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController invoiceNoController = TextEditingController();

  bool _isLoading = false;
  int itemsToShow = 10; // Pagination count

  @override
  void initState() {
    super.initState();
    loadInvoices();
    customerNameController.addListener(filterInvoices);
    invoiceNoController.addListener(filterInvoices);
  }

  Future<void> loadInvoices() async {
    setState(() => _isLoading = true);
    await repo.init();
    final all = await repo.getAllInvoices();
    setState(() {
      invoices = all;
      _isLoading = false;
      itemsToShow = 10; // Reset itemsToShow when loading new data
    });
  }

  void filterInvoices() async {
    setState(() => _isLoading = true);
    await repo.init();
    final allInvoices = await repo.getAllInvoices();

    setState(() {
      invoices = allInvoices.where((invoice) {
        final nameMatch = customerNameController.text.isEmpty ||
            invoice.customerName.toLowerCase().contains(customerNameController.text.toLowerCase());

        final invoiceNoMatch = invoiceNoController.text.isEmpty ||
            invoice.invoiceNo.toLowerCase().contains(invoiceNoController.text.toLowerCase());

        return nameMatch && invoiceNoMatch;
      }).toList();
      _isLoading = false;
      itemsToShow = 10; // Reset pagination on filter
    });
  }

  void resetFilters() {
    customerNameController.clear();
    invoiceNoController.clear();
    loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid = invoices.fold<double>(0, (sum, i) => sum + i.paidAmount);
    final totalUnpaid = invoices.fold<double>(0, (sum, i) => sum + i.unpaidAmount);

    final displayedInvoices = invoices.take(itemsToShow).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("All Invoices")),
      body: RefreshIndicator(
        onRefresh: loadInvoices,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Filters Card
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Search", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customerNameController,
                              decoration: const InputDecoration(
                                labelText: "Customer Name",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: invoiceNoController,
                              decoration: const InputDecoration(
                                labelText: "Invoice No",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: filterInvoices,
                            child: const Text("Search"),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: resetFilters,
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("Reset"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Invoice Data Table with Pagination
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : displayedInvoices.isEmpty
                    ? const Center(child: Text('No invoices found'))
                    : SizedBox(
                  height: double.infinity,
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                        columns: const [
                          DataColumn(label: Text("Invoice No")),
                          DataColumn(label: Text("Customer")),
                          DataColumn(label: Text("Total")),
                          DataColumn(label: Text("Paid/Unpaid")),
                          DataColumn(label: Text("Date")),
                          DataColumn(label: Text("GST No")),
                          DataColumn(label: Text("Action")),
                        ],
                        rows: displayedInvoices.map((invoice) {
                          return DataRow(
                            cells: [
                              DataCell(Text(invoice.invoiceNo)),
                              DataCell(
                                Row(
                                  children: [
                                    Expanded(child: Text(invoice.customerName)),
                                    GestureDetector(
                                      onTap: () async {
                                        final phone = invoice.customerMobile.replaceAll(RegExp(r'\D'), '');
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
                                          Text(
                                            invoice.customerMobile,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.call,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text("₹${invoice.total.toStringAsFixed(2)}")),
                              DataCell(Text(
                                  "₹${invoice.paidAmount.toStringAsFixed(2)} / ₹${invoice.unpaidAmount.toStringAsFixed(2)}")),
                              DataCell(Text(invoice.date)),
                              DataCell(Text(invoice.gstNumber ?? '')),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddInvoice(invoiceToEdit: invoice),
                                      ),
                                    );
                                    if (result == true) {
                                      loadInvoices(); // Reload list after edit/save
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                                          ),
                                        ),
                      ),
                    ),
              ),

              // Show More button for pagination
              if (invoices.length > itemsToShow)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        itemsToShow = (itemsToShow + 10).clamp(0, invoices.length);
                      });
                    },
                    child: const Text("Show More"),
                  ),
                ),

              const SizedBox(height: 12),

              // Summary of totals
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Paid: ₹${totalPaid.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Total Unpaid: ₹${totalUnpaid.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
