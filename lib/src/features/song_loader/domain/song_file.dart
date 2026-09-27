class SongFile {
  final String path;
  final String? displayPath;

  const SongFile({required this.path, this.displayPath});

  String get namePath => displayPath ?? path;

  String get extension {
    final fileName = namePath.split(RegExp(r'[\\/]+')).last;
    final extensionIndex = fileName.lastIndexOf('.');
    if (extensionIndex < 0 || extensionIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(extensionIndex).toLowerCase();
  }

  bool get isSupportedExtension => const {
    '.cho',
    '.crd',
    '.chopro',
    '.chordpro',
    '.pro',
    '.txt',
  }.contains(extension);

  bool get isChordPro {
    const chordProExtensions = {'.cho', '.crd', '.chopro', '.chordpro', '.pro'};

    return chordProExtensions.contains(extension);
  }
}
