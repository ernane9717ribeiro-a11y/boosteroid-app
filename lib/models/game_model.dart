// ── game_model.dart ──
// lib/models/game_model.dart

class GameModel {
  final String id;
  final String title;
  final String genre;
  final String imageUrl;
  final bool isAvailable;
  final double rating;

  const GameModel({
    required this.id,
    required this.title,
    required this.genre,
    required this.imageUrl,
    required this.isAvailable,
    required this.rating,
  });
}
