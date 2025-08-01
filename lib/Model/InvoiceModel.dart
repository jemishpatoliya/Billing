class InvoiceModel {
  int? id;
  String yourFirm;
  String customerName;
  String customerFirm;
  String date;
  int isGst;
  String invoiceNo;
  String shipTo;
  String transport;
  String productDetails; // JSON-encoded product rows
  double amount;
  double discount;
  double subtotal;
  double tax;
  double total;

  InvoiceModel({
    this.id,
    required this.yourFirm,
    required this.customerName,
    required this.customerFirm,
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
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'your_firm': yourFirm,
    'customer_name': customerName,
    'customer_firm': customerFirm,
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
  };

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
    id: json['id'],
    yourFirm: json['your_firm'],
    customerName: json['customer_name'],
    customerFirm: json['customer_firm'],
    date: json['date'],
    isGst: json['is_gst'],
    invoiceNo: json['invoice_no'],
    shipTo: json['ship_to'],
    transport: json['transport'],
    productDetails: json['product_details'],
    amount: json['amount'],
    discount: json['discount'],
    subtotal: json['subtotal'],
    tax: json['tax'],
    total: json['total'],
  );
}
