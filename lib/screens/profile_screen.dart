import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:waves/widgets/common/profile_avatar.dart';
import 'package:waves/widgets/common/note_parser.dart';
import 'package:go_router/go_router.dart';
import 'package:amber_signer/amber_signer.dart';

// Amber signer provider (same as in sign_in_screen.dart)
final amberSignerProvider = Provider<AmberSigner>(AmberSigner.new);

class ProfileScreen extends HookConsumerWidget {
  final String pubkey;

  const ProfileScreen({required this.pubkey, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load profile
    final profileState = ref.watch(query<Profile>(authors: {pubkey}));

    // Check if this is the current user's profile
    final activePubkey = ref.watch(Signer.activePubkeyProvider);
    final isOwnProfile = activePubkey == pubkey;

    // Load user's picture posts
    final userPicturesState = ref.watch(
      query<Picture>(
        authors: {pubkey},
        limit: 50,
        and: (picture) => {
          picture.author,
          picture.reactions,
          picture.zaps,
          picture.comments,
        },
      ),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: switch (profileState) {
                StorageData(:final models) =>
                  models.isNotEmpty
                      ? _buildProfileHeader(context, models.first)
                      : _buildEmptyProfileHeader(context),
                _ => _buildEmptyProfileHeader(context),
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () =>
                    _showProfileOptions(context, ref, isOwnProfile),
              ),
            ],
          ),

          // Photo grid
          switch (userPicturesState) {
            StorageLoading() => SliverToBoxAdapter(child: _buildLoadingGrid()),
            StorageError(:final exception) => SliverToBoxAdapter(
              child: _buildErrorWidget(exception),
            ),
            StorageData(:final models) => _buildPhotoGrid(models),
          },
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Profile profile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Profile picture
            ProfileAvatar(profile: profile, radius: 50),
            const SizedBox(height: 16),

            // Display name
            Text(
              profile.nameOrNpub,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            // Username/npub
            Text(
              _formatPubkey(profile.pubkey),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),

            const SizedBox(height: 12),

            // Bio
            if (profile.about != null && profile.about!.isNotEmpty) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 80),
                child: SingleChildScrollView(
                  child: NoteParser.parse(
                    context,
                    profile.about!,
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      textBaseline: TextBaseline.alphabetic,
                    ),
                    onNostrEntity: (entity) {
                      return NostrEntityWidget(
                        entity: entity,
                        colorPair: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primaryContainer,
                        ],
                        onProfileTap: (pubkey) =>
                            context.push('/profile/$pubkey'),
                      );
                    },
                    onHashtag: (hashtag) => GestureDetector(
                      onTap: () => context.push('/hashtag/$hashtag'),
                      child: Text(
                        '#$hashtag',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProfileHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Empty profile picture
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: Icon(Icons.person, size: 50, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            Text(
              'Loading profile...',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            Text(
              _formatPubkey(pubkey),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 9,
        itemBuilder: (context, index) => Container(color: Colors.grey[300]),
      ),
    );
  }

  Widget _buildErrorWidget(Object exception) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Failed to load posts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exception.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<Picture> pictures) {
    if (pictures.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No photos yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Photos shared by this user will appear here',
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(4.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final picture = pictures[index];
          final imageUrl = picture.imageUrl ?? picture.allImageUrls.firstOrNull;

          return AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () => context.push('/picture/${picture.id}'),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
            ),
          );
        }, childCount: pictures.length),
      ),
    );
  }

  String _formatPubkey(String pubkey) {
    try {
      final npub = Utils.encodeShareableIdentifier(NpubInput(value: pubkey));
      // Show first 16 characters of npub + "..."
      return '${npub.substring(0, 16)}...';
    } catch (e) {
      // Fallback to hex format if npub encoding fails
      if (pubkey.length <= 16) return pubkey;
      return '${pubkey.substring(0, 8)}...${pubkey.substring(pubkey.length - 8)}';
    }
  }

  void _showProfileOptions(
    BuildContext context,
    WidgetRef ref,
    bool isOwnProfile,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOwnProfile) ...[
            ListTile(
              leading: Icon(Icons.flash_on),
              title: Text('Nostr Wallet Connect'),
              subtitle: Text('Configure zap payments'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings/nwc');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Profile Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement profile settings functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () => _handleSignOut(context, ref),
            ),
            Divider(),
          ],
          ListTile(
            leading: Icon(Icons.share),
            title: Text('Share Profile'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement share profile functionality
            },
          ),
          if (!isOwnProfile) ...[
            ListTile(
              leading: Icon(Icons.block),
              title: Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.report_outlined),
              title: Text('Report User'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report functionality
              },
            ),
          ],
        ],
      ),
    );
  }

  void _handleSignOut(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context); // Close the bottom sheet first

    try {
      // Sign out immediately - no confirmation needed
      await ref.read(amberSignerProvider).signOut();

      if (context.mounted) {
        // Navigate immediately to sign-in screen
        context.go('/signin');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully signed out'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
