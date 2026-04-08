import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers.dart';
import 'models.dart';
import 'screens.dart';

class CookbookApp extends StatelessWidget {
  const CookbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'My Flutter Cookbook',
            debugShowCheckedModeBanner: false,
            themeMode: themeController.mode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            initialRoute: HomeScreen.routeName,
            routes: {
              HomeScreen.routeName: (_) => const HomeScreen(),
              FavoritesScreen.routeName: (_) => const FavoritesScreen(),
              MyRecipesScreen.routeName: (_) => const MyRecipesScreen(),
              AuthScreen.routeName: (_) => const AuthScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == SearchScreen.routeName) {
                final args = settings.arguments as SearchArguments?;
                return MaterialPageRoute<void>(
                  builder: (_) => SearchScreen(initialArgs: args),
                  settings: settings,
                );
              }

              if (settings.name == RecipeDetailScreen.routeName) {
                final mealId = settings.arguments as String;
                return MaterialPageRoute<void>(
                  builder: (_) => RecipeDetailScreen(mealId: mealId),
                  settings: settings,
                );
              }

              return null;
            },
          );
        },
      ),
    );
  }
}

class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: isDark ? const Color(0xFFEB6F92) : const Color(0xFFB4637A),
        brightness: brightness,
      ).copyWith(
        primary: isDark ? const Color(0xFFEB6F92) : const Color(0xFFB4637A),
        onPrimary: Colors.white,
        secondary: isDark ? const Color(0xFFC4A7E7) : const Color(0xFF907AA9),
        onSecondary: isDark ? const Color(0xFF191724) : Colors.white,
        tertiary: isDark ? const Color(0xFFF6C177) : const Color(0xFFEA9D34),
        onTertiary: isDark ? const Color(0xFF191724) : Colors.white,
        surface: isDark ? const Color(0xFF040308) : const Color(0xFFFAF4ED),
        onSurface: isDark ? const Color(0xFFE0DEF4) : const Color(0xFF575279),
        onSurfaceVariant: isDark
            ? const Color(0xFFA8A3BF)
            : const Color(0xFF797593),
        surfaceContainerLowest: isDark
            ? const Color(0xFF09070F)
            : const Color(0xFFFFFCF8),
        surfaceContainerLow: isDark
            ? const Color(0xFF12101A)
            : const Color(0xFFFFFAF3),
        surfaceContainer: isDark
            ? const Color(0xFF171422)
            : const Color(0xFFF8EFE7),
        surfaceContainerHigh: isDark
            ? const Color(0xFF1E1A2C)
            : const Color(0xFFF2E9E1),
        surfaceContainerHighest: isDark
            ? const Color(0xFF241F35)
            : const Color(0xFFEADFD4),
        outline: isDark ? const Color(0xFF524F67) : const Color(0xFFD3C7BB),
        outlineVariant: isDark
            ? const Color(0xFF403D52)
            : const Color(0xFFE4D7CA),
        error: isDark ? const Color(0xFFFF6B97) : const Color(0xFFB4637A),
        onError: Colors.white,
      );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'sans-serif',
  );

  return base.copyWith(
    scaffoldBackgroundColor: isDark ? const Color(0xFF020106) : scheme.surface,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _InstantPageTransitionsBuilder(),
        TargetPlatform.iOS: _InstantPageTransitionsBuilder(),
        TargetPlatform.macOS: _InstantPageTransitionsBuilder(),
        TargetPlatform.windows: _InstantPageTransitionsBuilder(),
        TargetPlatform.linux: _InstantPageTransitionsBuilder(),
      },
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      backgroundColor: scheme.surfaceContainer,
      selectedColor: scheme.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      elevation: 0,
      height: 74,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.surfaceContainerHigh,
      contentTextStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
    ),
    textTheme: base.textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.5),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
  );
}
