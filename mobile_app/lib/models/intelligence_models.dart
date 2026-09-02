class CustomerProfile {
  final int customerId;
  final double recency;
  final double frequency;
  final double monetary;
  final String rfScore;
  final String segment;
  final int kmeansCluster;

  CustomerProfile({
    required this.customerId,
    required this.recency,
    required this.frequency,
    required this.monetary,
    required this.rfScore,
    required this.segment,
    required this.kmeansCluster,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      customerId: json['customer_id'],
      recency: (json['recency'] as num).toDouble(),
      frequency: (json['frequency'] as num).toDouble(),
      monetary: (json['monetary'] as num).toDouble(),
      rfScore: json['rf_score'],
      segment: json['segment'],
      kmeansCluster: json['kmeans_cluster'],
    );
  }
}

class RecommendedItem {
  final String product;
  final double confidence;
  final double lift;

  RecommendedItem({
    required this.product,
    required this.confidence,
    required this.lift,
  });

  factory RecommendedItem.fromJson(Map<String, dynamic> json) {
    return RecommendedItem(
      product: json['product'],
      confidence: (json['confidence'] as num).toDouble(),
      lift: (json['lift'] as num).toDouble(),
    );
  }
}
