import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:waves/widgets/common/profile_avatar.dart';
import 'package:waves/widgets/common/time_utils.dart';
import 'package:waves/widgets/common/note_parser.dart';

import 'package:go_router/go_router.dart';
import 'package:async_button_builder/async_button_builder.dart';

class PhotoFeedScreen extends HookConsumerWidget {
  const PhotoFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePubkey = ref.watch(Signer.activePubkeyProvider);

    // Get user's contact list (following) if signed in
    final contactListState = activePubkey != null
        ? ref.watch(query<ContactList>(authors: {activePubkey}, limit: 1))
        : null;

    // Extract following pubkeys if available
    final followingPubkeys =
        contactListState?.models.firstOrNull?.followingPubkeys;

    // Query Picture events (kind 20) - designed for image-centric feeds
    final feedState = ref.watch(
      query<Picture>(
        // If signed in and following people, filter by following; otherwise show all
        authors:
            (activePubkey != null &&
                followingPubkeys != null &&
                followingPubkeys.isNotEmpty)
            ? followingPubkeys
            : null, // null means no filter (show all authors)
        limit: 100, // Increased limit to get more pictures
        and: (picture) => {
          picture.author, // Load author profile
          picture.reactions, // Load reactions for engagement
          picture.zaps, // Load zaps for engagement
          picture.comments, // Load comments
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.waves,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Waves',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt_outlined),
            onPressed: () {
              // TODO: Navigate to camera/photo composer
            },
          ),
        ],
      ),
      body: switch (feedState) {
        StorageLoading() => _buildLoadingSkeleton(),
        StorageError(:final exception) => () {
          debugPrint('Feed error: $exception');
          return _buildErrorWidget(exception);
        }(),
        StorageData(:final models) => () {
          debugPrint('Feed loaded: ${models.length} pictures');
          // Count how many have image URLs
          final picturesWithImages = models
              .where((p) => p.imageUrl != null || p.allImageUrls.isNotEmpty)
              .length;
          debugPrint(
            'Pictures with images: $picturesWithImages/${models.length}',
          );
          return _buildPhotoFeed(models);
        }(),
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      child: Column(
        children: [
          // Header skeleton
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 4),
                      Container(height: 14, width: 80, color: Colors.grey[300]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Image skeleton
          Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey[300],
          ),
          // Engagement skeleton
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(width: 60, height: 20, color: Colors.grey[300]),
                const SizedBox(width: 16),
                Container(width: 60, height: 20, color: Colors.grey[300]),
                const SizedBox(width: 16),
                Container(width: 60, height: 20, color: Colors.grey[300]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object exception) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Failed to load feed',
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

  Widget _buildPhotoFeed(List<Picture> pictures) {
    final picturesWithImages = pictures
        .where((p) => p.imageUrl != null || p.allImageUrls.isNotEmpty)
        .length;
    debugPrint(
      'Building feed: ${pictures.length} total, $picturesWithImages with images',
    );

    if (pictures.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: pictures.length,
      itemBuilder: (context, index) {
        return PhotoCard(picture: pictures[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera_outlined, size: 64, color: Colors.grey[400]),
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
            'Photos shared on Nostr will appear here',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PhotoCard extends HookConsumerWidget {
  final Picture picture;

  const PhotoCard({required this.picture, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Track image loading failures
    final imageLoadFailed = useState(false);

    // Debug: Print picture details (simplified since imeta is now supported)
    debugPrint(
      'PhotoCard ${picture.id}: imageUrl=${picture.imageUrl}, allImageUrls=${picture.allImageUrls}',
    );

    // Get all available image URLs
    final imageUrls = <String>[];
    if (picture.imageUrl != null) {
      imageUrls.add(picture.imageUrl!);
    }
    imageUrls.addAll(
      picture.allImageUrls.where((url) => url != picture.imageUrl),
    );

    // Debug: Print final URLs
    if (imageUrls.isEmpty) {
      debugPrint('No image URLs found for Picture ${picture.id}');
    } else {
      debugPrint('Final imageUrls for PhotoCard: $imageUrls');
    }

    // Determine if we should show images (have URLs and haven't failed to load)
    final shouldShowImages = imageUrls.isNotEmpty && !imageLoadFailed.value;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with profile info
          _buildHeader(context),

          // Photo content - only show if we have image URLs and they haven't failed to load
          if (shouldShowImages) _buildPhotoContent(imageUrls, imageLoadFailed),

          // Caption
          if (picture.description.trim().isNotEmpty) _buildCaption(context),

          // Engagement row
          _buildEngagementSection(context, ref),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: ProfileAvatar(profile: picture.author.value, radius: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToProfile(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    picture.author.value?.nameOrNpub ?? 'Anonymous',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    TimeUtils.formatTimestamp(picture.createdAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoContent(
    List<String> imageUrls,
    ValueNotifier<bool> imageLoadFailed,
  ) {
    if (imageUrls.length == 1) {
      return _buildSinglePhoto(imageUrls.first, imageLoadFailed);
    } else {
      return _buildMultiplePhotos(imageUrls, imageLoadFailed);
    }
  }

  Widget _buildSinglePhoto(
    String imageUrl,
    ValueNotifier<bool> imageLoadFailed,
  ) {
    debugPrint('_buildSinglePhoto: Attempting to load image: $imageUrl');

    return GestureDetector(
      onTap: () {
        // TODO: Open full-screen image viewer
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0), // Moderately rounded images
        child: AspectRatio(
          aspectRatio: 1.0, // Square aspect ratio like Instagram
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) {
              debugPrint('Image loading placeholder for: $url');
              return Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorWidget: (context, url, error) {
              debugPrint(
                'Image load ERROR for $url: $error - hiding image widget',
              );
              // Mark image as failed so the widget gets hidden
              WidgetsBinding.instance.addPostFrameCallback((_) {
                imageLoadFailed.value = true;
              });
              // Return empty container since this will be hidden anyway
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMultiplePhotos(
    List<String> imageUrls,
    ValueNotifier<bool> imageLoadFailed,
  ) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(
              12.0,
            ), // Moderately rounded images
            child: CachedNetworkImage(
              imageUrl: imageUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) {
                debugPrint(
                  'Multiple image load ERROR for $url: $error - hiding image widget',
                );
                // Mark image as failed so the entire widget gets hidden
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  imageLoadFailed.value = true;
                });
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEngagementSection(BuildContext context, WidgetRef ref) {
    final activePubkey = ref.watch(Signer.activePubkeyProvider);

    // Calculate user interaction state
    final userHasLiked =
        activePubkey != null &&
        picture.reactions.toList().any(
          (r) => r.author.value?.pubkey == activePubkey,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Like button with async handling
          _buildAsyncLikeButton(ref, userHasLiked, activePubkey != null),

          // Comment button
          InkWell(
            onTap: () => _handleComment(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.comment_outlined, size: 20),
                  const SizedBox(width: 4),
                  Text('${picture.comments.length}'),
                ],
              ),
            ),
          ),

          // Zap button with async handling
          _buildAsyncZapButton(context, ref, activePubkey != null),
        ],
      ),
    );
  }

  Widget _buildAsyncLikeButton(WidgetRef ref, bool isLiked, bool canInteract) {
    final likesCount = picture.reactions.length;

    if (!canInteract) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: isLiked ? Colors.red : null,
            ),
            const SizedBox(width: 4),
            Text('$likesCount'),
          ],
        ),
      );
    }

    return AsyncButtonBuilder(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: isLiked ? Colors.red : null,
          ),
          const SizedBox(width: 4),
          Text('$likesCount'),
        ],
      ),
      onPressed: () => _handleLike(ref),
      builder: (context, child, callback, buttonState) {
        return InkWell(
          onTap: buttonState.maybeWhen(
            loading: () => null,
            orElse: () => callback,
          ),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: buttonState.maybeWhen(
              loading: () => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 4),
                  Text('$likesCount'),
                ],
              ),
              orElse: () => child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAsyncZapButton(
    BuildContext context,
    WidgetRef ref,
    bool canInteract,
  ) {
    final activePubkey = ref.watch(Signer.activePubkeyProvider);
    final zaps = picture.zaps.toList();
    final zapCount = zaps.length;
    final totalSats = zaps.fold(0, (sum, zap) => sum + zap.amount);
    final zapDisplay = totalSats > 0
        ? _formatSatAmount(totalSats)
        : '$zapCount';

    // Check if current user has zapped this content
    final userHasZapped =
        activePubkey != null &&
        zaps.any((z) => z.author.value?.pubkey == activePubkey);

    final zapColor = userHasZapped
        ? const Color(0xFFFF9800) // Material Orange
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    if (!canInteract) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, size: 20, color: zapColor),
            const SizedBox(width: 4),
            Text(zapDisplay, style: TextStyle(color: zapColor)),
          ],
        ),
      );
    }

