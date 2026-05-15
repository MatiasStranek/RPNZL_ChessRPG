import 'dart:convert';
import 'package:flutter/services.dart';
import 'board_model.dart';
import 'package:chessrpg/piece/piece_model.dart';

class BoardLoader {
  static Future<BoardModel> loadMap(String mapName) async {
    final String json = await rootBundle.loadString(
      'assets/maps/$mapName.json',
    );
    final Map<String, dynamic> data = jsonDecode(json);

    final int width = data['width'];
    final int height = data['height'];
    final board = BoardModel.generate(width: width, height: height);

    for (final hole in data['holes']) {
      board.cells[hole['y']][hole['x']] = CellType.hole;
    }

    for (final p in data['pieces']) {
      final team = PieceTeam.values.byName(p['team']);
      board.pieces.add(PieceModel(team: team, x: p['x'], y: p['y']));
    }

    return board;
  }
}
