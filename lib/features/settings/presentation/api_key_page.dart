import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../nutrition/data/analyzer_providers.dart';

class ApiKeyPage extends ConsumerStatefulWidget {
  const ApiKeyPage({super.key});

  @override
  ConsumerState<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends ConsumerState<ApiKeyPage> {
  final _key = TextEditingController();
  var _hidden = true;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(apiKeyProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.apiKeyTitle)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(l10n.apiKeyIntro),
        const SizedBox(height: 16),
        Text(l10n.apiKeyStepsTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(l10n.apiKeySteps),
        const SizedBox(height: 8),
        const SelectableText('https://aistudio.google.com/apikey'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l10n.apiKeyPrivacy),
          ),
        ),
        const SizedBox(height: 16),
        if (saved != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(l10n.apiKeySaved),
            trailing: TextButton(
              onPressed: () => ref.read(apiKeyProvider.notifier).clear(),
              child: Text(l10n.apiKeyRemove),
            ),
          ),
        TextField(
          controller: _key,
          obscureText: _hidden,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: l10n.apiKeyField,
            suffixIcon: IconButton(
              icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _hidden = !_hidden),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            if (_key.text.trim().isEmpty) return;
            await ref.read(apiKeyProvider.notifier).save(_key.text);
            if (context.mounted) context.pop();
          },
          child: Text(l10n.save),
        ),
      ]),
    );
  }
}
