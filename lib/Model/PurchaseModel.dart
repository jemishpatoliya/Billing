import 'dart:convert';

import 'ProductModel.dart';

class PurchaseModel {
  String? id;
  String? purchaseId;
  String? invoiceNo;
  String? createdAt;
  String? companyName;
  String? companyAddress;
  String? companyGstin;
  String? companyEmail;
  List<PurchaseProduct>? products;
  double? finalAmount;
  String? dispatchFrom;
  String? shipTo;
  String? pdfPath;
  List<Map<String, dynamic>>? skuItems;

  PurchaseModel({
    this.id,
    this.purchaseId,
    this.invoiceNo,
    this.createdAt,
    this.companyName,
    this.companyAddress,
    this.companyGstin,
    this.companyEmail,
    this.products,
    this.finalAmount,
    this.dispatchFrom,
    this.shipTo,
    this.pdfPath,
    this.skuItems
  });

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    return PurchaseModel(
      purchaseId: map['purchase_id'],
      companyName: map['company_name'],
      companyAddress: map['company_address'],
      companyGstin: map['company_gstin'],
      invoiceNo: map['invoice_no'],
      finalAmount: map['final_amount'] != null ? map['final_amount'] * 1.0 : null,
      products: map['products'] != null
          ? List<PurchaseProduct>.from(
        (map['products'] as List).map((x) {
          if (x is PurchaseProduct) return x; // already object
          return PurchaseProduct.fromMap(x); // from Map
        }),
      )
          : [],
      skuItems: map['skuItems'] != null
          ? List<Map<String, dynamic>>.from(
          jsonDecode(map['skuItems']) as List)
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'invoice_no': invoiceNo,
      'created_at': createdAt,
      'company_name': companyName,
      'company_address': companyAddress,
      'company_gstin': companyGstin,
      'company_email': companyEmail,
      'products': products != null
          ? jsonEncode(products!.map((p) => p?.toMap()).toList())
          : null,
      'final_amount': finalAmount,
      'dispatch_from': dispatchFrom,
      'ship_to': shipTo,
      'pdf_path': pdfPath,
      'skuItems': skuItems != null ? jsonEncode(skuItems) : null,
    };
  }
}