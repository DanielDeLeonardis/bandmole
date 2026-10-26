import 'package:bandmole/l10n/app_localizations_fallback.dart';
import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/src/features/chordpro_editor/data/chordpro_song_store.dart';
import 'package:bandmole/src/features/chordpro_editor/domain/chordpro_document.dart';
import 'package:bandmole/src/features/lyrics_scroller/presentation/widgets/song_text_renderer.dart';
import 'package:bandmole/src/features/song_loader/domain/song.dart';
import 'package:bandmole/src/features/song_loader/domain/song_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChordProEditorRequest {
  const ChordProEditorRequest({required this.rootDirectory, this.song});

  final String rootDirectory;
  final Song? song;
}

class ChordProEditorView extends StatefulWidget {
  const ChordProEditorView({
    super.key,
    required this.request,
    this.store = const ChordProSongStore(),
  });

  final ChordProEditorRequest request;
  final ChordProSongStore store;

  @override
  State<ChordProEditorView> createState() => _ChordProEditorViewState();
}

class _ChordProEditorViewState extends State<ChordProEditorView> {
  static const _customNamesKey = 'chordpro_custom_directives';
  static const _hintDismissedKey = 'chordpro_editor_hint_dismissed';
  static const _directivePaletteWrapWidth = 640.0;
  late final TextEditingController _textController;
  late final TextEditingController _nameController;
  final FocusNode _editorFocus = FocusNode();
  final GlobalKey _dropTargetKey = GlobalKey();
  String _savedText = '';
  String _savedName = '';
  SongFile? _workingFile;
  SongFile? _lastSavedFile;
  bool _converted = true;
  bool _saving = false;
  bool _leaving = false;
  bool _hintDismissed = false;
  List<String> _customNames = [];

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
    final source = widget.request.song;
    _workingFile = source?.file;
    _converted = source == null || source.file.isChordPro;
    _savedText = source?.text ?? '';
    _textController = TextEditingController(text: _savedText)
      ..addListener(_refresh);
    final displayName =
        source?.file.namePath.split(RegExp(r'[\\/]')).last ?? '';
    _savedName = displayName.replaceFirst(RegExp(r'\.[^.]+$'), '');
    _nameController = TextEditingController(text: _savedName)
      ..addListener(_refresh);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _customNames = preferences.getStringList(_customNamesKey) ?? [];
      _hintDismissed = preferences.getBool(_hintDismissedKey) ?? false;
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    _editorFocus.dispose();
    super.dispose();
  }

  void _insert(String token) {
    final selection = _textController.selection;
    final start = selection.isValid
        ? selection.start
        : _textController.text.length;
    final end = selection.isValid ? selection.end : start;
    final updated = _textController.text.replaceRange(start, end, token);
    _textController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
    _editorFocus.requestFocus();
  }

  void _acceptToken(DragTargetDetails<String> details) {
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
      _textController.selection = TextSelection.collapsed(
        offset: editable!.getPositionForPoint(details.offset).offset,
      );
    }
    _insert(details.data);
  }

  void _moveSection(int oldIndex, int newIndex) {
    final moved = ChordProDocument(_textController.text)
        .moveSection(oldIndex, newIndex);
    _textController.text = moved.text;
  }

  Future<void> _addCustomDirective() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.editorCustomDirective),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: _l10n.editorCustomName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(_l10n.editorAdd),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null) return;
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name) ||
        ChordProDocument.supportedDirectives.contains(name)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_l10n.editorInvalidCustomName)));
      return;
    }
    if (!_customNames.contains(name)) {
      final names = [..._customNames, name]..sort();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(_customNamesKey, names);
      if (mounted) setState(() => _customNames = names);
    }
    _insert('{$name: }');
  }

  Future<bool> _save() async {
    if (!_converted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_l10n.editorConvertBeforeSave)));
      return false;
    }
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      final file = await widget.store.save(
        rootDirectory: widget.request.rootDirectory,
        fileName: _nameController.text,
        text: _textController.text,
        sourceFile: _workingFile,
      );
      if (!mounted) return false;
      setState(() {
        _workingFile = file;
        _lastSavedFile = file;
        _savedText = _textController.text;
        _savedName = _nameController.text;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_l10n.editorSongSaved)));
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.editorSaveFailed(error.toString()))),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pop() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(_lastSavedFile);
    });
  }

  Future<void> _requestClose() async {
    if (!_dirty) {
      _pop();
      return;
    }
    final previousFocus = FocusManager.instance.primaryFocus;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.editorUnsavedChanges),
        content: Text(_l10n.editorSaveBeforeLeaving),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(_l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(_l10n.editorDiscard),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text(_l10n.save),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'save') {
      if (await _save() && mounted) _pop();
    } else if (choice == 'discard') {
      _pop();
    } else {
      previousFocus?.requestFocus();
    }
  }

  Widget _palette(String label, String token) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Draggable<String>(
        data: token,
        feedback: Material(child: Chip(label: Text(label))),
        child: ActionChip(label: Text(label), onPressed: () => _insert(token)),
      ),
    );
  }

  Widget _directivePalette(List<String> directiveNames) {
    final chips = [
      ...directiveNames.map(
        (name) => _palette(
          name,
          name == 'scroll_speed' ? '{scroll_speed: 5}' : '{$name: }',
        ),
      ),
      ActionChip(
        label: Text('+ ${_l10n.editorCustomDirective}'),
        onPressed: _addCustomDirective,
      ),
    ];

    return LayoutBuilder(
      key: const ValueKey<String>('chordpro_directives'),
      builder: (context, constraints) {
        if (constraints.maxWidth >= _directivePaletteWrapWidth) {
          return Wrap(spacing: 0, runSpacing: 6, children: chips);
        }
        return SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: chips,
          ),
        );
      },
    );
  }

  Widget _editor() {
    final document = ChordProDocument(_textController.text);
    final directiveNames = <String>{
      ...ChordProDocument.supportedDirectives,
      ..._customNames,
      ...document.directives.map((entry) => entry.name),
    }.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_hintDismissed)
          MaterialBanner(
            content: Text(_l10n.editorHint),
            actions: [
              TextButton(
                onPressed: () async {
                  final preferences = await SharedPreferences.getInstance();
                  await preferences.setBool(_hintDismissedKey, true);
                  if (mounted) setState(() => _hintDismissed = true);
                },
                child: Text(_l10n.editorDismiss),
              ),
            ],
          ),
        _directivePalette(directiveNames),
        Expanded(
          child: DragTarget<String>(
            key: _dropTargetKey,
            onAcceptWithDetails: _acceptToken,
            builder: (context, candidates, rejected) => TextField(
              key: const ValueKey<String>('chordpro_source'),
              controller: _textController,
              focusNode: _editorFocus,
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
  }

  Widget _preview() {
    final document = ChordProDocument(_textController.text);
    return SingleChildScrollView(
      key: const ValueKey<String>('chordpro_preview'),
      padding: const EdgeInsets.all(12),
      child: SongTextRenderer(song: document.preview, fontSize: 18),
    );
  }

  Widget _outline() {
    final document = ChordProDocument(_textController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _l10n.editorOutline,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ReorderableListView(
            onReorderItem: _moveSection,
            children: [
              for (var index = 0; index < document.sections.length; index++)
                ListTile(
                  key: ValueKey<String>('section_$index'),
                  title: Text(document.sections[index].label),
                  subtitle: Text(
                    _l10n.editorLine(document.sections[index].start + 1),
                  ),
                ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            children: [
              for (final entry in document.directives)
                ListTile(
                  dense: true,
                  title: Text(entry.name),
                  subtitle: Text(entry.value ?? ''),
                  onTap: () {
                    final offset = document.lines
                        .take(entry.line)
                        .fold<int>(
                          0,
                          (sum, line) =>
                              sum + line.length + document.lineEnding.length,
                        );
                    _textController.selection = TextSelection.collapsed(
                      offset: offset,
                    );
                    _editorFocus.requestFocus();
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceIsPlainText =
        widget.request.song != null &&
        widget.request.song!.file.isChordPro == false &&
        _lastSavedFile == null;
    return PopScope(
      canPop: (!_dirty && _lastSavedFile == null) || _leaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestClose();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_l10n.editorTitle),
          leading: Semantics(
            button: true,
            label: _l10n.editorClose,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _requestClose,
            ),
          ),
          actions: [
            if (sourceIsPlainText)
              TextButton(
                onPressed: () {
                  _textController.text = ChordProDocument.convert(
                    _textController.text,
                  ).text;
                  setState(() => _converted = true);
                },
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
              SizedBox(
                width: 360,
                child: TextField(
                  key: const ValueKey<String>('chordpro_filename'),
                  controller: _nameController,
                  enabled: _workingFile?.isChordPro != true,
                  decoration: InputDecoration(
                    labelText: _l10n.editorFilename,
                    suffixText: '.chopro',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) {
                      return DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            TabBar(
                              tabs: [
                                Tab(text: _l10n.editorTitle),
                                Tab(text: _l10n.editorPreview),
                                Tab(text: _l10n.editorOutline),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [_editor(), _preview(), _outline()],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Row(
                      children: [
                        Expanded(flex: 2, child: _editor()),
                        const SizedBox(width: 8),
                        Expanded(child: _preview()),
                        const SizedBox(width: 8),
                        SizedBox(width: 230, child: _outline()),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

