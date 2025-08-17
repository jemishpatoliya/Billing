# billingsystem

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,

Live --------------------------------------------------------------

Steps to Send Data from Flutter to Google Sheets
1. Create a Google Cloud Project & Enable Sheets API

Go to Google Cloud Console.

Create a new project (or select your existing one).

Search for "Google Sheets API" → Enable it.

Search for "Google Drive API" → Enable it (needed for file access).

Go to APIs & Services → Credentials.

Create Service Account → give it Editor role.

Download the JSON credentials file (credentials.json).

2. Share Your Sheet with the Service Account

Open your Google Sheet:
https://docs.google.com/spreadsheets/d/1nUOrjiR9uUoxjf1GBSmVmtxA8ArJksWXEaTMELo-P4c/edit

Copy the Service Account email from the JSON file.
(Looks like: my-service-account@myproject.iam.gserviceaccount.com)

Share the sheet with Edit access to that email.

3. Flutter Dependencies

In pubspec.yaml:

dependencies:
gsheets: ^0.4.2


Run:

flutter pub get

4. Code to Connect and Update Google Sheet
   import 'dart:convert';
   import 'package:flutter/services.dart';
   import 'package:gsheets/gsheets.dart';

const _spreadsheetId = '1nUOrjiR9uUoxjf1GBSmVmtxA8ArJksWXEaTMELo-P4c'; // your sheet ID

late GSheets _gsheets;
late Spreadsheet _spreadsheet;

Future<void> initGoogleSheets() async {
// Load credentials
final credentials = json.decode(await rootBundle.loadString('assets/credentials.json'));
_gsheets = GSheets(credentials);

// Open spreadsheet
_spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);
}

Future<void> addRowToSheet(List<String> row) async {
final sheet = _spreadsheet.worksheetByTitle('Sheet1'); // Change to your sheet name
if (sheet != null) {
await sheet.values.appendRow(row);
print("✅ Row added: $row");
} else {
print("❌ Sheet not found");
}
}

5. Usage
   await initGoogleSheets();
   await addRowToSheet(["Invoice No", "Customer Name", "Amount"]);
   await addRowToSheet(["INV-001", "John Doe", "₹1500"]);


✅ Now, whenever your app calls addRowToSheet, data will instantly appear in your live Google Sheet — no desktop save, no manual upload.
We can also make it run every 1 hour automatically for live sync.

If you want, I can merge this Google Sheets sync into your existing Flutter DB backup/export function so your SQLite data auto-uploads every hour to that live sheet.
Do you want me to do that?
























// --- PDF Import & Auto-fill ---
Future<void> importPdf() async {
try {
FilePickerResult? result = await FilePicker.platform.pickFiles(
type: FileType.custom,
allowedExtensions: ['pdf'],
);

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final bytes = await File(path).readAsBytes();
        final pdfDoc = PdfDocument(inputBytes: bytes);

        setState(() {
          importedPdfName = result.files.single.name; // Save file name
        });

        final textExtractor = PdfTextExtractor(pdfDoc);
        final pageText = textExtractor.extractText(
            startPageIndex: 0, endPageIndex: pdfDoc.pages.count - 1);

        parsePdfText(pageText);
      }
    } catch (e) {
      print('Error picking file: $e');
    }
}

