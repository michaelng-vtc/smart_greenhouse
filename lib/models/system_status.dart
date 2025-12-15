class SystemStatus {
  final bool isFanOn;
  final bool isCurtainOn;
  final bool isPumpOn;
  final bool isHeaterOn;
  final bool isMisterOn;

  SystemStatus({
    this.isFanOn = false,
    this.isCurtainOn = false,
    this.isPumpOn = false,
    this.isHeaterOn = false,
    this.isMisterOn = false,
  });

  factory SystemStatus.initial() {
    return SystemStatus();
  }

  SystemStatus copyWith({
    bool? isFanOn,
    bool? isCurtainOn,
    bool? isPumpOn,
    bool? isHeaterOn,
    bool? isMisterOn,
  }) {
    return SystemStatus(
      isFanOn: isFanOn ?? this.isFanOn,
      isCurtainOn: isCurtainOn ?? this.isCurtainOn,
      isPumpOn: isPumpOn ?? this.isPumpOn,
      isHeaterOn: isHeaterOn ?? this.isHeaterOn,
      isMisterOn: isMisterOn ?? this.isMisterOn,
    );
  }
}
