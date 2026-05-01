class VaultModel {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final String color;
  final double? budget;
  final bool isDefault;
  final DateTime createdAt;

  const VaultModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    this.budget,
    required this.isDefault,
    required this.createdAt,
  });

  factory VaultModel.fromJson(Map<String, dynamic> json) => VaultModel(
    id:        json['id'] as String,
    userId:    json['user_id'] as String,
    name:      json['name'] as String,
    icon:      json['icon'] as String? ?? '📁',
    color:     json['color'] as String? ?? '#6366F1',
    budget:    json['budget'] != null ? (json['budget'] as num).toDouble() : null,
    isDefault: json['is_default'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'name': name,
    'icon': icon, 'color': color, 'budget': budget, 'is_default': isDefault,
  };
}
