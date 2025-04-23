// lib/screens/dice_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'widgets/dice_face.dart';

const int numPlayers = 5;
const int dicePerPlayer = 5;

class DicePage extends StatefulWidget {
  const DicePage({super.key});

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> with SingleTickerProviderStateMixin {
  // ────────────────────────────────────────────────────────────────────────────
  // State fields
  late List<List<int>> allDice;
  late List<bool>   alive;
  int       turnIndex       = 0;       // 0 = You, 1–4 = CPUs
  bool      hasRolled       = false;   // user may roll only once per turn
  int?      bidQuantity;
  int?      bidFace;

  // Inline bet UI
  bool      _showBetControls    = false;
  bool      _betRaiseQuantity   = true;
  late int  _tempQty;
  late int  _tempFace;

  final Random               _rand            = Random();
  late AnimationController   _controller;
  late Animation<double>     _animation;

  // history log
  final List<String>         history         = [];
  final ScrollController     _scrollController = ScrollController();

  // ────────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initGameState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initGameState() {
    allDice      = List.generate(numPlayers, (_) => List.filled(dicePerPlayer, 1));
    alive        = List.filled(numPlayers, true);
    turnIndex    = 0;
    hasRolled    = false;
    bidQuantity  = null;
    bidFace      = null;
    _showBetControls = false;
    history.clear();
  }

  void _addLog(String entry) {
    history.add(entry);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // User actions

  void rollDice() {
    if (turnIndex != 0 || hasRolled) return;
    _controller.forward(from: 0);
    setState(() {
      hasRolled = true;
      allDice[0] = List.generate(dicePerPlayer, (_) => _rand.nextInt(6) + 1);
      for (var i = 1; i < numPlayers; i++) {
        allDice[i] = List.generate(dicePerPlayer, (_) => _rand.nextInt(6) + 1);
      }
    });
    _addLog('You rolled: ${allDice[0].join(', ')}');
  }

  void _userBet() {
    if (turnIndex != 0 || !hasRolled) return;
    setState(() {
      // show inline controls
      _showBetControls  = true;
      _betRaiseQuantity = true;
      _tempQty          = (bidQuantity ?? 0) + 1;
      _tempFace         = (bidFace     ?? 1) + 1;
    });
  }

  void _confirmBet() {
    setState(() {
      if (_betRaiseQuantity) {
        bidQuantity = _tempQty;
      } else {
        bidFace     = _tempFace;
      }
      _addLog('You bet ${bidQuantity!} × ${bidFace!}');
      _showBetControls = false;
    });
    _nextTurn();
  }

  void _cancelBet() {
    setState(() {
      _showBetControls = false;
    });
  }

  void _userCall() {
    if (turnIndex != 0 || !hasRolled || bidQuantity == null) return;
    _addLog('You called bluff on ${bidQuantity!} × ${bidFace!}');
    _resolveCall(0);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CPU actions

  void _cpuAction() {
    final shouldCall = bidQuantity != null && _rand.nextInt(4) == 0;
    if (shouldCall) {
      _handleCpuCall();
    } else {
      _handleCpuBet();
    }
  }

  void _handleCpuCall() {
    final cpuIdx = turnIndex + 1;
    _addLog('CPU $cpuIdx calls bluff');
    _resolveCall(turnIndex);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (alive[0] && hasRolled) _nextTurn();
    });
  }

