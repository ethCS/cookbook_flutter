import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers.dart';
import 'models.dart';
import 'services.dart';

void _warmMealImages(BuildContext context, Iterable<Meal> meals) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final meal in meals.take(12)) {
      final imageUrl = InputSanitizer.safeHttpUrl(meal.imageUrl);
      if (imageUrl.isEmpty) continue;

      precacheImage(
        NetworkImage(
          imageUrl,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        ),
        context,
      );
    }
  });
}

class CookbookScaffold extends StatelessWidget {
  const CookbookScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
  });

  final String title;
  final String currentRoute;
  final Widget child;

  static const _routes = <String>[
    HomeScreen.routeName,
    SearchScreen.routeName,
    FavoritesScreen.routeName,
    MyRecipesScreen.routeName,
  ];

  void _navigate(BuildContext context, int index) {
    final route = _routes[index];
    if (route == currentRoute) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final themeController = context.watch<ThemeController>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 920;
    final selectedIndex = _routes.contains(currentRoute)
        ? _routes.indexOf(currentRoute)
        : 0;

    final destinations = const <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search),
        label: 'Search',
      ),
      NavigationDestination(
        icon: Icon(Icons.favorite_border),
        selectedIcon: Icon(Icons.favorite),
        label: 'Favorites',
      ),
      NavigationDestination(
        icon: Icon(Icons.book_outlined),
        selectedIcon: Icon(Icons.book),
        label: 'My Recipes',
      ),
    ];

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final content = SafeArea(child: SelectionArea(child: child));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(HomeScreen.routeName, (route) => false),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Find your next favorite recipe',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'Theme',
            initialValue: themeController.mode,
            icon: const Icon(Icons.palette_outlined),
            onSelected: (mode) => context.read<ThemeController>().setMode(mode),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ThemeMode.system,
                child: Text('System theme'),
              ),
              PopupMenuItem(value: ThemeMode.light, child: Text('Light theme')),
              PopupMenuItem(value: ThemeMode.dark, child: Text('Dark theme')),
            ],
          ),
          if (auth.user == null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    Navigator.pushNamed(context, AuthScreen.routeName),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Sign in'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'logout') {
                    await context.read<AuthController>().signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signed out successfully.'),
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    value: 'email',
                    child: Text(auth.user?.email ?? 'Signed in'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Log out'),
                  ),
                ],
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primary.withValues(alpha: 0.18),
                  foregroundColor: scheme.primary,
                  child: Text(
                    (auth.user?.email?.trim().isNotEmpty ?? false)
                        ? auth.user!.email!.trim()[0].toUpperCase()
                        : 'U',
                  ),
                ),
              ),
            ),
        ],
      ),
      body: content,
      bottomNavigationBar: isWide
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: NavigationBar(
                  selectedIndex: selectedIndex,
                  animationDuration: Duration.zero,
                  onDestinationSelected: (index) => _navigate(context, index),
                  destinations: destinations,
                ),
              ),
            ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _loading = true;
  List<Meal> _featured = const [];
  List<String> _categories = const [];

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHome() async {
    setState(() => _loading = true);
    try {
      final featured = await MealDbService.instance.randomMeals(count: 8);
      final categories = await MealDbService.instance.categories();
      if (!mounted) return;
      setState(() {
        _featured = featured;
        _categories = categories.take(10).toList();
      });
      _warmMealImages(context, featured);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load recipes right now.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refreshFeatured() async {
    MealDbService.instance.clearRandomCache();
    await _loadHome();
  }

  void _openSearch({String? query, String? category}) {
    final cleanedQuery = query == null
        ? null
        : InputSanitizer.cleanText(query, maxLength: 60);
    Navigator.pushNamed(
      context,
      SearchScreen.routeName,
      arguments: SearchArguments(query: cleanedQuery, category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CookbookScaffold(
      title: 'My Flutter Cookbook',
      currentRoute: HomeScreen.routeName,
      child: RefreshIndicator(
        onRefresh: _refreshFeatured,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final theme = Theme.of(context);
                final scheme = theme.colorScheme;
                final isDark = theme.brightness == Brightness.dark;
                final stacked = constraints.maxWidth < 640;

                final searchField = SelectionContainer.disabled(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _openSearch(query: value.trim());
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search any dish or ingredient…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                );

                final searchButton = FilledButton.icon(
                  onPressed: () {
                    if (_searchController.text.trim().isNotEmpty) {
                      _openSearch(query: _searchController.text.trim());
                    }
                  },
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Search'),
                );

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Your personal cookbook',
                              style: TextStyle(
                                color: scheme.primary,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Cook something\n',
                                  style: TextStyle(color: scheme.onSurface),
                                ),
                                TextSpan(
                                  text: 'worth remembering.',
                                  style: TextStyle(color: scheme.primary),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style:
                                (theme.textTheme.displayMedium ??
                                        theme.textTheme.headlineMedium)
                                    ?.copyWith(
                                      fontSize: stacked ? 44 : 64,
                                      fontWeight: FontWeight.w700,
                                      height: 0.98,
                                      letterSpacing: -1.0,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.34 : 0.08,
                                          ),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Search quickly, save the dishes you love, and build a cookbook that feels personal.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!stacked) ...[
                            const _InlineNavRow(
                              currentRoute: HomeScreen.routeName,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (stacked) ...[
                            searchField,
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: searchButton,
                            ),
                          ] else
                            Row(
                              children: [
                                Expanded(child: searchField),
                                const SizedBox(width: 12),
                                searchButton,
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Browse by category'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final category in _categories)
                      ActionChip(
                        label: Text(category),
                        onPressed: () => _openSearch(category: category),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Featured recipes',
              actionIcon: Icons.refresh_rounded,
              actionTooltip: 'Refresh featured recipes',
              onAction: _refreshFeatured,
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _MealGrid(meals: _featured),
          ],
        ),
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialArgs});

  static const routeName = '/search';
  final SearchArguments? initialArgs;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _queryController;
  bool _loading = false;
  bool _searched = false;
  String _headline = 'Search the MealDB catalog';
  List<Meal> _results = const [];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(
      text: widget.initialArgs?.query ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final category = widget.initialArgs?.category;
      final query = widget.initialArgs?.query;
      if (category != null && category.trim().isNotEmpty) {
        _runCategorySearch(category.trim());
      } else if (query != null && query.trim().isNotEmpty) {
        _runTextSearch(query.trim());
      }
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _runTextSearch(String query) async {
    setState(() {
      _loading = true;
      _searched = true;
      _headline = 'Results for “$query”';
    });

    try {
      final results = await MealDbService.instance.search(query);
      if (!mounted) return;
      setState(() => _results = results);
      _warmMealImages(context, results);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _runCategorySearch(String category) async {
    setState(() {
      _loading = true;
      _searched = true;
      _headline = 'Category: $category';
      _queryController.text = category;
    });

    try {
      final results = await MealDbService.instance.byCategory(category);
      if (!mounted) return;
      setState(() => _results = results);
      _warmMealImages(context, results);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category search failed.')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CookbookScaffold(
      title: 'Search recipes',
      currentRoute: SearchScreen.routeName,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: SelectionContainer.disabled(
                  child: TextField(
                    controller: _queryController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _runTextSearch(value.trim());
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search any recipe…',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () {
                  final query = _queryController.text.trim();
                  if (query.isNotEmpty) {
                    _runTextSearch(query);
                  }
                },
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _headline,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (_searched && !_loading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_results.length} result${_results.length == 1 ? '' : 's'} found',
              ),
            ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_searched && _results.isEmpty)
            const _EmptyState(
              title: 'No recipes found',
              message: 'Try a different ingredient or meal name.',
            )
          else if (!_searched)
            const _EmptyState(
              title: 'Start your search',
              message:
                  'Enter a dish name or choose a category from the home page.',
            )
          else
            _MealGrid(meals: _results),
        ],
      ),
    );
  }
}

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.mealId});

  static const routeName = '/recipe';
  final String mealId;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<Meal?> _future;

  @override
  void initState() {
    super.initState();
    _future = MealDbService.instance.mealById(widget.mealId);
  }

  Future<void> _toggleFavorite(Meal meal, bool saved) async {
    final user = context.read<AuthController>().user;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushNamed(context, AuthScreen.routeName);
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(meal.id);

    if (saved) {
      await docRef.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from favorites.')));
      return;
    }

    final safeImageUrl = InputSanitizer.safeHttpUrl(meal.imageUrl);
    if (safeImageUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This recipe image URL could not be verified.'),
        ),
      );
      return;
    }

    await docRef.set({
      'recipeId': meal.id,
      'title': InputSanitizer.cleanText(meal.name, maxLength: 120),
      'image': safeImageUrl,
      'category': InputSanitizer.cleanText(meal.category, maxLength: 60),
      'source': 'themealdb',
      'addedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Added to favorites.')));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;

    return FutureBuilder<Meal?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CookbookScaffold(
            title: 'Recipe details',
            currentRoute: HomeScreen.routeName,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final meal = snapshot.data;
        if (meal == null) {
          return const CookbookScaffold(
            title: 'Recipe details',
            currentRoute: HomeScreen.routeName,
            child: _EmptyState(
              title: 'Recipe not found',
              message: 'This meal could not be loaded from the API.',
            ),
          );
        }

        final favoriteDoc = user == null
            ? null
            : FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('favorites')
                  .doc(meal.id);

        return CookbookScaffold(
          title: meal.name,
          currentRoute: HomeScreen.routeName,
          child: SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _RemoteMealImage(
                          imageUrl: meal.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (meal.category.isNotEmpty)
                      Chip(label: Text(meal.category)),
                    if (meal.area.isNotEmpty) Chip(label: Text(meal.area)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        meal.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (favoriteDoc != null)
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: favoriteDoc.snapshots(),
                        builder: (context, snapshot) {
                          final saved = snapshot.data?.exists ?? false;
                          return FilledButton.icon(
                            onPressed: () => _toggleFavorite(meal, saved),
                            icon: Icon(
                              saved ? Icons.favorite : Icons.favorite_border,
                            ),
                            label: Text(saved ? 'Saved' : 'Save'),
                          );
                        },
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, AuthScreen.routeName),
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in to save'),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _DetailPanel(
                  title: 'Ingredients',
                  child: Column(
                    children: [
                      for (final item in meal.ingredients)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.name),
                          trailing: Text(item.measure),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DetailPanel(
                  title: 'Instructions',
                  child: Text(
                    meal.instructions.isEmpty
                        ? 'No instructions provided.'
                        : meal.instructions,
                    style: const TextStyle(height: 1.6),
                  ),
                ),
                if ((meal.sourceUrl ?? '').isNotEmpty ||
                    (meal.youtubeUrl ?? '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _DetailPanel(
                    title: 'Source links',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((meal.sourceUrl ?? '').isNotEmpty)
                          SelectableText('Original recipe: ${meal.sourceUrl}'),
                        if ((meal.youtubeUrl ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SelectableText('YouTube: ${meal.youtubeUrl}'),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const routeName = '/favorites';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;

    if (user == null) {
      return const CookbookScaffold(
        title: 'Favorites',
        currentRoute: FavoritesScreen.routeName,
        child: _AuthRequiredCard(
          title: 'Sign in to save favorites',
          message: 'Save the dishes you love and revisit them anytime.',
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots();

    return CookbookScaffold(
      title: 'Favorites',
      currentRoute: FavoritesScreen.routeName,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? const [];
          final meals = docs
              .map((doc) => Meal.fromFavorite(doc.data()))
              .toList();

          if (meals.isEmpty) {
            return const _EmptyState(
              title: 'No favorites yet',
              message:
                  'Save a recipe from the detail page to build your collection.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                '${meals.length} saved recipe${meals.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _MealGrid(
                meals: meals,
                trailingBuilder: (meal) => IconButton(
                  tooltip: 'Remove',
                  onPressed: () => FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('favorites')
                      .doc(meal.id)
                      .delete(),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MyRecipesScreen extends StatelessWidget {
  const MyRecipesScreen({super.key});

  static const routeName = '/my-recipes';

  Future<void> _openCreateDialog(BuildContext context, String userId) async {
    final created =
        await showDialog<bool>(
          context: context,
          builder: (_) => _CreateRecipeDialog(userId: userId),
        ) ??
        false;

    if (created && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved successfully.')),
      );
    }
  }

  void _showRecipeSheet(BuildContext context, CustomRecipe recipe) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (recipe.prepTime != null)
                    Chip(label: Text('${recipe.prepTime} min')),
                  if (recipe.servings != null)
                    Chip(label: Text('${recipe.servings} servings')),
                  for (final tag in recipe.tags) Chip(label: Text(tag)),
                ],
              ),
              if (recipe.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(recipe.description),
              ],
              const SizedBox(height: 18),
              Text(
                'Ingredients',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final item in recipe.ingredients)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $item'),
                ),
              const SizedBox(height: 18),
              Text(
                'Instructions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(recipe.instructions, style: const TextStyle(height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;

    if (user == null) {
      return const CookbookScaffold(
        title: 'My Recipes',
        currentRoute: MyRecipesScreen.routeName,
        child: _AuthRequiredCard(
          title: 'Sign in to create recipes',
          message: 'Build your own cookbook with recipes made just for you.',
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('customRecipes')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return CookbookScaffold(
      title: 'My Recipes',
      currentRoute: MyRecipesScreen.routeName,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? const [];
          final recipes = docs.map(CustomRecipe.fromDoc).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipes.isEmpty
                          ? 'No custom recipes yet'
                          : '${recipes.length} custom recipe${recipes.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openCreateDialog(context, user.uid),
                    icon: const Icon(Icons.add),
                    label: const Text('New recipe'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (recipes.isEmpty)
                const _EmptyState(
                  title: 'Nothing here yet',
                  message:
                      'Create your first recipe and it will appear here instantly.',
                )
              else
                ...recipes.map(
                  (recipe) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        title: Text(
                          recipe.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (recipe.description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(recipe.description),
                              ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (recipe.prepTime != null)
                                  Chip(label: Text('${recipe.prepTime} min')),
                                if (recipe.servings != null)
                                  Chip(
                                    label: Text('${recipe.servings} servings'),
                                  ),
                                for (final tag in recipe.tags.take(3))
                                  Chip(label: Text(tag)),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => _showRecipeSheet(context, recipe),
                        trailing: IconButton(
                          tooltip: 'Delete recipe',
                          onPressed: () => FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('customRecipes')
                              .doc(recipe.id)
                              .delete(),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const routeName = '/auth';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    final username = InputSanitizer.cleanText(
      _usernameController.text,
      maxLength: 40,
    );
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_isLogin && username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username is required for sign up.')),
      );
      return;
    }

    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use a valid email and a 6+ character password.'),
        ),
      );
      return;
    }

    try {
      if (_isLogin) {
        await auth.signIn(email: email, password: password);
      } else {
        await auth.signUp(username: username, email: email, password: password);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLogin ? 'Welcome back!' : 'Account created successfully.',
          ),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeScreen.routeName,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyAuthError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return CookbookScaffold(
      title: _isLogin ? 'Welcome back' : 'Create account',
      currentRoute: HomeScreen.routeName,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLogin
                        ? 'Sign in to access favorites and your recipes.'
                        : 'Create an account to save meals and build your own collection.',
                  ),
                  const SizedBox(height: 18),
                  if (!_isLogin) ...[
                    SelectionContainer.disabled(
                      child: TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SelectionContainer.disabled(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectionContainer.disabled(
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: auth.busy ? null : _submit,
                      child: Text(
                        auth.busy
                            ? 'Please wait…'
                            : (_isLogin ? 'Sign in' : 'Create account'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? 'Need an account? Sign up'
                            : 'Already have an account? Sign in',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateRecipeDialog extends StatefulWidget {
  const _CreateRecipeDialog({required this.userId});

  final String userId;

  @override
  State<_CreateRecipeDialog> createState() => _CreateRecipeDialogState();
}

class _CreateRecipeDialogState extends State<_CreateRecipeDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _ingredients = TextEditingController();
  final _instructions = TextEditingController();
  final _prepTime = TextEditingController();
  final _servings = TextEditingController();
  final _tags = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _ingredients.dispose();
    _instructions.dispose();
    _prepTime.dispose();
    _servings.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = InputSanitizer.cleanText(_title.text, maxLength: 80);
    final description = InputSanitizer.cleanText(
      _description.text,
      maxLength: 180,
    );
    final ingredients = InputSanitizer.splitLines(
      _ingredients.text,
      maxItems: 25,
      maxLength: 100,
    );
    final instructions = InputSanitizer.cleanMultiline(
      _instructions.text,
      maxLength: 4000,
    );
    final tags = InputSanitizer.splitTags(_tags.text, maxItems: 8);
    final prepTime = int.tryParse(_prepTime.text.trim());
    final servings = int.tryParse(_servings.text.trim());

    if (title.isEmpty || ingredients.isEmpty || instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title, ingredients, and instructions are required.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('customRecipes')
          .add({
            'title': title,
            'description': description,
            'ingredients': ingredients,
            'instructions': instructions,
            'prepTime': prepTime != null && prepTime > 0 && prepTime <= 1440
                ? prepTime
                : null,
            'servings': servings != null && servings > 0 && servings <= 50
                ? servings
                : null,
            'tags': tags,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save recipe right now. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create recipe'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectionContainer.disabled(
                child: TextField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
              ),
              const SizedBox(height: 10),
              SelectionContainer.disabled(
                child: TextField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ),
              const SizedBox(height: 10),
              SelectionContainer.disabled(
                child: TextField(
                  controller: _prepTime,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prep time (minutes)',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SelectionContainer.disabled(
                child: TextField(
                  controller: _servings,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Servings'),
                ),
              ),
              const SizedBox(height: 10),
              SelectionContainer.disabled(
                child: TextField(
                  controller: _ingredients,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Ingredients * (one per line)',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SelectionContainer.disabled(
                child: TextField(
                  controller: _instructions,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Instructions *',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SelectionContainer.disabled(
                child: TextField(
                  controller: _tags,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save recipe'),
        ),
      ],
    );
  }
}

class _MealGrid extends StatelessWidget {
  const _MealGrid({required this.meals, this.trailingBuilder});

  final List<Meal> meals;
  final Widget Function(Meal meal)? trailingBuilder;

  @override
  Widget build(BuildContext context) {
    final layoutWidth = MediaQuery.sizeOf(context).width.clamp(0.0, 1120.0);
    final columns = layoutWidth >= 1080
        ? 4
        : layoutWidth >= 760
        ? 3
        : layoutWidth >= 520
        ? 2
        : 1;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: meals.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final meal = meals[index];
            final scheme = Theme.of(context).colorScheme;

            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  RecipeDetailScreen.routeName,
                  arguments: meal.id,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: _RemoteMealImage(
                        imageUrl: meal.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.06),
                              Colors.black.withValues(alpha: 0.22),
                              Colors.black.withValues(alpha: 0.84),
                            ],
                            stops: const [0, 0.45, 1],
                          ),
                        ),
                      ),
                    ),
                    if (trailingBuilder != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Card(
                          color: scheme.surfaceContainerLow.withValues(
                            alpha: 0.9,
                          ),
                          child: trailingBuilder!(meal),
                        ),
                      ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (meal.category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                meal.category,
                                style: TextStyle(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            meal.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InlineNavRow extends StatelessWidget {
  const _InlineNavRow({required this.currentRoute});

  final String currentRoute;

  static const _items = <({String route, IconData icon, String label})>[
    (route: HomeScreen.routeName, icon: Icons.home_rounded, label: 'Home'),
    (
      route: SearchScreen.routeName,
      icon: Icons.search_rounded,
      label: 'Search',
    ),
    (
      route: FavoritesScreen.routeName,
      icon: Icons.favorite_rounded,
      label: 'Favorites',
    ),
    (
      route: MyRecipesScreen.routeName,
      icon: Icons.book_rounded,
      label: 'My Recipes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: _items.map((item) {
        final selected = item.route == currentRoute;
        return TextButton.icon(
          onPressed: () {
            if (item.route == currentRoute) return;
            Navigator.of(context).pushReplacementNamed(item.route);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: selected
                ? scheme.primary.withValues(alpha: 0.14)
                : scheme.surfaceContainerLow.withValues(
                    alpha: isDark ? 0.78 : 0.92,
                  ),
            foregroundColor: selected ? scheme.primary : scheme.onSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.26)
                    : scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          icon: Icon(item.icon, size: 18),
          label: Text(item.label),
        );
      }).toList(),
    );
  }
}

class _RemoteMealImage extends StatelessWidget {
  const _RemoteMealImage({required this.imageUrl, this.fit = BoxFit.cover});

  final String imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget placeholder() {
      return Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          gradient: LinearGradient(
            colors: [
              scheme.surfaceContainerHighest,
              scheme.surfaceContainerHigh,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.photo_library_outlined,
          size: 34,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    final safeUrl = InputSanitizer.safeHttpUrl(imageUrl);
    if (safeUrl.isEmpty) {
      return placeholder();
    }

    return Image.network(
      safeUrl,
      fit: fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            placeholder(),
            Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                value: loadingProgress.expectedTotalBytes == null
                    ? null
                    : loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!,
              ),
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, size: 40),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.onAction,
    this.actionIcon,
    this.actionTooltip,
  });

  final String title;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final String? actionTooltip;

  @override
  Widget build(BuildContext context) {
    final action = (onAction != null && actionIcon != null)
        ? IconButton(
            tooltip: actionTooltip,
            onPressed: onAction,
            icon: Icon(actionIcon, size: 20),
          )
        : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action],
      ],
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_dining_outlined, size: 52),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AuthRequiredCard extends StatelessWidget {
  const _AuthRequiredCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 42),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AuthScreen.routeName),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _friendlyAuthError(Object error) {
  final message = error.toString();
  if (message.contains('invalid-credential') ||
      message.contains('wrong-password')) {
    return 'That email/password combination was not accepted.';
  }
  if (message.contains('email-already-in-use')) {
    return 'An account already exists for that email.';
  }
  if (message.contains('weak-password')) {
    return 'Please choose a stronger password.';
  }
  return 'Authentication failed. Please try again.';
}
