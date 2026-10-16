import 'gig_song.dart';
import 'song_set.dart';

class Gig {
  final String id;
  final String title;
  final DateTime? date;
  final String? venue;
  final String? notes;
  final String? startTime;
  final List<SongSet> sets;

  const Gig({
    required this.id,
    required this.title,
    this.date,
    this.venue,
    this.notes,
    this.startTime,
    required this.sets,
  }) : assert(sets.length > 0, 'A gig must contain at least one set');

  factory Gig.create({
    required String id,
    required String title,
    DateTime? date,
    String? venue,
    String? notes,
    String? startTime,
    List<SongSet>? sets,
    bool clearDate = false,
    bool clearVenue = false,
    bool clearNotes = false,
    bool clearStartTime = false,
  }) {
    final effectiveSets = (sets != null && sets.isNotEmpty)
        ? sets
        : <SongSet>[
            SongSet(
              id: '${id}_set_1',
              title: 'Set 1',
              songs: const <GigSong>[],
            ),
          ];

    return Gig(
      id: id,
      title: title,
      date: date,
      venue: venue,
      notes: notes,
      startTime: startTime,
      sets: effectiveSets,
    );
  }

  List<String> get allSongPaths {
    return [
      for (final set in sets)
        for (final song in set.songs) song.relativePath,
    ];
  }

  List<GigSong> get allSongs {
    return [
      for (final set in sets)
        for (final song in set.songs) song,
    ];
  }

  GigSong? findSongById(String songId) {
    for (final set in sets) {
      for (final song in set.songs) {
        if (song.id == songId) return song;
      }
    }
    return null;
  }

  int getSetNumber(SongSet set) {
    final index = sets.indexOf(set);
    return index >= 0 ? index + 1 : 1;
  }

  Gig copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? venue,
    String? notes,
    String? startTime,
    List<SongSet>? sets,
    bool clearDate = false,
    bool clearVenue = false,
    bool clearNotes = false,
    bool clearStartTime = false,
  }) {
    return Gig(
      id: id ?? this.id,
      title: title ?? this.title,
      date: clearDate ? null : (date ?? this.date),
      venue: clearVenue ? null : (venue ?? this.venue),
      notes: clearNotes ? null : (notes ?? this.notes),
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      sets: sets ?? this.sets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (date != null) 'date': date!.toIso8601String(),
      if (venue != null) 'venue': venue,
      if (notes != null) 'notes': notes,
      if (startTime != null) 'startTime': startTime,
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }

  factory Gig.fromJson(Map<String, dynamic> json) {
    final setsRaw = (json['sets'] as List<dynamic>? ?? const <dynamic>[])
        .map((s) => SongSet.fromJson(s as Map<String, dynamic>))
        .toList();

    final effectiveSets = setsRaw.isNotEmpty
        ? setsRaw
        : <SongSet>[
            SongSet(
              id: '${json['id'] as String}_set_1',
              title: 'Set 1',
              songs: const <GigSong>[],
            ),
          ];

    final dateStr = json['date'] as String?;

    return Gig(
      id: json['id'] as String,
      title: json['title'] as String,
      date: dateStr != null ? DateTime.tryParse(dateStr) : null,
      venue: json['venue'] as String?,
      notes: json['notes'] as String?,
      startTime: json['startTime'] as String?,
      sets: effectiveSets,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          date == other.date &&
          venue == other.venue &&
          notes == other.notes &&
          startTime == other.startTime &&
          _listEquals(sets, other.sets);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    date,
    venue,
    notes,
    startTime,
    Object.hashAll(sets),
  );

  static bool _listEquals(List<SongSet> a, List<SongSet> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
