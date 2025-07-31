import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:waves/screens/photo_feed_screen.dart';

class PictureDetailScreen extends ConsumerWidget {
  final String pictureId;

  const PictureDetailScreen({required this.pictureId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load the specific picture by ID
    final pictureState = ref.watch(
      query<Picture>(
        ids: {pictureId},
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
        title: const Text('Photo'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePicture(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showPictureOptions(context),
          ),
        ],
      ),
      body: switch (pictureState) {
        StorageLoading() => const Center(child: CircularProgressIndicator()),
        StorageError(:final exception) => _buildErrorWidget(context, exception),
        StorageData(:final models) =>
          models.isEmpty
              ? _buildNotFoundWidget(context)
              : SingleChildScrollView(child: PhotoCard(picture: models.first)),
      },
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
              'Failed to load photo',
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

  Widget _buildNotFoundWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Photo not found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This photo may have been deleted or is no longer available',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePicture(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _showPictureOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              _sharePicture(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('Save'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement save functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Save functionality coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy Link'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement copy link functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copy link functionality coming soon'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_outlined),
            title: const Text('Report'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement report functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report functionality coming soon'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
