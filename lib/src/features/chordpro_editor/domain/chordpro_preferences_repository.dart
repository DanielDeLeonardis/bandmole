abstract interface class ChordProPreferencesRepository {
  Future<List<String>> loadGlobalCustomDirectives();
  Future<void> addGlobalCustomDirective(String name);
  Future<void> removeGlobalCustomDirective(String name);
  Future<bool> isHintDismissed();
  Future<void> setHintDismissed(bool dismissed);
}
