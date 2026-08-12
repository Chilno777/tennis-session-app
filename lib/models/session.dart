import 'match_pick.dart';

class Session {
  Session({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.participantIndexes,
    this.courts = 1,
  });

  final String id;
  String title;
  final DateTime createdAt;

  List<int> participantIndexes;

  int courts;

  Map<int, int> displayNo = {};

  List<int> order = [];

  int cursor = 0;

  final List<MatchPick> matches = [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'participantIndexes': participantIndexes,
      'courts': courts,
      'displayNo': displayNo,
      'order': order,
      'cursor': cursor,
      'matches': matches.map((m) => m.toJson()).toList(),
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    final s = Session(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      participantIndexes: List<int>.from(json['participantIndexes']),
      courts: json['courts'],
    );

    s.displayNo = (json['displayNo'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(int.parse(key), value as int));

    s.order = List<int>.from(json['order']);
    s.cursor = json['cursor'];

    s.matches.addAll(
      (json['matches'] as List)
          .map((m) => MatchPick.fromJson(m)),
    );

    return s;
  }
}