import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Database/UserRepository.dart';
import '../../Model/ProductModel.dart';
import '../../Model/PurchaseModel.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart'; // ✅ For FilePicker
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // for unique IDs

class ProductRow {
  TextEditingController productName = TextEditingController();
  TextEditingController hsnSac = TextEditingController();
  TextEditingController mm = TextEditingController();
  TextEditingController colour = TextEditingController();
  TextEditingController colourCode = TextEditingController();
  TextEditingController qty = TextEditingController();
  TextEditingController rate = TextEditingController();
  TextEditingController per = TextEditingController();
  double amount = 0;

  String? selectedFirst = "4";  // size dropdown 1
  String? selectedSecond = "8"; // size dropdown 2
  String? selectedProduct; // ✅ row-specific product
  String? selectedColor;   // ✅ row-specific color

  void clearFields() {
    productName.clear();
    hsnSac.clear();
    mm.clear();
    colour.clear();
    colourCode.clear();
    qty.clear();
    rate.clear();
    per.clear();
    amount = 0;
    selectedFirst = "4";
    selectedSecond = "8";
    selectedProduct = null;
    selectedColor = null;
  }

  void calculateAmount() {
    int q = int.tryParse(qty.text) ?? 0;
    double r = double.tryParse(rate.text) ?? 0;
    amount = q * r;
  }
  void updateSize() {
    if (selectedFirst != null && selectedSecond != null) {
      mm.text = "${selectedFirst!}*${selectedSecond!}";
    }
  }
 }

class FinalAmountResult {
  double finalAmount;
  String displayText;

  FinalAmountResult({required this.finalAmount, required this.displayText});
}

class AddPurchase extends StatefulWidget {
  const AddPurchase({super.key});

  @override
  State<AddPurchase> createState() => _AddPurchaseState();
}

class _AddPurchaseState extends State<AddPurchase> {
  final _formKey = GlobalKey<FormState>();
  final UserRepository repo = UserRepository();

  final companyNameController = TextEditingController();
  final companyAddressController = TextEditingController();
  final companyGstController = TextEditingController();
  final companyEmailController = TextEditingController();
  // final invoiceNumberController = TextEditingController();
  final finalAmountController = TextEditingController();
  final dispatchFromController = TextEditingController();
  final shipToController = TextEditingController();
  final packingController = TextEditingController();

  List<ProductRow> products = [ProductRow()];
  double igstRate = 0.18;

  @override
  void dispose() {
    companyNameController.dispose();
    companyAddressController.dispose();
    companyGstController.dispose();
    companyEmailController.dispose();
    // invoiceNumberController.dispose();
    finalAmountController.dispose();
    dispatchFromController.dispose();
    shipToController.dispose();
    packingController.dispose();

    for (var p in products) {
      p.productName.dispose();
      p.hsnSac.dispose();
      p.mm.dispose();
      p.colour.dispose();
      p.colourCode.dispose();
      p.qty.dispose();
      p.rate.dispose();
      p.per.dispose();
    }
    super.dispose();
  }

  double calculateFinalAmount() {
    double total = 0;
    for (var p in products) {
      p.calculateAmount();
      total += p.amount;
    }

    double packing = double.tryParse(packingController.text.replaceAll('"', '')) ?? 0;
    double igst = total * igstRate;
    double finalAmt = total + packing + igst;

    // Custom rounding logic
    int integerPart = finalAmt.floor();
    double decimalPart = finalAmt - integerPart;

    if (decimalPart > 0.5) {
      finalAmt = integerPart + 1; // round up
    } else {
      finalAmt = integerPart.toDouble(); // round down
    }

    return finalAmt;
  }
  FinalAmountResult calculateFinalAmountResult() {
    double totalProducts = 0;
    for (var p in products) {
      p.calculateAmount();
      totalProducts += p.amount;
    }

    double packing = double.tryParse(packingController.text.replaceAll(',', '')) ?? 0;
    double gstAmount = (totalProducts + packing) * igstRate; // 18% GST
    double finalAmt = totalProducts + packing + gstAmount;

    // Format numbers with Indian-style commas
    final formatter = NumberFormat('#,##,###.##');

    String displayText = "Total: ${formatter.format(totalProducts)}\n"
        "Packing: ${formatter.format(packing)}\n"
        "GST 18%: ${formatter.format(gstAmount)}\n"
        "Final Amount: ${formatter.format(finalAmt)}";

    return FinalAmountResult(finalAmount: finalAmt, displayText: displayText);
  }

