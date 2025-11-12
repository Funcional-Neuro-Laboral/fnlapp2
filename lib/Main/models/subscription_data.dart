class SubscriptionData {
  final bool isActive;
  final String? planType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;

  SubscriptionData({
    required this.isActive,
    this.planType,
    this.startDate,
    this.endDate,
    this.status,
  });

  factory SubscriptionData.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final subscription = data['subscription'];

    return SubscriptionData(
      isActive: data['isActive'] ?? false,
      planType: data['plan']?['type'],
      startDate: subscription?['start_date'] != null
          ? DateTime.parse(subscription['start_date'])
          : null,
      endDate: subscription?['end_date'] != null
          ? DateTime.parse(subscription['end_date'])
          : null,
      status: subscription?['status'],
    );
  }

  // Cambio principal: verificar que el tipo sea 'PRO'
  bool get isPro => isActive && planType == 'PRO';
  bool get isFree => !isActive || planType == 'FREE' || planType == null;
}
