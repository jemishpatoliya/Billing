import 'dart:convert';

import 'package:flutter/material.dart';
import '../../Database/UserRepository.dart';
import '../../Library/UserSession.dart';
import '../../Model/InvoiceModel.dart';
import 'AddInvoice.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceList extends StatefulWidget {
  const InvoiceList({Key? key}) : super(key: key);

  @override
  State<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  final repo = UserRepository();
  List<InvoiceModel> invoices = [];
  List<InvoiceModel> filteredInvoices = [];

  final TextEditingController invoiceNoController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();

  void applyFilter() {
    setState(() {
      filteredInvoices = invoices.where((inv) {
        final invoiceMatch = invoiceNoController.text.isEmpty ||
            inv.invoiceNo.toLowerCase().contains(invoiceNoController.text.toLowerCase());
        final nameMatch = customerController.text.isEmpty ||
            inv.buyerName.toLowerCase().contains(customerController.text.toLowerCase());
        final mobileMatch = mobileController.text.isEmpty ||
            inv.mobileNo!.contains(mobileController.text) ?? false;

        return invoiceMatch && nameMatch && mobileMatch;
      }).toList();

      itemsToShow = 10;
    });
  }


  bool _isLoading = false;
  int itemsToShow = 10;

  @override
  void initState() {
    super.initState();
    loadInvoices();
    invoiceNoController.addListener(applyFilter);
    customerController.addListener(applyFilter);
    mobileController.addListener(applyFilter);

  }

  Future<void> loadInvoices() async {
    setState(() => _isLoading = true);
    await repo.init();
    final all = await repo.getAllInvoices();
    setState(() {
      invoices = all;
      filteredInvoices = all;
      itemsToShow = 10;
      _isLoading = false;
    });
  }

  Future<void> generateInvoicePDFDesktop(InvoiceModel invoice, BuildContext context) async {
    final pdf = pw.Document();

    // Decode the productDetails JSON string to List<dynamic>
    List<dynamic> items = [];
    if (invoice.productDetails.isNotEmpty) {
      try {
        items = jsonDecode(invoice.productDetails);
      } catch (e) {
        // Handle JSON parse error
        items = [];
      }
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('RUDRA ENTERPRISE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('199, Sneh Milan Soc, Near Diamond Hospital, Varachha Road, Surat-395006'),
              pw.Text('GSTIN: 24AHHPU2550P1ZU'),
              pw.SizedBox(height: 10),
              pw.Text('INVOICE NO: ${invoice.invoiceNo}'),
              pw.Text('DATE: ${invoice.date}'),
              pw.Text('Buyer: ${invoice.buyerName}'),
              pw.Text('GST No: ${invoice.gstinBuyer}'),
              pw.Divider(),

              // Product Table
              pw.Table.fromTextArray(
                headers: ['No', 'Product Name', 'HSN', 'Qty', 'Rate', 'Amount'],
                data: List.generate(items.length, (index) {
                  final item = items[index];

                  return [
                    '${index + 1}',
                    item['name'] ?? '',
                    item['hsn'] ?? '',
                    (item['qty'] ?? 0).toString(),
                    '₹${(item['rate'] ?? 0).toStringAsFixed(2)}',
                    '₹${((item['qty'] ?? 0) * (item['rate'] ?? 0)).toStringAsFixed(2)}',
                  ];
                }),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              pw.SizedBox(height: 10),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ₹${invoice.subtotal.toStringAsFixed(2)}'),
                    pw.Text('CGST: ₹${invoice.cgst.toStringAsFixed(2)}'),
                    pw.Text('SGST: ₹${invoice.sgst.toStringAsFixed(2)}'),
                    pw.Text('Grand Total: ₹${invoice.total.toStringAsFixed(2)}'),
                    pw.Text('(in words): ${invoice.totalInWords}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Bank Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Bank Name: ${invoice.bankName ?? 'N/A'}'),
              pw.Text('A/C No: ${invoice.accountNumber ?? 'N/A'}'),
              pw.Text('IFSC: ${invoice.ifscCode ?? 'N/A'}'),
              pw.SizedBox(height: 20),
              pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if (invoice.termsConditions != null && invoice.termsConditions!.isNotEmpty)
                pw.Text(invoice.termsConditions!),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('For, ${invoice.yourFirm}\n\n(Authorised Signatory)'),
              ),
            ],
          ),
        ),
      ),
    );

    final outputDir = await getApplicationDocumentsDirectory();
    final file = File('${outputDir.path}/Invoice_${invoice.invoiceNo}.pdf');
    await file.writeAsBytes(await pdf.save());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PDF Generated'),
        content: Text('Saved at:\n${file.path}'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.file(file.path);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open PDF')),
                );
              }
            },
            child: const Text('Open'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> downloadAllInvoicesCSV() async {
    if (invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No invoices to export.")),
      );
      return;
    }

    List<List<String>> csvData = [
      // Headers matching your table columns
      [
        'Invoice No', 'Date', 'Your Firm', 'Your Firm Address',
        'Buyer Name', 'Buyer Address', 'Place of Supply',
        'GSTIN Supplier', 'GSTIN Buyer',
        'PO Number', 'Mobile No',
        'Product Details',
        'Subtotal', 'CGST', 'SGST', 'Total GST', 'Total', 'Rounded Total', 'Total in Words',
        'Bank Name', 'Account Number', 'IFSC Code',
        'Transport', 'Terms & Conditions', 'Jurisdiction', 'Signature',
        'HSN/SAC', 'MM'
      ],

      // Data rows
      ...invoices.map((inv) => [
        inv.invoiceNo,
        inv.date,
        inv.yourFirm ?? '',
        inv.yourFirmAddress ?? '',
        inv.buyerName,
        inv.buyerAddress ?? '',
        inv.placeOfSupply ?? '',
        inv.gstinSupplier ?? '',
        inv.gstinBuyer ?? '',
        inv.poNumber ?? '',
        inv.mobileNo ?? '',
        inv.productDetails ?? '',
        inv.subtotal?.toStringAsFixed(2) ?? '',
        inv.cgst?.toStringAsFixed(2) ?? '',
        inv.sgst?.toStringAsFixed(2) ?? '',
        inv.totalGst?.toStringAsFixed(2) ?? '',
        inv.total?.toStringAsFixed(2) ?? '',
        inv.roundedTotal?.toStringAsFixed(2) ?? '',
        inv.totalInWords ?? '',
        inv.bankName ?? '',
        inv.accountNumber ?? '',
        inv.ifscCode ?? '',
        inv.transport ?? '',
        inv.termsConditions ?? '',
        inv.jurisdiction ?? '',
        inv.signature ?? '',
        inv.hsnSac ?? '',
        inv.mm ?? '',
      ]),
    ];

    String csv = const ListToCsvConverter().convert(csvData);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/All_Invoices.csv');
    await file.writeAsString(csv);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('CSV Exported'),
        content: Text('All invoices saved to:\n${file.path}'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.file(file.path);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open CSV file')),
                );
              }
            },
            child: Text('Open'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedInvoices = filteredInvoices.take(itemsToShow).toList();

    bool canShowMore = itemsToShow < filteredInvoices.length;

    return Scaffold(
      appBar: AppBar(title: const Text("All Invoices")),
      body: RefreshIndicator(
        onRefresh: loadInvoices,
        child: Padding(
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
                      const Text("Search", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
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
                          Expanded(
                            child: TextField(
                              controller: customerController,
                              decoration: const InputDecoration(
                                labelText: "Buyer Name",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: mobileController,
                              decoration: const InputDecoration(
                                labelText: "Mobile No",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: applyFilter,
                            child: const Text("Search"),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              invoiceNoController.clear();
                              customerController.clear();
                              mobileController.clear();
                              applyFilter();
                            },
                            child: const Text("Reset"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text("Download Excel"),
                    onPressed: downloadAllInvoicesCSV,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : displayedInvoices.isEmpty
                    ? const Center(child: Text('No invoices found'))
                    : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Invoice No")),
                      DataColumn(label: Text("Buyer Name")),
                      DataColumn(label: Text("Total")),
                      DataColumn(label: Text("Date")),
                      DataColumn(label: Text("GST No")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: displayedInvoices.map((invoice) {
                      return DataRow(
                        cells: [
                          DataCell(Text(invoice.invoiceNo)),
                          DataCell(Text(invoice.buyerName)),
                          DataCell(Text("₹${invoice.total.toStringAsFixed(2)}")),
                          DataCell(Text(invoice.date)),
                          DataCell(Text(invoice.gstinBuyer)),
                          DataCell(Row(
                            children: [
                              Visibility(
                                visible: UserSession.canEdit('Invoice') ,
                                child: IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: "Edit",
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddInvoice(invoiceToEdit: invoice),
                                      ),
                                    );
                                    if (result == true) loadInvoices();
                                  },
                                ),
                              ),
                              Visibility(
                                visible: UserSession.canEdit('Invoice'),
                                child: IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  tooltip: "Delete",
                                  onPressed: () async {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("Delete Invoice"),
                                        content: const Text("Are you sure you want to delete this invoice?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text("Delete"),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await repo.deleteInvoice(invoice.id!);
                                      loadInvoices();
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.picture_as_pdf, size: 20),
                                tooltip: "Generate PDF",
                                onPressed: () {
                                  generateInvoicePDFDesktop(invoice,context); // you’ll define this method
                                },
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              if (canShowMore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        itemsToShow = (itemsToShow + 10).clamp(0, filteredInvoices.length);
                      });
                    },
                    child: const Text("Show More"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
