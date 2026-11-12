import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fit_widgets.dart';
import '../../progress/data/body_repository.dart';
import '../../settings/data/settings_repository.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController(text: '75');
  final _heightController = TextEditingController(text: '175');
  final _targetWeightController = TextEditingController(text: '75');
  final _caloriesController = TextEditingController(text: '2200');

  String _selectedGoal = 'build_muscle';
  String _selectedGender = 'male';
  int _weeklyWorkouts = 4;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _recalculateCalories() {
    final weight = parseNum(_weightController.text) ?? 75;
    final height = parseNum(_heightController.text) ?? 175;
    final isMale = _selectedGender == 'male';

    // BMR aproximado (Harris-Benedict simplificado)
    double bmr = isMale
        ? 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * 25)
        : 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * 25);

    // Factor de actividad física según días de entrenamiento
    double activity = 1.2 + (_weeklyWorkouts * 0.05);
    double tdee = bmr * activity;

    // Ajuste según objetivo
    double targetKcal = switch (_selectedGoal) {
      'lose_weight' => tdee - 400,
      'build_muscle' => tdee + 300,
      _ => tdee,
    };

    _caloriesController.text = targetKcal.round().clamp(1200, 6000).toString();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce tu nombre o apodo')),
      );
      return;
    }

    setState(() => _saving = true);
    final settings = ref.read(settingsRepositoryProvider);
    final bodyRepo = ref.read(bodyRepositoryProvider);

    final weight = parseNum(_weightController.text) ?? 75.0;
    final height = parseNum(_heightController.text);
    final targetWeight = parseNum(_targetWeightController.text);
    final calories = int.tryParse(_caloriesController.text.trim());

    // 1. Guardar ajustes y perfil del usuario
    await settings.set(SettingKeys.userName, name);
    await settings.set(SettingKeys.userGoal, _selectedGoal);
    await settings.set(SettingKeys.userGender, _selectedGender);
    if (height != null) await settings.set(SettingKeys.userHeight, height.toString());
    if (targetWeight != null) await settings.set(SettingKeys.targetWeight, targetWeight.toString());
    await settings.set(SettingKeys.weeklyWorkouts, _weeklyWorkouts.toString());
    if (calories != null) await settings.set(SettingKeys.dailyCalories, calories.toString());

    // 2. Guardar primera entrada de peso en el historial corporal
    await bodyRepo.save(
      date: DateTime.now(),
      weightKg: weight,
    );

    // 3. Marcar onboarding como completado
    await settings.set(SettingKeys.onboardingCompleted, 'true');

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    const goals = [
      ('build_muscle', 'Ganar masa muscular', 'Hipertrofia y desarrollo físico', Icons.fitness_center_rounded),
      ('lose_weight', 'Perder grasa', 'Definición y déficit controlado', Icons.local_fire_department_rounded),
      ('strength', 'Ganar fuerza', 'Superación en levantamientos pesados', Icons.bolt_rounded),
      ('maintain', 'Salud y forma', 'Mantenimiento y rendimiento general', Icons.favorite_rounded),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Encabezado
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.fitness_center_rounded, size: 18, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text('FITTRACK', style: display(18, weight: FontWeight.w700, color: AppColors.accent)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'CREA TU PERFIL'.toUpperCase(),
                textAlign: TextAlign.center,
                style: display(38, italic: true),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tus datos viven exclusivamente en este dispositivo de forma privada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 28),

              // 1. Nombre
              const _SectionLabel(title: '¿CÓMO TE LLAMAS?'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Tu nombre o apodo',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.accent),
                  fillColor: AppColors.surface,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Objetivo Principal
              const _SectionLabel(title: 'TU OBJETIVO PRINCIPAL'),
              const SizedBox(height: 10),
              for (final (id, title, desc, icon) in goals) ...[
                _GoalOption(
                  id: id,
                  title: title,
                  subtitle: desc,
                  icon: icon,
                  selected: _selectedGoal == id,
                  onTap: () {
                    setState(() => _selectedGoal = id);
                    _recalculateCalories();
                  },
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 20),

              // 3. Medidas físicas
              const _SectionLabel(title: 'DATOS FÍSICOS ACTUALES'),
              const SizedBox(height: 10),
              Panel(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: _NumberInput(
                        controller: _weightController,
                        label: 'Peso actual',
                        suffix: 'kg',
                        onChanged: (_) => _recalculateCalories(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberInput(
                        controller: _heightController,
                        label: 'Altura',
                        suffix: 'cm',
                        onChanged: (_) => _recalculateCalories(),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Text('Género:', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Hombre'),
                      selected: _selectedGender == 'male',
                      onSelected: (_) {
                        setState(() => _selectedGender = 'male');
                        _recalculateCalories();
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Mujer'),
                      selected: _selectedGender == 'female',
                      onSelected: (_) {
                        setState(() => _selectedGender = 'female');
                        _recalculateCalories();
                      },
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),

              // 4. Metas
              const _SectionLabel(title: 'TUS METAS INICIALES'),
              const SizedBox(height: 10),
              Panel(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(
                      child: _NumberInput(
                        controller: _targetWeightController,
                        label: 'Peso meta',
                        suffix: 'kg',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberInput(
                        controller: _caloriesController,
                        label: 'Calorías diarias',
                        suffix: 'kcal',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Text('Entrenamientos por semana: $_weeklyWorkouts días',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSoft)),
                  const SizedBox(height: 6),
                  Row(children: [
                    for (int d = 2; d <= 6; d++) ...[
                      if (d > 2) const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _weeklyWorkouts = d);
                            _recalculateCalories();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 42),
                            backgroundColor: _weeklyWorkouts == d ? AppColors.accent : Colors.transparent,
                            foregroundColor: _weeklyWorkouts == d ? AppColors.bg : AppColors.text,
                            side: BorderSide(
                              color: _weeklyWorkouts == d ? AppColors.accent : AppColors.border,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('$d', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                    ],
                  ]),
                ]),
              ),
              const SizedBox(height: 32),

              // Botón de finalización
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.lime,
                  foregroundColor: AppColors.bg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _saving ? 'GUARDANDO...' : 'COMENZAR MI ENTRENAMIENTO',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.muted,
        ),
      );
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String id, title, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF2E190E) : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.bg : AppColors.textSoft,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 22)
            else
              const Icon(Icons.circle_outlined, color: AppColors.border, size: 22),
          ]),
        ),
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.controller,
    required this.label,
    required this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label, suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: true,
        fillColor: AppColors.surfaceHigh,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
