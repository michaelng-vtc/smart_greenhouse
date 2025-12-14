class ClimateSetpoints {
  final double vpdTargetLow;
  final double vpdTargetHigh;
  final double vpdMisterThreshold;
  final double tempMinC;
  final double tempMaxC;
  final int co2HighPpm;
  final int lightMaxLux;
  final double soilMinPercent;

  ClimateSetpoints({
    this.vpdTargetLow = 0.8,
    this.vpdTargetHigh = 1.2,
    this.vpdMisterThreshold = 1.0,
    this.tempMinC = 18.0,
    this.tempMaxC = 30.0,
    this.co2HighPpm = 1500,
    this.lightMaxLux = 50000,
    this.soilMinPercent = 30.0,
  });

  factory ClimateSetpoints.fromJson(Map<String, dynamic> json) {
    return ClimateSetpoints(
      vpdTargetLow: (json['vpd_target_low'] as num?)?.toDouble() ?? 0.8,
      vpdTargetHigh: (json['vpd_target_high'] as num?)?.toDouble() ?? 1.2,
      vpdMisterThreshold:
          (json['vpd_mister_threshold'] as num?)?.toDouble() ?? 1.0,
      tempMinC: (json['temp_min_c'] as num?)?.toDouble() ?? 18.0,
      tempMaxC: (json['temp_max_c'] as num?)?.toDouble() ?? 30.0,
      co2HighPpm: (json['co2_high_ppm'] as num?)?.toInt() ?? 1500,
      lightMaxLux: (json['light_max_lux'] as num?)?.toInt() ?? 50000,
      soilMinPercent: (json['soil_min_percent'] as num?)?.toDouble() ?? 30.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vpd_target_low': vpdTargetLow,
      'vpd_target_high': vpdTargetHigh,
      'vpd_mister_threshold': vpdMisterThreshold,
      'temp_min_c': tempMinC,
      'temp_max_c': tempMaxC,
      'co2_high_ppm': co2HighPpm,
      'light_max_lux': lightMaxLux,
      'soil_min_percent': soilMinPercent,
    };
  }
}

class PlantProfile {
  final String profileName;
  final ClimateSetpoints setpoints;

  PlantProfile({required this.profileName, required this.setpoints});

  factory PlantProfile.fromJson(Map<String, dynamic> json) {
    return PlantProfile(
      profileName: json['profile_name'] as String,
      setpoints: ClimateSetpoints.fromJson(json['setpoints']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'profile_name': profileName, 'setpoints': setpoints.toJson()};
  }
}
