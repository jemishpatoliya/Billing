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
    final TextEditingController gstPercentCtrl = TextEditingController(
      text: "18",
    );
    final TextEditingController discountPercentCtrl = TextEditingController(
      text: "0",
    );

    List<Map<String, dynamic>> products = [];

    bool get isEditMode => widget.invoiceToEdit != null;

    @override
    void initState() {
      super.initState();

      if (isEditMode) {
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
        products = List<Map<String, dynamic>>.from(
          jsonDecode(inv.productDetails),
        );
        hsnSacCtrl.text = inv.hsnSac ?? '';
        mmCtrl.text = inv.mm ?? '';
      } else {
        products = [];
      }
    }

    // Add new product row
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
    }

    // Update calculations for product row
    void updateProduct(int index) {
      final p = products[index];
      double amount = (p['price'] ?? 0) * (p['qty'] ?? 1);
      double discountPercent = p['discount_percent'] ?? 0.0;
      double gstPercent = p['gst_percent'] ?? 0.0;

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

    // Save Invoice (Create or Edit)
    Future<void> saveInvoice() async {
      final subtotal = getTotal('subtotal');
      final gst = getTotal('gst_amount');
      final cgst = gst / 2;
      final sgst = gst / 2;
      final total = getTotal('total');
      final roundedTotal = total.roundToDouble();

      final model = InvoiceModel(
        id: isEditMode ? widget.invoiceToEdit!.id : null, // 👈 Important
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
        hsnSac: hsnSacCtrl.text,   // new
        mm: mmCtrl.text,
      );

      if (isEditMode) {
        await repo.updateInvoice(model);
      } else {
        await repo.addInvoice(model);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Invoice updated successfully' : 'Invoice added successfully'),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text(isEditMode ? "Update Invoice" : "Add Invoice")),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Invoice Fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: invoiceNoCtrl,
                      decoration: const InputDecoration(labelText: "Invoice No"),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: dateCtrl,
                      readOnly: true, // Prevent manual typing
                      decoration: const InputDecoration(labelText: "Date"),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode()); // Dismiss keyboard
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(), // Prevent future date
                        );
                        if (picked != null) {
                          dateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
                        }
                      },
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
                    ),
                  ),

                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: yourFirmCtrl,
                      decoration: const InputDecoration(labelText: "Your Firm"),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: yourFirmAddressCtrl,
                      decoration: const InputDecoration(
                        labelText: "Your Firm Address",
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: buyerNameCtrl,
                      decoration: const InputDecoration(labelText: "Buyer Name"),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: buyerAddressCtrl,
                      decoration: const InputDecoration(
                        labelText: "Buyer Address",
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: placeOfSupplyCtrl,
                      decoration: const InputDecoration(
                        labelText: "Place of Supply",
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: gstinSupplierCtrl,
                      decoration: const InputDecoration(labelText: "GSTIN Supplier"),
                      validator: (val) {
                        if (val == null || val.trim().length != 15 || !RegExp(r'^[A-Za-z0-9]+$').hasMatch(val)) {
                          return 'Must be 15 alphanumeric characters';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: gstinBuyerCtrl,
                      decoration: const InputDecoration(labelText: "GSTIN Buyer"),
                      validator: (val) {
                        if (val == null || val.trim().length != 15 || !RegExp(r'^[A-Za-z0-9]+$').hasMatch(val)) {
                          return 'Must be 15 alphanumeric characters';
                        }
                        return null;
                      },
                    ),
                  ),

                  Expanded(
                    child: TextFormField(
                      controller: poNumberCtrl,
                      decoration: const InputDecoration(labelText: "PO Number"),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: mobileNoCtrl,
                      maxLength: 10,
                      decoration: const InputDecoration(labelText: "Mobile No"),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (val) {
                        if (val == null || !RegExp(r'^\d{10}$').hasMatch(val)) {
                          return 'Enter valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: bankNameCtrl,
                      decoration: const InputDecoration(labelText: "Bank Name"),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: accountNumberCtrl,
                      decoration: const InputDecoration(labelText: "Account Number"),
                      keyboardType: TextInputType.number,
                      maxLength: 14,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Account number is required';
                        }
                        if (val.length < 6 || val.length > 14) {
                          return 'Enter 6 to 14 digits only';
                        }
                        return null;
                      },
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: ifscCodeCtrl,
                      maxLength: 11,
                      decoration: const InputDecoration(labelText: "IFSC Code"),
                      validator: (val) {
                        if (val == null || val.length != 11 || !RegExp(r'^[A-Z|a-z]{4}0[A-Z0-9]{6}$').hasMatch(val)) {
                          return 'Invalid IFSC code';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: transportCtrl,
                      decoration: const InputDecoration(labelText: "Transport"),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: termsCtrl,
                      decoration: const InputDecoration(
                        labelText: "Terms & Conditions",
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: jurisdictionCtrl,
                      decoration: const InputDecoration(
                        labelText: "Jurisdiction",
                      ),
                    ),
                  ),

                  Expanded(
                    child: TextFormField(
                      controller: signatureCtrl,
                      decoration: const InputDecoration(labelText: "Signature"),
                    ),
                  ),
                ],
              ),
              // Add Product Button
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text("Add Product"),
                onPressed: addEmptyProduct,
              ),
              const SizedBox(height: 10),

              ...products.asMap().entries.map((entry) {
                int index = entry.key;
                var item = entry.value;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item['product'],
                            decoration: InputDecoration(labelText: "Product Name"),
                            onChanged: (val) => item['product'] = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item['desc'],
                            decoration: InputDecoration(labelText: "Description"),
                            onChanged: (val) => item['desc'] = val,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item['hsnSac'] ?? '',
                            decoration: InputDecoration(labelText: "HSN/SAC"),
                            onChanged: (val) {
                              setState(() {
                                item['hsnSac'] = val;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            initialValue: item['mm'] ?? '',
                            decoration: InputDecoration(labelText: "MM"),
                            onChanged: (val) {
                              setState(() {
                                item['mm'] = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item['price'].toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: "Price"),
                            validator: (val) {
                              if (val == null || double.tryParse(val) == null) return 'Invalid';
                              return null;
                            },
                            onChanged: (val) {
                              item['price'] = double.tryParse(val) ?? 0.0;
                              updateProduct(index);
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item['qty'].toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: "Qty"),
                            onChanged: (val) {
                              item['qty'] = int.tryParse(val) ?? 1;
                              updateProduct(index);
                            },
                            validator: (val) {
                              if (val == null || double.tryParse(val) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item['discount_percent'].toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: "Discount %"),
                            onChanged: (val) {
                              item['discount_percent'] = double.tryParse(val) ?? 0.0;
                              updateProduct(index);
                            },
                            validator: (val) {
                              if (val == null || double.tryParse(val) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: Text("Amount: ₹${(item['price'] ?? 0) * (item['qty'] ?? 1)}")),
                        Expanded(child: Text("Discount: ₹${item['discount_amount'].toStringAsFixed(2)}")),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: Text("CGST: ₹${item['cgst'].toStringAsFixed(2)}")),
                        Expanded(child: Text("SGST: ₹${item['sgst'].toStringAsFixed(2)}")),
                        Expanded(child: Text("Total: ₹${item['total'].toStringAsFixed(2)}")),
                      ],
                    ),
                    Divider(),
                  ],
                );
              }).toList(),

              Divider(thickness: 2),
              Text("Subtotal: ₹${getTotal('subtotal').toStringAsFixed(2)}"),
              Text("Total GST: ₹${getTotal('gst_amount').toStringAsFixed(2)}"),
              Text("Total: ₹${getTotal('total').toStringAsFixed(2)}"),
              Visibility(
                visible: UserSession.canEdit('Invoice') || UserSession.canCreate('Invoice'),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await saveInvoice(); // Save the invoice if validation passes
                    }
                  },
                  child: Text(isEditMode ? "Update Invoice" : "Save Invoice"),
                ),
              )
            ],
          ),
        ),
      );
    }
  }
