import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../Database/UserRepository.dart';
import '../../Library/UserSession.dart';
import '../../Model/InvoiceModel.dart';

class AddInvoice extends StatefulWidget {
  final InvoiceModel? invoiceToEdit; // Add this line
  const AddInvoice({Key? key, this.invoiceToEdit}) : super(key: key);

  @override
  State<AddInvoice> createState() => _AddInvoiceState();
}

class _AddInvoiceState extends State<AddInvoice> {
  final _formKey = GlobalKey<FormState>();
  final repo = UserRepository();

  final TextEditingController customerCtrl = TextEditingController();
  final TextEditingController customerFirmCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController(
      text: DateFormat("dd/MM/yyyy").format(DateTime.now()));
  final TextEditingController invoiceNoCtrl = TextEditingController(text: "2024-2500002");
  final TextEditingController shipToCtrl = TextEditingController();
  final TextEditingController transportCtrl = TextEditingController();
  final TextEditingController customerMobileCtrl = TextEditingController();
  final TextEditingController customerAddressCtrl = TextEditingController();
  final TextEditingController paidAmountCtrl = TextEditingController(text: "0");
  final TextEditingController gstNumberCtrl = TextEditingController();

  final List<String> transportOptions = ['Road', 'Air', 'Sea', 'Courier', 'Other'];
  String selectedTransport = '';

  String selectedFirm = "MAHADEV ENTERPRISE";
  String gstValue = "Yes";

  List<Map<String, dynamic>> products = [];
  bool get isEditMode => widget.invoiceToEdit != null;
  void addEmptyProductRow() {
    setState(() {
      products.add({
        "product": "",
        "desc": "",
        "price": 0.0,
        "qty": 1,
        "discount_percent": 0.0,
        "discount_amount": 0.0,
        "gst_percent": 0.0,
        "gst_amount": 0.0,
        "subtotal": 0.0,
        "total": 0.0,
      });
    });
  }

  void updateProductCalculation(int index) {
    final item = products[index];
    double amount = (item['price'] ?? 0) * (item['qty'] ?? 1);
    double discountAmt = amount * ((item['discount_percent'] ?? 0) / 100);
    double net = amount - discountAmt;
    double gstAmt = net * ((item['gst_percent'] ?? 0) / 100);
    double total = net + gstAmt;

    setState(() {
      item['discount_amount'] = discountAmt;
      item['gst_amount'] = gstAmt;
      item['subtotal'] = net;
      item['total'] = total;
    });
  }

  double getTotalAmount(String key) {
    return products.fold<double>(
      0.0,
          (sum, item) {
        final val = item[key];
        if (val == null) return sum;
        if (val is int) return sum + val.toDouble();
        if (val is double) return sum + val;
        return sum;
      },
    );
  }
  Future<void> saveInvoice() async {

    final paidAmt = double.tryParse(paidAmountCtrl.text) ?? 0.0;
    final totalAmount = getTotalAmount('total');  // this returns num
    final unpaidAmt = (totalAmount - paidAmt).clamp(0, double.infinity);

    final invoice = InvoiceModel(
      id: isEditMode ? widget.invoiceToEdit!.id : null, // ✅ Preserve the ID for update
      yourFirm: selectedFirm,
      customerName: customerCtrl.text,
      customerFirm: customerFirmCtrl.text,
      customerMobile: customerMobileCtrl.text,
      customerAddress: customerAddressCtrl.text,
      date: dateCtrl.text,
      isGst: gstValue == "Yes" ? 1 : 0,
      invoiceNo: invoiceNoCtrl.text,
      shipTo: shipToCtrl.text,
      transport: selectedTransport,
      productDetails: jsonEncode(products),
      amount: getTotalAmount('price'),
      discount: getTotalAmount('discount_amount'),
      subtotal: getTotalAmount('subtotal'),
      tax: getTotalAmount('gst_amount'),
      total: getTotalAmount('total'),
      paidAmount: paidAmt,
      unpaidAmount: unpaidAmt.toDouble(),
      gstNumber: gstValue == "Yes" ? gstNumberCtrl.text : null,
    );

    if (isEditMode) {
      await repo.updateInvoice(invoice); // You need to add this method in your repo
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invoice Updated")));
    } else {
      await repo.addInvoice(invoice);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invoice Saved")));
    }
    Navigator.pop(context, true); // Return true to indicate saved/updated
  }

