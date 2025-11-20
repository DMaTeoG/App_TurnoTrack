import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_coaching_provider.dart';

/// Modal reusable que muestra el estado de la generación IA y permite cerrar/regenerar
class AIAdviceModal extends ConsumerWidget {
  final String title;

  const AIAdviceModal({super.key, this.title = 'Consejo IA'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiCoachingProvider);
    final notifier = ref.read(aiCoachingProvider.notifier);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Generando consejo...'),
                  ],
                ),
              )
            else if (state.error != null && (state.advice == null || state.advice!.isEmpty))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No se pudo generar el consejo.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  Text(state.error ?? ''),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  state.advice ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    notifier.clearAdvice();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cerrar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          // Re-generate using previously stored data (the notifier must have user/metrics provided earlier)
                          // For safety, just call clear and let caller re-trigger generation if needed
                          // Here we call clear then close; caller can call generation again explicitly
                          notifier.clearAdvice();
                          Navigator.of(context).pop();
                        },
                  child: const Text('Regenerar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
