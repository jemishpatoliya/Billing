import 'dart:convert';

class PurchaseProduct {
  String? productId;
  String? purchaseId;
  String? productName;
  String? hsnSac;
  String? mm;
  double? rate;
  String? colour;
  String? colourCode;
  String? per;
  double? total;
  double? gst;
  double? amount;
  double? packingForwarding;
  int? qty;

  PurchaseProduct({
    this.productId,
    this.purchaseId,
    this.productName,
    this.hsnSac,
    this.mm,
    this.rate,
    this.colour,
    this.colourCode,
    this.per,
    this.total,
    this.gst,
    this.amount,
    this.packingForwarding,
    this.qty,
  });

  factory PurchaseProduct.fromMap(Map<String, dynamic> map) {
    return PurchaseProduct(
      productId: map['product_id'],
      purchaseId: map['purchase_id'],
      productName: map['product_name'],
      hsnSac: map['hsn_sac'],
      mm: map['mm'],
      rate: map['rate'] != null ? map['rate'] * 1.0 : null,
      colour: map['colour'],
      colourCode: map['colour_code'],
      per: map['per'],
      total: map['total'] != null ? map['total'] * 1.0 : null,
      gst: map['gst'] != null ? map['gst'] * 1.0 : null,
      amount: map['amount'] != null ? map['amount'] * 1.0 : null,
      packingForwarding: map['packing_forwarding'] != null
          ? map['packing_forwarding'] * 1.0
          : null,
      qty: map['qty'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'purchase_id': purchaseId,
      'product_name': productName,
      'hsn_sac': hsnSac,
      'mm': mm,
      'rate': rate,
      'colour': colour,
      'colour_code': colourCode,
      'per': per,
      'total': total,
      'gst': gst,
      'amount': amount,
      'packing_forwarding': packingForwarding,
      'qty': qty,
    };
  }
}