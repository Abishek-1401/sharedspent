class InventoryItem {
  final String? id;
  final String itemName;
  final String category;
  final int quantity;
  final bool isVeg;
  final String status;
  final DateTime? expiryDate;
  final String apartmentId;
  final bool isPrivate;
  final DateTime createdAt;

  InventoryItem({
    this.id,
    required this.itemName,
    required this.category,
    required this.quantity,
    this.isVeg = false,
    this.status = 'refilled',
    this.expiryDate,
    required this.apartmentId,
    this.isPrivate = false,
    required this.createdAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String?,
      itemName: json['item_name'] as String,
      category: json['category'] as String? ?? 'room',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      isVeg: json['is_veg'] as bool? ?? false,
      status: json['status'] as String? ?? 'refilled',
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : null,
      apartmentId: json['apartment_id'] as String,
      isPrivate: json['is_private'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'item_name': itemName,
      'category': category,
      'quantity': quantity,
      'is_veg': isVeg,
      'status': status,
      'expiry_date': expiryDate?.toIso8601String(),
      'apartment_id': apartmentId,
      'is_private': isPrivate,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
