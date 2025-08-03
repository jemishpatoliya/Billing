import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool _isLoading = false;
  int itemsToShow = 10;
  String _sortColumn = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    loadInvoices();
    invoiceNoController.addListener(applyFilter);
    customerController.addListener(applyFilter);
    mobileController.addListener(applyFilter);
  }

  void applyFilter() {
    setState(() {
      filteredInvoices = invoices.where((inv) {
        final invoiceMatch = invoiceNoController.text.isEmpty ||
            inv.invoiceNo.toLowerCase().contains(invoiceNoController.text.toLowerCase());
        final nameMatch = customerController.text.isEmpty ||
            inv.buyerName.toLowerCase().contains(customerController.text.toLowerCase());
        final mobileMatch = mobileController.text.isEmpty ||
            (inv.mobileNo?.contains(mobileController.text) ?? false);

                return invoiceMatch && nameMatch && mobileMatch;
            }).toList();

      // Apply sorting
      _sortInvoices();
      itemsToShow = 10;
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

  void _sortInvoices() {
    filteredInvoices.sort((a, b) {
      var aValue, bValue;
      switch (_sortColumn) {
        case 'invoiceNo':
          aValue = a.invoiceNo;
          bValue = b.invoiceNo;
          break;
        case 'buyerName':
          aValue = a.buyerName;
          bValue = b.buyerName;
          break;
        case 'total':
          aValue = a.total;
          bValue = b.total;
          break;
        case 'date':
          aValue = DateFormat('dd/MM/yyyy').parse(a.date);
          bValue = DateFormat('dd/MM/yyyy').parse(b.date);
          break;
        case 'gstinBuyer':
          aValue = a.gstinBuyer;
          bValue = b.gstinBuyer;
          break;
        default:
          aValue = a.invoiceNo;
          bValue = b.invoiceNo;
      }

      if (aValue == bValue) return 0;
      if (aValue is Comparable && bValue is Comparable) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      return 0;
    });
  }

  Future<void> loadInvoices() async {
    setState(() => _isLoading = true);
    await repo.init();
    final all = await repo.getAllInvoices();
    setState(() {
      invoices = all;
      filteredInvoices = all;
      _sortInvoices();
      itemsToShow = 10;
      _isLoading = false;
    });
  }

  // ... [keep your existing generateInvoicePDFDesktop and downloadAllInvoicesCSV methods] ...

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedInvoices = filteredInvoices.take(itemsToShow).toList();
    bool canShowMore = itemsToShow < filteredInvoices.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice Management"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadInvoices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadInvoices,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Search Invoices",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: invoiceNoController,
                              decoration: InputDecoration(
                                labelText: "Invoice No",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.numbers),
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: customerController,
                              decoration: InputDecoration(
                                labelText: "Buyer Name",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: mobileController,
                              decoration: InputDecoration(
                                labelText: "Mobile No",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: Icon(Icons.clear, size: 18),
                            label: Text("Reset"),
                            onPressed: () {
                              invoiceNoController.clear();
                              customerController.clear();
                              mobileController.clear();
                              applyFilter();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: Icon(Icons.search, size: 18),
                            label: Text("Search"),
                            onPressed: applyFilter,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Invoice Records",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.download, size: 18),
                    label: Text("Export to Excel"),
                    onPressed: downloadAllInvoicesCSV,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : filteredInvoices.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        "No invoices found",
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                      if (invoiceNoController.text.isNotEmpty ||
                          customerController.text.isNotEmpty ||
                          mobileController.text.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            invoiceNoController.clear();
                            customerController.clear();
                            mobileController.clear();
                            applyFilter();
                          },
                          child: Text("Clear search filters"),
                        ),
                    ],
                  ),
                )
                    : Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.resolveWith<Color>(
                              (states) => theme.colorScheme.primary.withOpacity(0.05),
                        ),
                        sortColumnIndex: _sortColumn == 'invoiceNo'
                            ? 0
                            : _sortColumn == 'buyerName'
                            ? 1
                            : _sortColumn == 'total'
                            ? 2
                            : _sortColumn == 'date'
                            ? 3
                            : 4,
                        sortAscending: _sortAscending,
                        columns: [
                          DataColumn(
                            label: Text("Invoice No"),
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortColumn = 'invoiceNo';
                                _sortAscending = ascending;
                                _sortInvoices();
                              });
                            },
                          ),
                          DataColumn(
                            label: Text("Buyer"),
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortColumn = 'buyerName';
                                _sortAscending = ascending;
                                _sortInvoices();
                              });
                            },
                          ),
                          DataColumn(
                            label: Text("Amount"),
                            numeric: true,
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortColumn = 'total';
                                _sortAscending = ascending;
                                _sortInvoices();
                              });
                            },
                          ),
                          DataColumn(
                            label: Text("Date"),
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortColumn = 'date';
                                _sortAscending = ascending;
                                _sortInvoices();
                              });
                            },
                          ),
                          DataColumn(
                            label: Text("GST No"),
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortColumn = 'gstinBuyer';
                                _sortAscending = ascending;
                                _sortInvoices();
                              });
                            },
                          ),
                          DataColumn(
                            label: Text("Actions"),
                            numeric: true,
                          ),
                        ],
                        rows: displayedInvoices.map((invoice) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  invoice.invoiceNo,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              DataCell(
                                Tooltip(
                                  message: invoice.buyerAddress ?? '',
                                  child: Text(
                                    invoice.buyerName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  "₹${NumberFormat("#,##0.00").format(invoice.total)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                              DataCell(Text(invoice.date)),
                              DataCell(
                                Text(
                                  invoice.gstinBuyer,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              DataCell(
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 150),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.picture_as_pdf, size: 20),
                                        tooltip: "Generate PDF",
                                        onPressed: () {
                                          generateInvoicePDFDesktop(invoice, context);
                                        },
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      if (UserSession.canEdit('Invoice'))
                                        IconButton(
                                          icon: Icon(Icons.edit, size: 20, color: Colors.blue),
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
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if (UserSession.canEdit('Invoice'))
                                        IconButton(
                                          icon: Icon(Icons.delete, size: 20, color: Colors.red),
                                          tooltip: "Delete",
                                          onPressed: () async {
                                            final confirm = await showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: Text("Confirm Deletion"),
                                                content: Text("Are you sure you want to delete invoice ${invoice.invoiceNo}?"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: Text(
                                                      "Delete",
                                                      style: TextStyle(color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await repo.deleteInvoice(invoice.id!);
                                              loadInvoices();
                                            }
                                          },
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
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
              if (canShowMore)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        itemsToShow = (itemsToShow + 10).clamp(0, filteredInvoices.length);
                      });
                    },
                    child: Text("Load More (${filteredInvoices.length - itemsToShow} remaining)"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Visibility(
        visible: UserSession.canCreate('Invoice'),
        child: FloatingActionButton.extended(
          icon: Icon(Icons.add),
          label: Text("New Invoice"),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddInvoice()),
            );
            if (result == true) loadInvoices();
          },
          elevation: 4,
        ),
      ),
    );
  }
}