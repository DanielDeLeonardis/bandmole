import 'dart:io';

const featureRoots = <String, String>{
  'song_loader': 'lib/src/features/song_loader/',
  'lyrics_scroller': 'lib/src/features/lyrics_scroller/',
  'preferences': 'lib/src/features/preferences/',
};

void main() {
  final lcov = File('coverage/lcov.info');
  if (!lcov.existsSync()) {
    stderr.writeln(
      'coverage/lcov.info is missing. Run flutter test --coverage first.',
    );
    exitCode = 2;
    return;
  }

  final totals = <String, ({int found, int hit})>{};
  var branchRecords = 0;
  String? feature;
  for (final line in lcov.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      final path = line.substring(3).replaceAll('\\', '/');
      feature = featureRoots.entries
          .where((entry) => path.contains(entry.value))
          .map((entry) => entry.key)
          .firstOrNull;
    } else if (feature != null && line.startsWith('BRDA:')) {
      branchRecords++;
      final current = totals[feature] ?? (found: 0, hit: 0);
      final taken = line.split(',').last.trim();
      totals[feature] = (
        found: current.found + 1,
        hit: current.hit + (taken != '-' && taken != '0' ? 1 : 0),
      );
    }
  }

  if (branchRecords == 0) {
    stderr.writeln(
      'No branch records found in coverage/lcov.info. Use a coverage '
      'collector that emits LCOV BRDA records before enforcing the 80% target.',
    );
    exitCode = 2;
    return;
  }

  var failed = false;
  for (final root in featureRoots.keys) {
    final total = totals[root];
    final percentage = total == null || total.found == 0
        ? 0.0
        : total.hit * 100 / total.found;
    stdout.writeln('$root branch coverage: ${percentage.toStringAsFixed(1)}%');
    if (percentage < 80) failed = true;
  }
  if (failed) {
    stderr.writeln('Branch coverage target is 80% for every active feature.');
    exitCode = 1;
  }
}