void parsePdfText(String text) {

    final lines = text.split('\n').map((e) => e.trim()).toList();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Invoice Number
      if (line.startsWith('Invoice No')) {
        final parts = line.split('-');
        if (parts.length > 1) invoiceNumberController.text = parts[1].trim();
      }

      // Buyer (Bill to)
      if (line.startsWith('Buyer (Bill to)')) {
        if (i + 1 < lines.length) companyNameController.text = lines[i + 1];
        if (i + 2 < lines.length) companyAddressController.text = lines[i + 2] + ', ' + (i + 3 < lines.length ? lines[i + 3] : '');
      }

      // Product Name
      if (line.startsWith('No. Goods and Services')) {
        final parts = line.split('-');
        if (parts.length > 1) productNameController.text = parts[1].trim();
      }

      // Rate
      if (line.startsWith('Rate')) {
        final parts = line.split('-');
        if (parts.length > 1) rateController.text = parts[1].trim();
      }
    }
    // Company Name
    final companyNameMatch = RegExp(r'Company Name[:\s]+(.+)').firstMatch(text);
    if (companyNameMatch != null) {
      companyNameController.text = companyNameMatch.group(1)!.trim();
    }

    // Company Address
    final companyAddressMatch = RegExp(r'Company Address[:\s]+(.+)').firstMatch(text);
    if (companyAddressMatch != null) {
      companyAddressController.text = companyAddressMatch.group(1)!.trim();
    }

    // GST IN
    final gstMatch = RegExp(r'GST\s*IN[:\s]+(.+)').firstMatch(text);
    if (gstMatch != null) {
      companyGstController.text = gstMatch.group(1)!.trim();
    }

    // Email
    final emailMatch = RegExp(r'Email[:\s]+(.+)').firstMatch(text);
    if (emailMatch != null) {
      companyEmailController.text = emailMatch.group(1)!.trim();
    }

    // // Invoice Number
    // final invoiceMatch = RegExp(r'Invoice\s*(No|Number)[:\s]+(.+)').firstMatch(text);
    // if (invoiceMatch != null) {
    //   invoiceNumberController.text = invoiceMatch.group(2)!.trim();
    // }
    //
    // // Product Name
    // final productMatch = RegExp(r'Product Name[:\s]+(.+)').firstMatch(text);
    // if (productMatch != null) {
    //   productNameController.text = productMatch.group(1)!.trim();
    // }

    // HSN/SAC
    final hsnMatch = RegExp(r'HSN/SAC[:\s]+(.+)').firstMatch(text);
    if (hsnMatch != null) {
      hsnSacController.text = hsnMatch.group(1)!.trim();
    }

    // Rate
    final rateMatch = RegExp(r'Rate[:\s]+([\d.]+)').firstMatch(text);
    if (rateMatch != null) {
      rateController.text = rateMatch.group(1)!.trim();
    }

    // Color
    final colorMatch = RegExp(r'Color[:\s]+(.+)').firstMatch(text);
    if (colorMatch != null) {
      colorController.text = colorMatch.group(1)!.trim();
    }

    // Color Code
    final colorCodeMatch = RegExp(r'Color Code[:\s]+(.+)').firstMatch(text);
    if (colorCodeMatch != null) {
      colorCodeController.text = colorCodeMatch.group(1)!.trim();
    }

    // Total
    final totalMatch = RegExp(r'Total[:\s]+([\d.]+)').firstMatch(text);
    if (totalMatch != null) {
      totalController.text = totalMatch.group(1)!.trim();
    }

    // GST Amount
    final gstAmountMatch = RegExp(r'GST[:\s]+([\d.]+)').firstMatch(text);
    if (gstAmountMatch != null) {
      gstController.text = gstAmountMatch.group(1)!.trim();
    }

    // Final Amount
    final finalAmountMatch = RegExp(r'Final Amount[:\s]+([\d.]+)').firstMatch(text);
    if (finalAmountMatch != null) {
      finalAmountController.text = finalAmountMatch.group(1)!.trim();
    }

    // Dispatch From
    final dispatchMatch = RegExp(r'Dispatch From[:\s]+(.+)').firstMatch(text);
    if (dispatchMatch != null) {
      dispatchFromController.text = dispatchMatch.group(1)!.trim();
    }

    // Ship To
    final shipToMatch = RegExp(r'Ship To[:\s]+(.+)').firstMatch(text);
    if (shipToMatch != null) {
      shipToController.text = shipToMatch.group(1)!.trim();
    }
}


actions: [
Row(
children: [
IconButton(
icon: const Icon(Icons.picture_as_pdf),
onPressed: importPdf, // Import PDF button
),
if (importedPdfName != null)
Padding(
padding: const EdgeInsets.only(right: 16),
child: Text(
importedPdfName!,
style: const TextStyle(
fontWeight: FontWeight.bold, fontSize: 14),
),
),
],
),
],























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
}

class PurchaseDetailScreen extends StatelessWidget {
final PurchaseModel purchase;

    PurchaseDetailScreen({Key? key, required this.purchase}) : super(key: key);

    Future<List<Map<String, dynamic>>> ensureSKUsGenerated() async {
      // If already generated, just return
      if (purchase.skuItems != null && purchase.skuItems!.isNotEmpty) {
        return purchase.skuItems!;
      }

      // Load last counter once
      final prefs = await SharedPreferences.getInstance();
      GlobalSKU.counter = prefs.getInt('last_sku_counter') ?? 1;

      List<Map<String, dynamic>> skuList = [];

      for (var prod in purchase.products ?? []) {
        final qty = prod.qty ?? 0;
        for (int i = 0; i < qty; i++) {
          String sku = "SK${GlobalSKU.counter.toString().padLeft(8, '0')}";
          skuList.add({
            "product": prod,
            "sku": sku,
            "index": i + 1,
          });
          GlobalSKU.counter++;
        }
      }

      purchase.skuItems = skuList;

      // Save last counter after generation
      await prefs.setInt('last_sku_counter', GlobalSKU.counter);

      return skuList;
    }

    Future<void> generateQRCodePDF(List<Map<String, dynamic>> skuItems) async {
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
                      "invoice": purchase.invoiceNo
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
      final pdfFile = File("${dir.path}/invoice_${purchase.invoiceNo}.pdf");
      await pdfFile.create(recursive: true);
      await pdfFile.writeAsBytes(await pdf.save());

      if (await pdfFile.exists()) {
        await launchUrl(Uri.file(pdfFile.path));
      }
    }

    @override
    Widget build(BuildContext context) {
      final products = purchase.products ?? [];

      return Scaffold(
        appBar: AppBar(title: Text("Invoice: ${purchase.invoiceNo ?? "-"}")),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: ensureSKUsGenerated(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final skuItems = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ...products.map((prod) {
                  final prodSkus = skuItems.where((item) => item["product"] == prod).toList();
                  return ExpansionTile(
                    title: Text(prod.productName ?? "Unnamed Product"),
                    subtitle: Text("Rate: ₹${prod.rate ?? 0}, Color: ${prod.colour ?? "-"}, Qty: ${prod.qty ?? 0}"),
                    children: prodSkus.map((item) {
                      final sku = item["sku"] as String;
                      final idx = item["index"];
                      return ListTile(
                        title: Text("Item $idx - SKU: $sku"),
                        trailing: Text("₹${prod.rate ?? 0}"),
                      );
                    }).toList(),
                  );
                }),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Generate PDF with QR Codes"),
                  onPressed: () => generateQRCodePDF(skuItems),
                ),
              ],
            );
          },
        ),
      );
    }
}