    return AsyncButtonBuilder(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 20, color: zapColor),
          const SizedBox(width: 4),
          Text(
            zapDisplay,
            style: TextStyle(
              color: zapColor,
              fontWeight: userHasZapped ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      onPressed: () async {
        // Check NWC connection before allowing zap
        final signer = ref.read(Signer.activeSignerProvider);
        if (signer != null) {
          final nwcString = await signer.getNWCString();
          if (nwcString == null || nwcString.isEmpty) {
            if (context.mounted) {
              _showNwcNotConnectedDialog(context);
            }
            return;
          }
        }
        if (context.mounted) {
          _handleZap(context, ref);
        }
      },
      builder: (context, child, callback, buttonState) {
        return InkWell(
          onTap: buttonState.maybeWhen(
            loading: () => null,
            orElse: () => callback,
          ),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: buttonState.maybeWhen(
              loading: () => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: zapColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    zapDisplay,
                    style: TextStyle(
                      color: zapColor,
                      fontWeight: userHasZapped
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              orElse: () => child,
            ),
          ),
        );
      },
    );
  }

  String _formatSatAmount(int sats) {
    if (sats >= 1000000) return '${(sats / 1000000).toStringAsFixed(1)}M';
    if (sats >= 1000) return '${(sats / 1000).toStringAsFixed(1)}K';
    return '$sats';
  }

