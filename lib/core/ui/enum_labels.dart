import '../../l10n/gen/app_localizations.dart';
import '../db/enums.dart';

extension MuscleGroupLabel on MuscleGroup {
  String label(AppLocalizations l) => switch (this) {
        MuscleGroup.chest => l.muscleChest,
        MuscleGroup.back => l.muscleBack,
        MuscleGroup.shoulders => l.muscleShoulders,
        MuscleGroup.biceps => l.muscleBiceps,
        MuscleGroup.triceps => l.muscleTriceps,
        MuscleGroup.legs => l.muscleLegs,
        MuscleGroup.glutes => l.muscleGlutes,
        MuscleGroup.core => l.muscleCore,
        MuscleGroup.cardio => l.muscleCardio,
        MuscleGroup.fullBody => l.muscleFullBody,
      };
}

extension MealTypeLabel on MealType {
  String label(AppLocalizations l) => switch (this) {
        MealType.breakfast => l.mealBreakfast,
        MealType.lunch => l.mealLunch,
        MealType.dinner => l.mealDinner,
        MealType.snack => l.mealSnack,
      };
}

extension EquipmentLabel on Equipment {
  String label(AppLocalizations l) => switch (this) {
        Equipment.barbell => l.equipBarbell,
        Equipment.dumbbell => l.equipDumbbell,
        Equipment.machine => l.equipMachine,
        Equipment.cable => l.equipCable,
        Equipment.bodyweight => l.equipBodyweight,
        Equipment.other => l.equipOther,
      };
}
