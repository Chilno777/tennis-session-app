class MatchPick {
  MatchPick({
    required this.a1,
    required this.a2,
    required this.b1,
    required this.b2,
    this.gameA,
    this.gameB,
  });

  final int a1;
  final int a2;
  final int b1;
  final int b2;

  int? gameA;
  int? gameB;

  String get scoreText {
    if (gameA == null || gameB == null) return '未入力';
    return '$gameA - $gameB';
  }

  String get resultText {
    if (gameA == null || gameB == null) return '未入力';
    if (gameA! > gameB!) return 'A勝ち';
    if (gameA! < gameB!) return 'B勝ち';
    return '引き分け';
  }

  Map<String, dynamic> toJson() {
    return {
      'a1': a1,
      'a2': a2,
      'b1': b1,
      'b2': b2,
      'gameA': gameA,
      'gameB': gameB,
    };
  }

  factory MatchPick.fromJson(Map<String, dynamic> json) {
    return MatchPick(
      a1: json['a1'],
      a2: json['a2'],
      b1: json['b1'],
      b2: json['b2'],
      gameA: json['gameA'],
      gameB: json['gameB'],
    );
  }
}