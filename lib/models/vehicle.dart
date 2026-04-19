class Vehicle {
  final int? id;
  final String brand;
  final String model;
  final int year;
  final bool isFavorite;

  Vehicle({
    this.id,
    required this.brand,
    required this.model,
    required this.year,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'year': year,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      brand: (map['brand'] ?? '').toString(),
      model: (map['model'] ?? '').toString(),
      year: map['year'] as int? ?? 0,
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
    );
  }

  String get displayName => '$year $brand $model';
}