  @override
  void initState() {
    super.initState();
    print(UserSession.canEdit('Customer'));
    paidAmountCtrl.addListener(() {
      setState(() {}); // updates unpaid amount preview as user types
    });
    if (isEditMode) {
      final invoice = widget.invoiceToEdit!;
      customerCtrl.text = invoice.customerName;
      customerFirmCtrl.text = invoice.customerFirm;
      customerMobileCtrl.text = invoice.customerMobile;
      customerAddressCtrl.text = invoice.customerAddress;
      dateCtrl.text = invoice.date;
      invoiceNoCtrl.text = invoice.invoiceNo;
      shipToCtrl.text = invoice.shipTo;
      selectedTransport = invoice.transport;
      gstValue = invoice.isGst == 1 ? "Yes" : "No";
      gstNumberCtrl.text = invoice.gstNumber ?? "";
      paidAmountCtrl.text = invoice.paidAmount.toString();

      // Decode and assign product details
      if (invoice.productDetails.isNotEmpty) {
        setState(() {
          products = List<Map<String, dynamic>>.from(jsonDecode(invoice.productDetails));
          for (int i = 0; i < products.length; i++) {
            updateProductCalculation(i);
          }
        });
      }
      else {
        print("Empty");
        products = [];
      }
    } else {
      // Default date and empty product list
      dateCtrl.text = DateFormat("dd/MM/yyyy").format(DateTime.now());
      products = [];
    }
    loadCustomerNames();
  }
  List<String> existingCustomerNames = [];
  bool isLoadingCustomers = true;

  String? selectedCustomerName;

