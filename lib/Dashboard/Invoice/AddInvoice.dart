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
  final TextEditingController yourFirmCtrl = TextEditingController();
  final TextEditingController yourFirmAddressCtrl = TextEditingController();
  final TextEditingController buyerNameCtrl = TextEditingController();
  final TextEditingController buyerAddressCtrl = TextEditingController();
  final TextEditingController placeOfSupplyCtrl = TextEditingController();
  final TextEditingController gstinSupplierCtrl = TextEditingController();
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
  bool useGST = true;
  bool payOnline = false;

  final TextEditingController gstPercentCtrl = TextEditingController(text: "18");
  final TextEditingController discountPercentCtrl = TextEditingController(text: "0");

  List<Map<String, dynamic>> products = [];

  bool get isEditMode => widget.invoiceToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadInvoiceData();
    } else {
      products = [];
    }
  }

  void _loadInvoiceData() {
    final inv = widget.invoiceToEdit!;
    invoiceNoCtrl.text = inv.invoiceNo;
    dateCtrl.text = inv.date;
    yourFirmCtrl.text = inv.yourFirm;
    yourFirmAddressCtrl.text = inv.yourFirmAddress;
    buyerNameCtrl.text = inv.buyerName;
    buyerAddressCtrl.text = inv.buyerAddress;
    placeOfSupplyCtrl.text = inv.placeOfSupply;
    gstinSupplierCtrl.text = inv.gstinSupplier;
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
    products = List<Map<String, dynamic>>.from(jsonDecode(inv.productDetails));
    hsnSacCtrl.text = inv.hsnSac ?? '';
    mmCtrl.text = inv.mm ?? '';
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

      // Scroll to bottom after adding product
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
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
      p['discount_amount'] = dis;
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

  Future<void> saveInvoice() async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product.')),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final subtotal = getTotal('subtotal');
      final gst = getTotal('gst_amount');
      final cgst = gst / 2;
      final sgst = gst / 2;
      final total = getTotal('total');
      final roundedTotal = total.roundToDouble();

      final model = InvoiceModel(
        id: isEditMode ? widget.invoiceToEdit!.id : null,
        invoiceNo: invoiceNoCtrl.text,
        date: dateCtrl.text,
        yourFirm: yourFirmCtrl.text,
        yourFirmAddress: yourFirmAddressCtrl.text,
        buyerName: buyerNameCtrl.text,
        buyerAddress: buyerAddressCtrl.text,
        placeOfSupply: placeOfSupplyCtrl.text,
        gstinSupplier: gstinSupplierCtrl.text,
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
              content: Text(isEditMode ? 'Invoice updated successfully' : 'Invoice added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
    void Function(String)? onChanged,
    void Function()? onTap, // Added correctly here
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: !enabled,
          fillColor: Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLength: maxLength,
        onChanged: onChanged,
        onTap: onTap, // Moved to be inside TextFormField

      ),
    );
  }

  Widget _buildSwitchOption(String label, bool value, Function(bool) onChanged) {
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
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            controller: _scrollController,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Basic Information'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: invoiceNoCtrl,
                              label: "Invoice No",
                              validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildFormField(
                              controller: dateCtrl,
                              label: "Date",
                              // readOnly: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                try {
                                  final selected = DateFormat('dd/MM/yyyy').parseStrict(value);
                                  final now = DateTime.now();
                                  if (selected.isAfter(now)) {
                                    return 'Future date not allowed';
                                  }
                                } catch (_) {
                                  return 'Invalid date format';
                                }
                                return null;
                              },
                              onTap: () async {
                                FocusScope.of(context).requestFocus(FocusNode());
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  dateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Seller Details'),
                      _buildFormField(
                        controller: yourFirmCtrl,
                        label: "Your Firm",
                        validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
                      ),
                      _buildFormField(
                        controller: yourFirmAddressCtrl,
                        label: "Firm Address",
                        validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
                      ),
                      _buildFormField(
                        controller: gstinSupplierCtrl,
                        label: "GSTIN Supplier",
                        enabled: useGST,
                        validator: (val) {
                          if (!useGST) return null;
                          if (val == null || val.trim().isEmpty) return 'Required';
                          if (val.trim().length != 15 || !RegExp(r'^[A-Za-z0-9]+$').hasMatch(val)) {
                            return 'Must be 15 alphanumeric characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Buyer Details'),
                      _buildFormField(
                        controller: buyerNameCtrl,
                        label: "Buyer Name",
                        validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
                      ),
                      _buildFormField(
                        controller: buyerAddressCtrl,
                        label: "Buyer Address",
                        validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
                      ),
                      _buildFormField(
                        controller: gstinBuyerCtrl,
                        label: "GSTIN Buyer",
                        enabled: useGST,
                        validator: (val) {
                          if (!useGST) return null;
                          if (val == null || val.trim().isEmpty) return 'Required';
                          if (val.trim().length != 15 || !RegExp(r'^[A-Za-z0-9]+$').hasMatch(val)) {
                            return 'Must be 15 alphanumeric characters';
                          }
                          return null;
                        },
                      ),
                      _buildFormField(
                        controller: mobileNoCtrl,
                        label: "Mobile No",
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (val) => val == null || !RegExp(r'^\d{10}$').hasMatch(val)
                            ? 'Enter valid 10-digit number' : null,
                      ),
                      _buildFormField(
                        controller: poNumberCtrl,
                        label: "PO Number",
                      ),
                      _buildFormField(
                        controller: placeOfSupplyCtrl,
                        label: "Place of Supply",
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Settings'),
                      _buildSwitchOption(
                        'Use GST',
                        useGST,
                            (val) {
                          setState(() {
                            useGST = val;
                            if (!useGST) {
                              for (var p in products) {
                                p['gst_percent'] = 0.0;
                              }
                            } else {
                              double gstPercent = double.tryParse(gstPercentCtrl.text) ?? 18.0;
                              for (var p in products) {
                                p['gst_percent'] = gstPercent;
                              }
                            }
                            for (int i = 0; i < products.length; i++) {
                              updateProduct(i);
                            }
                          });
                        },
                      ),
                      _buildSwitchOption(
                        'Pay Online',
                        payOnline,
                            (val) => setState(() => payOnline = val),
                      ),
                      if (payOnline) ...[
                        SizedBox(height: 12),
                        _buildFormField(
                          controller: bankNameCtrl,
                          label: "Bank Name",
                          validator: (val) => payOnline && (val?.isEmpty ?? true)
                              ? 'Required for online payment' : null,
                        ),
                        _buildFormField(
                          controller: accountNumberCtrl,
                          label: "Account Number",
                          keyboardType: TextInputType.number,
                          maxLength: 14,
                          validator: (val) {
                            if (!payOnline) return null;
                            if (val == null || val.isEmpty) return 'Required';
                            if (val.length < 6 || val.length > 14) {
                              return 'Enter 6 to 14 digits only';
                            }
                            return null;
                          },
                        ),
                        _buildFormField(
                          controller: ifscCodeCtrl,
                          label: "IFSC Code",
                          maxLength: 11,
                          validator: (val) {
                            if (!payOnline) return null;
                            if (val == null || val.length != 11 || !RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(val)) {
                              return 'Invalid IFSC code';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Additional Information'),
                      _buildFormField(
                        controller: transportCtrl,
                        label: "Transport",
                        validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
                      ),
                      _buildFormField(
                        controller: termsCtrl,
                        label: "Terms & Conditions",
                        maxLength: 3,
                      ),
                      _buildFormField(
                        controller: jurisdictionCtrl,
                        label: "Jurisdiction",
                      ),
                      _buildFormField(
                        controller: signatureCtrl,
                        label: "Signature",
                        enabled: false,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add, size: 20),
                    label: Text("Add Product"),
                    onPressed: addEmptyProduct,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              if (products.isEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'No products added yet. Click "Add Product" to start.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

              ...products.asMap().entries.map((entry) {
                int index = entry.key;
                var item = entry.value;
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 1,
                  child: Padding(
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
                              child: TextFormField(
                                initialValue: item['product'],
                                decoration: InputDecoration(
                                  labelText: "Product Name",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onChanged: (val) => item['product'] = val,
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
                        SizedBox(height: 12),
                        Row(
                          children: [
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
                            SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: item['mm'] ?? '',
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: "MM",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                initialValue: item['price'].toString(),
                                decoration: InputDecoration(
                                  labelText: "Price",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
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
                                ),
                                keyboardType: TextInputType.number,
                                validator: (val) => val == null || int.tryParse(val) == null ? 'Invalid' : null,
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
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                                onChanged: (val) {
                                  item['discount_percent'] = double.tryParse(val) ?? 0.0;
                                  updateProduct(index);
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Amount:", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text("₹${((item['price'] ?? 0) * (item['qty'] ?? 1)).toStringAsFixed(2)}"),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Discount:", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text("-₹${item['discount_amount'].toStringAsFixed(2)}",
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                              if (useGST) ...[
                                SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("CGST (${(item['gst_percent'] / 2).toStringAsFixed(1)}%):",
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text("₹${item['cgst'].toStringAsFixed(2)}"),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("SGST (${(item['gst_percent'] / 2).toStringAsFixed(1)}%):",
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text("₹${item['sgst'].toStringAsFixed(2)}"),
                                  ],
                                ),
                              ],
                              Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("TOTAL:", style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.primaryColor,
                                  )),
                                  Text("₹${item['total'].toStringAsFixed(2)}", style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.primaryColor,
                                  )),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              if (products.isNotEmpty) ...[
                SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildSectionHeader('Invoice Summary'),
                        _buildSummaryRow("Subtotal:", getTotal('subtotal')),
                        if (useGST) _buildSummaryRow("Total GST:", getTotal('gst_amount')),
                        Divider(height: 24),
                        _buildSummaryRow(
                          "GRAND TOTAL:",
                          getTotal('total'),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              SizedBox(height: 32),

              if (UserSession.canEdit('Invoice') || UserSession.canCreate('Invoice'))
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saveInvoice,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
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
                    ),
                  ],
                ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}