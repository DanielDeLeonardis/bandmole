import 'gig_song.dart';

class SongSet {
  final String id;
  final String title;
  final List<GigSong> songs;

  const SongSet({
    required this.id,
    required this.title,
    this.songs = const <GigSong>[],
  });

  SongSet copyWith({
    String? id,
    String? title,
    List<GigSong>? songs,
  }) {
    return SongSet(
      id: id ?? this.id,
      title: title ?? this.title,
      songs: songs ?? this.songs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'songs': songs.map((s) => s.toJson()).toList(),
    };
  }

  factory SongSet.fromJson(Map<String, dynamic> json) {
    return SongSet(
      id: json['id'] as String,
      title: json['title'] as String,
      songs: (json['songs'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => GigSong.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongSet &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          _listEquals(songs, other.songs);

  @override
  int get hashCode => Object.hash(id, title, Object.hashAll(songs));

  static bool _listEquals(List<GigSong> a, List<GigSong> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
