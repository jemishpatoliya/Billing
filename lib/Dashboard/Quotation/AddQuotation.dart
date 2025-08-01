import 'package:flutter/material.dart';

class AddQuotation extends StatefulWidget {
  @override
  _AddQuotationState createState() => _AddQuotationState();
}

class _AddQuotationState extends State<AddQuotation> {
  final TextEditingController quotationNoController = TextEditingController(text: "00001");
  final TextEditingController quotationNoteController = TextEditingController();

  bool isGST = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Quotation')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Your Firm & Customer Section
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    items: ['MAHADEV ENTERPRISE']
                        .map((firm) => DropdownMenuItem(value: firm, child: Text(firm)))
                        .toList(),
                    onChanged: (_) {},
                    decoration: InputDecoration(labelText: 'Your Firm'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(decoration: InputDecoration(labelText: 'Customer')),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Date & GST Section
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Date'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Text('Is GST?'),
                      Radio(value: true, groupValue: isGST, onChanged: (val) => setState(() => isGST = true)),
                      Text('Yes'),
                      Radio(value: false, groupValue: isGST, onChanged: (val) => setState(() => isGST = false)),
                      Text('No'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Quotation No and Note
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: quotationNoController,
                    decoration: InputDecoration(labelText: 'Quotation No'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: quotationNoteController,
                    decoration: InputDecoration(labelText: 'Quotation Note'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Product Table Headers
            Container(
              padding: EdgeInsets.all(12),
              color: Colors.grey[300],
              child: Row(
                children: const [
                  Expanded(child: Text('Product')),
                  Expanded(child: Text('Desc')),
                  Expanded(child: Text('Price')),
                  Expanded(child: Text('Qty')),
                  Expanded(child: Text('Amount')),
                  Expanded(child: Text('Dis.%')),
                  Expanded(child: Text('Dis.₹')),
                  Expanded(child: Text('Subtotal')),
                  Expanded(child: Text('GST %')),
                  Expanded(child: Text('GST ₹')),
                  Expanded(child: Text('Total')),
                ],
              ),
            ),

            // Dynamic rows to be added here with ListView.builder (can be added later)

            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Add new row logic
              },
              icon: Icon(Icons.add),
              label: Text('Add new product'),
            ),

            SizedBox(height: 24),

            // Total Summary Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                buildTotalRow('Amount', '0'),
                buildTotalRow('Discount', '0'),
                buildTotalRow('Subtotal', '0'),
                buildTotalRow('Tax', '0'),
                buildTotalRow('Roundoff', '0.00'),
                Divider(),
                buildTotalRow('Total', '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTotalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Container(
            width: 100,
            alignment: Alignment.centerRight,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
