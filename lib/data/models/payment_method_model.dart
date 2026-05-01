class PaymentMethodModel {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final String color;
  final DateTime createdAt;

  const PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) =>
      PaymentMethodModel(
        id:        json['id'] as String,
        userId:    json['user_id'] as String,
        name:      json['name'] as String,
        icon:      json['icon'] as String? ?? '💳',
        color:     json['color'] as String? ?? '#E91E8C',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'name': name, 'icon': icon, 'color': color,
  };
}
