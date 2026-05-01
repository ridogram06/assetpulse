class AssetModel {
  final String id;
  final String userId;
  final String? vaultId;
  final String? paymentMethodId;
  final String name;
  final String? category;
  final String icon;
  final String color;
  final String? notes;
  final String assetType; // 'deterministic' | 'probabilistic'
  final double cost;
  final String currency;
  final DateTime startDate;

  // Deterministic only
  final DateTime? endDate;
  final String? billingCycle;
  final bool autoRenew;
  final int notifyDaysBefore;
  final DateTime? suspendedAt;
  final DateTime? suspendedUntil;

  // Probabilistic only
  final DateTime? finishedAt;
  final DateTime? predictedEndDate;
  final double? predictionConfidence;

  final String status;
  final DateTime clientUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssetModel({
    required this.id,
    required this.userId,
    this.vaultId,
    this.paymentMethodId,
    required this.name,
    this.category,
    required this.icon,
    required this.color,
    this.notes,
    required this.assetType,
    required this.cost,
    required this.currency,
    required this.startDate,
    this.endDate,
    this.billingCycle,
    required this.autoRenew,
    required this.notifyDaysBefore,
    this.suspendedAt,
    this.suspendedUntil,
    this.finishedAt,
    this.predictedEndDate,
    this.predictionConfidence,
    required this.status,
    required this.clientUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDeterministic => assetType == 'deterministic';
  bool get isProbabilistic => assetType == 'probabilistic';
  bool get isFinished => status == 'finished';
  bool get isSuspended => status == 'suspended';
  bool get isExpired => status == 'expired';

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id:                   json['id'] as String,
      userId:               json['user_id'] as String,
      vaultId:              json['vault_id'] as String?,
      paymentMethodId:      json['payment_method_id'] as String?,
      name:                 json['name'] as String,
      category:             json['category'] as String?,
      icon:                 json['icon'] as String? ?? '📦',
      color:                json['color'] as String? ?? '#6366F1',
      notes:                json['notes'] as String?,
      assetType:            json['asset_type'] as String,
      cost:                 (json['cost'] as num).toDouble(),
      currency:             json['currency'] as String? ?? 'BDT',
      startDate:            DateTime.parse(json['start_date'] as String),
      endDate:              json['end_date'] != null
                              ? DateTime.parse(json['end_date'] as String)
                              : null,
      billingCycle:         json['billing_cycle'] as String?,
      autoRenew:            json['auto_renew'] as bool? ?? false,
      notifyDaysBefore:     json['notify_days_before'] as int? ?? 3,
      suspendedAt:          json['suspended_at'] != null
                              ? DateTime.parse(json['suspended_at'] as String)
                              : null,
      suspendedUntil:       json['suspended_until'] != null
                              ? DateTime.parse(json['suspended_until'] as String)
                              : null,
      finishedAt:           json['finished_at'] != null
                              ? DateTime.parse(json['finished_at'] as String)
                              : null,
      predictedEndDate:     json['predicted_end_date'] != null
                              ? DateTime.parse(json['predicted_end_date'] as String)
                              : null,
      predictionConfidence: json['prediction_confidence'] != null
                              ? (json['prediction_confidence'] as num).toDouble()
                              : null,
      status:               json['status'] as String? ?? 'active',
      clientUpdatedAt:      DateTime.parse(
                              json['client_updated_at'] as String? ??
                              DateTime.now().toIso8601String()),
      createdAt:            DateTime.parse(json['created_at'] as String),
      updatedAt:            DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':                     id,
      'user_id':                userId,
      'vault_id':               vaultId,
      'payment_method_id':      paymentMethodId,
      'name':                   name,
      'category':               category,
      'icon':                   icon,
      'color':                  color,
      'notes':                  notes,
      'asset_type':             assetType,
      'cost':                   cost,
      'currency':               currency,
      'start_date':             startDate.toIso8601String().split('T').first,
      'end_date':               endDate?.toIso8601String().split('T').first,
      'billing_cycle':          billingCycle,
      'auto_renew':             autoRenew,
      'notify_days_before':     notifyDaysBefore,
      'suspended_at':           suspendedAt?.toIso8601String(),
      'suspended_until':        suspendedUntil?.toIso8601String(),
      'finished_at':            finishedAt?.toIso8601String(),
      'predicted_end_date':     predictedEndDate?.toIso8601String().split('T').first,
      'prediction_confidence':  predictionConfidence,
      'status':                 status,
      'client_updated_at':      clientUpdatedAt.toIso8601String(),
    };
  }

  AssetModel copyWith({
    String? id, String? userId, String? vaultId, String? paymentMethodId,
    String? name, String? category, String? icon, String? color, String? notes,
    String? assetType, double? cost, String? currency, DateTime? startDate,
    DateTime? endDate, String? billingCycle, bool? autoRenew,
    int? notifyDaysBefore, DateTime? suspendedAt, DateTime? suspendedUntil,
    DateTime? finishedAt, DateTime? predictedEndDate,
    double? predictionConfidence, String? status, DateTime? clientUpdatedAt,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return AssetModel(
      id:                   id ?? this.id,
      userId:               userId ?? this.userId,
      vaultId:              vaultId ?? this.vaultId,
      paymentMethodId:      paymentMethodId ?? this.paymentMethodId,
      name:                 name ?? this.name,
      category:             category ?? this.category,
      icon:                 icon ?? this.icon,
      color:                color ?? this.color,
      notes:                notes ?? this.notes,
      assetType:            assetType ?? this.assetType,
      cost:                 cost ?? this.cost,
      currency:             currency ?? this.currency,
      startDate:            startDate ?? this.startDate,
      endDate:              endDate ?? this.endDate,
      billingCycle:         billingCycle ?? this.billingCycle,
      autoRenew:            autoRenew ?? this.autoRenew,
      notifyDaysBefore:     notifyDaysBefore ?? this.notifyDaysBefore,
      suspendedAt:          suspendedAt ?? this.suspendedAt,
      suspendedUntil:       suspendedUntil ?? this.suspendedUntil,
      finishedAt:           finishedAt ?? this.finishedAt,
      predictedEndDate:     predictedEndDate ?? this.predictedEndDate,
      predictionConfidence: predictionConfidence ?? this.predictionConfidence,
      status:               status ?? this.status,
      clientUpdatedAt:      clientUpdatedAt ?? this.clientUpdatedAt,
      createdAt:            createdAt ?? this.createdAt,
      updatedAt:            updatedAt ?? this.updatedAt,
    );
  }
}
