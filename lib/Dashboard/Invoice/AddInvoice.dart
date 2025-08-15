import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../Database/UserRepository.dart';
import '../../Library/UserSession.dart';
import '../../Model/InvoiceModel.dart';
import 'AllInvoice.dart';

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
  final TextEditingController dateCtrl = TextEditingController(
    text: DateFormat("dd/MM/yyyy").format(DateTime.now()),
  );
  // final TextEditingController yourFirmCtrl = TextEditingController();
  // final TextEditingController yourFirmAddressCtrl = TextEditingController();
  final TextEditingController buyerNameCtrl = TextEditingController();
  final TextEditingController buyerAddressCtrl = TextEditingController();
  final TextEditingController placeOfSupplyCtrl = TextEditingController();
  // final TextEditingController gstinSupplierCtrl = TextEditingController();
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

  bool get isEditMode => widget.invoiceToEdit != null;

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
  }

  void _loadInvoiceData() async {
    final inv = widget.invoiceToEdit!;
    invoiceNoCtrl.text = await _generateInvoiceNumber();
    dateCtrl.text = inv.date;
    // yourFirmCtrl.text = inv.yourFirm;
    // yourFirmAddressCtrl.text = inv.yourFirmAddress;
    buyerNameCtrl.text = inv.buyerName;
    buyerAddressCtrl.text = inv.buyerAddress;
    placeOfSupplyCtrl.text = inv.placeOfSupply;
    // gstinSupplierCtrl.text = inv.gstinSupplier;
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
    size = inv.size.toString();  // sizeValue should be a variable you declared
    useGST = inv.isGst ?? false;
    payOnline = inv.isOnline?? false;
    paidAmountCtrl.text = (inv.paid_amount ?? 0).toString();
    unpaidAmountCtrl.text = (inv.unpaid_amount ?? 0).toString();

    // IMPORTANT: call setState so UI updates with products
    setState(() {
      products = List<Map<String, dynamic>>.from(jsonDecode(inv.productDetails));
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
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) { // <-- check if attached
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

  int? sheetSize1;
  int? sheetSize2;
  String? size;

  final List<int> sheetSize1List = List.generate(
    8,
    (index) => index + 1,
  ); // 1 to 8
  final List<int> sheetSize2List = List.generate(
    6,
    (index) => index + 1,
  ); // 1 to 6

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

    final model = InvoiceModel(
      id: isEditMode ? widget.invoiceToEdit!.id : null,
      invoiceNo: invoiceNo,
      date: dateCtrl.text,
      yourFirm: "yourFirmCtrl.text",
      yourFirmAddress: "ourFirmAddressCtrl.text,",
      buyerName: buyerNameCtrl.text,
      buyerAddress: buyerAddressCtrl.text,
      placeOfSupply: placeOfSupplyCtrl.text,
      gstinSupplier: "gstinSupplierCtrl.text",
      gstinBuyer: gstinBuyerCtrl.text,
      poNumber: poNumberCtrl.text,
      mobileNo: mobileNoCtrl.text,
      productDetails: jsonEncode(products),
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
      size: "${sheetSize1 ?? 1} * ${sheetSize2 ?? 1}",
      isGst: useGST,
      isOnline: payOnline,
    );

    try {
      if (isEditMode) {
        await repo.updateInvoice(model);
      } else {
        await repo.addInvoice(model);
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
        ),
      );
    }
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
              // Seller Details - Static
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
                            future: repo.getAllBuyerNames(), // 👈 defined below
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
                                  validator:
                                      (val) =>
                                          val == null ||
                                                  !RegExp(
                                                    r'^\d{10}$',
                                                  ).hasMatch(val)
                                              ? 'Invalid number'
                                              : null,
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
                            validator:
                                (val) =>
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
                        validator:
                            (val) =>
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

              ...products.asMap().entries.map((entry) {
                int index = entry.key;
                var item = entry.value;
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(index),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value:
                                  item['product']?.isEmpty ?? true
                                      ? null
                                      : item['product'],
                              decoration: InputDecoration(
                                labelText: "Product Name",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              items: [
                                // Replace with your actual product list
                                DropdownMenuItem(
                                  value: "Product 1",
                                  child: Text("Product 1"),
                                ),
                                DropdownMenuItem(
                                  value: "Product 2",
                                  child: Text("Product 2"),
                                ),
                                DropdownMenuItem(
                                  value: "Product 3",
                                  child: Text("Product 3"),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  item['product'] = val ?? '';
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Select a product'
                                          : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Row(
                            children: [
                              // Dropdown for d1
                              DropdownButton<int>(
                                hint: Text('Select D1'),
                                value: sheetSize1,
                                items:
                                    sheetSize1List.map((val) {
                                      return DropdownMenuItem(
                                        value: val,
                                        child: Text(val.toString()),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    sheetSize1 = val;
                                  });
                                },
                              ),
                              const SizedBox(width: 20),
                              // Dropdown for d2
                              DropdownButton<int>(
                                hint: Text('Select D2'),
                                value: sheetSize2,
                                items:
                                    sheetSize2List.map((val) {
                                      return DropdownMenuItem(
                                        value: val,
                                        child: Text(val.toString()),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    sheetSize2 = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: item['desc'],
                              decoration: InputDecoration(
                                labelText: "Description",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onChanged: (val) => item['desc'] = val,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: item['hsnSac'] ?? '',
                              decoration: InputDecoration(
                                labelText: "HSN/SAC",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onChanged: (val) => item['hsnSac'] = val,
                            ),
                          ),
                          SizedBox(width: 12),
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
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onChanged: (val) => item['mm'] = val,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              initialValue: item['price'].toString(),
                              decoration: InputDecoration(
                                labelText: "Price",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator:
                                  (val) =>
                                      val == null ||
                                              double.tryParse(val) == null
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
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator:
                                  (val) =>
                                      val == null || int.tryParse(val) == null
                                          ? 'Invalid'
                                          : null,
                              onChanged: (val) {
                                item['qty'] = int.tryParse(val) ?? 1;
                                updateProduct(index);
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
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator:
                                  (val) =>
                                      val == null ||
                                              double.tryParse(val) == null
                                          ? 'Invalid'
                                          : null,
                              onChanged: (val) {
                                item['discount_percent'] =
                                    double.tryParse(val) ?? 0.0;
                                updateProduct(index);
                              },
                            ),
                          ),
                        ],
                      ),
                      // SizedBox(height: 16),
                      // Container(
                      //   padding: EdgeInsets.all(12),
                      //   decoration: BoxDecoration(
                      //     color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      //     borderRadius: BorderRadius.circular(8),
                      //   ),
                      //   child: Column(
                      //     children: [
                      //       Row(
                      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //         children: [
                      //           Text("Amount:", style: TextStyle(fontWeight: FontWeight.bold)),
                      //           Text("₹${((item['price'] ?? 0) * (item['qty'] ?? 1)).toStringAsFixed(2)}"),
                      //         ],
                      //       ),
                      //       SizedBox(height: 6),
                      //       Row(
                      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //         children: [
                      //           Text("Discount:", style: TextStyle(fontWeight: FontWeight.bold)),
                      //           Text("-₹${item['discount_amount'].toStringAsFixed(2)}",
                      //               style: TextStyle(color: Colors.red)),
                      //         ],
                      //       ),
                      //       if (useGST) ...[
                      //         SizedBox(height: 6),
                      //         Row(
                      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //           children: [
                      //             Text("CGST (${(item['gst_percent'] / 2).toStringAsFixed(1)}%):",
                      //                 style: TextStyle(fontWeight: FontWeight.bold)),
                      //             Text("₹${item['cgst'].toStringAsFixed(2)}"),
                      //           ],
                      //         ),
                      //         SizedBox(height: 6),
                      //         Row(
                      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //           children: [
                      //             Text("SGST (${(item['gst_percent'] / 2).toStringAsFixed(1)}%):",
                      //                 style: TextStyle(fontWeight: FontWeight.bold)),
                      //             Text("₹${item['sgst'].toStringAsFixed(2)}"),
                      //           ],
                      //         ),
                      //       ],
                      //       Divider(height: 20),
                      //       Row(
                      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //         children: [
                      //           Text("TOTAL:", style: TextStyle(
                      //             fontWeight: FontWeight.bold,
                      //             fontSize: 16,
                      //             color: theme.primaryColor,
                      //           )),
                      //           Text("₹${item['total'].toStringAsFixed(2)}", style: TextStyle(
                      //             fontWeight: FontWeight.bold,
                      //             fontSize: 16,
                      //             color: theme.primaryColor,
                      //           )),
                      //         ],
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
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
                        _buildCompactSummaryRow(
                          "Subtotal:",
                          getTotal('subtotal'),
                        ),
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
                        _buildCompactSummaryRow(
                          "TOTAL:",
                          getTotal('total'),
                          isTotal: true,
                        ),
                        SizedBox(height: 8),
                        _buildCompactFormField(
                          controller: paidAmountCtrl,
                          label: "Paid Amount",
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty)
                              return 'Enter amount';
                            final paid = double.tryParse(val) ?? 0;
                            final total = getTotal('total');
                            if (paid > total)
                              return 'Cannot pay more than total';
                            return null;
                          },
                          onChanged: (val) {
                            setState(() {
                              // Update unpaid amount when paid amount changes
                              final paid = double.tryParse(val) ?? 0;
                              final total = getTotal('total');
                              unpaidAmountCtrl.text = (total - paid)
                                  .toStringAsFixed(2);
                            });
                          },
                        ),
                        _buildCompactSummaryRow(
                          "Unpaid Amount:",
                          getTotal('total') -
                              (double.tryParse(paidAmountCtrl.text) ?? 0),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Save Button
              if (UserSession.canEdit('Invoice') ||
                  UserSession.canCreate('Invoice'))
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

  // Compact summary row
  Widget _buildCompactSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
  }) {
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
