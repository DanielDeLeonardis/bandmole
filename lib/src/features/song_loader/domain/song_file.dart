class SongFile {
  final String path;

  const SongFile({
    required this.path,
  });

  bool get isChordPro {
    final normalizedPath = path.toLowerCase();
    final fileName = normalizedPath.split(RegExp(r'[\\/]+')).last;
    final extensionIndex = fileName.lastIndexOf('.');

    if (extensionIndex < 0 || extensionIndex == fileName.length - 1) {
      return false;
    }

    const chordProExtensions = {
      '.cho',
      '.crd',
      '.chopro',
      '.chordpro',
      '.pro',
    };

    return chordProExtensions.contains(fileName.substring(extensionIndex));
  }
}
