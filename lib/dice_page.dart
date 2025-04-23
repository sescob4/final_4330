// lib/screens/dice_page.dart
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

class _DicePageState extends State<DicePage>
    with SingleTickerProviderStateMixin {
  late List<List<int>> allDice;
  late List<bool> alive;
  int turnIndex = 0;        // whose turn (0 = you, 1–4 = CPUs)
  bool hasRolled = false;
  int? bidQuantity;
  int? bidFace;

  final _rand = Random();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    allDice = List.generate(numPlayers, (_) => List.filled(dicePerPlayer, 1));
    alive = List.filled(numPlayers, true);
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Move to next alive player; if CPU, trigger its action.
  void _nextTurn() {
    do {
      turnIndex = (turnIndex + 1) % numPlayers;
    } while (!alive[turnIndex]);
    if (turnIndex != 0) {
      Future.delayed(const Duration(milliseconds: 400), _cpuAction);
    }
  }

  /// User rolls once (only on their turn, once).
  void rollDice() {
    if (turnIndex != 0 || hasRolled) return;
    _controller.forward(from: 0);
    setState(() {
      hasRolled = true;
      // roll user
      allDice[0] = List.generate(dicePerPlayer, (_) => _rand.nextInt(6) + 1);
      // roll CPUs
      for (var i = 1; i < numPlayers; i++) {
        allDice[i] = List.generate(dicePerPlayer, (_) => _rand.nextInt(6) + 1);
      }
    });
    // after roll, move to CPU #1
    Future.delayed(const Duration(milliseconds: 500), _nextTurn);
  }

  /// User places a bet
  Future<void> _userBet() async {
    if (turnIndex != 0 || !hasRolled) return;
    final result = await showDialog<_Bid>(
      context: context,
      builder: (_) => _BetDialog(oldQuantity: bidQuantity ?? 0, oldFace: bidFace ?? 1),
    );
    if (result == null) return;
    setState(() {
      bidQuantity = result.quantity;
      bidFace = result.face;
    });
    _nextTurn();
  }

  /// User calls
  void _userCall() {
    if (turnIndex != 0 || !hasRolled || bidQuantity == null) return;
    _resolveCall(0);
  }

  /// CPU makes decision
  void _cpuAction() {
    // always either call (1/4) or bet
    final doCall = bidQuantity != null && _rand.nextInt(4) == 0;
    if (doCall) {
      _resolveCall(turnIndex);
    } else {
      // always raise either quantity or face
      final oldQty = bidQuantity ?? 0;
      final oldFace = bidFace ?? 1;
      bool raiseQty = _rand.nextBool();
      int newQty = oldQty;
      int newFace = oldFace;
      if (raiseQty) {
        // geometric raise on quantity
        int inc = 1;
        while (_rand.nextInt(inc + 1) == 0) {
          newQty++;
          inc++;
        }
      } else {
        // raise face by exactly 1
        if (newFace < 6) newFace++;
      }
      setState(() {
        bidQuantity = newQty;
        bidFace = newFace;
      });
      final snack = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CPU ${turnIndex + 1} bets $newQty × $newFace')),
      );
      snack.closed.then((_) => _nextTurn());
    }
  }

  /// Resolve a call by [caller]
  void _resolveCall(int caller) {
    final counts = <int,int>{};
    for (var hand in allDice) {
      for (var v in hand) counts[v] = (counts[v] ?? 0) + 1;
    }
    final qty = bidQuantity!;
    final face = bidFace!;
    final actual = counts[face] ?? 0;
    // determine loser
    final last = (turnIndex + numPlayers - 1) % numPlayers;
    final loser = actual < qty ? last : caller;
    setState(() {
      alive[loser] = false;
      bidQuantity = null;
      bidFace = null;
      hasRolled = false;
      turnIndex = 0;
    });
    final snack = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call: needed $qty×$face, found $actual — player ${loser == 0 ? "You" : loser+1} out')),
    );
    snack.closed.then((_) {
      // start next round
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade900,
      appBar: AppBar(title: const Text('Liar\'s Dice'), backgroundColor: Colors.brown.shade700),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 350,
              height: 350,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0x99795000),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // seats
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
                  // user controls (only your turn after roll)
                  if (turnIndex == 0 && hasRolled)
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(onPressed: _userBet, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.brown.shade900), child: const Text('Bet')),
                          const SizedBox(width: 16),
                          ElevatedButton(onPressed: _userCall, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.brown.shade900), child: const Text('Call')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Roll button disappears after click
            if (!hasRolled)
              ElevatedButton(
                onPressed: rollDice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.brown.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Roll Dice'),
              ),
            if (bidQuantity != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Current bid: $bidQuantity × $bidFace',
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }

  Alignment _playerAlignment(int idx) {
    switch (idx) {
      case 0:
        return const Alignment(-4.1, 0.6);
      case 1:
        return const Alignment(-4.1, -0.7);
      case 2:
        return const Alignment(0.0, -1.5);
      case 3:
        return const Alignment(4.0, -0.7);
      case 4:
        return const Alignment(4.0, 0.6);
      default:
        return Alignment.center;
    }
  }

  Widget _outBox({required String label}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      );
}

