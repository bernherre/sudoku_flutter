import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_flutter/engine/sudoku.dart';

void main() {
  test('genera un tablero resuelto v�lido 4x4', () {
    final eng = SudokuEngine(n: 4);
    final solved = eng.generateSolved();
    expect(eng.isCompleteAndValid(solved), true);
  });

  test('genera puzzle 6x6 y la soluci�n es v�lida', () {
    final eng = SudokuEngine(n: 6);
    final pack = eng.generatePuzzle(20);
    expect(eng.isCompleteAndValid(pack.solved), true);
  });
}
