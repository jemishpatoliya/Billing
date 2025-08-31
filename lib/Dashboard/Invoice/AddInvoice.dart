import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../Database/UserRepository.dart';
import '../../Library/UserSession.dart';
import '../../Model/InvoiceModel.dart';
import '../../Model/StockModel.dart';

class AddInvoice extends StatefulWidget {
  final InvoiceModel? invoiceToEdit;
  const AddInvoice({Key? key, this.invoiceToEdit}) : super(key: key);

  @override
  State<AddInvoice> createState() => _AddInvoiceState();
}

class _AddInvoiceState extends State<AddInvoice> {
  final _formKey = GlobalKey<FormState>();
  final repo = UserRepository();
  final _scrollController = ScrollController();

  // Controllers for InvoiceModel fields
  final TextEditingController invoiceNoCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController(text: DateFormat("dd/MM/yyyy").format(DateTime.now()),);
  final TextEditingController buyerNameCtrl = TextEditingController();
  final TextEditingController buyerAddressCtrl = TextEditingController();
  final TextEditingController placeOfSupplyCtrl = TextEditingController();
  final TextEditingController gstinBuyerCtrl = TextEditingController();
  final TextEditingController poNumberCtrl = TextEditingController();
  final TextEditingController mobileNoCtrl = TextEditingController();
  final TextEditingController bankNameCtrl = TextEditingController();
  final TextEditingController accountNumberCtrl = TextEditingController();
  final TextEditingController ifscCodeCtrl = TextEditingController();
  final TextEditingController transportCtrl = TextEditingController();
  final TextEditingController termsCtrl = TextEditingController();
  final TextEditingController jurisdictionCtrl = TextEditingController();
  final TextEditingController signatureCtrl = TextEditingController();
  final TextEditingController hsnSacCtrl = TextEditingController();
  final TextEditingController mmCtrl = TextEditingController();
  final TextEditingController paidAmountCtrl = TextEditingController(text: "0");
  final TextEditingController unpaidAmountCtrl = TextEditingController();

  bool useGST = true;
  bool payOnline = false;

  final TextEditingController gstPercentCtrl = TextEditingController(
    text: "18",
  );
  final TextEditingController discountPercentCtrl = TextEditingController(
    text: "0",
  );

  List<Map<String, dynamic>> products = [];
  List<StockModel> availableStock = [];
  List<String> availableProducts = [];
  Map<String, List<StockModel>> productStockMap = {};

  bool get isEditMode => widget.invoiceToEdit != null;

