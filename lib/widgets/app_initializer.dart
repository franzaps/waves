import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:waves/screens/sign_in_screen.dart';

// Storage configuration provider
final storageConfigurationProvider = Provider<StorageConfiguration>((ref) {
  return StorageConfiguration(
    // Database path will be set during initialization
    databasePath: null, // Will be set to actual path
    keepSignatures: false,
    skipVerification: false,
    relayGroups: {
      'default': {
        'wss://relay.damus.io',
        'wss://relay.primal.net',
        'wss://nos.lol',
        'wss://relay.nostr.band',
      },
      'social': {
        'wss://relay.damus.io',
        'wss://relay.primal.net',
        'wss://nos.lol',
      },
    },
    defaultRelayGroup: 'default',
    defaultQuerySource: LocalAndRemoteSource(stream: true),
    idleTimeout: const Duration(minutes: 5),
    responseTimeout: const Duration(seconds: 6),
    streamingBufferWindow: const Duration(seconds: 2),
    keepMaxModels: 20000,
  );
});

// App initialization provider
final appInitializationProvider = FutureProvider<void>((ref) async {
  // Get the documents directory for SQLite database
  final appDocumentsDir = await getApplicationDocumentsDirectory();
  final databasePath = '${appDocumentsDir.path}/waves.sqlite';

  // Create storage configuration with proper database path
  final config = StorageConfiguration(
    databasePath: databasePath,
    keepSignatures: false,
    skipVerification: false,
    relayGroups: {
      'default': {
        'wss://relay.damus.io',
        'wss://relay.primal.net',
        'wss://nos.lol',
        'wss://relay.nostr.band',
      },
      'social': {
        'wss://relay.damus.io',
        'wss://relay.primal.net',
        'wss://nos.lol',
      },
    },
    defaultRelayGroup: 'default',
    defaultQuerySource: LocalAndRemoteSource(stream: true),
    idleTimeout: const Duration(minutes: 5),
    responseTimeout: const Duration(seconds: 6),
    streamingBufferWindow: const Duration(seconds: 2),
    keepMaxModels: 20000,
  );

  // Initialize storage
  await ref.read(initializationProvider(config).future);

  // Attempt auto sign-in with Amber
  try {
    await ref.read(amberSignerProvider).attemptAutoSignIn();
  } catch (e) {
    // Auto sign-in failed, but this is not critical
    debugPrint('Auto sign-in failed: $e');
  }
});

class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initializationState = ref.watch(appInitializationProvider);
    final activePubkey = ref.watch(Signer.activePubkeyProvider);

    return initializationState.when(
      loading: () => _buildLoadingScreen(context),
      error: (error, stackTrace) => _buildErrorScreen(context, error),
      data: (_) {
        // After initialization, navigate to appropriate screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (activePubkey != null) {
            context.go('/app');
          } else {
            context.go('/signin');
          }
        });
        // Return loading screen while navigation happens
        return _buildLoadingScreen(context);
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.waves,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Waves',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Initializing...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, Object error) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.error.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),

                const SizedBox(height: 24),

                Text(
                  'Initialization Failed',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Failed to initialize the app. Please check your connection and try again.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Error: $error',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                FilledButton.icon(
                  onPressed: () {
                    // Force refresh the provider
                    context.go('/');
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