class PlayerArea extends StatelessWidget {
  final String name;
  final bool isCurrent;
  final List<int>? diceValues;
  final bool small;

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
        ? (diceValues ?? [])
            .map((v) => SizedBox(
                  width: dieSize,
                  height: dieSize,
                  child: FittedBox(fit: BoxFit.contain, child: DiceFace(value: v)),
                ))
            .toList()
        : List.generate(dicePerPlayer, (_) => SizedBox(width: dieSize, height: dieSize, child: const CoveredDice()));
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisSize: MainAxisSize.min, children: diceWidgets)),
    ]);
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

// Represents a bid from the Bet dialog.
class _Bid {
  final int quantity, face;
  _Bid(this.quantity, this.face);
}

// Dialog to place a bet.
class _BetDialog extends StatefulWidget {
  final int oldQuantity, oldFace;
  const _BetDialog({required this.oldQuantity, required this.oldFace});

  @override
  State<_BetDialog> createState() => _BetDialogState();
}

class _BetDialogState extends State<_BetDialog> {
  bool raiseQuantity = true;
  late int newQuantity;
  late int newFace;

  @override
  void initState() {
    super.initState();
    newQuantity = widget.oldQuantity + 1;
    newFace = widget.oldFace + 1;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Place your bid'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        RadioListTile<bool>(
          title: Text('Raise quantity (was ${widget.oldQuantity})'),
          value: true,
          groupValue: raiseQuantity,
          onChanged: (_) => setState(() => raiseQuantity = true),
        ),
        RadioListTile<bool>(
          title: Text('Raise face (was ${widget.oldFace})'),
          value: false,
          groupValue: raiseQuantity,
          onChanged: (_) => setState(() => raiseQuantity = false),
        ),
        if (raiseQuantity)
          Slider(
            min: (widget.oldQuantity + 1).toDouble(),
            max: (dicePerPlayer * numPlayers).toDouble(),
            divisions: dicePerPlayer * numPlayers - widget.oldQuantity,
            value: newQuantity.toDouble(),
            label: '$newQuantity',
            onChanged: (v) => setState(() => newQuantity = v.toInt()),
          )
        else
          Slider(
            min: (widget.oldFace + 1).toDouble(),
            max: 6.0,
            divisions: 6 - widget.oldFace,
            value: newFace.toDouble(),
            label: '$newFace',
            onChanged: (v) => setState(() => newFace = v.toInt()),
          ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final qty = raiseQuantity ? newQuantity : widget.oldQuantity;
            final face = raiseQuantity ? widget.oldFace : newFace;
            Navigator.pop(context, _Bid(qty, face));
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
