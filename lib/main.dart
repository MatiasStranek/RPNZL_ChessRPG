import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'board/board_loader.dart';
import 'game/chess_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final board = await BoardLoader.loadMap('map_board_1');
  runApp(GameWidget(game: ChessGame(board: board)));
}
