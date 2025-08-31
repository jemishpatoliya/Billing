class StockModel {
  String? id;
  String? productName;
  String? hsnSac;
  String? mm;
  String? size;
  int? quantity;
  double? rate;
  String? colour;
  String? colourCode;
  String? per;
  DateTime? createdAt;
  DateTime? updatedAt;

  StockModel({
    this.id,
    this.productName,
    this.hsnSac,
    this.mm,
    this.size,
    this.quantity,
    this.rate,
    this.colour,
    this.colourCode,
    this.per,
    this.createdAt,
    this.updatedAt,
  });

  factory StockModel.fromMap(Map<String, dynamic> map) {
    return StockModel(
      id: map['id'],
      productName: map['product_name'],
      hsnSac: map['hsn_sac'],
      mm: map['mm'],
      size: map['size'],
      quantity: map['quantity'],
      rate: map['rate'] != null ? map['rate'] * 1.0 : null,
      colour: map['colour'],
      colourCode: map['colour_code'],
      per: map['per'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_name': productName,
      'hsn_sac': hsnSac,
      'mm': mm,
      'size': size,
      'quantity': quantity,
      'rate': rate,
      'colour': colour,
      'colour_code': colourCode,
      'per': per,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper method to get available sizes for a product
  static List<String> getAvailableSizes(List<StockModel> stockItems) {
    return stockItems.map((item) => item.size ?? '').where((size) => size.isNotEmpty).toSet().toList();
  }

  // Helper method to get total quantity for a product across all sizes
  static int getTotalQuantity(List<StockModel> stockItems) {
    return stockItems.fold(0, (sum, item) => sum + (item.quantity ?? 0));
  }

  // Helper method to check if product is in stock
  bool get isInStock => (quantity ?? 0) > 0;

  // Helper method to get stock status
  String get stockStatus {
    final qty = quantity ?? 0;
    if (qty == 0) return 'Out of Stock';
    if (qty <= 10) return 'Low Stock';
    return 'In Stock';
  }
}
