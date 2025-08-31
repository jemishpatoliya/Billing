enum TransactionType {
  purchase,    // Stock added from purchase
  sale,        // Stock sold in invoice
  adjustment,  // Manual stock adjustment
  returned,    // Return from customer (changed from 'return' to avoid keyword conflict)
  damage,      // Damaged stock removal
}

class StockTransactionModel {
  String? id;
  String? stockId;
  String? productName;
  String? size;
  int? quantity;
  double? rate;
  String? colour;
  TransactionType? transactionType;
  String? referenceId; // Invoice ID or Purchase ID
  String? referenceType; // 'invoice' or 'purchase'
  String? notes;
  DateTime? createdAt;
  String? createdBy;

  StockTransactionModel({
    this.id,
    this.stockId,
    this.productName,
    this.size,
    this.quantity,
    this.rate,
    this.colour,
    this.transactionType,
    this.referenceId,
    this.referenceType,
    this.notes,
    this.createdAt,
    this.createdBy,
  });

  factory StockTransactionModel.fromMap(Map<String, dynamic> map) {
    return StockTransactionModel(
      id: map['id'],
      stockId: map['stock_id'],
      productName: map['product_name'],
      size: map['size'],
      quantity: map['quantity'],
      rate: map['rate'] != null ? map['rate'] * 1.0 : null,
      colour: map['colour'],
      transactionType: _parseTransactionType(map['transaction_type']),
      referenceId: map['reference_id'],
      referenceType: map['reference_type'],
      notes: map['notes'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      createdBy: map['created_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stock_id': stockId,
      'product_name': productName,
      'size': size,
      'quantity': quantity,
      'rate': rate,
      'colour': colour,
      'transaction_type': transactionType?.name,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  static TransactionType _parseTransactionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'purchase':
        return TransactionType.purchase;
      case 'sale':
        return TransactionType.sale;
      case 'adjustment':
        return TransactionType.adjustment;
      case 'returned':
        return TransactionType.returned;
      case 'damage':
        return TransactionType.damage;
      default:
        return TransactionType.adjustment;
    }
  }

  // Helper method to get transaction description
  String get transactionDescription {
    switch (transactionType) {
      case TransactionType.purchase:
        return 'Stock Added';
      case TransactionType.sale:
        return 'Stock Sold';
      case TransactionType.adjustment:
        return 'Stock Adjusted';
      case TransactionType.returned:
        return 'Stock Returned';
      case TransactionType.damage:
        return 'Stock Damaged';
      default:
        return 'Stock Transaction';
    }
  }

  // Helper method to check if transaction increases stock
  bool get increasesStock {
    return transactionType == TransactionType.purchase || 
           transactionType == TransactionType.returned;
  }

  // Helper method to check if transaction decreases stock
  bool get decreasesStock {
    return transactionType == TransactionType.sale || 
           transactionType == TransactionType.damage;
  }
}
