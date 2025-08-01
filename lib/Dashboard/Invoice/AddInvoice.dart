import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Database/UserRepository.dart';
import '../../Model/InvoiceModel.dart';

class AddInvoice extends StatefulWidget {
  const AddInvoice({Key? key}) : super(key: key);

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

  String selectedFirm = "MAHADEV ENTERPRISE";
  String gstValue = "Yes";

  List<Map<String, dynamic>> products = [];

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
      });
    });
  }

  double getTotal() {
    double total = 0.0;
    for (var item in products) {
      double amount = (item['price'] ?? 0) * (item['qty'] ?? 1);
      double disAmt = amount * ((item['discount_percent'] ?? 0) / 100);
      double net = amount - disAmt;
      double gstAmt = net * ((item['gst_percent'] ?? 0) / 100);
      total += net + gstAmt;
    }
    return total;
  }

  Future<void> saveInvoice() async {
    final invoice = InvoiceModel(
      yourFirm: selectedFirm,
      customerName: customerCtrl.text,
      customerFirm: customerFirmCtrl.text,
      date: dateCtrl.text,
      isGst: gstValue == "Yes" ? 1 : 0,
      invoiceNo: invoiceNoCtrl.text,
      shipTo: shipToCtrl.text,
      transport: transportCtrl.text,
      productDetails: jsonEncode(products),
      amount: products.fold(0, (sum, item) => sum + ((item['price'] ?? 0) * (item['qty'] ?? 1))),
      discount: products.fold(0, (sum, item) => sum + ((item['price'] ?? 0) * (item['qty'] ?? 1)) * ((item['discount_percent'] ?? 0) / 100)),
      subtotal: products.fold(0, (sum, item) => sum + ((item['price'] ?? 0) * (item['qty'] ?? 1)) * (1 - ((item['discount_percent'] ?? 0) / 100))),
      tax: products.fold(0, (sum, item) {
        final amount = (item['price'] ?? 0) * (item['qty'] ?? 1);
        final discount = amount * ((item['discount_percent'] ?? 0) / 100);
        final net = amount - discount;
        return sum + (net * ((item['gst_percent'] ?? 0) / 100));
      }),
      total: getTotal(),
    );

    await repo.addInvoice(invoice);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invoice Saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Invoice")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Basic Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Your Firm"),
                value: selectedFirm,
                items: ["MAHADEV ENTERPRISE", "XYZ FIRM"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => selectedFirm = val!),
              ),
              TextFormField(controller: customerCtrl, decoration: const InputDecoration(labelText: "Customer")),
              TextFormField(controller: customerFirmCtrl, decoration: const InputDecoration(labelText: "Customer Firm")),
              TextFormField(
                controller: dateCtrl,
                readOnly: true,
                onTap: () async {
                  DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030));
                  if (date != null) {
                    dateCtrl.text = DateFormat("dd/MM/yyyy").format(date);
                  }
                },
                decoration: const InputDecoration(labelText: "Date"),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Text("Is GST?"),
                Radio<String>(
                    value: "Yes",
                    groupValue: gstValue,
                    onChanged: (val) => setState(() => gstValue = val!)
                ),
                const Text("Yes"),
                Radio<String>(
                    value: "No",
                    groupValue: gstValue,
                    onChanged: (val) => setState(() => gstValue = val!)
                ),
                const Text("No"),
              ]),
              TextFormField(controller: invoiceNoCtrl, decoration: const InputDecoration(labelText: "Invoice No")),
              TextFormField(controller: shipToCtrl, decoration: const InputDecoration(labelText: "Ship To")),
              TextFormField(controller: transportCtrl, decoration: const InputDecoration(labelText: "Transport")),
              const SizedBox(height: 20),
              const Text("Product Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...products.asMap().entries.map((entry) {
                int index = entry.key;
                var item = entry.value;
                return Row(children: [
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: "Product"), onChanged: (val) => item['product'] = val)),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: "Desc"), onChanged: (val) => item['desc'] = val)),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number, onChanged: (val) => item['price'] = double.tryParse(val) ?? 0.0)),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: "Qty"), keyboardType: TextInputType.number, onChanged: (val) => item['qty'] = int.tryParse(val) ?? 1)),
                ]);
              }),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: addEmptyProductRow, child: const Text("Add new product")),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) saveInvoice();
                },
                child: const Text("Save Invoice"),
              ),
              const SizedBox(height: 10),
              Text("Total: ₹ ${getTotal().toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
