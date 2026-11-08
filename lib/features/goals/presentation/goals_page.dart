import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/format.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../settings/data/settings_repository.dart';
import '../data/goals_providers.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  final _weight = TextEditingController();
  final _weekly = TextEditingController();
  final _calories = TextEditingController();
  var _ready = false;
  var _invalid = false;

  @override
  void initState() {
    super.initState();
    ref.read(goalsProvider.future).then((g) {
      if (!mounted) return;
      setState(() {
        _weight.text = g.targetWeightKg == null ? '' : fmtNum(g.targetWeightKg!);
        _weekly.text = '${g.weeklyWorkouts}';
        _calories.text = g.dailyCalories?.toString() ?? '';
        _ready = true;
      });
    });
  }

  @override
  void dispose() {
    _weight.dispose();
    _weekly.dispose();
    _calories.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final w = parseNum(_weight.text);
    final wk = int.tryParse(_weekly.text.trim());
    final kc = int.tryParse(_calories.text.trim());
    final ok = (_weight.text.trim().isEmpty || (w != null && w >= 20 && w <= 400)) &&
        (wk != null && wk >= 1 && wk <= 7) &&
        (_calories.text.trim().isEmpty || (kc != null && kc >= 500 && kc <= 10000));
    if (!ok) {
      setState(() => _invalid = true);
      return;
    }
    final repo = ref.read(settingsRepositoryProvider);
    await repo.set(SettingKeys.targetWeight, w == null ? null : '$w');
    await repo.set(SettingKeys.weeklyWorkouts, '$wk');
    await repo.set(SettingKeys.dailyCalories, kc == null ? null : '$kc');
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalsTitle)),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              TextField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.goalTargetWeight, suffixText: 'kg'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _weekly,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.goalWeeklyWorkouts),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _calories,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.goalDailyCalories, suffixText: 'kcal'),
              ),
              if (_invalid)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(l10n.goalsInvalid,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: Text(l10n.save)),
            ]),
    );
  }
}
