import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seelocals/core/l10n/l10n.dart';
import 'package:seelocals/core/l10n/locale_controller.dart';

/// Placeholder until the feed exists (Step 7).
class HomeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                const Icon(Icons.groups_outlined, size: 72),
                const SizedBox(height: 16),
                Text(
                  l10n.homeHeadline,
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.homeSubtitle,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(l10n.languageLabel, style: textTheme.titleSmall),
                const SizedBox(height: 8),
                const _LanguageSelector(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(localeControllerProvider);
    final controller = ref.read(localeControllerProvider.notifier);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        ChoiceChip(
          label: Text(context.l10n.languageDevice),
          selected: selected == null,
          onSelected: (_) => controller.select(null),
        ),
        for (final locale in AppLocalizations.supportedLocales)
          ChoiceChip(
            // Each language is labelled in its own language.
            label: Text(lookupAppLocalizations(locale).languageName),
            selected: selected == locale,
            onSelected: (_) => controller.select(locale),
          ),
      ],
    );
  }
}
