class AssetHistoryModel {
  final String id;
  final String userId;
  final String? assetId;
  final String assetName;
  final String? category;
  final double? cost;
  final String currency;
  final DateTime startDate;
  final DateTime finishedAt;
  final int lifespanDays;
  final double? costPerDay;
  final String? notes;
  final DateTime createdAt;

  const AssetHistoryModel({
    required this.id,
    required this.userId,
    this.assetId,
    required this.assetName,
    this.category,
    this.cost,
    required this.currency,
    required this.startDate,
    required this.finishedAt,
    required this.lifespanDays,
    this.costPerDay,
    this.notes,
    required this.createdAt,
  });

  factory AssetHistoryModel.fromJson(Map<String, dynamic> json) {
    return AssetHistoryModel(
      id:           json['id'] as String,
      userId:       json['user_id'] as String,
      assetId:      json['asset_id'] as String?,
      assetName:    json['asset_name'] as String,
      category:     json['category'] as String?,
      cost:         json['cost'] != null ? (json['cost'] as num).toDouble() : null,
      currency:     json['currency'] as String? ?? 'BDT',
      startDate:    DateTime.parse(json['start_date'] as String),
      finishedAt:   DateTime.parse(json['finished_at'] as String),
      lifespanDays: json['lifespan_days'] as int? ?? 0,
      costPerDay:   json['cost_per_day'] != null
                      ? (json['cost_per_day'] as num).toDouble()
                      : null,
      notes:        json['notes'] as String?,
      createdAt:    DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':           id,
    'user_id':      userId,
    'asset_id':     assetId,
    'asset_name':   assetName,
    'category':     category,
    'cost':         cost,
    'currency':     currency,
    'start_date':   startDate.toIso8601String().split('T').first,
    'finished_at':  finishedAt.toIso8601String(),
    'notes':        notes,
  };
}
