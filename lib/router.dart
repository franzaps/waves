import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:waves/screens/main_app_screen.dart';
import 'package:waves/screens/profile_screen.dart';
import 'package:waves/screens/comments_screen.dart';
import 'package:waves/screens/sign_in_screen.dart';
import 'package:waves/screens/nwc_settings_screen.dart';
import 'package:waves/screens/hashtag_screen.dart';
import 'package:waves/screens/picture_detail_screen.dart';
import 'package:waves/widgets/app_initializer.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppInitializer()),
      GoRoute(path: '/app', builder: (context, state) => const MainAppScreen()),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/profile/:pubkey',
        builder: (context, state) {
          final pubkey = state.pathParameters['pubkey']!;
          return ProfileScreen(pubkey: pubkey);
        },
      ),
      GoRoute(
        path: '/picture/:pictureId/comments',
        builder: (context, state) {
          final pictureId = state.pathParameters['pictureId']!;
          return CommentsScreen(pictureId: pictureId);
        },
      ),
      GoRoute(
        path: '/settings/nwc',
        builder: (context, state) => const NwcSettingsScreen(),
      ),
      GoRoute(
        path: '/hashtag/:hashtag',
        builder: (context, state) {
          final hashtag = state.pathParameters['hashtag']!;
          return HashtagScreen(hashtag: hashtag);
        },
      ),
      GoRoute(
        path: '/picture/:pictureId',
        builder: (context, state) {
          final pictureId = state.pathParameters['pictureId']!;
          return PictureDetailScreen(pictureId: pictureId);
        },
      ),
    ],
  );
});
