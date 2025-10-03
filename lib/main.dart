import 'dart:async';
import 'package:flutter/material.dart';
import 'engine/sudoku.dart';
import 'dart:math' show Point;

void main() {
  runApp(const SudokuApp());
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku Boxed (Flutter)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22C55E), brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Color(0xFFE5E7EB))),
      ),
      home: const SudokuPage(),
    );
  }
}

class SudokuPage extends StatefulWidget {
  const SudokuPage({super.key});
  @override
  State<SudokuPage> createState() => _SudokuPageState();
}

class _SudokuPageState extends State<SudokuPage> {
  int size = 6;
  Difficulty difficulty = Difficulty.media;
  late SudokuEngine engine;
  late List<List<int>> grid;
  late List<List<int>> solution;
  late List<List<bool>> fixed;
  final Map<String, String> feedback = {}; // "ok" | "bad"
  int? selR, selC;
  late int startAtMs;
  late Timer timer;
  Duration elapsed = Duration.zero;
  bool won = false;

  @override
  void initState() {
    super.initState();
    engine = SudokuEngine(n: size);
    _newGame();
    timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() => elapsed = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - startAtMs));
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void _newGame() {
    final (min, max) = difficulty.rangeFor(size);
    final clues = ((min + max) / 2).floor();
    final pack = engine.generatePuzzle(clues);
    grid = pack.puzzle.map((r) => List<int>.from(r)).toList(growable: false);
    solution = pack.solved.map((r) => List<int>.from(r)).toList(growable: false);
    fixed = pack.puzzle.map((row) => row.map((v) => v != 0).toList()).toList(growable: false);
    feedback.clear();
    won = false;
    selR = selC = null;
    startAtMs = DateTime.now().millisecondsSinceEpoch;
    elapsed = Duration.zero;
    setState(() {});
  }

  void _resetTo(int newSize, Difficulty newDiff) {
    size = newSize;
    difficulty = newDiff;
    engine = SudokuEngine(n: size);
    _newGame();
  }

  void _setCell(int r, int c, int v) {
    if (fixed[r][c]) return;
    grid[r][c] = v;
    final k = '$r,$c';
    if (v == 0) {
      feedback.remove(k);
    } else {
      feedback[k] = (solution[r][c] == v) ? 'ok' : 'bad';
    }
    setState(() {});
  }

  void _check() {
    bool anyBad = false, anyEmpty = false;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final k = '$r,$c';
        if (grid[r][c] == 0) {
          anyEmpty = true;
          feedback.remove(k);
        } else {
          feedback[k] = (grid[r][c] == solution[r][c]) ? 'ok' : 'bad';
          if (feedback[k] == 'bad') anyBad = true;
        }
      }
    }
    if (!anyBad && !anyEmpty && engine.isCompleteAndValid(grid)) {
      won = true;
    }
    setState(() {});
  }

  void _solve() {
    grid = solution.map((r) => List<int>.from(r)).toList(growable: false);
    feedback.clear();
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        feedback['$r,$c'] = 'ok';
      }
    }
    won = true;
    setState(() {});
  }

  void _clear() {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (!fixed[r][c]) grid[r][c] = 0;
      }
    }
    feedback.clear();
    won = false;
    startAtMs = DateTime.now().millisecondsSinceEpoch;
    setState(() {});
  }

  String _fmtTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    String pad(int n) => n < 10 ? '0$n' : '$n';
    return '${pad(m)}:${pad(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final boxRows = (size == 4) ? 2 : 3;
    final boxCols = 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku Boxed (Flutter)'),
        backgroundColor: const Color(0xFF111827),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Toolbar
                Card(
                  color: const Color(0x1AFFFFFF),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 8,
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text('Tamaño: '),
                          const SizedBox(width: 6),
                          DropdownButton<int>(
                            value: size,
                            items: const [
                              DropdownMenuItem(value: 4, child: Text('4×4')),
                              DropdownMenuItem(value: 6, child: Text('6×6')),
                            ],
                            onChanged: (v) => _resetTo(v!, difficulty),
                          ),
                          const SizedBox(width: 12),
                          const Text('Dificultad: '),
                          const SizedBox(width: 6),
                          DropdownButton<Difficulty>(
                            value: difficulty,
                            items: const [
                              DropdownMenuItem(value: Difficulty.facil, child: Text('Fácil')),
                              DropdownMenuItem(value: Difficulty.media, child: Text('Media')),
                              DropdownMenuItem(value: Difficulty.dificil, child: Text('Difícil')),
                            ],
                            onChanged: (v) => _resetTo(size, v!),
                          ),
                        ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          FilledButton(onPressed: _newGame, child: const Text('Nuevo')),
                          const SizedBox(width: 8),
                          FilledButton.tonal(onPressed: _check, child: const Text('Verificar')),
                          const SizedBox(width: 8),
                          OutlinedButton(onPressed: _solve, child: const Text('Resolver')),
                          const SizedBox(width: 8),
                          OutlinedButton(onPressed: _clear, child: const Text('Limpiar')),
                        ]),
                        Text('Tiempo: ${_fmtTime(elapsed)}${won ? " · ¡Completado! 🎉" : ""}',
                            style: const TextStyle(color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Board
                Expanded(
                  child: Card(
                    color: const Color(0x1AFFFFFF),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _Board(
                          size: size,
                          boxRows: boxRows,
                          boxCols: boxCols,
                          grid: grid,
                          fixed: fixed,
                          feedback: feedback,
                          selected: (selR != null && selC != null) ? Point(selR!, selC!) : null,
                          onTapCell: (r, c) {
                            setState(() {
                              selR = r; selC = c;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Keypad
                if (selR != null && selC != null && !fixed[selR!][selC!])
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      for (int v = 1; v <= size; v++)
                        ElevatedButton(
                          onPressed: () => _setCell(selR!, selC!, v),
                          child: Text('$v', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ElevatedButton.icon(
                        onPressed: () => _setCell(selR!, selC!, 0),
                        icon: const Icon(Icons.backspace),
                        label: const Text('Borrar'),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                const Text('Tip: Pulsa una celda y usa el teclado numérico de abajo. En web se puede instalar como PWA.',
                    textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  final int size, boxRows, boxCols;
  final List<List<int>> grid;
  final List<List<bool>> fixed;
  final Map<String, String> feedback;
  final Point<int>? selected;
  final void Function(int r, int c) onTapCell;

  const _Board({
    required this.size,
    required this.boxRows,
    required this.boxCols,
    required this.grid,
    required this.fixed,
    required this.feedback,
    required this.selected,
    required this.onTapCell,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
      ),
      itemCount: size * size,
      itemBuilder: (context, i) {
        final r = i ~/ size, c = i % size;
        final v = grid[r][c];
        final key = '$r,$c';
        final isFixed = fixed[r][c];
        final fb = feedback[key];
        final isSel = (selected?.x == r && selected?.y == c);
        final base = isFixed ? const Color(0xFF1F2937) : const Color(0xFF0B1220);
        final ok = const Color(0xFF064E3B);
        final bad = const Color(0xFF7F1D1D);
        final bg = switch (fb) {
          'ok' => ok,
          'bad' => bad,
          _ => base,
        };

        BorderSide b(double w) => BorderSide(color: const Color(0xFF374151), width: w);
        final thick = 2.0, thin = 1.0;

        return InkWell(
          onTap: () => onTapCell(r, c),
          child: Container(
            decoration: BoxDecoration(
              color: isSel ? bg.withOpacity(0.85) : bg,
              border: Border(
                top: b(r % boxRows == 0 ? thick : thin),
                left: b(c % boxCols == 0 ? thick : thin),
                right: b((c + 1) % boxCols == 0 ? thick : thin),
                bottom: b((r + 1) % boxRows == 0 ? thick : thin),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              v == 0 ? '' : '$v',
              style: TextStyle(
                color: isFixed ? const Color(0xFFCbd5e1) : const Color(0xFFE5E7EB),
                fontWeight: FontWeight.w800,
                fontSize: (size == 4) ? 22 : 20,
              ),
            ),
          ),
        );
      },
    );
  }
}