  Widget _buildCaption(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: NoteParser.parse(
        context,
        picture.description,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        onHashtagTap: (hashtag) => context.push('/hashtag/$hashtag'),
        onProfileTap: (pubkey) => context.push('/profile/$pubkey'),
        onNostrEntity: (entity) => NostrEntityWidget(
          entity: entity,
          colorPair: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
          onProfileTap: (pubkey) => context.push('/profile/$pubkey'),
          onHashtagTap: (hashtag) => context.push('/hashtag/$hashtag'),
        ),
        onHttpUrl: (url) => UrlChipWidget(
          url: url,
          colorPair: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
        onMediaUrl: (url) => MediaWidget(
          url: url,
          colorPair: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    final authorPubkey = picture.author.value?.pubkey;
    if (authorPubkey != null) {
      context.push('/profile/$authorPubkey');
    }
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.share),
            title: Text('Share'),
            onTap: () async {
              Navigator.pop(context);
              // Copy event ID to clipboard
              await Clipboard.setData(ClipboardData(text: picture.id));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Event ID copied to clipboard'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.bookmark_border),
            title: Text('Save'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement save functionality
            },
          ),
          ListTile(
            leading: Icon(Icons.report_outlined),
            title: Text('Report'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement report functionality
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleLike(WidgetRef ref) async {
    final signer = ref.read(Signer.activeSignerProvider);
    if (signer == null) return;

    final reaction = PartialReaction(
      reactedOn: picture,
      emojiTag: ('+', ''), // Standard like reaction
    );

    final signedReaction = await reaction.signWith(signer);

    // Save locally and publish to relays
    await ref.read(storageNotifierProvider.notifier).save({signedReaction});
    await ref.read(storageNotifierProvider.notifier).publish({signedReaction});
  }

  void _handleComment(BuildContext context) {
    // TODO: Navigate to comment screen
    context.push('/picture/${picture.id}/comments');
  }

  Future<void> _handleZap(BuildContext context, WidgetRef ref) async {
    // Show zap amount and comment selection dialog
    final zapResult = await _showZapDialog(context, ref);

    if (zapResult != null && zapResult.amount > 0) {
      try {
        final signer = ref.read(Signer.activeSignerProvider);
        if (signer == null) {
          throw Exception('No active signer found. Please sign in first.');
        }

        // Check NWC connection
        final nwcString = await signer.getNWCString();
        if (nwcString == null || nwcString.isEmpty) {
          throw Exception(
            'No wallet connected. Please connect a wallet using Nostr Wallet Connect in your profile settings.',
          );
        }

        // Create zap request
        final zapRequest = PartialZapRequest();
        zapRequest.amount =
            zapResult.amount * 1000; // Convert sats to millisats

        if (zapResult.comment.isNotEmpty) {
          zapRequest.comment = zapResult.comment;
        }

        // Link to recipient (content author)
        zapRequest.linkProfileByPubkey(picture.author.value?.pubkey ?? '');

        // Link to the content being zapped
        zapRequest.linkModel(picture);

        // Add relay information for better delivery
        zapRequest.relays = ref
            .read(storageNotifierProvider.notifier)
            .config
            .getRelays()
            .toList();

        // Sign and send the zap
        final signedZapRequest = await zapRequest.signWith(signer);
        await signedZapRequest.pay();

        // Success - show confirmation
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚡ Zap successful! ${zapResult.amount} sats sent'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Handle errors
        _handleZapError(context, e);
      }
    }
  }

  Future<ZapResult?> _showZapDialog(BuildContext context, WidgetRef ref) async {
    return await showDialog<ZapResult>(
      context: context,
      builder: (context) => _ZapDialog(ref: ref, target: picture),
    );
  }

  void _handleZapError(BuildContext context, dynamic error) {
    String message = 'Failed to send zap: $error';

    if (error.toString().contains('No NWC connection') ||
        error.toString().contains('No wallet connected')) {
      message =
          'No wallet connected. Please connect a wallet using Nostr Wallet Connect in your profile settings.';
    } else if (error.toString().contains('expired')) {
      message =
          'Nostr Wallet Connect session expired. Please reconnect in your profile settings.';
    } else if (error.toString().contains('invoice')) {
      message = 'The author doesn\'t have Lightning receiving setup.';
    } else if (error.toString().contains('insufficient')) {
      message = 'Insufficient balance in your Lightning wallet.';
    } else if (error.toString().contains('rate limit')) {
      message = 'Too many requests. Please wait and try again.';
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}

class ZapResult {
  final int amount;
  final String comment;

  const ZapResult({required this.amount, required this.comment});
}

class _ZapDialog extends HookConsumerWidget {
  final WidgetRef ref;
  final Picture target;

  const _ZapDialog({required this.ref, required this.target});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAmount = useState<int>(21);
    final comment = useState<String>('');
    final customController = useTextEditingController();
    final commentController = useTextEditingController();

    final quickAmounts = [21, 100, 500, 1000, 5000];

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.flash_on, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 8),
          Text('Send Zap'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select amount in sats:'),
            SizedBox(height: 16),

            // Quick amount buttons
            Wrap(
              spacing: 8,
              children: quickAmounts.map((amount) {
                final isSelected = selectedAmount.value == amount;
                return FilterChip(
                  label: Text('$amount'),
                  selected: isSelected,
                  onSelected: (selected) {
                    selectedAmount.value = amount;
                    customController.clear();
                  },
                );
              }).toList(),
            ),

            SizedBox(height: 16),

            // Custom amount input
            TextField(
              controller: customController,
              decoration: InputDecoration(
                labelText: 'Custom amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final customAmount = int.tryParse(value);
                if (customAmount != null) {
                  selectedAmount.value = customAmount;
                }
              },
            ),

            SizedBox(height: 16),

            // Optional comment
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Comment (Optional)',
                hintText: 'Add a message with your zap...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                comment.value = value;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        AsyncButtonBuilder(
          onPressed: selectedAmount.value > 0
              ? () => _sendZap(
                  context,
                  selectedAmount.value,
                  commentController.text,
                )
              : null,
          child: Text('Zap ${selectedAmount.value} sats'),
          builder: (context, child, callback, buttonState) {
            return FilledButton(
              onPressed: buttonState.maybeWhen(
                loading: () => null,
                orElse: () => callback,
              ),
              child: buttonState.maybeWhen(
                loading: () => SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                orElse: () => child,
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _sendZap(
    BuildContext context,
    int amount,
    String comment,
  ) async {
    final result = ZapResult(amount: amount, comment: comment);
    Navigator.pop(context, result);
  }
}

// Helper method to show NWC connection dialog
void _showNwcNotConnectedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.flash_off, color: Colors.orange),
          SizedBox(width: 8),
          Text('Wallet Not Connected'),
        ],
      ),
      content: Text(
        'You need to connect a wallet using Nostr Wallet Connect to send zaps. Would you like to set one up now?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Maybe Later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            if (context.mounted) {
              context.push('/settings/nwc');
            }
          },
          child: Text('Connect Wallet'),
        ),
      ],
    ),
  );
}
