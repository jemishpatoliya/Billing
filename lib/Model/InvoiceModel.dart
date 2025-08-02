class InvoiceModel {
  int? id;
  String yourFirm;
  String customerName;
  String customerFirm;
  String customerMobile;
  String customerAddress;
  String date;
  int isGst;
  String invoiceNo;
  String shipTo;
  String transport;
  String productDetails;
  double amount;
  double discount;
  double subtotal;
  double tax;
  double total;
  double paidAmount;
  double unpaidAmount;
  final String? gstNumber;  // Add this field

  InvoiceModel({
    this.id,
    required this.yourFirm,
    required this.customerName,
    required this.customerFirm,
    required this.customerMobile,
    required this.customerAddress,
    required this.date,
    required this.isGst,
    required this.invoiceNo,
    required this.shipTo,
    required this.transport,
    required this.productDetails,
    required this.amount,
    required this.discount,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paidAmount,
    required this.unpaidAmount,
    this.gstNumber,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'your_firm': yourFirm,
    'customer_name': customerName,
    'customer_firm': customerFirm,
    'customer_mobile': customerMobile,
    'customer_address': customerAddress,
    'date': date,
    'is_gst': isGst,
    'invoice_no': invoiceNo,
    'ship_to': shipTo,
    'transport': transport,
    'product_details': productDetails,
    'amount': amount,
    'discount': discount,
    'subtotal': subtotal,
    'tax': tax,
    'total': total,
    'paid_amount': paidAmount,
    'unpaid_amount': unpaidAmount,
    'gst_number': gstNumber,
  };

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'],
      yourFirm: map['your_firm'],
      customerName: map['customer_name'],
      customerFirm: map['customer_firm'],
      customerMobile: map['customer_mobile'],
      customerAddress: map['customer_address'],
      date: map['date'],
      isGst: map['is_gst'],
      invoiceNo: map['invoice_no'],
      shipTo: map['ship_to'],
      transport: map['transport'],
      productDetails: map['product_details'],
      amount: map['amount'] * 1.0,
      discount: map['discount'] * 1.0,
      subtotal: map['subtotal'] * 1.0,
      tax: map['tax'] * 1.0,
      total: map['total'] * 1.0,
      paidAmount: map['paid_amount'] * 1.0,
      unpaidAmount: map['unpaid_amount'] * 1.0,
      gstNumber: map['gst_number'],
    );
  }
}
