import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:waves/screens/photo_feed_screen.dart';
import 'package:waves/screens/profile_screen.dart';
import 'package:models/models.dart';
import 'package:amber_signer/amber_signer.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

// Amber signer provider (same as in sign_in_screen.dart)
final amberSignerProvider = Provider<AmberSigner>(AmberSigner.new);

class MainAppScreen extends HookConsumerWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);
    final activePubkey = ref.watch(Signer.activePubkeyProvider);

    // Define the screens for each tab
    final screens = [
      const PhotoFeedScreen(),
      const SearchScreen(),
      const CameraScreen(),
      const ActivityScreen(),
      activePubkey != null
          ? ProfileScreen(pubkey: activePubkey)
          : const SignInPromptScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex.value, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex.value,
        onTap: (index) => currentIndex.value = index,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Placeholder screens for now
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Search for photos, users, and hashtags',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Camera Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Take photos and share them on Nostr',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // TODO: Implement photo picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo picker coming soon!')),
                );
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Activity Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'See likes, comments, and zaps on your photos',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SignInPromptScreen extends ConsumerWidget {
  const SignInPromptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                  Icons.person_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Sign In Required',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Sign in with Amber to access your profile, post photos, and interact with the community.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Direct sign-in functionality - no intermediate screen
              _buildSignInButton(context, ref),

              const SizedBox(height: 16),

              TextButton.icon(
                onPressed: () => _showAmberInfo(context),
                icon: const Icon(Icons.info_outline),
                label: const Text('What is Amber?'),
              ),

              const SizedBox(height: 16),

              Text(
                'You can still browse photos without signing in',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
                child: CircularProgressIndicator(strokeWidth: 2),
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
        title: Row(
          children: [
            Icon(Icons.security),
            SizedBox(width: 8),
            Text('About Amber'),
          ],
        ),
        content: Text(
          'Amber is a secure key manager for Nostr. It keeps your private keys safe on your device and allows you to sign in to Nostr apps without exposing your keys.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              launchUrl(Uri.parse('https://github.com/greenart7c3/Amber'));
            },
            child: Text('Download'),
          ),
        ],
      ),
    );
  }
}
