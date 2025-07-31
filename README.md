# Waves

![Waves](assets/images/waves_icon.svg)

A Nostr-enabled Flutter photo sharing application built with the Purplestack development stack. Waves allows users to share and discover photos through the decentralized Nostr network, featuring real-time feeds, user profiles, hashtag browsing, and social interactions.

## Features

- **Photo Sharing**: Upload and share photos with the Nostr community
- **Real-time Feeds**: View photos from followed users and discover new content
- **User Profiles**: Customize your profile and view others' photo collections
- **Hashtag Browsing**: Explore photos by hashtags and trending topics
- **Social Interactions**: Like, comment, and engage with photos
- **Decentralized**: Built on Nostr protocol for censorship-resistant sharing
- **Android-focused**: Optimized for Android mobile devices

## Technology Stack

- **Flutter**: Cross-platform UI framework
- **Nostr Protocol**: Decentralized social networking protocol
- **Purplebase**: Local-first Nostr SDK with storage and relay pool
- **Riverpod**: State management and dependency injection
- **Material 3**: Modern design system with light/dark themes

## Development Setup

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio (for Android development)
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd waves
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

### Environment Setup

For detailed environment setup instructions, see the [Purplestack documentation](https://purplestack.io).

## Building for Production

### Android
```bash
flutter build apk --target-platform android-arm64
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see LICENSE file for details.

---

Powered by [Purplestack](https://purplestack.io)