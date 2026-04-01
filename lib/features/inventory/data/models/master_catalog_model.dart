class MasterCatalogItem {
  final String id;
  final String name;
  final String category;
  final int defaultExpiryDays;

  MasterCatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultExpiryDays,
  });

  factory MasterCatalogItem.fromJson(Map<String, dynamic> json) {
    return MasterCatalogItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      defaultExpiryDays: json['default_expiry_days'] as int? ?? 14,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'default_expiry_days': defaultExpiryDays,
    };
  }
}
