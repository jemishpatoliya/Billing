class InvoiceModel {
  int? id;
  String invoiceNo;
  String date;
  String yourFirm;
  String yourFirmAddress;
  String buyerName;
  String buyerAddress;
  String placeOfSupply;
  String gstinSupplier;
  String gstinBuyer;
  String? poNumber;
  String? mobileNo;
  String productDetails; // JSON-encoded list of items
  double subtotal;
  double cgst;
  double sgst;
  double totalGst;
  double total;
  double roundedTotal;
  String totalInWords;
  String? bankName;
  String? accountNumber;
  String? ifscCode;
  String? transport;
  String? termsConditions;
  String? jurisdiction;
  String? signature;
  final String? hsnSac;
  final String? mm;
  double? paid_amount;
  double? unpaid_amount;
  String? size;
  bool? isGst;
  bool? isOnline;

  InvoiceModel({
    this.id,
    required this.invoiceNo,
    required this.date,
    required this.yourFirm,
    required this.yourFirmAddress,
    required this.buyerName,
    required this.buyerAddress,
    required this.placeOfSupply,
    required this.gstinSupplier,
    required this.gstinBuyer,
    this.poNumber,
    this.mobileNo,
    required this.productDetails,
    required this.subtotal,
    required this.cgst,
    required this.sgst,
    required this.totalGst,
    required this.total,
    required this.roundedTotal,
    required this.totalInWords,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.transport,
    this.termsConditions,
    this.jurisdiction,
    this.signature,
    this.hsnSac,   // new
    this.mm,
    this.paid_amount,
    this.unpaid_amount,
    this.size,
    this.isGst,
    this.isOnline,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoice_no': invoiceNo,
    'date': date,
    'your_firm': yourFirm,
    'your_firm_address': yourFirmAddress,
    'buyer_name': buyerName,
    'buyer_address': buyerAddress,
    'place_of_supply': placeOfSupply,
    'gstin_supplier': gstinSupplier,
    'gstin_buyer': gstinBuyer,
    'po_number': poNumber,
    'mobile_no': mobileNo,
    'product_details': productDetails,
    'subtotal': subtotal,
    'cgst': cgst,
    'sgst': sgst,
    'total_gst': totalGst,
    'total': total,
    'rounded_total': roundedTotal,
    'total_in_words': totalInWords,
    'bank_name': bankName,
    'account_number': accountNumber,
    'ifsc_code': ifscCode,
    'transport': transport,
    'terms_conditions': termsConditions,
    'jurisdiction': jurisdiction,
    'signature': signature,
    'hsnSac': hsnSac,  // new
    'mm': mm,          // new
    'paid_amount': paid_amount,          // new
    'unpaid_amount': unpaid_amount,          // new
    'size': size,          // new
    'isGst': isGst == true ? 1 : 0,       // store as int 0 or 1
    'isOnline': isOnline == true ? 1 : 0, // store as int 0 or 1    // new
  };

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'],
      invoiceNo: map['invoice_no'],
      date: map['date'],
      yourFirm: map['your_firm'],
      yourFirmAddress: map['your_firm_address'],
      buyerName: map['buyer_name'],
      buyerAddress: map['buyer_address'],
      placeOfSupply: map['place_of_supply'],
      gstinSupplier: map['gstin_supplier'],
      gstinBuyer: map['gstin_buyer'],
      poNumber: map['po_number'],
      mobileNo: map['mobile_no'],
      productDetails: map['product_details'],
      subtotal: map['subtotal'] * 1.0,
      cgst: map['cgst'] * 1.0,
      sgst: map['sgst'] * 1.0,
      totalGst: map['total_gst'] * 1.0,
      total: map['total'] * 1.0,
      roundedTotal: map['rounded_total'] * 1.0,
      totalInWords: map['total_in_words'],
      bankName: map['bank_name'],
      accountNumber: map['account_number'],
      ifscCode: map['ifsc_code'],
      transport: map['transport'],
      termsConditions: map['terms_conditions'],
      jurisdiction: map['jurisdiction'],
      signature: map['signature'],
      hsnSac: map['hsnSac'],   // new
      mm: map['mm'],
      paid_amount: map['paid_amount'],
      unpaid_amount: map['unpaid_amount'],
      size: map['size'],
      isGst: (map['isGst'] ?? 0) == 1,     // convert int 0/1 to bool
      isOnline: (map['isOnline'] ?? 0) == 1, // convert int 0/1 to bool
    );
  }
}
