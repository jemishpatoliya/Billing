import 'dart:io';
  import 'package:url_launcher/url_launcher.dart';
  import 'package:Invoxel/Database/UserRepository.dart';
  import 'package:flutter/material.dart';import '../../Model/ProductModel.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import '../../Model/PurchaseModel.dart';
  import 'dart:convert';
  import 'package:pdf/widgets.dart' as pw;
  import 'package:path_provider/path_provider.dart';
  import 'package:flutter/services.dart' show rootBundle;

  class PurchaseList extends StatefulWidget {
    const PurchaseList({Key? key}) : super(key: key);

    @override
    State<PurchaseList> createState() => _PurchaseListState();
  }

  class _PurchaseListState extends State<PurchaseList> {
    final repo = UserRepository();
    List<PurchaseModel> allPurchases = [];
    List<PurchaseModel> filteredPurchases = [];

    final TextEditingController searchCtrl = TextEditingController();

    @override
    void initState() {
      super.initState();
      fetchPurchases();
      searchCtrl.addListener(_applySearch);
    }

    Future<void> fetchPurchases() async {
      final list = await repo.getAllPurchasesForUI(); // Use UI method for display order
      setState(() {
        allPurchases = list;
        filteredPurchases = list;
      });
    }

    void _applySearch() {
      final query = searchCtrl.text.toLowerCase();
      setState(() {
        filteredPurchases = allPurchases.where((p) {
          final products = p.products ?? [];
          return (p.companyName ?? "").toLowerCase().contains(query) ||
              (p.invoiceNo ?? "").toLowerCase().contains(query) ||
              products.any((prod) =>
                  (prod.productName ?? "").toLowerCase().contains(query));
        }).toList();
      });
    }

    @override
    void dispose() {
      searchCtrl.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Purchases"),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            // Show confirmation dialog
            bool? confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Reset All SKUs"),
                content: const Text(
                  "This will reset all SKU numbers across all purchases starting from SK00000001. "
                  "This action cannot be undone. Are you sure?"
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Reset All SKUs"),
                  ),
                ],
              ),
            );
            
            if (confirm == true) {
              try {
                await GlobalSKU.resetCounter();
                await fetchPurchases();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("All SKU numbers have been reset successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error resetting SKUs: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          icon: const Icon(Icons.refresh),
          label: const Text("Reset All SKUs"),
          backgroundColor: Colors.red,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: "Search by Company, Invoice, Product...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredPurchases.isEmpty
                  ? const Center(child: Text("No Purchases Found"))
                  : ListView.builder(
                itemCount: filteredPurchases.length,
                itemBuilder: (context, index) {
                  final purchase = filteredPurchases[index];
                  final products = purchase.products ?? [];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        "${purchase.companyName ?? "Unknown"} "
                            "(Invoice: ${purchase.invoiceNo ?? "-"})",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Address: ${purchase.companyAddress ?? "-"}"),
                          Text("GSTIN: ${purchase.companyGstin ?? "-"}"),
                          const SizedBox(height: 4),
                          Text("Products: ${products.length}"),
                          Text("Final Amount: ₹${purchase.finalAmount ?? 0}"),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PurchaseDetailScreen(
                              purchase: purchase,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  class GlobalSKU {
    static int counter = 1;

    static Future<void> loadCounter() async {
      final prefs = await SharedPreferences.getInstance();
      counter = prefs.getInt('last_sku_counter') ?? 1;
    }

    static Future<void> saveCounter() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_sku_counter', counter);
    }

    static Future<void> resetCounter() async {
      counter = 1;
      await saveCounter();
    }
  }

  class PurchaseDetailScreen extends StatefulWidget {
    final PurchaseModel purchase;
    const PurchaseDetailScreen({Key? key, required this.purchase}) : super(key: key);

    @override
    State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
  }

  class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
    List<Map<String, dynamic>> skuItems = [];
    bool isLoading = true;

    @override
    void initState() {
      super.initState();
      _ensureSKUs();
    }

    Future<void> _ensureSKUs() async {
      setState(() {
        isLoading = true;
      });

      try {
        // Load the current global counter
        await GlobalSKU.loadCounter();
        
        if (widget.purchase.skuItems != null && widget.purchase.skuItems!.isNotEmpty) {
          // If SKUs already exist, use them
          skuItems = widget.purchase.skuItems!;
        } else {
          // Generate new SKUs for this purchase
          await _generateNewSKUs();
        }
      } catch (e) {
        print('Error ensuring SKUs: $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }

    Future<void> _generateNewSKUs() async {
      List<Map<String, dynamic>> tempList = [];
      
      // Get the next available SKU number for this specific purchase
      final repo = UserRepository();
      int currentCounter = await repo.getNextSKUNumberForPurchase(widget.purchase.purchaseId ?? '');
      
      print('🔄 Generating SKUs for purchase ${widget.purchase.purchaseId} starting from: $currentCounter');
      
      for (var prod in widget.purchase.products ?? []) {
        int qty = prod.qty ?? 0;
        print('📦 Product: ${prod.productName}, Quantity: $qty');
        
        // Generate SKUs for each unit of this product
        for (int i = 0; i < qty; i++) {
          String sku = "SK${currentCounter.toString().padLeft(8, '0')}";
          tempList.add({
            "product": prod,
            "sku": sku,
            "index": i + 1,
          });
          print('  ✅ Generated SKU: $sku for item ${i + 1}');
          currentCounter++;
        }
      }
      
      print('🎯 Total SKUs generated: ${tempList.length}');
      print('🔢 Next available SKU number: $currentCounter');
      
      // Update the global counter to match the database state
      GlobalSKU.counter = currentCounter;
      await GlobalSKU.saveCounter();
      
      // Update the purchase model and local state
      widget.purchase.skuItems = tempList;
      skuItems = tempList;
      
      // Save the updated purchase to database
      await repo.updatePurchase(widget.purchase);
      
      // Update stock when SKUs are generated
      await _updateStockFromPurchase();
      
      print('💾 Purchase updated in database with SKUs');
    }

    // Update stock from purchase data
    Future<void> _updateStockFromPurchase() async {
      try {
        final repo = UserRepository();

        for (var prod in widget.purchase.products ?? []) {
          if (prod.productName != null && prod.qty != null && prod.qty! > 0) {
            // Determine size from the product
            // Parse mm value which should be in format like "4*8"
            String size;
            if (prod.mm != null && prod.mm!.contains('*')) {
              // Use the mm value directly as size, just replacing * with ×
              size = prod.mm!.replaceAll('*', '×');
            } else {
              // Fallback to default size if mm is not in expected format
              size = "${prod.mm ?? '1'}×${prod.mm ?? '1'}";
            }
            print('Using size: $size for product: ${prod.productName}');

            // Process stock purchase
            await repo. processStockPurchase(
              prod.productName!,
              size,
              prod.qty!,
              widget.purchase.purchaseId ?? '',
              hsnSac: prod.hsnSac,
              mm: prod.mm,
              rate: prod.rate,
              colour: prod.colour,
              colourCode: prod.colourCode,
              per: prod.per,
            );

            print('📦 Stock updated for ${prod.productName} - $size: +${prod.qty} pieces');
          }
        }
      } catch (e) {
        print('❌ Error updating stock: $e');
      }
    }

    Future<void> generateQRCodePDF() async {
      if (skuItems.isEmpty) return;

      final pdf = pw.Document();
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      for (var item in skuItems) {
        final prod = item["product"] as PurchaseProduct;
        final sku = item["sku"] as String;

        pdf.addPage(
          pw.Page(
            build: (context) => pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("${prod.productName} - ${prod.colour}",
                      style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text("Rate: ₹${prod.rate}", style: pw.TextStyle(font: ttf, fontSize: 14)),
                  pw.Text("SKU: $sku", style: pw.TextStyle(font: ttf, fontSize: 14)),
                  pw.SizedBox(height: 10),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: jsonEncode({
                      "sku": sku,
                      "product": prod.productName,
                      "color": prod.colour,
                      "rate": prod.rate,
                      "invoice": widget.purchase.invoiceNo
                    }),
                    width: 100,
                    height: 100,
                  ),
                  pw.Divider(height: 30, thickness: 2),
                ],
              ),
            ),
          ),
        );
      }

      final dir = await getTemporaryDirectory();
      final pdfFile = File("${dir.path}/invoice_${widget.purchase.invoiceNo}.pdf");
      await pdfFile.create(recursive: true);
      await pdfFile.writeAsBytes(await pdf.save());

      if (await pdfFile.exists()) {
        await launchUrl(Uri.file(pdfFile.path));
      }
    }

    @override
    Widget build(BuildContext context) {
      final products = widget.purchase.products ?? [];

      return Scaffold(
        appBar: AppBar(
          title: Text("Invoice: ${widget.purchase.invoiceNo ?? "-"}"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _ensureSKUs();
              },
              tooltip: "Refresh SKUs",
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Purchase Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Company: ${widget.purchase.companyName ?? "Unknown"}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text("Address: ${widget.purchase.companyAddress ?? "-"}"),
                    Text("GSTIN: ${widget.purchase.companyGstin ?? "-"}"),
                    Text("Final Amount: ₹${widget.purchase.finalAmount ?? 0}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Products with SKUs
            ...products.map((prod) {
              final prodSkus = skuItems.where((item) => item["product"] == prod).toList();
              return ExpansionTile(
                title: Text(prod.productName ?? "Unnamed Product"),
                subtitle: Text(
                    "Rate: ₹${prod.rate ?? 0}, Color: ${prod.colour ?? "-"}, Qty: ${prod.qty ?? 0}"),
                children: [
                  ...prodSkus.map((item) {
                    final sku = item["sku"] as String;
                    final idx = item["index"];
                    return ListTile(
                      title: Text("Item $idx - SKU: $sku"),
                      trailing: Text("₹${prod.rate ?? 0}"),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            idx.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            }),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Generate PDF with QR Codes"),
                    onPressed: generateQRCodePDF,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Regenerate SKUs"),
                    onPressed: () async {
                      await GlobalSKU.resetCounter();
                      await _generateNewSKUs();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // SKU Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "SKU Summary",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text("Total SKUs Generated: ${skuItems.length}"),
                    if (skuItems.isNotEmpty) ...[
                      Text("First SKU: ${skuItems.first["sku"]}"),
                      Text("Last SKU: ${skuItems.last["sku"]}"),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
