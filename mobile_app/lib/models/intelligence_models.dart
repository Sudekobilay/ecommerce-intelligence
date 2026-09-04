class CustomerScorecard {
  final int healthScore;
  final String healthStatus;
  final double monetaryPercentile;
  final double frequencyPercentile;
  final double recencyPercentile;

  CustomerScorecard({
    required this.healthScore,
    required this.healthStatus,
    required this.monetaryPercentile,
    required this.frequencyPercentile,
    required this.recencyPercentile,
  });

  factory CustomerScorecard.fromJson(Map<String, dynamic> json) {
    return CustomerScorecard(
      healthScore: json['health_score'] ?? 0,
      healthStatus: json['health_status'] ?? 'Bilinmiyor',
      monetaryPercentile:
          (json['monetary_percentile'] as num?)?.toDouble() ?? 0.0,
      frequencyPercentile:
          (json['frequency_percentile'] as num?)?.toDouble() ?? 0.0,
      recencyPercentile:
          (json['recency_percentile'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PrescriptiveAction {
  final String riskLevel;
  final String actionTitle;
  final String actionDetail;
  final String recommendedChannel;

  PrescriptiveAction({
    required this.riskLevel,
    required this.actionTitle,
    required this.actionDetail,
    required this.recommendedChannel,
  });

  factory PrescriptiveAction.fromJson(Map<String, dynamic> json) {
    return PrescriptiveAction(
      riskLevel: json['risk_level'] ?? 'Orta',
      actionTitle: json['action_title'] ?? '',
      actionDetail: json['action_detail'] ?? '',
      recommendedChannel: json['recommended_channel'] ?? '',
    );
  }
}

class CustomerProfile {
  final int customerId;
  final double recency;
  final double frequency;
  final double monetary;
  final int rScore;
  final int fScore;
  final int mScore;
  final String rfScore;
  final String segment;
  final int kmeansCluster;
  final CustomerScorecard? scorecard;
  final PrescriptiveAction? actionPlan;

  CustomerProfile({
    required this.customerId,
    required this.recency,
    required this.frequency,
    required this.monetary,
    required this.rScore,
    required this.fScore,
    required this.mScore,
    required this.rfScore,
    required this.segment,
    required this.kmeansCluster,
    this.scorecard,
    this.actionPlan,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      customerId: json['customer_id'] ?? 0,
      recency: (json['recency'] as num?)?.toDouble() ?? 0.0,
      frequency: (json['frequency'] as num?)?.toDouble() ?? 0.0,
      monetary: (json['monetary'] as num?)?.toDouble() ?? 0.0,
      rScore: json['r_score'] ?? 3,
      fScore: json['f_score'] ?? 3,
      mScore: json['m_score'] ?? 3,
      rfScore: (json['rf_score'] ?? json['rfm_score'] ?? '').toString(),
      segment: (json['segment'] ?? 'Bilinmiyor').toString(),
      kmeansCluster: json['kmeans_cluster'] ?? 0,
      scorecard: json['scorecard'] != null
          ? CustomerScorecard.fromJson(json['scorecard'])
          : null,
      actionPlan: json['action_plan'] != null
          ? PrescriptiveAction.fromJson(json['action_plan'])
          : null,
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
      product: json['product'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      lift: (json['lift'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// --- GÜN 13: WHAT-IF SİMÜLASYON MODELLERİ ---
class SimulationMetricComparison {
  final double current;
  final double simulated;
  final double delta;

  SimulationMetricComparison({
    required this.current,
    required this.simulated,
    required this.delta,
  });

  factory SimulationMetricComparison.fromJson(Map<String, dynamic> json) {
    return SimulationMetricComparison(
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      simulated: (json['simulated'] as num?)?.toDouble() ?? 0.0,
      delta: (json['delta'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SimulationResult {
  final int customerId;
  final SimulationMetricComparison healthScore;
  final SimulationMetricComparison churnProbabilityPct;
  final String riskAssessment;
  final String impactSummary;

  SimulationResult({
    required this.customerId,
    required this.healthScore,
    required this.churnProbabilityPct,
    required this.riskAssessment,
    required this.impactSummary,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    return SimulationResult(
      customerId: json['customer_id'] as int? ?? 0,
      healthScore: SimulationMetricComparison.fromJson(
        json['health_score'] ?? {},
      ),
      churnProbabilityPct: SimulationMetricComparison.fromJson(
        json['churn_probability_pct'] ?? {},
      ),
      riskAssessment: json['risk_assessment'] as String? ?? '',
      impactSummary: json['impact_summary'] as String? ?? '',
    );
  }
}