  String calculateFinalAmountText() {
    double totalProducts = 0;
    for (var p in products) {
      p.calculateAmount();
      totalProducts += p.amount;
    }

    double packing = double.tryParse(packingController.text) ?? 0;
    double gstAmount = (totalProducts + packing) * igstRate;
    double finalAmt = totalProducts + packing + gstAmount;

    return "Total: ${totalProducts.toStringAsFixed(2)}\n"
        "Packing: ${packing.toStringAsFixed(2)}\n"
        "GST 18%: ${gstAmount.toStringAsFixed(2)}\n"
        "Final Amount: ${finalAmt.toStringAsFixed(2)}";
  }

  Future<String> _generateInvoiceNumber() async {
    // Get the last invoice number from database
    final lastInvoice = await repo.getLastInvoice();

    if (lastInvoice == null) {
      // If no invoices exist, start with 1
      return 'INV-${DateFormat('yyyyMM').format(DateTime.now())}-0001';
    }

    // Extract the sequence number from the last invoice
    final parts = lastInvoice.invoiceNo.split('-');
    final lastNumber = int.tryParse(parts.last) ?? 0;

    // Generate new invoice number with incremented sequence
    return 'PurINV-${DateFormat('yyyyMM').format(DateTime.now())}-${(lastNumber + 1).toString().padLeft(4, '0')}';
  }

  void savePurchase() async {
    if (_formKey.currentState!.validate()) {
      final finalResult = calculateFinalAmountResult();

      // Generate unique purchase ID
      String purchaseId = const Uuid().v4();

      // Current timestamp
      String createdAt = DateTime.now().toIso8601String();

      List<PurchaseProduct> productList = [];
      int productCounter = 1;

      for (var p in products) {
        // Generate unique product ID
        String productId = '${purchaseId}_P${productCounter.toString().padLeft(3, '0')}';
        productCounter++;

        productList.add(PurchaseProduct(
          productId: productId,
          purchaseId: purchaseId,
          productName: p.productName.text,
          hsnSac: p.hsnSac.text,
          mm: p.mm.text,
          colour: p.colour.text,
          colourCode: p.colourCode.text,
          qty: int.tryParse(p.qty.text) ?? 0,
          rate: double.tryParse(p.rate.text) ?? 0,
          per: p.per.text,
          total: p.amount,
        ));
      }

      // Create PurchaseModel
      PurchaseModel purchase = PurchaseModel(
        purchaseId: purchaseId,
        invoiceNo: await _generateInvoiceNumber(),
        createdAt: createdAt,
        companyName: companyNameController.text,
        companyAddress: companyAddressController.text,
        companyGstin: companyGstController.text,
        companyEmail: companyEmailController.text,
        finalAmount: finalResult.finalAmount, // numeric value
        dispatchFrom: dispatchFromController.text,
        shipTo: shipToController.text,
        pdfPath: importedPdfName,  // store path
        products: productList,
      );

      await repo.addPurchase(purchase);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase added successfully!')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    }
  }

  String? importedPdfName;
  String? importedPdfPath; // <-- declare the variable to store PDF path


  Future<void> importPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);

        // Load PDF document
        final PdfDocument pdfDocument = PdfDocument(inputBytes: await file.readAsBytes());

        // Extract all text using PdfTextExtractor
        final PdfTextExtractor extractor = PdfTextExtractor(pdfDocument);
        final String text = extractor.extractText(); // extracts text from all pages

        setState(() {
          importedPdfName = result.files.single.name;
          importedPdfPath = path;
        });

        parsePdfText(text); // your existing parser
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }
  void parsePdfText(String text) {}
// Helper functions
  double parseRate(String value) {
    final clean = value.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0;
  }

  double parseQty(String value) {
    final clean = value.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0;
  }

