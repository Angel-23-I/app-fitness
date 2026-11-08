import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/enums.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/analyzer_providers.dart';
import '../data/food_image.dart';
import '../data/meal_repository.dart';
import '../domain/food_models.dart';

class _Row {
  _Row(this.draft);
  final Key key = UniqueKey();
  FoodItemDraft draft;
}

enum _Phase { analyzing, error, editing }

/// Reviews (and lets the user fix) the AI estimate — or a blank manual entry — before saving.
class MealReviewPage extends ConsumerStatefulWidget {
  const MealReviewPage({super.key, this.imageBytes});
  final Uint8List? imageBytes;

  @override
  ConsumerState<MealReviewPage> createState() => _MealReviewPageState();
}

class _MealReviewPageState extends ConsumerState<MealReviewPage> {
  var _phase = _Phase.editing;
  FoodAnalysisError? _error;
  Confidence? _confidence;
  final _rows = <_Row>[];
  late MealType _type = _defaultType();
  var _saveError = false;

  static MealType _defaultType() {
    final h = DateTime.now().hour;
    return h < 11 ? MealType.breakfast : h < 16 ? MealType.lunch : h < 21 ? MealType.dinner : MealType.snack;
  }

  @override
  void initState() {
    super.initState();
    if (widget.imageBytes != null) {
      _phase = _Phase.analyzing;
      _analyze();
    } else {
      _rows.add(_Row(_blank));
    }
  }

  static const _blank = FoodItemDraft(name: '', grams: 100, kcal: 0, proteinG: 0, carbsG: 0, fatG: 0);

  Future<void> _analyze() async {
    setState(() => _phase = _Phase.analyzing);
    try {
      final analyzer = ref.read(foodAnalyzerProvider);
      if (analyzer == null) throw const FoodAnalysisException(FoodAnalysisError.noApiKey);
      final Uint8List jpeg;
      try {
        jpeg = await prepareFoodImage(widget.imageBytes!);
      } on FormatException {
        throw const FoodAnalysisException(FoodAnalysisError.unparseable, 'bad image');
      }
      final result = await analyzer.analyze(jpeg);
      if (!mounted) return;
      setState(() {
        _rows
          ..clear()
          ..addAll(result.foods.map(_Row.new));
        _confidence = result.confidence;
        _phase = _Phase.editing;
      });
    } on FoodAnalysisException catch (e) {
      _fail(e.error);
    } catch (_) {
      _fail(FoodAnalysisError.server);
    }
  }

  void _fail(FoodAnalysisError e) {
    if (!mounted) return;
    setState(() {
      _error = e;
      _phase = _Phase.error;
    });
  }