  Future<String> _generateInvoiceNumber() async {
    final lastInvoice = await repo.getLastInvoice();

    if (lastInvoice == null) {
      return 'INV-${DateFormat('yyyyMM').format(DateTime.now())}-0001';
    }

    final parts = lastInvoice.invoiceNo.split('-');
    final lastNumber = int.tryParse(parts.last) ?? 0;

    return 'INV-${DateFormat('yyyyMM').format(DateTime.now())}-${(lastNumber + 1).toString().padLeft(4, '0')}';
  }

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadInvoiceData();
    } else {
      addEmptyProduct();
    }
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    try {
      final repo = UserRepository();

      final productsWithStock = await repo.getProductsWithStockFromPurchases();

      print('Products with stock loaded: ${productsWithStock.length}');

      availableProducts.clear();
      productStockMap.clear();
      availableStock.clear();

      Set<String> uniqueProducts = {};

      for (var item in productsWithStock) {
        String productName = item['product_name'];
        uniqueProducts.add(productName);

        StockModel stockModel = StockModel(
          productName: productName,
          size: item['size'],
          quantity: item['available_stock'],
          rate: item['rate']?.toDouble(),
          hsnSac: item['hsn_sac'],
          mm: item['mm'],
          colour: item['colour'],
          colourCode: item['colour_code'],
          per: item['per'],
        );

        availableStock.add(stockModel);

        if (!productStockMap.containsKey(productName)) {
          productStockMap[productName] = [];
        }
        productStockMap[productName]!.add(stockModel);
      }

      availableProducts = uniqueProducts.toList()..sort();

      if (availableProducts.isEmpty) {
        availableProducts = ['No products available'];
        productStockMap['No products available'] = [];
      }

      print('Available products loaded: ${availableProducts.length}');
      for (String product in availableProducts) {
        print('- $product: ${productStockMap[product]?.length ?? 0} sizes');
      }

      setState(() {});
    } catch (e) {
      print('Error loading stock data: $e');
      availableProducts = ['No products available'];
      productStockMap.clear();
      productStockMap['No products available'] = [];
      setState(() {});
    }
  }

  void onProductSelected(String productName, int productIndex) {
    print('onProductSelected called with productName: $productName, index: $productIndex');

    if (productName.isEmpty || productName.trim().isEmpty) {
      print('Empty product name');
      setState(() {
        products[productIndex]['product'] = '';
        products[productIndex]['hsnSac'] = '';
        products[productIndex]['mm'] = '';
        products[productIndex]['rate'] = 0.0;
        products[productIndex]['price'] = 0.0;
        products[productIndex]['colour'] = '';
        products[productIndex]['size'] = '';
        products[productIndex]['qty'] = 0;
        products[productIndex]['selectedStock'] = null;
      });
      return;
    }

    if (productName == 'No products available') {
      print('No products available selected');
      setState(() {
        products[productIndex]['product'] = productName;
        products[productIndex]['hsnSac'] = '';
        products[productIndex]['mm'] = '';
        products[productIndex]['rate'] = 0.0;
        products[productIndex]['colour'] = '';
        products[productIndex]['size'] = '0×0';
        products[productIndex]['qty'] = 0;
        products[productIndex]['price'] = 0.0;
        products[productIndex]['amount'] = 0.0;
        products[productIndex]['selectedStock'] = null;
      });
      return;
    }

    final stockItems = productStockMap[productName] ?? [];
    print('Stock items for $productName: ${stockItems.length}');

    setState(() {
      products[productIndex]['product'] = productName;
      products[productIndex]['availableStocks'] = stockItems;

      // Clear previous selection but keep product name
      products[productIndex]['hsnSac'] = '';
      products[productIndex]['mm'] = '';
      products[productIndex]['rate'] = 0.0;
      products[productIndex]['price'] = 0.0;
      products[productIndex]['colour'] = '';
      products[productIndex]['size'] = '';
      products[productIndex]['qty'] = 0;
      products[productIndex]['selectedStock'] = null;

      // Auto-show stock selection dialog if stocks are available
      if (stockItems.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showStockSelectionDialog(productIndex);
        });
      }

      updateProduct(productIndex);
    });
  }

  void _showStockSelectionDialog(int productIndex) async {
    final productName = products[productIndex]['product'] as String?;
    if (productName == null || productName.isEmpty || productName == 'No products available') {
      return;
    }

    final stockItems = productStockMap[productName] ?? [];
    if (stockItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No stock available for $productName'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedStock = await showDialog<StockModel>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select Size & Stock for $productName',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Choose from available sizes and quantities below:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: stockItems.length,
                    itemBuilder: (context, index) {
                      final stock = stockItems[index];
                      final isAvailable = (stock.quantity ?? 0) > 0;

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: isAvailable ? 3 : 1,
                        color: isAvailable ? null : Colors.grey[50],
                        child: InkWell(
                          onTap: isAvailable ? () {
                            Navigator.of(context).pop(stock);
                          } : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Stock Status Icon
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isAvailable ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isAvailable ? Icons.check_circle : Icons.cancel,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      Text(
                                        '${stock.quantity ?? 0}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'pcs',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16),
                                // Stock Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.straighten,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Size: ${stock.size ?? 'N/A'}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isAvailable ? Colors.black : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.currency_rupee, size: 14, color: Colors.green),
                                                    Text('Rate: ₹${stock.rate?.toStringAsFixed(2) ?? '0.00'}'),
                                                  ],
                                                ),
                                                if (stock.hsnSac != null && stock.hsnSac!.isNotEmpty)
                                                  Row(
                                                    children: [
                                                      Icon(Icons.tag, size: 14, color: Colors.orange),
                                                      Text('HSN: ${stock.hsnSac}'),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.inventory, size: 14, color: Colors.blue),
                                                    Text('Qty: ${stock.quantity ?? 0} pieces'),
                                                  ],
                                                ),
                                                if (stock.mm != null && stock.mm!.isNotEmpty)
                                                  Row(
                                                    children: [
                                                      Icon(Icons.straighten, size: 14, color: Colors.purple),
                                                      Text('MM: ${stock.mm}'),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (stock.colour != null && stock.colour!.isNotEmpty) ...[
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.color_lens, size: 14, color: Colors.pink),
                                            SizedBox(width: 4),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[100],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                stock.colour!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      SizedBox(height: 8),
                                      // Status Badge
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isAvailable ? Colors.green[100] : Colors.red[100],
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isAvailable ? Colors.green[300]! : Colors.red[300]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isAvailable ? Icons.check : Icons.error,
                                              size: 14,
                                              color: isAvailable ? Colors.green[700] : Colors.red[700],
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              isAvailable ? 'Available - Click to Select' : 'Out of Stock',
                                              style: TextStyle(
                                                color: isAvailable ? Colors.green[700] : Colors.red[700],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAvailable)
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select any available size to continue with your invoice',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedStock != null) {
      setState(() {
        products[productIndex]['selectedStock'] = selectedStock;
        products[productIndex]['hsnSac'] = selectedStock.hsnSac ?? '';
        products[productIndex]['mm'] = selectedStock.mm ?? '';
        products[productIndex]['rate'] = selectedStock.rate ?? 0.0;
        products[productIndex]['price'] = selectedStock.rate ?? 0.0;
        products[productIndex]['colour'] = selectedStock.colour ?? '';
        products[productIndex]['size'] = selectedStock.size ?? '';

        final availableQty = selectedStock.quantity ?? 0;
        if (availableQty > 0) {
          products[productIndex]['qty'] = 1;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected: ${selectedStock.size} - Available: $availableQty pieces'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          products[productIndex]['qty'] = 0;
        }

        updateProduct(productIndex);
      });
    }
  }

  void _loadInvoiceData() async {
    final inv = widget.invoiceToEdit!;
    invoiceNoCtrl.text = await _generateInvoiceNumber();
    dateCtrl.text = inv.date;
    buyerNameCtrl.text = inv.buyerName;
    buyerAddressCtrl.text = inv.buyerAddress;
    placeOfSupplyCtrl.text = inv.placeOfSupply;
    gstinBuyerCtrl.text = inv.gstinBuyer;
    poNumberCtrl.text = inv.poNumber ?? '';
    mobileNoCtrl.text = inv.mobileNo ?? '';
    bankNameCtrl.text = inv.bankName ?? '';
    accountNumberCtrl.text = inv.accountNumber ?? '';
    ifscCodeCtrl.text = inv.ifscCode ?? '';
    transportCtrl.text = inv.transport ?? '';
    termsCtrl.text = inv.termsConditions ?? '';
    jurisdictionCtrl.text = inv.jurisdiction ?? '';
    signatureCtrl.text = inv.signature ?? '';
    hsnSacCtrl.text = inv.hsnSac ?? '';
    mmCtrl.text = inv.mm ?? '';
    useGST = inv.isGst ?? false;
    payOnline = inv.isOnline ?? false;
    paidAmountCtrl.text = (inv.paid_amount ?? 0).toString();
    unpaidAmountCtrl.text = (inv.unpaid_amount ?? 0).toString();

    setState(() {
      products = List<Map<String, dynamic>>.from(jsonDecode(inv.productDetails));
    });
  }

  // Update this method in your _AddInvoiceState class
  StockModel? getStockForProductAndSize(String productName, String size) {
    if (productName.isEmpty || size.isEmpty) {
      return null;
    }

    final stockItems = productStockMap[productName] ?? [];

    try {
      return stockItems.firstWhere((item) => item.size == size);
    } catch (e) {
      return null;
    }
  }

  // Add this method to your _AddInvoiceState class
  void onSizeSelected(String size, int productIndex) {
    final productName = products[productIndex]['product'] as String?;

    if (productName == null || productName.isEmpty) {
      return;
    }

    final stockForSize = getStockForProductAndSize(productName, size);

    setState(() {
      products[productIndex]['size'] = size;

      if (stockForSize != null) {
        products[productIndex]['selectedStock'] = stockForSize;
        products[productIndex]['hsnSac'] = stockForSize.hsnSac ?? '';
        products[productIndex]['mm'] = stockForSize.mm ?? '';
        products[productIndex]['rate'] = stockForSize.rate ?? 0.0;
        products[productIndex]['price'] = stockForSize.rate ?? 0.0;
        products[productIndex]['colour'] = stockForSize.colour ?? '';
      } else {
        products[productIndex]['selectedStock'] = null;
        products[productIndex]['rate'] = 0.0;
        products[productIndex]['price'] = 0.0;
      }

      updateProduct(productIndex);
    });
  }

  void addEmptyProduct() {
    double gstPercent = double.tryParse(gstPercentCtrl.text) ?? 0.0;
    double discountPercent = double.tryParse(discountPercentCtrl.text) ?? 0.0;

    setState(() {
      products.add({
        "product": "",
        "desc": "",
        "price": 0.0,
        "qty": 1,
        "discount_percent": discountPercent,
        "discount_amount": 0.0,
        "gst_percent": useGST ? gstPercent : 0.0,
        "gst_amount": 0.0,
        "cgst": 0.0,
        "sgst": 0.0,
        "subtotal": 0.0,
        "total": 0.0,
        "selectedStock": null,
        "availableStocks": [],
        "availableSizes": <String>[],
        "size": "",
        "hsnSac": "",
        "mm": "",
        "colour": "",
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void updateProduct(int index) {
    final p = products[index];
    double amount = (p['price'] ?? 0) * (p['qty'] ?? 1);
    double discountPercent = p['discount_percent'] ?? 0.0;
    double gstPercent = useGST ? (p['gst_percent'] ?? 0.0) : 0.0;

    double dis = amount * (discountPercent / 100);
    double net = amount - dis;
    double gst = net * (gstPercent / 100);
    double cgst = gst / 2;
    double sgst = gst / 2;
    double total = net + gst;

    setState(() {
      p['discount_amount'] = -dis;
      p['gst_amount'] = gst;
      p['cgst'] = cgst;
      p['sgst'] = sgst;
      p['subtotal'] = net;
      p['total'] = total;
    });
  }

  double getTotal(String key) {
    return products.fold(0.0, (sum, p) => sum + (p[key] ?? 0.0));
  }

  String generateInvoiceNo(int nextNumber) {
    final now = DateTime.now();
    final datePart =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final sequencePart = nextNumber.toString().padLeft(3, '0');
    return "INV-$datePart-$sequencePart";
  }

  String? _getMaxQuantityText(int productIndex) {
    final product = products[productIndex];
    final selectedStock = product['selectedStock'] as StockModel?;

    if (selectedStock != null) {
      final maxQty = selectedStock.quantity ?? 0;
      return 'Max: $maxQty';
    }

    return null;
  }

  Future<void> saveInvoice() async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Validate stock availability before saving
    for (var product in products) {
      final selectedStock = product['selectedStock'] as StockModel?;
      final qty = product['qty'] as int?;

      if (selectedStock != null && qty != null && qty > 0) {
        if ((selectedStock.quantity ?? 0) < qty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Insufficient stock for ${selectedStock.productName} (${selectedStock.size}). Available: ${selectedStock.quantity ?? 0}, Requested: $qty'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    final subtotal = getTotal('subtotal');
    final gst = getTotal('gst_amount');
    final cgst = gst / 2;
    final sgst = gst / 2;
    final total = getTotal('total');
    final roundedTotal = total.roundToDouble();

    String invoiceNo;

    if (isEditMode) {
      invoiceNo = invoiceNoCtrl.text;
    } else {
      int nextInvoiceNumber = await repo.getNextInvoiceNumberForToday();
      invoiceNo = generateInvoiceNo(nextInvoiceNumber);
      invoiceNoCtrl.text = invoiceNo;
    }

    // Clean products data for JSON encoding - remove non-serializable objects
    List<Map<String, dynamic>> cleanProducts = products.map((product) {
      Map<String, dynamic> cleanProduct = Map.from(product);
      // Remove StockModel objects and other non-serializable data
      cleanProduct.remove('selectedStock');
      cleanProduct.remove('availableStocks');
      cleanProduct.remove('availableSizes');
      return cleanProduct;
    }).toList();

    final model = InvoiceModel(
      id: isEditMode ? widget.invoiceToEdit!.id : null,
      invoiceNo: invoiceNo,
      date: dateCtrl.text,
      yourFirm: "RUDRA ENTERPRISE",
      yourFirmAddress: "199, Sneh Milan Soc, Near Diamond Hospital",
      buyerName: buyerNameCtrl.text,
      buyerAddress: buyerAddressCtrl.text,
      placeOfSupply: placeOfSupplyCtrl.text,
      gstinSupplier: "24AHHPU2550P1ZU",
      gstinBuyer: gstinBuyerCtrl.text,
      poNumber: poNumberCtrl.text,
      mobileNo: mobileNoCtrl.text,
      productDetails: jsonEncode(cleanProducts), // Use cleaned products
      subtotal: subtotal,
      cgst: cgst,
      sgst: sgst,
      totalGst: gst,
      total: total,
      roundedTotal: roundedTotal,
      totalInWords: "",
      bankName: bankNameCtrl.text,
      accountNumber: accountNumberCtrl.text,
      ifscCode: ifscCodeCtrl.text,
      transport: transportCtrl.text,
      termsConditions: termsCtrl.text,
      jurisdiction: jurisdictionCtrl.text,
      signature: signatureCtrl.text,
      hsnSac: hsnSacCtrl.text,
      mm: mmCtrl.text,
      paid_amount: double.tryParse(paidAmountCtrl.text) ?? 0.0,
      unpaid_amount: total - (double.tryParse(paidAmountCtrl.text) ?? 0),
      size: products.isNotEmpty && products.first['size'] != null ? products.first['size'] : "1*1",
      isGst: useGST,
      isOnline: payOnline,
    );

    try {
      if (isEditMode) {
        await repo.updateInvoice(model);
      } else {
        await repo.addInvoice(model);

        // Update stock after successful save
        // await _updateStockFromInvoice();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode ? 'Invoice updated successfully' : 'Invoice added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } catch (e) {
      print('Error saving invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving invoice: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => products.removeAt(index));
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchOption(
      String label,
      bool value,
      Function(bool) onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfoWidget(int productIndex) {
    final product = products[productIndex];
    final selectedStock = product['selectedStock'] as StockModel?;
    final productName = product['product'] as String?;

    if (productName == null || productName.isEmpty || productName == 'No products available') {
      return SizedBox.shrink();
    }

    if (selectedStock == null) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.orange[700]),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tap "Select Stock" to choose size and view availability',
                style: TextStyle(color: Colors.orange[700]),
              ),
            ),
            TextButton.icon(
              icon: Icon(Icons.inventory, size: 16),
              label: Text('Select Stock'),
              onPressed: () => _showStockSelectionDialog(productIndex),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange[700],
                backgroundColor: Colors.orange[100],
              ),
            ),
          ],
        ),
      );
    }

    final availableQty = selectedStock.quantity ?? 0;
    final requestedQty = product['qty'] as int? ?? 0;
    final isSufficient = availableQty >= requestedQty;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSufficient ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSufficient ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSufficient ? Icons.check_circle : Icons.warning,
                color: isSufficient ? Colors.green[700] : Colors.red[700],
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selected Stock Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSufficient ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
              TextButton.icon(
                icon: Icon(Icons.edit, size: 16),
                label: Text('Change'),
                onPressed: () => _showStockSelectionDialog(productIndex),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  backgroundColor: Colors.blue[100],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Size Display Row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.straighten, size: 16, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text(
                  'Selected Size: ${selectedStock.size ?? 'N/A'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available: $availableQty pieces'),
                    Text('Rate: ₹${selectedStock.rate?.toStringAsFixed(2) ?? '0.00'}'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedStock.hsnSac != null && selectedStock.hsnSac!.isNotEmpty)
                      Text('HSN/SAC: ${selectedStock.hsnSac}'),
                    if (selectedStock.mm != null && selectedStock.mm!.isNotEmpty)
                      Text('MM: ${selectedStock.mm}'),
                    if (selectedStock.colour != null && selectedStock.colour!.isNotEmpty)
                      Text('Colour: ${selectedStock.colour}'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSufficient ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSufficient ? Colors.green[300]! : Colors.red[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSufficient ? Icons.check : Icons.error,
                  size: 16,
                  color: isSufficient ? Colors.green[700] : Colors.red[700],
                ),
                SizedBox(width: 4),
                Text(
                  isSufficient
                      ? 'Stock Available (Requested: $requestedQty)'
                      : 'Insufficient Stock (Available: $availableQty, Requested: $requestedQty)',
                  style: TextStyle(
                    color: isSufficient ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    buyerNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? "Update Invoice" : "Create New Invoice"),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView(
            controller: _scrollController,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                        'Buyer Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      FutureBuilder<List<String>>(
                        future: repo.getAllBuyerNames(),
                        builder: (context, snapshot) {
                          final names = snapshot.data ?? [];

                          return Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') {
                                return const Iterable<String>.empty();
                              }
                              return names.where((String option) {
                                return option
                                    .toLowerCase()
                                    .contains(textEditingValue.text.toLowerCase());
                              });
                            },
                            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                              controller.text = buyerNameCtrl.text;

                              controller.addListener(() {
                                buyerNameCtrl.text = controller.text;
                              });
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(labelText: 'Name'),
                                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
                              );
                            },
                            onSelected: (String selection) async {
                              final customer = await repo.fetchCustomerByName(selection);
                              if (customer != null) {
                                buyerAddressCtrl.text = customer['buyer_address'] ?? '';
                                mobileNoCtrl.text = customer['mobile_no'] ?? '';
                                gstinBuyerCtrl.text = customer['gstin_buyer'] ?? '';
                                poNumberCtrl.text = customer['po_number'] ?? '';
                                placeOfSupplyCtrl.text = customer['place_of_supply'] ?? '';
                              }
                            },
                          );
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactFormField(
                              controller: mobileNoCtrl,
                              label: "Mobile",
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _buildCompactFormField(
                                controller: poNumberCtrl,
                                label: "PO Number",
                              ),
                            ),
                            ],
                          ),
                          _buildCompactFormField(
                            controller: buyerAddressCtrl,
                            label: "Address",
                            validator: (val) =>
                            val?.isEmpty ?? true ? 'Required' : null,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactFormField(
                                  controller: gstinBuyerCtrl,
                                  label: "GSTIN",
                                  enabled: useGST,
                                  validator: (val) {
                                    if (!useGST) return null;
                                    if (val == null || val.trim().isEmpty)
                                      return 'Required';
                                    if (val.trim().length != 15)
                                      return 'Invalid GSTIN';
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactFormField(
                                  controller: placeOfSupplyCtrl,
                                  label: "Place of Supply",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seller Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "RUDRA ENTERPRISE",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "199, Sneh Milan Soc, Near Daimond Hospital",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Chikuwadi Varachha Road, Surat - 395006",
                          style: TextStyle(fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "GSTIN: 24AHHPU2550P1ZU",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Settings Toggle
              _buildSwitchOption('Use GST', useGST, (val) {
                setState(() {
                  useGST = val;
                  if (!useGST) {
                    for (var p in products) {
                      p['gst_percent'] = 0.0;
                    }
                  } else {
                    double gstPercent =
                        double.tryParse(gstPercentCtrl.text) ?? 18.0;
                    for (var p in products) {
                      p['gst_percent'] = gstPercent;
                    }
                  }
                  for (int i = 0; i < products.length; i++) {
                    updateProduct(i);
                  }
                });
              }),
              _buildSwitchOption(
                'Pay Online',
                payOnline,
                    (val) => setState(() => payOnline = val),
              ),

              // Bank Details (only shown if payOnline is true)
              if (payOnline) ...[
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bank Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildCompactFormField(
                        controller: bankNameCtrl,
                        label: "Bank Name",
                        validator: (val) =>
                        payOnline && (val?.isEmpty ?? true)
                            ? 'Required'
                            : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactFormField(
                              controller: accountNumberCtrl,
                              label: "Account No",
                              keyboardType: TextInputType.number,
                              maxLength: 14,
                              validator: (val) {
                                if (!payOnline) return null;
                                if (val == null || val.isEmpty)
                                  return 'Required';
                                if (val.length < 6 || val.length > 14) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildCompactFormField(
                              controller: ifscCodeCtrl,
                              label: "IFSC Code",
                              maxLength: 11,
                              validator: (val) {
                                if (!payOnline) return null;
                                if (val == null || val.length != 11) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Products Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.add, size: 18),
                    label: Text("Add"),
                    onPressed: addEmptyProduct,
                  ),
                ],
              ),

              if (products.isEmpty)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      'No products added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

// In the build method, replace the products mapping section with this:

              ...products.asMap().entries.map((entry) {
                int index = entry.key;
                var item = entry.value;
                final availableSizes = (item['availableSizes'] as List<String>?) ?? [];

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Product ${index + 1}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(index),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Product Selection Row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: item['product']?.isEmpty ?? true ? null : item['product'],
                                decoration: InputDecoration(
                                  labelText: "Product Name",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                items: availableProducts.isEmpty
                                    ? [
                                  DropdownMenuItem<String>(
                                    value: 'No products available',
                                    child: Text('No products available',
                                        style: TextStyle(color: Colors.red)),
                                  )
                                ]
                                    : availableProducts.map((product) {
                                  return DropdownMenuItem(
                                    value: product,
                                    child: Text(product),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  onProductSelected(val ?? '', index);
                                },
                                validator: (value) => value == null || value.isEmpty
                                    ? 'Select a product'
                                    : null,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: item['desc'],
                                decoration: InputDecoration(
                                  labelText: "Description",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onChanged: (val) => item['desc'] = val,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Size and HSN/SAC Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: item['size']?.isEmpty ?? true ? null : item['size'],
                                decoration: InputDecoration(
                                  labelText: "Size",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                items: availableSizes.isEmpty
                                    ? [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('No sizes available', style: TextStyle(color: Colors.grey)),
                                  )
                                ]
                                    : availableSizes.map((size) {
                                  return DropdownMenuItem(
                                    value: size,
                                    child: Text(size),
                                  );
                                }).toList(),
                                onChanged: availableSizes.isEmpty ? null : (val) {
                                  if (val != null) {
                                    onSizeSelected(val, index);
                                  }
                                },
                                validator: (value) => availableSizes.isNotEmpty && (value == null || value.isEmpty)
                                    ? 'Select a size'
                                    : null,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: item['hsnSac'] ?? '',
                                decoration: InputDecoration(
                                  labelText: "HSN/SAC",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onChanged: (val) => item['hsnSac'] = val,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // MM Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: item['mm'] ?? '',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: "MM",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onChanged: (val) => item['mm'] = val,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(child: SizedBox()), // Empty space for alignment
                          ],
                        ),

                        SizedBox(height: 16),

                        // Price, Quantity, Discount Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: item['price'].toString(),
                                decoration: InputDecoration(
                                  labelText: "Price",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: (val) => val == null || double.tryParse(val) == null
                                    ? 'Invalid'
                                    : null,
                                onChanged: (val) {
                                  item['price'] = double.tryParse(val) ?? 0.0;
                                  updateProduct(index);
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: item['qty'].toString(),
                                decoration: InputDecoration(
                                  labelText: "Quantity",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                  suffixText: _getMaxQuantityText(index),
                                  suffixStyle: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (val == null || int.tryParse(val) == null) {
                                    return 'Invalid';
                                  }
                                  final qty = int.parse(val);
                                  final selectedStock = item['selectedStock'] as StockModel?;
                                  if (selectedStock != null) {
                                    final maxQty = selectedStock.quantity ?? 0;
                                    if (qty > maxQty) {
                                      return 'Max: $maxQty';
                                    }
                                  }
                                  return null;
                                },
                                onChanged: (val) {
                                  final qty = int.tryParse(val) ?? 1;
                                  final selectedStock = item['selectedStock'] as StockModel?;

                                  if (selectedStock != null) {
                                    final maxQty = selectedStock.quantity ?? 0;
                                    if (qty > maxQty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Only $maxQty pieces available in stock'),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      item['qty'] = maxQty;
                                    } else {
                                      item['qty'] = qty;
                                    }
                                  } else {
                                    item['qty'] = qty;
                                  }

                                  updateProduct(index);
                                  setState(() {}); // Refresh to show validation
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: item['discount_percent'].toString(),
                                decoration: InputDecoration(
                                  labelText: "Discount %",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: (val) => val == null || double.tryParse(val) == null
                                    ? 'Invalid'
                                    : null,
                                onChanged: (val) {
                                  item['discount_percent'] = double.tryParse(val) ?? 0.0;
                                  updateProduct(index);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              // Invoice Summary
              if (products.isNotEmpty) ...[
                Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          'Invoice Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildCompactSummaryRow("Subtotal:", getTotal('subtotal')),
                        if (useGST) ...[
                          _buildCompactSummaryRow(
                            "CGST (${(double.tryParse(gstPercentCtrl.text) ?? 18) / 2}%):",
                            getTotal('cgst'),
                          ),
                          _buildCompactSummaryRow(
                            "SGST (${(double.tryParse(gstPercentCtrl.text) ?? 18) / 2}%):",
                            getTotal('sgst'),
                          ),
                        ],
                        Divider(height: 16),
                        _buildCompactSummaryRow("TOTAL:", getTotal('total'), isTotal: true),
                        SizedBox(height: 8),
                        _buildCompactFormField(
                          controller: paidAmountCtrl,
                          label: "Paid Amount",
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Enter amount';
                            final paid = double.tryParse(val) ?? 0;
                            final total = getTotal('total');
                            if (paid > total) return 'Cannot pay more than total';
                            return null;
                          },
                          onChanged: (val) {
                            setState(() {
                              final paid = double.tryParse(val) ?? 0;
                              final total = getTotal('total');
                              unpaidAmountCtrl.text = (total - paid).toStringAsFixed(2);
                            });
                          },
                        ),
                        _buildCompactSummaryRow(
                          "Unpaid Amount:",
                          getTotal('total') - (double.tryParse(paidAmountCtrl.text) ?? 0),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Save Button
              if (UserSession.canEdit('Invoice') || UserSession.canCreate('Invoice'))
                ElevatedButton(
                  onPressed: saveInvoice,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    backgroundColor: theme.primaryColor,
                  ),
                  child: Text(
                    isEditMode ? "UPDATE INVOICE" : "SAVE INVOICE",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactFormField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLength: maxLength,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCompactSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}