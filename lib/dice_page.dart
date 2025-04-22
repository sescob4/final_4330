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
  int currentPlayer = 0;
  int lastBidder = 0;
  int? bidQuantity;
  int? bidFace;

  final random = Random();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    allDice = List.generate(
      numPlayers,
      (_) => List.filled(dicePerPlayer, 1),
    );
    alive = List.filled(numPlayers, true);
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
    super.dispose();
  }

  void _advanceTurn() {
    do {
      currentPlayer = (currentPlayer + 1) % numPlayers;
    } while (!alive[currentPlayer]);
  }

  void rollDice() {
    _controller.forward(from: 0);
    setState(() {
      allDice[currentPlayer] = List.generate(
        dicePerPlayer,
        (_) => random.nextInt(6) + 1,
      );
    });
  }

  Future<void> _onBet() async {
    final result = await showDialog<_Bid>(
      context: context,
      builder: (_) => _BetDialog(
        oldQuantity: bidQuantity ?? 0,
        oldFace: bidFace ?? 1,
      ),
    );
    if (result == null) return;
    setState(() {
      lastBidder = currentPlayer;
      bidQuantity = result.quantity;
      bidFace = result.face;
      _advanceTurn();
    });
  }

  void _onCall() {
    if (bidQuantity == null || bidFace == null) return;
    final total = allDice.expand((d) => d).where((v) => v == bidFace).length;
    final loser = total >= bidQuantity! ? currentPlayer : lastBidder;
    setState(() {
      alive[loser] = false;
      bidQuantity = null;
      bidFace = null;
      _advanceTurn();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade900,
      appBar: AppBar(
        title: const Text('Liar\'s Dice'),
        backgroundColor: Colors.brown.shade700,
      ),
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
                  // Table background
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0x99795000),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Bet / Call buttons
                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: _onBet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.brown.shade900,
                          ),
                          child: const Text('Bet'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _onCall,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.brown.shade900,
                          ),
                          child: const Text('Call'),
                        ),
                      ],
                    ),
                  ),
                  // Opponents around the table
                  for (var i = 0; i < numPlayers; i++)
                    if (i != currentPlayer)
                      Align(
                        alignment: _playerAlignment(i),
                        child: alive[i]
                            ? PlayerArea(
                                name: 'Player ${i + 1}',
                                isCurrent: false,
                                diceValues: allDice[i],
                                small: true,
                              )
                            : _outBox(),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Your area below
            ScaleTransition(
              scale: _animation,
              child: alive[currentPlayer]
                  ? PlayerArea(
                      name: 'You',
                      isCurrent: true,
                      diceValues: allDice[currentPlayer],
                      small: false,
                    )
                  : _outBox(label: 'You'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: rollDice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.brown.shade900,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
              ),
              child: const Text('Roll Dice'),
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

  Widget _outBox({String label = 'Out'}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white)),
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
        ? (diceValues ?? []).map((v) => SizedBox(
              width: dieSize,
              height: dieSize,
              child: FittedBox(
                fit: BoxFit.contain,
                child: DiceFace(value: v),
              ),
            )).toList()
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
        Text(name,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: diceWidgets,
          ),
        ),
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
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Icon(Icons.help_outline,
            color: Colors.white, size: 24),
      ),
    );
  }
}

class _Bid {
  final int quantity, face;
  _Bid(this.quantity, this.face);
}

class _BetDialog extends StatefulWidget {
  final int oldQuantity, oldFace;
  const _BetDialog({
    required this.oldQuantity,
    required this.oldFace,
  });

  @override
  _BetDialogState createState() => _BetDialogState();
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
          title:
              Text('Raise quantity (was ${widget.oldQuantity})'),
          value: true,
          groupValue: raiseQuantity,
          onChanged: (_) =>
              setState(() => raiseQuantity = true),
        ),
        RadioListTile<bool>(
          title: Text('Raise face (was ${widget.oldFace})'),
          value: false,
          groupValue: raiseQuantity,
          onChanged: (_) =>
              setState(() => raiseQuantity = false),
        ),
        if (raiseQuantity)
          Slider(
            min: (widget.oldQuantity + 1).toDouble(),
            max: (dicePerPlayer * numPlayers).toDouble(),
            divisions:
                dicePerPlayer * numPlayers - widget.oldQuantity,
            value: newQuantity.toDouble(),
            onChanged: (v) =>
                setState(() => newQuantity = v.toInt()),
            label: '$newQuantity',
          )
        else
          Slider(
            min: (widget.oldFace + 1).toDouble(),
            max: 6.0,
            divisions: 6 - widget.oldFace,
            value: newFace.toDouble(),
            onChanged: (v) =>
                setState(() => newFace = v.toInt()),
            label: '$newFace',
          ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final qty = raiseQuantity
                ? newQuantity
                : widget.oldQuantity;
            final face =
                raiseQuantity ? widget.oldFace : newFace;
            Navigator.pop(context, _Bid(qty, face));
          },
          child: const Text('OK'),
        ),
      ],
    );  
  }
}