  Future<void> loadCustomerNames() async {
    await repo.init();
    final allInvoices = await repo.getAllInvoices();

    final namesSet = <String>{};
    for (var inv in allInvoices) {
      if (inv.customerName.isNotEmpty) {
        namesSet.add(inv.customerName);
      }
    }

    setState(() {
      existingCustomerNames = namesSet.toList()..sort();
      isLoadingCustomers = false;

      // Optional: if editing invoice, set selectedCustomerName to existing customer
      if (isEditMode) {
        selectedCustomerName = widget.invoiceToEdit?.customerName;
        customerCtrl.text = selectedCustomerName ?? '';
      }
    });
  }
  bool validateDate() {
    if (dateCtrl.text.isEmpty) return false;

    try {
      final inputDate = DateFormat("dd/MM/yyyy").parseStrict(dateCtrl.text);
      final today = DateTime.now();

      if (isEditMode) {
        final originalDate = DateFormat("dd/MM/yyyy").parseStrict(widget.invoiceToEdit!.date);
        // inputDate >= originalDate && inputDate <= today
        if (inputDate.isBefore(originalDate)) return false;
        if (inputDate.isAfter(today)) return false;
      } else {
        // For new invoice, inputDate >= today
        final inputDateOnly = DateTime(inputDate.year, inputDate.month, inputDate.day);
        final todayOnly = DateTime(today.year, today.month, today.day);
        if (inputDateOnly.isBefore(todayOnly)) return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }
  bool validateProducts() {
    if (products.isEmpty) return false;
    for (var p in products) {
      if ((p['product'] ?? '').toString().trim().isEmpty) return false;
      if ((p['price'] == null) || (p['price'] is! num) || (p['price'] <= 0)) return false;
      if ((p['qty'] == null) || (p['qty'] is! int) || (p['qty'] <= 0)) return false;
      if ((p['discount_percent'] == null) || (p['discount_percent'] is! num) || (p['discount_percent'] < 0)) return false;
      if ((p['gst_percent'] == null) || (p['gst_percent'] is! num) || (p['gst_percent'] < 0)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? "Edit Invoice" : "Add Invoice")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Details
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text("Basic Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        value: selectedFirm,
                        items: ["MAHADEV ENTERPRISE", "XYZ FIRM"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => selectedFirm = val!),
                        decoration: const InputDecoration(labelText: "Your Firm"),
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedCustomerName,
                        decoration: const InputDecoration(labelText: "Customer"),
                        items: existingCustomerNames.map((name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedCustomerName = val;

                            if (val != null && val.isNotEmpty) {
                              customerCtrl.text = val;
                            } else {
                              customerCtrl.clear();
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: customerCtrl,
                        decoration: const InputDecoration(labelText: "Customer"),
                        enabled: selectedCustomerName == null, // Editable only if no dropdown selection
                        validator: (val) {
                          if ((selectedCustomerName == null || selectedCustomerName!.isEmpty) && (val == null || val.isEmpty)) {
                            return 'Please enter customer name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(controller: customerFirmCtrl, decoration: const InputDecoration(labelText: "Customer Firm")),
                      TextFormField(
                        controller: customerMobileCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: "Customer Mobile"),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter mobile number';
                          if (!RegExp(r'^\d{10}$').hasMatch(val)) return 'Mobile number must be 10 digits';
                          return null;
                        },
                      ),
                      TextFormField(controller: customerAddressCtrl, decoration: const InputDecoration(labelText: "Customer Address")),
                      TextFormField(
                        controller: dateCtrl,
                        readOnly: true,
                        onTap: () async {
                          DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: isEditMode
                                  ? DateFormat("dd/MM/yyyy").parse(widget.invoiceToEdit!.date)
                                  : DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030));
                          if (date != null) dateCtrl.text = DateFormat("dd/MM/yyyy").format(date);
                        },
                        decoration: const InputDecoration(labelText: "Date"),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please select a date';
                          if (!validateDate()) return 'Date is invalid for this invoice';
                          return null;
                        },
                      ),
                      Row(children: [
                        const Text("Is GST?"),
                        Radio<String>(
                            value: "Yes",
                            groupValue: gstValue,
                            onChanged: (val) => setState(() {
                              gstValue = val!;
                              if (gstValue == "No") {
                                gstNumberCtrl.clear();
                              }
                            })),
                        const Text("Yes"),
                        Radio<String>(
                            value: "No",
                            groupValue: gstValue,
                            onChanged: (val) => setState(() {
                              gstValue = val!;
                              if (gstValue == "No") {
                                gstNumberCtrl.clear();
                              }
                            })),
                        const Text("No"),
                      ]),
                      if (gstValue == "Yes")
                        TextFormField(
                          controller: gstNumberCtrl,
                          decoration: const InputDecoration(labelText: "GST Number"),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            LengthLimitingTextInputFormatter(15),
                          ],
                          validator: (val) {
                            if (gstValue == "Yes") {
                              if (val == null || val.isEmpty) return "Please enter GST Number";
                              if (!RegExp(r'^[a-zA-Z0-9]{15}$').hasMatch(val)) {
                                return "GST Number must be exactly 15 alphanumeric characters";
                              }
                            }
                            return null;
                          },
                        ),
                      TextFormField(controller: invoiceNoCtrl, decoration: const InputDecoration(labelText: "Invoice No")),
                      TextFormField(controller: shipToCtrl, decoration: const InputDecoration(labelText: "Ship To")),
                      DropdownButtonFormField<String>(
                        value: selectedTransport.isNotEmpty ? selectedTransport : null,
                        decoration: const InputDecoration(labelText: "Transport"),
                        items: transportOptions
                            .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(e),
                        ))
                            .toList(),
                        onChanged: (val) => setState(() => selectedTransport = val ?? ''),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please select transport';
                          return null;
                        },
                      ),                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // Product Table
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text("Product Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ...products.asMap().entries.map((entry) {
                        int i = entry.key;
                        var item = entry.value;
                        return Row(children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: item['product']?.toString() ?? '',
                              onChanged: (val) {
                                setState(() {
                                  item['product'] = val;
                                });
                              },
                              decoration: const InputDecoration(labelText: "Product"),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: item['desc']?.toString() ?? '',
                              onChanged: (val) {
                                setState(() {
                                  item['desc'] = val;
                                });
                              },
                              decoration: const InputDecoration(labelText: "Desc"),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: (item['price'] ?? 0).toString(),
                              onChanged: (val) {
                                setState(() {
                                  item['price'] = double.tryParse(val) ?? 0;
                                  updateProductCalculation(i);
                                });
                              },
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')), // allows 2 decimals max
                              ],
                              decoration: const InputDecoration(labelText: "Price"),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              initialValue: (item['qty'] ?? 1).toString(),
                              onChanged: (val) {
                                setState(() {
                                  item['qty'] = int.tryParse(val) ?? 1;
                                  updateProductCalculation(i);
                                });
                              },
                              decoration: const InputDecoration(labelText: "Qty"),
                            ),
                          ),
                          Expanded(
                            child: Text("₹ ${(item['price'] ?? 0) * (item['qty'] ?? 1)}"),
                          ),
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              initialValue: (item['discount_percent'] ?? 0.0).toString(),
                              onChanged: (val) {
                                setState(() {
                                  item['discount_percent'] = double.tryParse(val) ?? 0.0;
                                  updateProductCalculation(i);
                                });
                              },
                              decoration: const InputDecoration(labelText: "Dis.%"),
                            ),
                          ),
                          Expanded(
                            child: Text("₹ ${item['discount_amount']?.toStringAsFixed(2) ?? '0.00'}"),
                          ),
                          Expanded(
                            child: Text("₹ ${item['subtotal']?.toStringAsFixed(2) ?? '0.00'}"),
                          ),
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              initialValue: (item['gst_percent'] ?? 0.0).toString(),
                              onChanged: (val) {
                                setState(() {
                                  item['gst_percent'] = double.tryParse(val) ?? 0.0;
                                  updateProductCalculation(i);
                                });
                              },
                              decoration: const InputDecoration(labelText: "GST%"),
                            ),
                          ),
                          Expanded(
                            child: Text("₹ ${item['gst_amount']?.toStringAsFixed(2) ?? '0.00'}"),
                          ),
                          Expanded(
                            child: Text("₹ ${item['total']?.toStringAsFixed(2) ?? '0.00'}"),
                          ),

                        ]);
                      }).toList(),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: addEmptyProductRow, child: const Text("Add Product"))
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: paidAmountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Please enter paid amount';
                        final paid = double.tryParse(val);
                        if (paid == null || paid < 0) return 'Invalid paid amount';
                        if (paid > getTotalAmount('total')) return 'Paid amount cannot exceed total';
                        return null;
                      },
                      decoration: const InputDecoration(labelText: "Paid Amount"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Unpaid Amount: ₹ ${(getTotalAmount('total') - (double.tryParse(paidAmountCtrl.text) ?? 0.0)).clamp(0, double.infinity).toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Summary & Save
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Subtotal: ₹ ${getTotalAmount('subtotal').toStringAsFixed(2)}"),
                      Text("Discount: ₹ ${getTotalAmount('discount_amount').toStringAsFixed(2)}"),
                      Text("GST: ₹ ${getTotalAmount('gst_amount').toStringAsFixed(2)}"),
                      Text("Total: ₹ ${getTotalAmount('total').toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Visibility(
                        visible: UserSession.canEdit('Customer'),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (!validateProducts()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please fill all product fields correctly")),
                                );
                                return;
                              }
                              try {
                                await saveInvoice();
                              } catch (e, stack) {
                                // Print error to console
                                print('Error saving invoice: $e\n$stack');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to save invoice: $e')),
                                );
                              }
                            }
                          },
                          child: Text(isEditMode ? "Update Invoice" : "Save Invoice"),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
