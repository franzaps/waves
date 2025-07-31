import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:amber_signer/amber_signer.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waves/widgets/common/profile_avatar.dart';
import 'package:go_router/go_router.dart';

// Amber signer provider
final amberSignerProvider = Provider<AmberSigner>(AmberSigner.new);

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(
      Signer.activeProfileProvider(RemoteSource(group: 'default')),
    );
    final pubkey = ref.watch(Signer.activePubkeyProvider);

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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo/title
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.waves,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Welcome to Waves',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Share your moments on Nostr',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // If authenticated, show profile info
                  if (pubkey != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            if (profile?.pictureUrl != null)
                              ProfileAvatar(profile: profile, radius: 40),

                            const SizedBox(height: 12),

                            if (profile?.nameOrNpub != null)
                              Text(
                                profile!.nameOrNpub,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),

                            const SizedBox(height: 4),

                            Text(
                              Utils.encodeShareableIdentifier(
                                    NpubInput(value: pubkey),
                                  ).substring(0, 16) +
                                  '...',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                    fontFamily: 'monospace',
                                  ),
                            ),

                            const SizedBox(height: 20),

                            FilledButton(
                              onPressed: () =>
                                  ref.read(amberSignerProvider).signOut(),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // If not authenticated, show sign-in options
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.security,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),

                            const SizedBox(height: 16),

                            Text(
                              'Secure Authentication',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Sign in with Amber for secure, private key management. Your keys never leave your device.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 24),

                            _buildSignInButton(context, ref),

                            const SizedBox(height: 16),

                            TextButton.icon(
                              onPressed: () => _showAmberInfo(context),
                              icon: const Icon(Icons.info_outline),
                              label: const Text('What is Amber?'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Continue without sign-in option
                  if (pubkey == null)
                    TextButton(
                      onPressed: () {
                        // Navigate to main app without authentication
                        context.go('/app');
                      },
                      child: Text(
                        'Continue without signing in',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context, WidgetRef ref) {
    return AsyncButtonBuilder(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.key, size: 20),
          const SizedBox(width: 8),
          const Text('Sign In with Amber'),
        ],
      ),
      onPressed: () async {
        try {
          await ref.read(amberSignerProvider).signIn();
          // Navigate to main app after successful sign-in
          if (context.mounted) {
            context.go('/app');
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Sign-in failed: Please install Amber app'),
                action: SnackBarAction(
                  label: 'Install',
                  onPressed: () => launchUrl(
                    Uri.parse('https://github.com/greenart7c3/Amber'),
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            );
          }
        }
      },
      builder: (context, child, callback, buttonState) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: buttonState.maybeWhen(
              loading: () => null,
              orElse: () => callback,
            ),
            child: buttonState.maybeWhen(
              loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              orElse: () => child,
            ),
          ),
        );
      },
    );
  }

  void _showAmberInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Amber'),
        content: const Text(
          'Amber is a Nostr event signer app that manages your private keys securely. '
          'It implements NIP-55 to allow other apps to request event signing without '
          'exposing your private keys.\n\n'
          'With Amber, your private keys stay on your device and are never shared with other apps.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              launchUrl(Uri.parse('https://github.com/greenart7c3/Amber'));
            },
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }
}
