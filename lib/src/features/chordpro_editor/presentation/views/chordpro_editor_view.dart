import 'package:bandmole/l10n/app_localizations_fallback.dart';
import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_document.dart';
import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_preferences_repository.dart';
import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_song_store.dart';
import 'package:bandmole/src/features/chordpro_editor/presentation/providers/chordpro_preferences_provider.dart';
import 'package:bandmole/src/features/chordpro_editor/presentation/providers/chordpro_song_store_provider.dart';
import 'package:bandmole/src/features/chordpro_editor/presentation/widgets/chordpro_editor_dialogs.dart';
import 'package:bandmole/src/features/chordpro_editor/presentation/widgets/chordpro_outline_panel.dart';
import 'package:bandmole/src/features/chordpro_editor/presentation/widgets/chordpro_palettes.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/widgets/song_text_renderer.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChordProEditorRequest {
  const ChordProEditorRequest({required this.rootDirectory, this.song});

  final String rootDirectory;
  final Song? song;
}

class ChordProEditorView extends ConsumerStatefulWidget {
  const ChordProEditorView({
    super.key,
    required this.request,
    this.store,
    this.preferencesRepository,
  });

  final ChordProEditorRequest request;
  final ChordProSongStore? store;
  final ChordProPreferencesRepository? preferencesRepository;

  @override
  ConsumerState<ChordProEditorView> createState() => _ChordProEditorViewState();
}

