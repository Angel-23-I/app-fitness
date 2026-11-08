# FitTrack

App móvil de fitness (Flutter, Android primero; el código también compila para iOS). Todo vive en el dispositivo: sin cuentas ni backend.

## Funciones

- **Rutinas**: catálogo de ~40 ejercicios + propios, rutinas con ejercicios ordenables (arrastrar), series y reps objetivo.
- **Modo entrenamiento**: registra peso/reps por serie, temporizador de descanso configurable (30–180 s), último rendimiento como referencia, entrenamiento reanudable si cierras la app.
- **Historial y récords**: detalle por sesión y PR por ejercicio (peso máximo y 1RM estimado con Epley).
- **Progreso corporal**: peso y medidas (cintura, pecho, brazo, muslo), gráficas de 1 mes / 3 meses / todo, fotos de progreso privadas con comparación lado a lado.
- **Metas y recordatorios**: peso objetivo, entrenamientos por semana, calorías diarias, rachas (días y semanas), recordatorios semanales.
- **Inicio**: entrenamiento sugerido (rotación de rutinas), racha, progreso semanal, peso y calorías del día.
- **Calorías desde una foto** (opcional, Gemini): estimación editable antes de guardar en el diario de comidas.

## Requisitos

- Flutter estable (probado con 3.47.9 / Dart 3.13).
- Android SDK (Android Studio) con las licencias aceptadas: `flutter doctor --android-licenses`.
- Para iOS: macOS con Xcode.

## Ejecutar

```bash
flutter pub get
dart run build_runner build      # genera el código de Drift (ya está en git, solo si cambias tablas)
flutter gen-l10n                 # regenera las traducciones si editas lib/l10n/app_es.arb
flutter run                      # con un emulador o móvil conectado
```

Comprobaciones:

```bash
flutter analyze
flutter test
flutter build apk --debug        # APK en build/app/outputs/flutter-apk/
```

## Configurar el análisis de comida (API key de Gemini)

La función está **desactivada hasta que añadas tu propia clave**; el resto de la app funciona igual sin ella.

1. Entra en <https://aistudio.google.com/apikey> con tu cuenta de Google y crea una clave de API.
2. En la app: **Ajustes → Análisis de comida con IA**, pega la clave y guarda.
3. En **Comida → Añadir comida**, toma o elige una foto, revisa los resultados y guarda.

Detalles:

- La clave se guarda con `flutter_secure_storage` (Keystore en Android / Keychain en iOS). **No está en el código ni en git**, y viaja solo en la cabecera `x-goog-api-key` hacia la API de Google.
- La foto se reduce (máx. 1024 px, JPEG calidad 80) antes de enviarse. Google recibe esa imagen reducida; no se guarda ninguna foto de comida en el dispositivo.
- Modelo: `gemini-3.8-flash` (constante `geminiModel` en `lib/features/nutrition/data/gemini_food_analyzer.dart`), llamado con `generateContent` y respuesta JSON estructurada. Google marca `generateContent` como API heredada pero soportada; la API Interactions es la recomendada para proyectos nuevos.
- La IA está detrás de la interfaz `FoodAnalyzer` (`lib/features/nutrition/domain/food_models.dart`): para cambiar de proveedor basta con otra implementación y devolverla en `foodAnalyzerProvider`.
- Errores manejados: sin internet, clave inválida, cuota agotada, respuesta no interpretable y foto sin comida; siempre queda la opción de añadir la comida a mano.
- Las estimaciones son aproximadas; la app lo avisa en la pantalla de revisión.

## Estructura

```
lib/
  core/        tema, router (go_router), base de datos Drift, widgets de estado, formato
  l10n/        app_es.arb (español; añade app_xx.arb para otros idiomas)
  features/
    exercises/ routines/ workout/ progress/ goals/ nutrition/ dashboard/ settings/
      data/ (repositorios, Drift, APIs)  domain/ (lógica pura y modelos)  presentation/ (pantallas)
test/          PR, rachas, parseo de Gemini, repositorios y widget tests
```

## Notas

- Base de datos: `lib/core/db/tables.dart`. Si cambias el esquema, sube `schemaVersion` en `app_database.dart` y añade la migración.
- Recordatorios: usan alarmas inexactas (sin permiso de "alarma exacta"), así que pueden retrasarse unos minutos. Se pide el permiso de notificaciones (Android 13+/iOS) al crear el primero. El aviso de fin de descanso en el entrenamiento es una vibración dentro de la app, no una notificación.
- El `applicationId` es `com.example.fittrack` y las builds de release usan la firma de debug: cámbialos antes de publicar.
