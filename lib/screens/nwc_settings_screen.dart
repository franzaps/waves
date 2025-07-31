import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:url_launcher/url_launcher.dart';

class NwcSettingsScreen extends HookConsumerWidget {
  const NwcSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nwcController = useTextEditingController();
    final signer = ref.watch(Signer.activeSignerProvider);
    final connectionStatus = useState<ConnectionStatus>(
      ConnectionStatus.checking,
    );
    final hasText = useState<bool>(false);

    // Check current NWC connection on screen load
    useEffect(() {
      _checkCurrentConnection(signer, connectionStatus, nwcController, hasText);
      return null;
    }, [signer]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nostr Wallet Connect'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection status card
              _buildConnectionStatusCard(context, connectionStatus.value),

              const SizedBox(height: 24),

              // What is NWC info
              _buildInfoCard(context),

              const SizedBox(height: 24),

              // NWC connection form
              _buildConnectionForm(
                context,
                ref,
                nwcController,
                signer,
                connectionStatus,
                hasText,
              ),

              const SizedBox(height: 24),

              // Compatible wallets info
              _buildCompatibleWalletsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(
    BuildContext context,
    ConnectionStatus status,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Wallet Connection',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusMessage(status),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (status == ConnectionStatus.connected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Chip(
                  label: const Text('⚡ Ready to Zap'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'About Nostr Wallet Connect',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Connect your Lightning wallet to send zaps (Bitcoin tips) to content creators using Nostr Wallet Connect (NWC). Your wallet stays secure and you control all payments.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionForm(
    BuildContext context,
    WidgetRef ref,
    TextEditingController controller,
    Signer? signer,
    ValueNotifier<ConnectionStatus> connectionStatus,
    ValueNotifier<bool> hasText,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wallet Connection String',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              enabled: connectionStatus.value != ConnectionStatus.connected,
              decoration: InputDecoration(
                hintText: connectionStatus.value == ConnectionStatus.connected
                    ? 'Wallet connected'
                    : 'nostr+walletconnect://...',
                border: const OutlineInputBorder(),
                helperText: connectionStatus.value == ConnectionStatus.connected
                    ? 'Your wallet connection is active'
                    : 'Get this from your NWC-compatible wallet app',
                prefixIcon: Icon(
                  connectionStatus.value == ConnectionStatus.connected
                      ? Icons.check_circle
                      : Icons.link,
                  color: connectionStatus.value == ConnectionStatus.connected
                      ? Colors.green
                      : null,
                ),
              ),
              maxLines: 3,
              keyboardType: TextInputType.url,
              onChanged: (value) {
                hasText.value = value.trim().isNotEmpty;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (connectionStatus.value != ConnectionStatus.connected)
                  Expanded(
                    child: AsyncButtonBuilder(
                      onPressed: signer != null && hasText.value
                          ? () => _connectWallet(
                              context,
                              signer,
                              controller.text.trim(),
                              connectionStatus,
                            )
                          : null,
                      child: const Text('Connect Wallet'),
                      builder: (context, child, callback, buttonState) {
                        return FilledButton.icon(
                          onPressed: buttonState.maybeWhen(
                            loading: () => null,
                            orElse: () => callback,
                          ),
                          icon: buttonState.maybeWhen(
                            loading: () => const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            orElse: () => const Icon(Icons.flash_on),
                          ),
                          label: child,
                        );
                      },
                    ),
                  ),
                if (connectionStatus.value == ConnectionStatus.connected) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _disconnectWallet(
                        signer,
                        controller,
                        connectionStatus,
                        hasText,
                      ),
                      icon: const Icon(Icons.link_off),
                      label: const Text('Disconnect Wallet'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibleWalletsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compatible Wallets',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Works with wallets that support Nostr Wallet Connect (NWC) protocol:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Alby')),
                Chip(label: Text('Mutiny')),
                Chip(label: Text('Cashu.me')),
                Chip(label: Text('NWC-compatible wallets')),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _launchUrl('https://nwc.dev/'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Learn more about NWC'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkCurrentConnection(
    Signer? signer,
    ValueNotifier<ConnectionStatus> status,
    TextEditingController controller,
    ValueNotifier<bool> hasText,
  ) async {
    if (signer == null) return;

    try {
      final nwcString = await signer.getNWCString();
      if (nwcString != null && nwcString.isNotEmpty) {
        // Mask the connection string for display (show first/last few chars)
        controller.text = _maskConnectionString(nwcString);
        hasText.value = true;
        status.value = ConnectionStatus.connected;
      } else {
        status.value = ConnectionStatus.disconnected;
        hasText.value = false;
      }
    } catch (e) {
      status.value = ConnectionStatus.error;
      hasText.value = false;
    }
  }

  Future<void> _connectWallet(
    BuildContext context,
    Signer signer,
    String nwcString,
    ValueNotifier<ConnectionStatus> status,
  ) async {
    try {
      status.value = ConnectionStatus.connecting;

      // Validate NWC string format
      if (!nwcString.startsWith('nostr+walletconnect://')) {
        throw Exception('Invalid NWC connection string format');
      }

      // Store the NWC connection
      await signer.setNWCString(nwcString);

      status.value = ConnectionStatus.connected;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Lightning wallet connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      status.value = ConnectionStatus.error;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect wallet: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectWallet(
    Signer? signer,
    TextEditingController controller,
    ValueNotifier<ConnectionStatus> status,
    ValueNotifier<bool> hasText,
  ) async {
    if (signer == null) return;

    try {
      await signer.setNWCString('');
      controller.clear();
      hasText.value = false;
      status.value = ConnectionStatus.disconnected;
    } catch (e) {
      status.value = ConnectionStatus.error;
    }
  }

  String _maskConnectionString(String nwcString) {
    if (nwcString.length <= 20) return nwcString;
    return '${nwcString.substring(0, 15)}...${nwcString.substring(nwcString.length - 15)}';
  }

  IconData _getStatusIcon(ConnectionStatus status) {
    return switch (status) {
      ConnectionStatus.checking => Icons.sync,
      ConnectionStatus.connected => Icons.check_circle,
      ConnectionStatus.connecting => Icons.sync,
      ConnectionStatus.disconnected => Icons.flash_off,
      ConnectionStatus.error => Icons.error,
    };
  }

  Color _getStatusColor(ConnectionStatus status) {
    return switch (status) {
      ConnectionStatus.checking => Colors.grey,
      ConnectionStatus.connected => Colors.green,
      ConnectionStatus.connecting => Colors.blue,
      ConnectionStatus.disconnected => Colors.grey,
      ConnectionStatus.error => Colors.red,
    };
  }

  String _getStatusMessage(ConnectionStatus status) {
    return switch (status) {
      ConnectionStatus.checking => 'Checking wallet connection...',
      ConnectionStatus.connected =>
        'Your wallet is connected via Nostr Wallet Connect and ready to send zaps.',
      ConnectionStatus.connecting =>
        'Connecting to your wallet via Nostr Wallet Connect...',
      ConnectionStatus.disconnected =>
        'No wallet connected. Connect one using Nostr Wallet Connect to send zaps.',
      ConnectionStatus.error =>
        'Error connecting to your wallet via Nostr Wallet Connect. Please try again.',
    };
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

enum ConnectionStatus { checking, connected, connecting, disconnected, error }
