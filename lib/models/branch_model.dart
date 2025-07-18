class Branch {
  final String id;
  final String name;
  final String address;

  Branch({required this.id, required this.name, required this.address});

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'],
      name: map['name'],
      address: map['address'] ?? '',
    );
  }
} 