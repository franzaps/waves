import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:models/models.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:waves/widgets/common/profile_avatar.dart';
import 'package:waves/widgets/common/time_utils.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:go_router/go_router.dart';

class CommentsScreen extends HookConsumerWidget {
  final String pictureId;

  const CommentsScreen({required this.pictureId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the picture
    final pictureState = ref.watch(
      query<Picture>(
        ids: {pictureId},
        and: (picture) => {
          picture.author,
          picture.comments,
          ...picture.comments.toList().map((comment) => comment.author),
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: switch (pictureState) {
        StorageLoading() => const Center(child: CircularProgressIndicator()),
        StorageError(:final exception) => Center(
          child: Text('Error: $exception'),
        ),
        StorageData(:final models) =>
          models.isEmpty
              ? const Center(child: Text('Picture not found'))
              : _buildCommentsView(context, ref, models.first),
      },
    );
  }

  Widget _buildCommentsView(
    BuildContext context,
    WidgetRef ref,
    Picture picture,
  ) {
    final textController = useTextEditingController();
    final activePubkey = ref.watch(Signer.activePubkeyProvider);
    final comments = picture.comments.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Oldest first

    return Column(
      children: [
        // Original picture preview
        _buildPicturePreview(context, picture),

        const Divider(),

        // Comments list
        Expanded(
          child: comments.isEmpty
              ? const Center(
                  child: Text(
                    'No comments yet.\nBe the first to comment!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return _buildCommentItem(context, comments[index]);
                  },
                ),
        ),

        // Comment input
        if (activePubkey != null)
          _buildCommentInput(context, ref, textController, picture),
      ],
    );
  }

  Widget _buildPicturePreview(BuildContext context, Picture picture) {
    final imageUrls = <String>[];
    if (picture.imageUrl != null) {
      imageUrls.add(picture.imageUrl!);
    }
    imageUrls.addAll(
      picture.allImageUrls.where((url) => url != picture.imageUrl),
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small preview image
          if (imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: SizedBox(
                width: 80,
                height: 80,
                child: CachedNetworkImage(
                  imageUrl: imageUrls.first,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),

          const SizedBox(width: 12),

          // Picture info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToProfile(
                        context,
                        picture.author.value?.pubkey,
                      ),
                      child: ProfileAvatar(
                        profile: picture.author.value,
                        radius: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToProfile(
                          context,
                          picture.author.value?.pubkey,
                        ),
                        child: Text(
                          picture.author.value?.nameOrNpub ?? 'Anonymous',
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Text(
                      TimeUtils.formatTimestamp(picture.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),

                if (picture.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    picture.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(BuildContext context, Comment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () =>
                _navigateToProfile(context, comment.author.value?.pubkey),
            child: ProfileAvatar(profile: comment.author.value, radius: 18),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author and time
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToProfile(
                          context,
                          comment.author.value?.pubkey,
                        ),
                        child: Text(
                          comment.author.value?.nameOrNpub ?? 'Anonymous',
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Text(
                      TimeUtils.formatTimestamp(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Comment content
                Text(
                  comment.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(
    BuildContext context,
    WidgetRef ref,
    TextEditingController textController,
    Picture picture,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // User avatar (current user)
            CircleAvatar(radius: 16, child: Icon(Icons.person, size: 20)),

            const SizedBox(width: 12),

            // Text input
            Expanded(
              child: TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            const SizedBox(width: 8),

            // Post button
            AsyncButtonBuilder(
              child: const Icon(Icons.send),
              onPressed: () => _postComment(ref, textController, picture),
              builder: (context, child, callback, buttonState) {
                return IconButton(
                  icon: buttonState.maybeWhen(
                    loading: () => const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    orElse: () => child,
                  ),
                  onPressed: buttonState.maybeWhen(
                    loading: () => null,
                    orElse: () =>
                        textController.text.trim().isEmpty ? null : callback,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _postComment(
    WidgetRef ref,
    TextEditingController textController,
    Picture picture,
  ) async {
    final content = textController.text.trim();
    if (content.isEmpty) return;

    final signer = ref.read(Signer.activeSignerProvider);
    if (signer == null) return;

    try {
      final comment = PartialComment(content: content, rootModel: picture);

      final signedComment = await comment.signWith(signer);

      // Save locally and publish to relays
      await ref.read(storageNotifierProvider.notifier).save({signedComment});
      await ref.read(storageNotifierProvider.notifier).publish({signedComment});

      // Clear the input
      textController.clear();
    } catch (e) {
      debugPrint('Failed to post comment: $e');
      // TODO: Show error to user
    }
  }

  void _navigateToProfile(BuildContext context, String? pubkey) {
    if (pubkey != null) {
      context.push('/profile/$pubkey');
    }
  }
}
