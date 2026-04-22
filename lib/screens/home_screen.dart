import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/game_card.dart';
import '../models/game_model.dart';
import 'stream_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  String _searchQuery = '';

  final List<GameModel> _games = [
    GameModel(
      id: '1',
      title: 'Cyberpunk 2077',
      genre: 'RPG',
      imageUrl: 'https://via.placeholder.com/300x170/7B2FFF/FFFFFF?text=Cyberpunk+2077',
      isAvailable: true,
      rating: 4.5,
    ),
    GameModel(
      id: '2',
      title: 'God of War',
      genre: 'Action',
      imageUrl: 'https://via.placeholder.com/300x170/00D4FF/000000?text=God+of+War',
      isAvailable: true,
      rating: 4.9,
    ),
    GameModel(
      id: '3',
      title: 'GTA V',
      genre: 'Open World',
      imageUrl: 'https://via.placeholder.com/300x170/FF3D6B/FFFFFF?text=GTA+V',
      isAvailable: true,
      rating: 4.7,
    ),
    GameModel(
      id: '4',
      title: 'FIFA 24',
      genre: 'Sports',
      imageUrl: 'https://via.placeholder.com/300x170/00FF88/000000?text=FIFA+24',
      isAvailable: true,
      rating: 4.2,
    ),
    GameModel(
      id: '5',
      title: 'Red Dead Redemption 2',
      genre: 'Adventure',
      imageUrl: 'https://via.placeholder.com/300x170/FF8800/FFFFFF?text=RDR2',
      isAvailable: false,
      rating: 4.8,
    ),
    GameModel(
      id: '6',
      title: 'Elden Ring',
      genre: 'RPG',
      imageUrl: 'https://via.placeholder.com/300x170/FFDD00/000000?text=Elden+Ring',
      isAvailable: true,
      rating: 4.9,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<GameModel> get _filteredGames => _games
      .where((g) =>
          g.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.genre.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildFeaturedBanner()),
            SliverToBoxAdapter(child: _buildSectionTitle('Jogos Disponíveis')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final game = _filteredGames[index];
                    return GameCard(
                      game: game,
                      onTap: () => _launchGame(game),
                    );
                  },
                  childCount: _filteredGames.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildStreamFAB(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 60,
      floating: true,
      pinned: false,
      backgroundColor: AppTheme.background,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.cloud, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Boosteroid',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
          onPressed: () {},
        ),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.secondary,
              child: Text('U', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar jogos...',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
          filled: true,
          fillColor: AppTheme.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFeaturedBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppTheme.secondary, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('DESTAQUE', style: TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  )),
                ),
                const SizedBox(height: 8),
                const Text('Cyberpunk 2077', style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800,
                )),
                const Text('Jogue agora na nuvem • 4K • 60fps', style: TextStyle(
                  color: Colors.white70, fontSize: 12,
                )),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _launchGame(_games[0]),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('JOGAR', style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13,
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(title, style: const TextStyle(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
      )),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Início'},
      {'icon': Icons.games_outlined, 'label': 'Biblioteca'},
      {'icon': Icons.person_outline, 'label': 'Perfil'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: items
            .map((e) => BottomNavigationBarItem(
                  icon: Icon(e['icon'] as IconData),
                  label: e['label'] as String,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildStreamFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _launchGame(_games[0]),
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.play_circle_fill),
      label: const Text('STREAM', style: TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  void _launchGame(GameModel game) {
    if (!game.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${game.title} não disponível no momento'),
          backgroundColor: AppTheme.accent,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StreamScreen(game: game)),
    );
  }
}
