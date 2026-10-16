class GigSong {
  final String id;
  final String relativePath;
  final bool isBroken;
  final String? brokenReason;

  const GigSong({
    required this.id,
    required this.relativePath,
    this.isBroken = false,
    this.brokenReason,
  });

  String get displayName {
    final parts = relativePath.split(RegExp(r'[\\/]+'));
    return parts.isNotEmpty ? parts.last : relativePath;
  }

  GigSong copyWith({
    String? id,
    String? relativePath,
    bool? isBroken,
    String? brokenReason,
    bool clearBrokenReason = false,
  }) {
    return GigSong(
      id: id ?? this.id,
      relativePath: relativePath ?? this.relativePath,
      isBroken: isBroken ?? this.isBroken,
      brokenReason: clearBrokenReason
          ? null
          : (brokenReason ?? this.brokenReason),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relativePath': relativePath,
      'isBroken': isBroken,
      if (brokenReason != null) 'brokenReason': brokenReason,
    };
  }

  factory GigSong.fromJson(Map<String, dynamic> json) {
    return GigSong(
      id: json['id'] as String,
      relativePath: json['relativePath'] as String,
      isBroken: json['isBroken'] as bool? ?? false,
      brokenReason: json['brokenReason'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GigSong &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          relativePath == other.relativePath &&
          isBroken == other.isBroken &&
          brokenReason == other.brokenReason;

  @override
  int get hashCode => Object.hash(id, relativePath, isBroken, brokenReason);
}
