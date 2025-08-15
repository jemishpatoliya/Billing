import 'package:flutter/material.dart';
import '../../Database/UserRepository.dart';

class AddTransport extends StatefulWidget {
  const AddTransport({super.key});

  @override
  State<AddTransport> createState() => _AddTransportState();
}

class _AddTransportState extends State<AddTransport> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController invoiceNoCtrl = TextEditingController();
  final TextEditingController fromCtrl = TextEditingController();
  final TextEditingController toCtrl = TextEditingController();
  final TextEditingController costCtrl = TextEditingController();
  final TextEditingController summaryCtrl = TextEditingController();
  bool _isSubmitting = false;
  List<Map<String, dynamic>> transportList = [];

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
    _loadTransportList();
  }

  Future<void> _generateInvoiceNumber() async {
    String invoiceNo = await UserRepository().generateNextTransportInvoiceNumber();
    setState(() => invoiceNoCtrl.text = invoiceNo);
  }

  Future<void> _loadTransportList() async {
    final list = await UserRepository().getAllTransport();
    setState(() => transportList = list);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await UserRepository().addTransport({
        'invoice_no': invoiceNoCtrl.text.trim(),
        'from_location': fromCtrl.text.trim(),
        'to_location': toCtrl.text.trim(),
        'cost': double.parse(costCtrl.text.trim()),
        'summary': summaryCtrl.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transport added successfully!')),
      );

      // Clear form and reload data
      fromCtrl.clear();
      toCtrl.clear();
      costCtrl.clear();
      summaryCtrl.clear();
      await _loadTransportList();
      await _generateInvoiceNumber();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Management'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransportList,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Add New Transport',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: invoiceNoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Number',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: fromCtrl,
                              decoration: const InputDecoration(
                                labelText: 'From Location',
                                prefixIcon: Icon(Icons.location_on),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: toCtrl,
                              decoration: const InputDecoration(
                                labelText: 'To Location',
                                prefixIcon: Icon(Icons.location_on),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: costCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Transport Cost (₹)',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          if (val?.isEmpty ?? true) return 'Enter amount';
                          if (double.tryParse(val!) == null) return 'Invalid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: summaryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Summary/Notes',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: _isSubmitting
                            ? const SizedBox.shrink()
                            : const Icon(Icons.save),
                        label: _isSubmitting
                            ? const CircularProgressIndicator()
                            : const Text('Save Transport'),
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Recent Transport Records',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: transportList.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No transport records found'),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: transportList.length,
                      itemBuilder: (context, index) {
                        final item = transportList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.local_shipping, color: Colors.blue),
                            title: Text('Invoice: ${item['invoice_no']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item['from_location']} → ${item['to_location']}'),
                                Text('Cost: ₹${item['cost']}'),
                                if (item['summary']?.isNotEmpty == true)
                                  Text('Notes: ${item['summary']}'),
                              ],
                            ),
                            trailing: Text(
                              '₹${item['cost']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    invoiceNoCtrl.dispose();
    fromCtrl.dispose();
    toCtrl.dispose();
    costCtrl.dispose();
    summaryCtrl.dispose();
    super.dispose();
  }
}