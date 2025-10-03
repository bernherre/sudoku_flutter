import 'dart:math';

class SudokuEngine {
  final int n;
  late final int boxRows;
  late final int boxCols;
  int _seed;

  SudokuEngine({this.n = 6, int? seed})
      : assert(n == 4 || n == 6, 'Solo 4x4 o 6x6'),
        _seed = seed ?? DateTime.now().millisecondsSinceEpoch {
    if (n == 4) {
      boxRows = 2;
      boxCols = 2;
    } else {
      boxRows = 3;
      boxCols = 2; // 6x6 => 3x2
    }
  }

  double _rng01() {
    // LCG simple, reproducible
    _seed = (_seed * 48271) % 2147483647;
    return _seed / 2147483647;
  }

  List<T> _shuffled<T>(List<T> a) {
    final list = List<T>.from(a);
    for (int i = list.length - 1; i > 0; i--) {
      final j = (_rng01() * (i + 1)).floor();
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }

  List<List<int>> empty() =>
      List.generate(n, (_) => List<int>.filled(n, 0, growable: false),
          growable: false);

  List<List<int>> clone(List<List<int>> g) =>
      List.generate(n, (r) => List<int>.from(g[r]), growable: false);

  bool isValid(List<List<int>> g, int r, int c, int v) {
    if (v < 1 || v > n) return false;
    for (int i = 0; i < n; i++) {
      if (g[r][i] == v) return false;
      if (g[i][c] == v) return false;
    }
    final sr = (r ~/ boxRows) * boxRows;
    final sc = (c ~/ boxCols) * boxCols;
    for (int rr = 0; rr < boxRows; rr++) {
      for (int cc = 0; cc < boxCols; cc++) {
        if (g[sr + rr][sc + cc] == v) return false;
      }
    }
    return true;
  }

  Point<int>? _findEmpty(List<List<int>> g) {
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (g[r][c] == 0) return Point(r, c);
      }
    }
    return null;
  }

  bool solve(List<List<int>> g) {
    final pos = _findEmpty(g);
    if (pos == null) return true;
    final r = pos.x, c = pos.y;
    for (final v in _shuffled(List.generate(n, (i) => i + 1))) {
      if (isValid(g, r, c, v)) {
        g[r][c] = v;
        if (solve(g)) return true;
        g[r][c] = 0;
      }
    }
    return false;
  }

  int countSolutions(List<List<int>> g, {int limit = 2}) {
    int cnt = 0;
    void dfs() {
      if (cnt >= limit) return;
      final p = _findEmpty(g);
      if (p == null) {
        cnt++;
        return;
      }
      final r = p.x, c = p.y;
      for (int v = 1; v <= n && cnt < limit; v++) {
        if (isValid(g, r, c, v)) {
          g[r][c] = v;
          dfs();
          g[r][c] = 0;
        }
      }
    }

    dfs();
    return cnt;
  }

  List<List<int>> generateSolved() {
    final g = empty();
    solve(g);
    return g;
  }

  ({List<List<int>> puzzle, List<List<int>> solved}) generatePuzzle(int clues) {
    final solved = generateSolved();
    final puzzle = clone(solved);
    final idxs = List.generate(n * n, (i) => i);
    for (final idx in _shuffled(idxs)) {
      if (puzzle.expand((e) => e).where((x) => x != 0).length <= clues) break;
      final r = idx ~/ n, c = idx % n;
      final bak = puzzle[r][c];
      if (bak == 0) continue;

      final rowFilled = puzzle[r].where((x) => x != 0).length;
      final colFilled = List.generate(n, (i) => puzzle[i][c])
          .where((x) => x != 0)
          .length;
      if (rowFilled <= n / 2 || colFilled <= n / 2) continue; // evita filas/cols muy vacías

      puzzle[r][c] = 0;
      final test = clone(puzzle);
      if (countSolutions(test, limit: 2) != 1) {
        puzzle[r][c] = bak;
      }
    }
    return (puzzle: puzzle, solved: solved);
  }

  bool isCompleteAndValid(List<List<int>> g) {
    for (int r = 0; r < n; r++) {
      final row = <int>{};
      final col = <int>{};
      for (int c = 0; c < n; c++) {
        final vr = g[r][c], vc = g[c][r];
        if (vr < 1 || vr > n || row.contains(vr)) return false;
        if (vc < 1 || vc > n || col.contains(vc)) return false;
        row.add(vr);
        col.add(vc);
      }
    }
    for (int br = 0; br < n; br += boxRows) {
      for (int bc = 0; bc < n; bc += boxCols) {
        final box = <int>{};
        for (int rr = 0; rr < boxRows; rr++) {
          for (int cc = 0; cc < boxCols; cc++) {
            final v = g[br + rr][bc + cc];
            if (v < 1 || v > n || box.contains(v)) return false;
            box.add(v);
          }
        }
      }
    }
    return true;
  }
}

enum Difficulty { facil, media, dificil }

extension DifficultyClues on Difficulty {
  (int min, int max) rangeFor(int n) {
    final total = n * n;
    switch (this) {
      case Difficulty.facil:
        return ((total * 0.65).floor(), (total * 0.80).floor());
      case Difficulty.media:
        return ((total * 0.50).floor(), (total * 0.65).floor());
      case Difficulty.dificil:
        return ((total * 0.35).floor(), (total * 0.50).floor());
    }
  }
}
