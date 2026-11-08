import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/body_repository.dart';

class PhotoImage extends ConsumerWidget {
  const PhotoImage(this.photo, {super.key, this.cacheWidth});
  final ProgressPhoto photo;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(photoFileProvider(photo)).when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const Icon(Icons.broken_image_outlined),
        data: (f) => Image.file(f,
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined))),
      );
}

class PhotosTab extends ConsumerStatefulWidget {
  const PhotosTab({super.key});

  @override
  ConsumerState<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends ConsumerState<PhotosTab> {
  var _comparing = false;
  final _picked = <ProgressPhoto>[];

  Future<void> _add(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Downscale at pick time: progress photos do not need full sensor resolution.
      final x = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (x == null) return;
      await ref.read(bodyRepositoryProvider).addPhoto(x.path, DateTime.now());
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.photoError)));
    }
  }

  void _addMenu() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.photoCamera),
            onTap: () {
              Navigator.pop(ctx);
              _add(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.photoGallery),
            onTap: () {
              Navigator.pop(ctx);
              _add(ImageSource.gallery);
            },
          ),
        ]),
      ),
    );
  }

  void _tap(ProgressPhoto p) {
    if (!_comparing) {
      _viewer(p);
      return;
    }
    setState(() {
      if (!_picked.remove(p)) {
        if (_picked.length == 2) _picked.removeAt(0);
        _picked.add(p);
      }
    });
  }

  void _viewer(ProgressPhoto p) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: InteractiveViewer(child: PhotoImage(p))),
          Row(children: [
            Padding(padding: const EdgeInsets.all(12), child: Text(fmtDate(p.date))),
            const Spacer(),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(bodyRepositoryProvider).deletePhoto(p);
              },
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMenu,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(l10n.photoAdd),
      ),
      body: AsyncBody<List<ProgressPhoto>>(
        value: ref.watch(photosProvider),
        onRetry: () => ref.invalidate(photosProvider),
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(icon: Icons.photo_outlined, message: l10n.photosEmpty),
        builder: (photos) => Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              if (!_comparing)
                OutlinedButton.icon(
                  onPressed: photos.length < 2 ? null : () => setState(() => _comparing = true),
                  icon: const Icon(Icons.compare),
                  label: Text(l10n.photoCompare),
                )
              else ...[
                TextButton(
                  onPressed: () => setState(() {
                    _comparing = false;
                    _picked.clear();
                  }),
                  child: Text(l10n.cancel),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _picked.length == 2
                      ? () {
                          final ids = _picked.map((p) => p.id).toList();
                          setState(() {
                            _comparing = false;
                            _picked.clear();
                          });
                          context.push('/progress/compare?a=${ids[0]}&b=${ids[1]}');
                        }
                      : null,
                  child: Text(_picked.length == 2 ? l10n.photoCompareView : l10n.photoCompareHint),
                ),
              ],
            ]),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: photos.length,
              itemBuilder: (_, i) {
                final p = photos[i];
                final sel = _picked.contains(p);
                return GestureDetector(
                  onTap: () => _tap(p),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(fit: StackFit.expand, children: [
                      PhotoImage(p, cacheWidth: 300),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(fmtDate(p.date),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ),
                      if (sel)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Align(
                              alignment: Alignment.topRight,
                              child: Padding(padding: EdgeInsets.all(4), child: Icon(Icons.check_circle, color: Colors.white))),
                        ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
