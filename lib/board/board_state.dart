import 'package:flutter/material.dart';
import 'board_model.dart';
import 'package:chessrpg/piece/piece_model.dart';

class BoardState extends ChangeNotifier {
  BoardModel board;
  PieceModel? selectedPiece;

  BoardState({required this.board});

  void selectPiece(PieceModel piece) {
    if (selectedPiece == piece) {
      selectedPiece = null;
    } else {
      selectedPiece = piece;
    }
    notifyListeners();
  }

  void movePiece(int x, int y) {
    if (selectedPiece == null) return;
    if (board.cells[y][x] == CellType.hole) return;

    final dx = (x - selectedPiece!.x).abs();
    final dy = (y - selectedPiece!.y).abs();
    if (dx > 1 || dy > 1) {
      selectedPiece = null;
      notifyListeners();
      return;
    }

    selectedPiece!.x = x;
    selectedPiece!.y = y;
    selectedPiece = null;
    notifyListeners();
  }

  void deselectPiece() {
    if (selectedPiece == null) return;
    selectedPiece = null;
    notifyListeners();
  }

  bool isReachable(int x, int y) {
    if (selectedPiece == null) return false;
    if (board.cells[y][x] == CellType.hole) return false;

    final dx = (x - selectedPiece!.x).abs();
    final dy = (y - selectedPiece!.y).abs();
    return dx <= 1 && dy <= 1 && !(dx == 0 && dy == 0);
  }
}