// Inside buildProductRow
  final formatter = NumberFormat('#,##,###.##');

  List<String> productNames = ["Acrylic Mirror Sheets", "PC Sheets / Rolls (<5.0)", "Acrylic Sheet"]; // default items
  String? selectedProduct;

  Future<String?> _addProductDialog() async {
    final TextEditingController newProductController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Product"),
        content: TextField(
          controller: newProductController,
          decoration: const InputDecoration(hintText: "Enter new product"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (newProductController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, newProductController.text.trim()); // ✅ return new product
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Map<String, String> colorMap = {
    "Red": "#FF0000",
    "Blue": "#0000FF",
    "Yellow": "#00FF00",
    "Black": "#00FF00",
    "Milky": "#00FF00",
  };

  String? selectedColor;

  void _addNewColorDialog() {
    final TextEditingController colorController = TextEditingController();
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Colour"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: "Colour Name"),
              ),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: "Colour Code"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Add"),
              onPressed: () {
                setState(() {
                  colorMap[colorController.text] = codeController.text;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }


  Widget buildProductRow(ProductRow p, int index) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: p.selectedProduct,  // use row-specific variable
                hint: const Text("Select Product"),
                isExpanded: true,
                items: productNames
                    .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    p.selectedProduct = value;
                    p.productName.text = value ?? "";
                  });
                },
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blue),
              onPressed: () {
                _addProductDialog().then((newProduct) {
                  if (newProduct != null) {
                    setState(() {
                      productNames.add(newProduct);
                      p.selectedProduct = newProduct;
                      p.productName.text = newProduct;
                    });
                  }
                });
              },
            ),
            Expanded(
              child: TextFormField(
                controller: p.hsnSac,
                decoration: const InputDecoration(hintText: 'HSN/SAC', border: InputBorder.none),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  DropdownButton<String>(
                    hint: const Text("W"),
                    value: p.selectedFirst,
                    items: ["1", "2", "3", "4"]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        p.selectedFirst = val;
                        p.updateSize();
                      });
                    },
                  ),
                  const SizedBox(width: 5),
                  DropdownButton<String>(
                    hint: const Text("H"),
                    value: p.selectedSecond,
                    items: ["1","2","3","4","5","6","7","8"]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        p.selectedSecond = val;
                        p.updateSize();
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: p.selectedColor,
                hint: const Text("Select Colour"),
                isExpanded: true,
                items: colorMap.keys
                    .map((color) => DropdownMenuItem(
                  value: color,
                  child: Text(color),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    p.selectedColor = value;
                    p.colour.text = value ?? "";
                    p.colourCode.text = colorMap[value] ?? "";
                  });
                },
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
            ),
            // ➕ Add Button
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blue),
              onPressed: () {
                _addNewColorDialog();
              },
            ),
            Expanded(
              child: TextFormField(
                controller: p.colourCode,
                readOnly: true, // ✅ user can't type manually
                decoration: const InputDecoration(
                    hintText: 'Colour Code', border: InputBorder.none),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: p.qty,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(hintText: 'Qty', border: InputBorder.none),
                onChanged: (_) {
                  setState(() {
                    final rate = parseRate(p.rate.text);
                    final qty = parseQty(p.qty.text);
                    p.amount = rate * qty;

                    finalAmountController.text = calculateFinalAmountResult().displayText;
                  });
                },
              ),
            ),

            Expanded(
              child: TextFormField(
                controller: p.rate,
                decoration: const InputDecoration(hintText: 'Rate', border: InputBorder.none),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) {
                  setState(() {
                    final rate = parseRate(p.rate.text);
                    final qty = parseQty(p.qty.text);
                    p.amount = rate * qty;

                    finalAmountController.text = calculateFinalAmountResult().displayText;
                  });
                },
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: p.per,
                decoration: const InputDecoration(hintText: 'Per', border: InputBorder.none),
              ),
            ),
            Expanded(
              child: Text(
                formatter.format(p.amount), // display row amount with commas
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(
              width: 40,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  setState(() {
                    products.removeAt(index);
                    finalAmountController.text = calculateFinalAmount().toString();
                  });
                },
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Purchase'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Import PDF',
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: importPdf,
            ),
          ),
          if (importedPdfName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Chip(
                label: Text(
                  importedPdfName!,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: isDarkMode ? Colors.blueGrey : Colors.blue.shade100,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    importedPdfName = null;
                    importedPdfPath = null;
                  });
                },
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Information Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, color: theme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Company Information',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildFormField(
                        controller: companyNameController,
                        label: 'Company Name',
                        icon: Icons.business_rounded,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        controller: companyAddressController,
                        label: 'Company Address',
                        icon: Icons.location_on,
                        isRequired: true,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: companyGstController,
                              label: 'GSTIN',
                              icon: Icons.receipt_long,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty)
                                  return 'Required';
                                if (val.trim().length != 15)
                                  return 'Invalid GSTIN';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFormField(
                              controller: companyEmailController,
                              label: 'Email',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 12),
                      // _buildFormField(
                      //   controller: invoiceNumberController,
                      //   label: 'Invoice Number',
                      //   icon: Icons.numbers,
                      // ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Products Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.inventory, color: theme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Products',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle,
                                color: theme.primaryColor, size: 32),
                            tooltip: 'Add Product',
                            onPressed: () {
                              setState(() {
                                products.add(ProductRow());
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (products.isEmpty)
                        Center(
                          child: Text(
                            'No products added',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.disabledColor,
                            ),
                          ),
                        ),
                      if (products.isNotEmpty)
                        Column(
                          children: [
                            // Table Header
                            Container(
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: const Row(
                                children: [
                                  Expanded(flex: 2, child: Text('Product')),
                                  Expanded(child: Text('HSN/SAC')),
                                  Expanded(child: Text('Size')),
                                  Expanded(flex: 2, child: Text('Color')),
                                  Expanded(child: Text('Qty')),
                                  Expanded(child: Text('Rate')),
                                  Expanded(child: Text('Per')),
                                  Expanded(child: Text('Amount')),
                                  SizedBox(width: 40),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: products.length,
                              separatorBuilder: (_, __) => const Divider(height: 16),
                              itemBuilder: (context, index) =>
                                  buildProductRow(products[index], index),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Additional Information Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt, color: theme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Additional Information',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildFormField(
                        controller: packingController,
                        label: 'Packing & Forwarding (₹)',
                        icon: Icons.local_shipping,
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          setState(() {
                            finalAmountController.text =
                                calculateFinalAmountText();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        controller: dispatchFromController,
                        label: 'Dispatch From',
                        icon: Icons.place,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        controller: shipToController,
                        label: 'Ship To',
                        icon: Icons.place_outlined,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: finalAmountController,
                        decoration: InputDecoration(
                          labelText: 'Amount Breakdown',
                          prefixIcon: const Icon(Icons.calculate),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? Colors.grey.shade800.withOpacity(0.5)
                              : Colors.grey.shade100,
                        ),
                        readOnly: true,
                        maxLines: 4,
                        style: const TextStyle(fontFamily: 'RobotoMono'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: savePurchase,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SAVE PURCHASE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 16),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget buildProductRows(ProductRow p, int index) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Dropdown with Add button
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: p.selectedProduct,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: theme.dividerColor.withOpacity(0.5)),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                hint: const Text('Select'),
                isExpanded: true,
                items: productNames
                    .map((name) => DropdownMenuItem(
                  value: name,
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    p.selectedProduct = value;
                    p.productName.text = value ?? "";
                  });
                },
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add New'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  _addProductDialog().then((newProduct) {
                    if (newProduct != null) {
                      setState(() {
                        productNames.add(newProduct);
                        p.selectedProduct = newProduct;
                        p.productName.text = newProduct;
                      });
                    }
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // HSN/SAC
        Expanded(
          child: TextFormField(
            controller: p.hsnSac,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),

        // Size Dropdowns
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border.all(
                  color: theme.dividerColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: p.selectedFirst,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ["1", "2", "3", "4"]
                        .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v, textAlign: TextAlign.center),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        p.selectedFirst = val;
                        p.updateSize();
                      });
                    },
                  ),
                ),
                Text('×', style: theme.textTheme.bodySmall),
                Expanded(
                  child: DropdownButton<String>(
                    value: p.selectedSecond,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ["1","2","3","4","5","6","7","8"]
                        .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v, textAlign: TextAlign.center),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        p.selectedSecond = val;
                        p.updateSize();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Color Dropdown with Add button
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: p.selectedColor,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                hint: const Text('Select'),
                isExpanded: true,
                items: colorMap.keys
                    .map((color) => DropdownMenuItem(
                  value: color,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getColorFromHex(colorMap[color] ?? '#FFFFFF'),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.dividerColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(color),
                    ],
                  ),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    p.selectedColor = value;
                    p.colour.text = value ?? "";
                    p.colourCode.text = colorMap[value] ?? "";
                  });
                },
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Color'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _addNewColorDialog,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Qty
        Expanded(
          child: TextFormField(
            controller: p.qty,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) {
              setState(() {
                final rate = parseRate(p.rate.text);
                final qty = parseQty(p.qty.text);
                p.amount = rate * qty;
                finalAmountController.text = calculateFinalAmountResult().displayText;
              });
            },
          ),
        ),
        const SizedBox(width: 8),

        // Rate
        Expanded(
          child: TextFormField(
            controller: p.rate,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) {
              setState(() {
                final rate = parseRate(p.rate.text);
                final qty = parseQty(p.qty.text);
                p.amount = rate * qty;
                finalAmountController.text = calculateFinalAmountResult().displayText;
              });
            },
          ),
        ),
        const SizedBox(width: 8),

        // Per
        Expanded(
          child: TextFormField(
            controller: p.per,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),

        // Amount
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              formatter.format(p.amount),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Delete Button
        SizedBox(
          width: 40,
          child: IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: () {
              setState(() {
                products.removeAt(index);
                finalAmountController.text = calculateFinalAmount().toString();
              });
            },
          ),
        ),
      ],
    );
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse("0x$hexColor"));
  }
}
