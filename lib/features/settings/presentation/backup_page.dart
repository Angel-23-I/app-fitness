import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fit_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../data/backup_service.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _loading = false;
  List<File> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final list = await ref.read(backupServiceProvider).listBackups();
    if (mounted) {
      setState(() => _backups = list);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(backupServiceProvider);
      final json = await service.exportBackupJson();
      final file = await service.saveBackupToFile(json);
      await _loadBackups();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copia creada: ${file.path.split(Platform.pathSeparator).last}'),
          action: SnackBarAction(
            label: 'Copiar JSON',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copiado al portapapeles')),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear copia: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showRestoreDialog([String? initialJson]) async {
    final controller = TextEditingController(text: initialJson ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar copia de seguridad'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'Pega el contenido JSON de tu copia de seguridad. Los datos se incorporarán a tu app.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 6,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              hintText: '{\n  "appName": "FitTrack",\n  ...\n}',
              border: OutlineInputBorder(),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
        ],
      ),
    );

    if (ok == true && controller.text.trim().isNotEmpty) {
      setState(() => _loading = true);
      try {
        final result = await ref.read(backupServiceProvider).restoreBackupFromJson(controller.text.trim());
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¡Restauración exitosa!'),
            content: Text(
              'Se han restaurado:\n'
              '• ${result['workouts']} entrenamientos\n'
              '• ${result['routines']} rutinas\n'
              '• ${result['bodyEntries']} registros corporales\n'
              '• ${result['meals']} comidas',
            ),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Aceptar')),
            ],
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al restaurar: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _restoreFromFile(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Restaurar copia?'),
        content: Text('¿Deseas restaurar los datos del archivo ${file.path.split(Platform.pathSeparator).last}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
        ],
      ),
    );

    if (confirm == true) {
      final json = await file.readAsString();
      await _showRestoreDialog(json);
    }
  }

  Future<void> _exportCsv({required bool workouts}) async {
    setState(() => _loading = true);
    try {
      final service = ref.read(backupServiceProvider);
      final csv = workouts ? await service.exportWorkoutsCsv() : await service.exportMeasuresCsv();
      final file = await service.saveCsvToFile(workouts ? 'entrenamientos' : 'medidas', csv);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guardado: ${file.path.split(Platform.pathSeparator).last}'),
          action: SnackBarAction(
            label: 'Copiar CSV',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV copiado al portapapeles')),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar CSV: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copia de seguridad y datos'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // Tarjeta informativa
                Panel(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2812),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppColors.lime, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Tus datos te pertenecen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        SizedBox(height: 2),
                        Text(
                          'FitTrack no sube nada a la nube. Exporta copias periódicas para no perder tu progreso.',
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // Acciones de Backup
                const Text(
                  'COPIA COMPLETA (JSON)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _createBackup,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.bg,
                  ),
                  icon: const Icon(Icons.backup_rounded),
                  label: const Text('CREAR COPIA DE SEGURIDAD AHORA'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showRestoreDialog(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('RESTAURAR DESDE TEXTO O PORTAPAPELES'),
                ),
                const SizedBox(height: 24),

                // Exportar a CSV
                const Text(
                  'EXPORTAR TABLAS A CSV (EXCEL / SHEETS)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _exportCsv(workouts: true),
                      icon: const Icon(Icons.table_chart_outlined, size: 18),
                      label: const Text('Entrenamientos'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _exportCsv(workouts: false),
                      icon: const Icon(Icons.monitor_weight_outlined, size: 18),
                      label: const Text('Medidas'),
                    ),
                  ),
                ]),
                const SizedBox(height: 28),

                // Lista de backups locales
                const Text(
                  'COPIAS GUARDADAS EN EL DISPOSITIVO',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                if (_backups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      message: 'No hay copias guardadas aún en este dispositivo.',
                    ),
                  )
                else
                  for (final file in _backups) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined, color: AppColors.lime),
                        title: Text(
                          file.path.split(Platform.pathSeparator).last,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text(
                          '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB · ${_formatFileDate(file.lastModifiedSync())}',
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.restore_rounded, color: AppColors.accent),
                            tooltip: 'Restaurar',
                            onPressed: () => _restoreFromFile(file),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted),
                            tooltip: 'Eliminar',
                            onPressed: () async {
                              await ref.read(backupServiceProvider).deleteBackupFile(file);
                              await _loadBackups();
                            },
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
              ],
            ),
    );
  }

  String _formatFileDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
