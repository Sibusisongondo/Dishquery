import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../theme.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'meal_planner_screen.dart';
import 'shopping_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _activeTab = 'all'; // 'all' | 'favorites'
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<RecipeProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.95 &&
        !provider.isFetchingMore &&
        provider.canInfiniteScroll &&
        _activeTab == 'all') {
      provider.fetchMoreRandomRecipes();
    }
  }

  void _goToDetail(String id) async {
    final provider = context.read<RecipeProvider>();
    final recipe = await provider.fetchRecipeDetails(id);
    if (recipe != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: recipe),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load recipe details.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _RecipeListView(
        activeTab: _activeTab,
        onTabChange: (tab) => setState(() => _activeTab = tab),
        scrollController: _scrollController,
        searchController: _searchController,
        onDetail: _goToDetail,
      ),
      const MealPlannerScreen(),
      const ShoppingListScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: IndexedStack(index: _navIndex, children: screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ---- Recipe List Sub-view ----

class _RecipeListView extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChange;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final ValueChanged<String> onDetail;

  const _RecipeListView({
    required this.activeTab,
    required this.onTabChange,
    required this.scrollController,
    required this.searchController,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeProvider>(
      builder: (context, provider, _) {
        final displayedRecipes =
            activeTab == 'favorites' ? provider.favorites : provider.recipes;
        final activeFilter =
            provider.selectedCategory ?? provider.selectedArea;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          drawer: _FilterDrawer(provider: provider),
          body: CustomScrollView(
            controller: scrollController,
            slivers: [
              _AppBar(
                provider: provider,
                activeFilter: activeFilter,
                searchController: searchController,
              ),
              // Tabs
              SliverToBoxAdapter(
                child: _TabBar(
                  activeTab: activeTab,
                  onTabChange: onTabChange,
                  favCount: provider.favorites.length,
                ),
              ),
              // Content
              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              else if (provider.error != null && displayedRecipes.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              color: AppTheme.textSecondary, size: 56),
                          const SizedBox(height: 16),
                          Text(provider.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 15)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary),
                            onPressed: provider.fetchInitialRecipes,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (displayedRecipes.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      activeTab == 'favorites'
                          ? 'No favourites yet.\nTap ♥ on any recipe to save it.'
                          : 'No recipes found.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 15),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == displayedRecipes.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primary),
                            ),
                          );
                        }
                        final recipe = displayedRecipes[index];
                        return RecipeCard(
                          recipe: recipe,
                          isFavorite: provider.isFavorite(recipe.id),
                          onToggleFavorite: () =>
                              provider.toggleFavorite(recipe),
                          onTap: () => onDetail(recipe.id),
                        );
                      },
                      childCount: displayedRecipes.length +
                          (provider.isFetchingMore ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---- Sliver AppBar ----

class _AppBar extends StatelessWidget {
  final RecipeProvider provider;
  final String? activeFilter;
  final TextEditingController searchController;

  const _AppBar({
    required this.provider,
    required this.activeFilter,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      expandedHeight: 140,
      backgroundColor: AppTheme.bgDark,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppTheme.textPrimary),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: activeFilter != null
            ? _FilterChip(
                label: activeFilter!,
                onRemove: provider.fetchInitialRecipes,
              )
            : null,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A0A00), AppTheme.bgDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'What are you\ncooking today?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: AppTheme.bgDark,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Search recipes...',
                      hintStyle: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 15),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppTheme.textSecondary, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 13),
                    ),
                    onSubmitted: (v) => provider.searchRecipes(v),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => provider.searchRecipes(searchController.text),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.search_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                color: AppTheme.primary, size: 16),
          ),
        ],
      ),
    );
  }
}

// ---- Tab Bar ----

class _TabBar extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChange;
  final int favCount;

  const _TabBar({
    required this.activeTab,
    required this.onTabChange,
    required this.favCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgDark,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _Tab(
              label: 'All Recipes',
              isActive: activeTab == 'all',
              onTap: () => onTabChange('all')),
          const SizedBox(width: 8),
          _Tab(
              label: 'Favourites${favCount > 0 ? ' ($favCount)' : ''}',
              isActive: activeTab == 'favorites',
              onTap: () => onTabChange('favorites')),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ---- Filter Drawer ----

class _FilterDrawer extends StatelessWidget {
  final RecipeProvider provider;

  const _FilterDrawer({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.bgCard,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Text('Filters',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      provider.fetchInitialRecipes();
                    },
                    child: const Text('Reset',
                        style: TextStyle(color: AppTheme.primary)),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.divider),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerSection(
                    title: 'Categories',
                    icon: Icons.category_rounded,
                    isActive: provider.selectedCategory != null,
                    children: provider.categories
                        .map((cat) => _DrawerItem(
                              label: cat.name,
                              imageUrl: cat.thumbUrl,
                              isSelected:
                                  provider.selectedCategory == cat.name,
                              onTap: () {
                                Navigator.pop(context);
                                provider.fetchByCategory(cat.name);
                              },
                            ))
                        .toList(),
                  ),
                  _DrawerSection(
                    title: 'Cuisines',
                    icon: Icons.public_rounded,
                    isActive: provider.selectedArea != null,
                    children: provider.areas
                        .map((area) => _DrawerItem(
                              label: area,
                              isSelected: provider.selectedArea == area,
                              onTap: () {
                                Navigator.pop(context);
                                provider.fetchByArea(area);
                              },
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final List<Widget> children;

  const _DrawerSection({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(icon,
          color: isActive ? AppTheme.primary : AppTheme.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.primary : AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconColor: AppTheme.textSecondary,
      collapsedIconColor: AppTheme.textSecondary,
      children: children,
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.label,
    this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: imageUrl != null
          ? CircleAvatar(
              backgroundImage: NetworkImage(imageUrl!),
              backgroundColor: AppTheme.bgElevated,
              radius: 18,
            )
          : null,
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      tileColor: isSelected ? AppTheme.primary.withOpacity(0.1) : null,
      onTap: onTap,
    );
  }
}

// ---- Bottom Nav ----

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Recipes',
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0)),
              _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Meal Plan',
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1)),
              _NavItem(
                  icon: Icons.shopping_basket_rounded,
                  label: 'Shopping',
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withOpacity(0.15) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                size: 26),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}