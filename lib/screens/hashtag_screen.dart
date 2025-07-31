import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class HashtagScreen extends ConsumerWidget {
  final String hashtag;

  const HashtagScreen({required this.hashtag, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load pictures with the specific hashtag
    final picturesState = ref.watch(
      query<Picture>(
        tags: {
          '#t': {hashtag}, // Using 't' tag for topics/hashtags
        },
        limit: 100,
        and: (picture) => {
          picture.author,
          picture.reactions,
          picture.zaps,
          picture.comments,
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('#$hashtag'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHashtagInfo(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header with hashtag info
          SliverToBoxAdapter(
            child: switch (picturesState) {
              StorageData(:final models) => _buildHashtagHeader(
                context,
                models.length,
              ),
              _ => _buildHashtagHeader(context, 0),
            },
          ),

          // Pictures grid
          switch (picturesState) {
            StorageLoading() => SliverToBoxAdapter(child: _buildLoadingGrid()),
            StorageError(:final exception) => SliverToBoxAdapter(
              child: _buildErrorWidget(context, exception),
            ),
            StorageData(:final models) =>
              models.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState(context))
                  : _buildPhotoGrid(models),
          },
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object exception) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Failed to load hashtag',
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tag, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No photos found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No photos have been tagged with #$hashtag yet',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Browse Other Content'),
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

  Widget _buildPhotoGrid(List<Picture> pictures) {
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

  Widget _buildHashtagHeader(BuildContext context, int photoCount) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#$hashtag',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$photoCount ${photoCount == 1 ? 'photo' : 'photos'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showHashtagInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('#$hashtag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This hashtag is used to categorize and discover photos.'),
            const SizedBox(height: 12),
            Text(
              'Hashtags help connect people with similar interests and make content more discoverable.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