  void _handleCpuBet() {
    final cpuIdx  = turnIndex + 1;
    final oldQty  = bidQuantity ?? 0;
    final oldFace = bidFace     ?? 1;

    bool raiseQty = _rand.nextBool();
    if (!raiseQty && oldFace >= 6) raiseQty = true;

    final newQty  = raiseQty ? oldQty + 1 : oldQty;
    final newFace = raiseQty ? oldFace : min(oldFace + 1, 6);

    setState(() {
      bidQuantity = newQty;
      bidFace     = newFace;
    });

    final msg = 'CPU $cpuIdx bets $newQty × $newFace';
    _addLog(msg);
    ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)))
      .closed
      .then((_) => _nextTurn());
  }

  // ────────────────────────────────────────────────────────────────────────────
  void _resolveCall(int caller) {
    final counts = <int,int>{};
    for (var hand in allDice) {
      for (var v in hand) {
        counts[v] = (counts[v] ?? 0) + 1;
      }
    }
    final qty    = bidQuantity!;
    final face   = bidFace!;
    final actual = counts[face] ?? 0;
    final last   = (turnIndex + numPlayers - 1) % numPlayers;
    final loser  = actual < qty ? last : caller;
    final loserName = loser == 0 ? 'You' : 'CPU ${loser + 1}';

    final msg = 'Call: needed $qty×$face, found $actual — $loserName out';
    _addLog(msg);

    setState(() {
      alive[loser] = false;
    });

    ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)))
      .closed
      .then((_) {
        if (loser != 0) {
          setState(() {
            hasRolled   = false;
            bidQuantity = null;
            bidFace     = null;
            turnIndex   = 0;
          });
        }
      });
  }

  void _nextTurn() {
    setState(() {
      do {
        turnIndex = (turnIndex + 1) % numPlayers;
      } while (!alive[turnIndex]);
    });

    if (turnIndex == 0 && hasRolled) {
      _addLog('Your turn again: Bet or Call');
    }
    if (turnIndex != 0) {
      Future.delayed(const Duration(milliseconds: 400), _cpuAction);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade900,
      appBar: AppBar(
        title: const Text('Liar\'s Dice'),
        backgroundColor: Colors.brown.shade700,
      ),
      body: Row(
        children: [
          // Main game area
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTable(),
                const SizedBox(height: 16),
                if (!hasRolled) _buildRollButton(),
                if (turnIndex == 0 && hasRolled && !_showBetControls) _buildUserControls(),
                if (_showBetControls) _buildInlineBetControls(),
              ],
            ),
          ),
          // History column
          Container(
            width: 150,
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.black38, border: Border.all(color: Colors.white54)),
            child: Scrollbar(
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: history.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(history[i], style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SizedBox(
      width: 350,
      height: 350,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: Container(decoration: const BoxDecoration(color: Color(0x99795000), shape: BoxShape.circle)),
        ),
        for (var i = 0; i < numPlayers; i++)
          Align(
            alignment: _playerAlignment(i),
            child: alive[i]
                ? PlayerArea(
                    name: i == 0 ? 'You' : 'CPU ${i + 1}',
                    isCurrent: i == 0,
                    diceValues: i == 0 ? allDice[0] : null,
                    small: i != 0,
                  )
                : _outBox(label: i == 0 ? 'You' : 'CPU ${i + 1}'),
          ),
      ]),
    );
  }

  Widget _buildRollButton() {
    return ElevatedButton(
      onPressed: rollDice,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.brown.shade900,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: const Text('Roll Dice'),
    );
  }

  Widget _buildUserControls() {
    return Align(
      alignment: Alignment.center,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        ElevatedButton(onPressed: _userBet, child: const Text('Bet')),
        const SizedBox(width: 16),
        ElevatedButton(onPressed: _userCall, child: const Text('Call')),
      ]),
    );
  }

  Widget _buildInlineBetControls() {
    final minVal     = _betRaiseQuantity ? (bidQuantity ?? 0) + 1 : (bidFace ?? 1) + 1;
    final maxVal     = _betRaiseQuantity ? dicePerPlayer * numPlayers : 6;
    final currentVal = _betRaiseQuantity ? _tempQty.toDouble() : _tempFace.toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.brown.shade800,
        border: Border.all(color: Colors.amber),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ChoiceChip(
            label: const Text('Raise Qty'),
            selected: _betRaiseQuantity,
            onSelected: (_) => setState(() => _betRaiseQuantity = true),
          ),
          const SizedBox(width: 12),
          ChoiceChip(
            label: const Text('Raise Face'),
            selected: !_betRaiseQuantity,
            onSelected: (_) => setState(() => _betRaiseQuantity = false),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Icon(_betRaiseQuantity ? Icons.format_list_numbered : Icons.looks_one),
          Expanded(
            child: Slider(
              min: minVal.toDouble(),
              max: maxVal.toDouble(),
              divisions: maxVal - minVal,
              value: currentVal.clamp(minVal.toDouble(), maxVal.toDouble()),
              label: '${currentVal.toInt()}',
              onChanged: (v) {
                setState(() {
                  if (_betRaiseQuantity) {
                    _tempQty = v.toInt();
                  } else {
                    _tempFace = v.toInt();
                  }
                });
              },
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(onPressed: _confirmBet, child: const Text('Confirm')),
          const SizedBox(width: 16),
          TextButton(onPressed: _cancelBet, child: const Text('Cancel')),
        ]),
      ]),
    );
  }

  Alignment _playerAlignment(int idx) {
    switch (idx) {
      case 0:
        return const Alignment(-4.1, 0.6);
      case 1:
        return const Alignment(-2.1, -0.7);
      case 2:
        return const Alignment(0.0, -1.5);
      case 3:
        return const Alignment(2.0, -0.7);
      case 4:
        return const Alignment(2.0, 0.6);
      default:
        return Alignment.center;
    }
  }

  Widget _outBox({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

class PlayerArea extends StatelessWidget {
  final String     name;
  final bool       isCurrent;
  final List<int>? diceValues;
  final bool       small;

  const PlayerArea({
    required this.name,
    required this.isCurrent,
    this.diceValues,
    this.small = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dieSize = small ? 32.0 : 48.0;
    final diceWidgets = isCurrent
        ? (diceValues ?? []).map((v) {
            return SizedBox(
              width: dieSize,
              height: dieSize,
              child: FittedBox(fit: BoxFit.contain, child: DiceFace(value: v)),
            );
          }).toList()
        : List.generate(
            dicePerPlayer,
            (_) => SizedBox(
              width: dieSize,
              height: dieSize,
              child: const CoveredDice(),
            ),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisSize: MainAxisSize.min, children: diceWidgets)),
      ],
    );
  }
}

class CoveredDice extends StatelessWidget {
  const CoveredDice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(6)),
      child: const Center(child: Icon(Icons.help_outline, color: Colors.white)),
    );
  }
}