class _ChordProEditorViewState extends ConsumerState<ChordProEditorView>
    with SingleTickerProviderStateMixin {
  static const List<String> _defaultChords = <String>[
    'C',
    'D',
    'E',
    'F',
    'G',
    'A',
    'B',
    'Am',
    'Dm',
    'Em',
    'G7',
    'C7',
    'D7',
    'F#m',
    'Bm',
  ];

  late final TextEditingController _textController;
  late final TextEditingController _nameController;
  late final TabController _narrowTabController;
  late final String _preferredLineEnding;
  final FocusNode _editorFocus = FocusNode();
  final GlobalKey _dropTargetKey = GlobalKey();

  late ChordProDocument _document;
  String _savedText = '';
  String _savedName = '';
  SongFile? _workingFile;
  SongFile? _lastSavedFile;
  bool _converted = true;
  bool _saving = false;
  bool _leaving = false;
  bool _hintDismissed = false;
  List<String> _customNames = <String>[];
  final List<String> _songCustomNames = <String>[];
  final List<String> _sessionChords = <String>[];

  ChordProSongStore get _store =>
      widget.store ?? ref.read(chordProSongStoreProvider);

  ChordProPreferencesRepository get _preferencesRepository =>
      widget.preferencesRepository ??
      ref.read(chordProPreferencesRepositoryProvider);

  AppLocalizations get _l10n =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      EnglishAppLocalizations();

  bool get _dirty =>
      (_converted &&
          widget.request.song?.file.isChordPro == false &&
          _lastSavedFile == null) ||
      _textController.text != _savedText ||
      _nameController.text != _savedName;

  @override
  void initState() {
    super.initState();
    _narrowTabController = TabController(length: 3, vsync: this);
    final source = widget.request.song;
    _workingFile = source?.file;
    _converted = source == null || source.file.isChordPro;
    _savedText = source?.text ?? '';
    _document = ChordProDocument(_savedText);
    _preferredLineEnding = _document.lineEnding;
    _textController = TextEditingController(text: _savedText)
      ..addListener(_onTextChanged);
    final displayName =
        source?.file.namePath.split(RegExp(r'[\\/]')).last ?? '';
    _savedName = displayName.replaceFirst(RegExp(r'\.[^.]+$'), '');
    _nameController = TextEditingController(text: _savedName)
      ..addListener(_refresh);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final repo = _preferencesRepository;
    final names = await repo.loadGlobalCustomDirectives();
    final dismissed = await repo.isHintDismissed();
    if (!mounted) return;
    setState(() {
      _customNames = names;
      _hintDismissed = dismissed;
    });
  }

  void _onTextChanged() {
    _document = ChordProDocument(_textController.text);
    _refresh();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _narrowTabController.dispose();
    _textController.dispose();
    _nameController.dispose();
    _editorFocus.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _insertTemplate(ChordProInsertTemplate template) {
    if (!_converted) return;
    final selection = _textController.selection;
    final start = selection.isValid
        ? selection.start
        : _textController.text.length;
    final end = selection.isValid ? selection.end : start;
    final updated = _textController.text.replaceRange(
      start,
      end,
      template.text,
    );
    _textController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + template.cursorOffset),
    );
    _editorFocus.requestFocus();
  }

  void _acceptTemplate(DragTargetDetails<ChordProInsertTemplate> details) {
    if (!_converted) return;
    RenderEditable? editable;
    void findEditable(RenderObject node) {
      if (node is RenderEditable) {
        editable = node;
        return;
      }
      node.visitChildren(findEditable);
    }

    final root = _dropTargetKey.currentContext?.findRenderObject();
    if (root != null) findEditable(root);
    if (editable != null) {
      final offset = editable!.getPositionForPoint(details.offset).offset;
      if (offset >= 0) {
        _textController.selection = TextSelection.collapsed(
          offset: offset.clamp(0, _textController.text.length),
        );
      }
    }
    _insertTemplate(details.data);
  }

  void _moveSection(int oldIndex, int newIndex) {
    if (!_converted) return;
    final moved = _document.moveSection(oldIndex, newIndex);
    if (moved.text != _textController.text) {
      _textController.text = moved.text;
    }
  }

  void _jumpToLine(int lineIndex) {
    final offset = _document.offsetForLine(lineIndex);
    _textController.selection = TextSelection.collapsed(offset: offset);
    if (_narrowTabController.index != 0) {
      _narrowTabController.animateTo(0);
    }
    _editorFocus.requestFocus();
  }

  void _convertPlainText() {
    final result = ChordProDocument.convertDetailed(_textController.text);
    _textController.text = result.document.text;
    setState(() => _converted = true);
    if (result.ambiguousLines.isNotEmpty) {
      _showMessage(
        _l10n.editorConversionAmbiguous(result.ambiguousLines.length),
      );
    }
    _editorFocus.requestFocus();
  }

  Future<void> _addCustomChord() async {
    if (!_converted) return;
    final chord = await showDialog<String>(
      context: context,
      builder: (context) => CustomChordDialog(l10n: _l10n),
    );
    if (!mounted || chord == null) return;
    final cleaned = chord.replaceAll('[', '').replaceAll(']', '').trim();
    if (cleaned.isEmpty) {
      _showMessage(_l10n.editorInvalidChord);
      return;
    }
    if (!_sessionChords.contains(cleaned) &&
        !_defaultChords.contains(cleaned)) {
      setState(() => _sessionChords.add(cleaned));
    }
    _insertTemplate(ChordProInsertTemplate('[$cleaned]'));
  }

  Future<void> _addCustomDirective() async {
    if (!_converted) return;
    final result = await showDialog<({String name, bool isGlobal})>(
      context: context,
      builder: (context) => CustomDirectiveDialog(l10n: _l10n),
    );
    if (!mounted || result == null) return;

    final normalized = ChordProDocument.normalizeDirectiveName(result.name);
    if (!ChordProDocument.isValidCustomDirectiveName(normalized)) {
      _showMessage(_l10n.editorInvalidCustomName);
      return;
    }

    final existingGlobal = _customNames
        .map(ChordProDocument.normalizeDirectiveName)
        .toSet();
    final existingSong = {
      ..._songCustomNames.map(ChordProDocument.normalizeDirectiveName),
      ..._document.directives.map((entry) => entry.normalizedName),
    };
    final isDuplicate =
        ChordProDocument.isBuiltInDirective(normalized) ||
        existingGlobal.contains(normalized) ||
        (!result.isGlobal && existingSong.contains(normalized));
    if (isDuplicate) {
      _showMessage(_l10n.editorDuplicateCustomDirective);
      return;
    }

    if (result.isGlobal) {
      await _preferencesRepository.addGlobalCustomDirective(normalized);
      final updated = [..._customNames, normalized]..sort();
      if (mounted) setState(() => _customNames = updated);
    } else {
      setState(() {
        _songCustomNames
          ..add(normalized)
          ..sort();
      });
    }
    _insertTemplate(ChordProDocument.directiveTemplate(normalized));
  }

  Future<void> _removeGlobalCustomDirective(String name) async {
    await _preferencesRepository.removeGlobalCustomDirective(name);
    if (mounted) {
      setState(
        () =>
            _customNames = _customNames.where((item) => item != name).toList(),
      );
    }
  }

  String _localizedSaveError(Object error) {
    if (error is ChordProSaveException) {
      switch (error.code) {
        case ChordProSaveErrorCode.invalidFilename:
          return _l10n.editorInvalidFilename;
        case ChordProSaveErrorCode.outsideLibrary:
          return _l10n.editorOutsideLibrary;
        case ChordProSaveErrorCode.folderUnavailable:
          return _l10n.editorFolderUnavailable;
        case ChordProSaveErrorCode.writePermissionDenied:
          return _l10n.editorWritePermissionRequired;
        case ChordProSaveErrorCode.fileAlreadyExists:
          return _l10n.editorOverwriteMessage(
            error.targetPath ?? _nameController.text,
          );
        case ChordProSaveErrorCode.writeFailed:
          return _l10n.editorSaveFailed(error.detail ?? error.code.name);
      }
    }
    return _l10n.editorSaveFailed(error.toString());
  }

  Future<bool> _confirmOverwrite(String targetPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          OverwriteFileDialog(l10n: _l10n, targetPath: targetPath),
    );
    return confirmed == true;
  }

  Future<bool> _save({bool overwrite = false}) async {
    if (!_converted) {
      _showMessage(_l10n.editorConvertBeforeSave);
      return false;
    }
    if (_saving) return false;
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() => _saving = true);
    String? overwriteTarget;
    try {
      final serializedText = _document.withLineEnding(_preferredLineEnding);
      final file = await _store.save(
        rootDirectory: widget.request.rootDirectory,
        fileName: _nameController.text,
        text: serializedText,
        sourceFile: _workingFile,
        overwrite: overwrite,
      );
      if (!mounted) return false;
      setState(() {
        _workingFile = file;
        _lastSavedFile = file;
        _savedText = _textController.text;
        _savedName = _nameController.text;
      });
      _showMessage(_l10n.editorSongSaved);
      return true;
    } on ChordProSaveException catch (error) {
      if (!mounted) return false;
      if (error.code == ChordProSaveErrorCode.fileAlreadyExists && !overwrite) {
        overwriteTarget =
            error.targetPath ?? '${_nameController.text.trim()}.chopro';
      } else {
        _showMessage(_localizedSaveError(error));
        return false;
      }
    } catch (error) {
      if (mounted) _showMessage(_localizedSaveError(error));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (mounted) {
      final confirmed = await _confirmOverwrite(overwriteTarget);
      if (confirmed && mounted) {
        return _save(overwrite: true);
      }
    }
    return false;
  }

  void _pop() {
    if (_leaving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(_lastSavedFile);
    });
  }

  Future<void> _requestClose() async {
    if (_leaving) return;
    if (!_dirty) {
      _pop();
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => UnsavedChangesDialog(l10n: _l10n),
    );
    if (!mounted) return;
    if (choice == 'save') {
      if (await _save() && mounted) _pop();
    } else if (choice == 'discard') {
      _pop();
    } else if (_converted) {
      _editorFocus.requestFocus();
    }
  }

  Widget _editor() {
    final chords = <String>{
      ..._defaultChords,
      ..._sessionChords,
      ..._document.usedChords,
    }.toList(growable: false);
    final directiveNames = <String>{
      ...ChordProDocument.supportedDirectives,
      ..._customNames,
      ..._songCustomNames,
      ..._document.directives.map((entry) => entry.normalizedName),
    }.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final allowWrap = constraints.maxHeight >= 520;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_hintDismissed)
              MaterialBanner(
                content: Text(_l10n.editorHint),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await _preferencesRepository.setHintDismissed(true);
                      if (mounted) setState(() => _hintDismissed = true);
                    },
                    child: Text(_l10n.editorDismiss),
                  ),
                ],
              ),
            if (!_converted)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _l10n.editorReadOnlyBeforeConvert,
                  key: const ValueKey<String>('chordpro_readonly_notice'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ChordProChordPalette(
              chords: chords,
              enabled: _converted,
              l10n: _l10n,
              allowWrap: allowWrap,
              onInsert: _insertTemplate,
              onAddCustomChord: _addCustomChord,
            ),
            const SizedBox(height: 6),
            ChordProDirectivePalette(
              directiveNames: directiveNames,
              globalCustomNames: _customNames.toSet(),
              enabled: _converted,
              l10n: _l10n,
              allowWrap: allowWrap,
              onInsert: _insertTemplate,
              onAddCustomDirective: _addCustomDirective,
              onRemoveGlobalDirective: _removeGlobalCustomDirective,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: DragTarget<ChordProInsertTemplate>(
                key: _dropTargetKey,
                onWillAcceptWithDetails: (_) => _converted,
                onAcceptWithDetails: _acceptTemplate,
                builder: (context, candidates, rejected) => TextField(
                  key: const ValueKey<String>('chordpro_source'),
                  controller: _textController,
                  focusNode: _editorFocus,
                  readOnly: !_converted,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: _l10n.editorSource,
                    filled: candidates.isNotEmpty,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _preview() {
    return SingleChildScrollView(
      key: const ValueKey<String>('chordpro_preview'),
      padding: const EdgeInsets.all(12),
      child: SongTextRenderer(song: _document.preview, fontSize: 18),
    );
  }

  Widget _outline() {
    return ChordProOutlinePanel(
      sections: _document.sections,
      directives: _document.directives,
      enabled: _converted,
      l10n: _l10n,
      onMoveSection: _moveSection,
      onJumpToLine: _jumpToLine,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceIsPlainText =
        widget.request.song != null &&
        widget.request.song!.file.isChordPro == false &&
        _lastSavedFile == null;
    final filenameSuffix = _workingFile?.isChordPro == true
        ? _workingFile!.extension
        : '.chopro';

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          if (_converted && !_saving) _save();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          if (_converted && !_saving) _save();
        },
        const SingleActivator(LogicalKeyboardKey.escape): _requestClose,
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
        canPop: (!_dirty && _lastSavedFile == null) || _leaving,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _requestClose();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_l10n.editorTitle),
            leading: IconButton(
              tooltip: _l10n.editorClose,
              icon: const Icon(Icons.arrow_back),
              onPressed: _requestClose,
            ),
            actions: [
              if (sourceIsPlainText && !_converted)
                TextButton(
                  key: const ValueKey<String>('chordpro_convert'),
                  onPressed: _convertPlainText,
                  child: Text(_l10n.editorConvert),
                ),
              TextButton(
                key: const ValueKey<String>('chordpro_save'),
                onPressed: _saving || !_converted ? null : _save,
                child: Text(_l10n.save),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: TextField(
                    key: const ValueKey<String>('chordpro_filename'),
                    controller: _nameController,
                    enabled: _converted && _workingFile?.isChordPro != true,
                    decoration: InputDecoration(
                      labelText: _l10n.editorFilename,
                      suffixText: filenameSuffix,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return Column(
                          children: [
                            TabBar(
                              controller: _narrowTabController,
                              tabs: [
                                Tab(text: _l10n.editorTitle),
                                Tab(text: _l10n.editorPreview),
                                Tab(text: _l10n.editorOutline),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: _narrowTabController,
                                children: [_editor(), _preview(), _outline()],
                              ),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(flex: 2, child: _editor()),
                          const SizedBox(width: 8),
                          Expanded(child: _preview()),
                          const SizedBox(width: 8),
                          SizedBox(width: 260, child: _outline()),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