  Future<void> _save() async {
    final items = [for (final r in _rows) if (r.draft.name.trim().isNotEmpty) r.draft];
    if (items.isEmpty) {
      setState(() => _saveError = true);
      return;
    }
    final day = ref.read(selectedDayProvider);
    final now = DateTime.now();
    await ref.read(mealRepositoryProvider).save(
          type: _type,
          eatenAt: DateTime(day.year, day.month, day.day, now.hour, now.minute),
          items: items,
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mealReviewTitle),
        actions: [
          if (_phase == _Phase.editing) TextButton(onPressed: _save, child: Text(l10n.save)),
        ],
      ),
      body: switch (_phase) {
        _Phase.analyzing => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.analyzing),
            ]),
          ),
        _Phase.error => _errorView(l10n),
        _Phase.editing => _editor(l10n),
      },
    );
  }

  Widget _errorView(AppLocalizations l10n) {
    final e = _error!;
    final msg = switch (e) {
      FoodAnalysisError.noApiKey => l10n.errNoApiKey,
      FoodAnalysisError.noInternet => l10n.errNoInternet,
      FoodAnalysisError.invalidApiKey => l10n.errInvalidKey,
      FoodAnalysisError.quotaExceeded => l10n.errQuota,
      FoodAnalysisError.unparseable => l10n.errUnparseable,
      FoodAnalysisError.noFood => l10n.errNoFood,
      FoodAnalysisError.server => l10n.errServer,
    };
    final needsKey = e == FoodAnalysisError.noApiKey || e == FoodAnalysisError.invalidApiKey;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(msg, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (needsKey)
            FilledButton(onPressed: () => context.push('/settings/api-key'), child: Text(l10n.configureKey))
          else
            FilledButton(onPressed: _analyze, child: Text(l10n.retry)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() {
              _rows
                ..clear()
                ..add(_Row(_blank));
              _phase = _Phase.editing;
            }),
            child: Text(l10n.addManually),
          ),
        ]),
      ),
    );
  }

  Widget _editor(AppLocalizations l10n) {
    final totals = Totals.of(_rows.map((r) => r.draft));
    final scheme = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (widget.imageBytes != null) ...[
        Card(
          color: scheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${l10n.estimateDisclaimer}${_confidence == null ? '' : '\n${l10n.confidenceLabel(_confidenceText(l10n, _confidence!))}'}',
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
      ],
      DropdownButtonFormField<MealType>(
        initialValue: _type,
        decoration: InputDecoration(labelText: l10n.mealType),
        items: [for (final t in MealType.values) DropdownMenuItem(value: t, child: Text(t.label(l10n)))],
        onChanged: (v) => setState(() => _type = v!),
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < _rows.length; i++)
        _ItemEditor(
          key: _rows[i].key,
          draft: _rows[i].draft,
          onChanged: (d) => setState(() => _rows[i].draft = d),
          onRemove: () => setState(() => _rows.removeAt(i)),
        ),
      TextButton.icon(
        onPressed: () => setState(() => _rows.add(_Row(_blank))),
        icon: const Icon(Icons.add),
        label: Text(l10n.addFoodItem),
      ),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.mealTotal, style: Theme.of(context).textTheme.labelLarge),
            Text('${totals.kcal.round()} kcal', style: Theme.of(context).textTheme.headlineSmall),
            Text(l10n.macrosLine(fmtNum(totals.proteinG.roundToDouble()), fmtNum(totals.carbsG.roundToDouble()),
                fmtNum(totals.fatG.roundToDouble()))),
          ]),
        ),
      ),
      if (_saveError)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.mealNeedItem, style: TextStyle(color: scheme.error)),
        ),
      const SizedBox(height: 16),
      FilledButton(onPressed: _save, child: Text(l10n.mealSave)),
    ]);
  }

  String _confidenceText(AppLocalizations l10n, Confidence c) => switch (c) {
        Confidence.high => l10n.confidenceHigh,
        Confidence.medium => l10n.confidenceMedium,
        Confidence.low => l10n.confidenceLow,
      };
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({super.key, required this.draft, required this.onChanged, required this.onRemove});
  final FoodItemDraft draft;
  final ValueChanged<FoodItemDraft> onChanged;
  final VoidCallback onRemove;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late FoodItemDraft _cur = widget.draft;
  late final _name = TextEditingController(text: _cur.name);
  late final _grams = TextEditingController(text: _n(_cur.grams));
  late final _kcal = TextEditingController(text: _n(_cur.kcal));
  late final _protein = TextEditingController(text: _n(_cur.proteinG));
  late final _carbs = TextEditingController(text: _n(_cur.carbsG));
  late final _fat = TextEditingController(text: _n(_cur.fatG));

  static String _n(double v) => fmtNum(double.parse(v.toStringAsFixed(1)));

  @override
  void dispose() {
    for (final c in [_name, _grams, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  void _set(FoodItemDraft d) {
    _cur = d;
    widget.onChanged(d);
  }

  /// Changing the portion rescales calories and macros; the other fields are edited as-is.
  void _onGrams(String s) {
    final g = parseNum(s);
    if (g == null) return;
    _set(_cur.withGrams(g));
    _kcal.text = _n(_cur.kcal);
    _protein.text = _n(_cur.proteinG);
    _carbs.text = _n(_cur.carbsG);
    _fat.text = _n(_cur.fatG);
  }

  Widget _num(TextEditingController c, String label, String suffix, void Function(double) apply) =>
      Expanded(
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, suffixText: suffix, isDense: true),
          onChanged: (s) {
            final v = parseNum(s);
            if (v != null && v >= 0) apply(v);
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.foodName, isDense: true),
                onChanged: (s) => _set(_cur.copyWith(name: s)),
              ),
            ),
            IconButton(icon: const Icon(Icons.close), tooltip: l10n.delete, onPressed: widget.onRemove),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _grams,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.grams, suffixText: 'g', isDense: true),
                onChanged: _onGrams,
              ),
            ),
            const SizedBox(width: 8),
            _num(_kcal, 'kcal', '', (v) => _set(_cur.copyWith(kcal: v))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _num(_protein, l10n.protein, 'g', (v) => _set(_cur.copyWith(proteinG: v))),
            const SizedBox(width: 8),
            _num(_carbs, l10n.carbs, 'g', (v) => _set(_cur.copyWith(carbsG: v))),
            const SizedBox(width: 8),
            _num(_fat, l10n.fat, 'g', (v) => _set(_cur.copyWith(fatG: v))),
          ]),
        ]),
      ),
    );
  }
}
