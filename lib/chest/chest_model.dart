class ChestModel {
  final String id;
  final String fromBeatWorldId;
  final String displayName;
  final int earnedAt;
  final bool isOpened;

  const ChestModel({
    required this.id,
    required this.fromBeatWorldId,
    required this.displayName,
    required this.earnedAt,
    this.isOpened = false,
  });

  ChestModel copyWith({bool? isOpened}) => ChestModel(
    id: id,
    fromBeatWorldId: fromBeatWorldId,
    displayName: displayName,
    earnedAt: earnedAt,
    isOpened: isOpened ?? this.isOpened,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromBeatWorldId': fromBeatWorldId,
    'displayName': displayName,
    'earnedAt': earnedAt,
    'isOpened': isOpened,
  };

  factory ChestModel.fromJson(Map<String, dynamic> j) => ChestModel(
    id: j['id'] as String,
    fromBeatWorldId: j['fromBeatWorldId'] as String,
    displayName: j['displayName'] as String,
    earnedAt: j['earnedAt'] as int,
    isOpened: j['isOpened'] as bool? ?? false,
  );
}
