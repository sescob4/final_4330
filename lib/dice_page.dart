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

class _DicePageState extends State<DicePage>
    with SingleTickerProviderStateMixin {
  // ────────────────────────────────────────────────────────────────────────────
  // State fields
  late List<List<int>> allDice;
  late List<bool> alive;
  int turnIndex = 0;       // 0 = You, 1–4 = CPUs
  bool hasRolled = false;  // User may roll only once per turn
  int? bidQuantity;
  int? bidFace;

  final Random _rand = Random();
  late AnimationController _controller;
  late Animation<double> _animation;

  // history log
  final List<String> history = [];
  final ScrollController _scrollController = ScrollController();

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
    allDice = List.generate(numPlayers, (_) => List.filled(dicePerPlayer, 1));
    alive = List.filled(numPlayers, true);
    turnIndex = 0;
    hasRolled = false;
    bidQuantity = null;
    bidFace = null;
    history.clear();
  }

  void _addLog(String entry) {
    history.add(entry);
    // scroll to bottom
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

  Future<void> _userBet() async {
    if (turnIndex != 0 || !hasRolled) return;
    final result = await showDialog<_Bid>(
      context: context,
      builder: (_) => _BetDialog(
        oldQuantity: bidQuantity ?? 0,
        oldFace: bidFace ?? 1,
      ),
    );
    if (result == null) return;
    setState(() {
      bidQuantity = result.quantity;
      bidFace = result.face;
    });
    _addLog('You bet ${bidQuantity!} × ${bidFace!}');
    _nextTurn();
  }

  void _userCall() {
    if (turnIndex != 0 || !hasRolled || bidQuantity == null) return;
    _addLog('You called bluff on ${bidQuantity!} × ${bidFace!}');
    _resolveCall(0);
  }

// ────────────────────────────────────────────────────────────────────────────
// CPU actions

/// Called when it’s a CPU’s turn: 1-in-4 chance to call, otherwise bet.
void _cpuAction() {
  final shouldCall = bidQuantity != null && _rand.nextInt(4) == 0;
  if (shouldCall) {
    _handleCpuCall();
  } else {
    _handleCpuBet();
  }
}

/// Handles the CPU calling the bluff.
void _handleCpuCall() {
  final cpuIdx = turnIndex + 1; // human=0, so CPU # is +1
  _addLog('CPU $cpuIdx calls bluff');
  _resolveCall(turnIndex);
}

/// Handles the CPU making a bet (always raises either qty or face by ≥1).
/// If face is already at max (6), it will raise quantity instead.
void _handleCpuBet() {
  final cpuIdx  = turnIndex + 1;
  final oldQty  = bidQuantity ?? 0;
  final oldFace = bidFace     ?? 1;

  // Randomly pick whether to raise quantity or face
  bool raiseQty = _rand.nextBool();

  // If we picked "raise face" but face is already maxed out, force quantity
  if (!raiseQty && oldFace >= 6) {
    raiseQty = true;
  }

  // Compute the new bid values
  final newQty  = raiseQty
      ? oldQty + 1       // always at least +1
      : oldQty;          // unchanged
  final newFace = raiseQty
      ? oldFace         // unchanged
      : (oldFace < 6 ? oldFace + 1 : 6);

  // Commit to state
  setState(() {
    bidQuantity = newQty;
    bidFace     = newFace;
  });

  // Log it, show a SnackBar, then advance turn
  final msg = 'CPU $cpuIdx bets $newQty × $newFace';
  _addLog(msg);
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)))
      .closed
      .then((_) => _nextTurn());
}

/// Geometrically increases the quantity by 1, then
/// with 1/(inc+1) chance continues raising further.
int _generateRaisedQuantity(int currentQty) {
  var qty = currentQty;
  var inc = 1;
  while (_rand.nextInt(inc + 1) == 0) {
    qty++;
    inc++;
  }
  return qty;
}
 // ────────────────────────────────────────────────────────────────────────────
  /// Resolve a bluff call by [caller].
void _resolveCall(int caller) {
  // Count all dice on board
  final counts = <int,int>{};
  for (var hand in allDice) {
    for (var v in hand) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
  }

  final qty    = bidQuantity!;
  final face   = bidFace!;
  final actual = counts[face] ?? 0;

  // Determine who loses: if actual < qty, last bidder loses; else caller loses
  final last    = (turnIndex + numPlayers - 1) % numPlayers;
  final loser   = actual < qty ? last : caller;
  final loserName = loser == 0 ? 'You' : 'CPU ${loser + 1}';

  // Log the result
  final msg = 'Call: needed $qty×$face, found $actual — $loserName out';
  _addLog(msg);

  // Update alive state
  setState(() {
    alive[loser] = false;
  });

  // Show a notification, then only reset the round if a CPU was eliminated
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)))
      .closed
      .then((_) {
    if (loser != 0) {
      // CPU eliminated → reset for next round
      setState(() {
        hasRolled    = false;
        bidQuantity  = null;
        bidFace      = null;
        turnIndex    = 0;
      });
    }
    // If the user was eliminated (loser == 0), we leave the final state in place.
  });
}

  void _nextTurn() {
  // move to next alive player
  do {
    turnIndex = (turnIndex + 1) % numPlayers;
  } while (!alive[turnIndex]);

  // if we wrapped back to the user and they've already rolled,
  // prompt them again to Bet or Call
  if (turnIndex == 0 && hasRolled) {
    _addLog('Your turn again: Bet or Call');
    // (the build() already shows Bet/Call controls whenever turnIndex==0 && hasRolled)
  }

  // if it's a CPU's turn, schedule their action
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
          // main game area
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTable(),
                const SizedBox(height: 16),
                if (!hasRolled) _buildRollButton(),
                if (turnIndex == 0 && hasRolled) _buildUserControls(),
              ],
            ),
          ),

          // history column
          Container(
            width: 150,
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black38,
              border: Border.all(color: Colors.white54),
            ),
            child: Scrollbar(
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: history.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    history[i],
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
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
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0x99795000),
              shape: BoxShape.circle,
            ),
          ),
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
        ElevatedButton(
          onPressed: _userBet,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.brown.shade900,
          ),
          child: const Text('Bet'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _userCall,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.brown.shade900,
          ),
          child: const Text('Call'),
        ),
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
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: diceWidgets),
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
      decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(6)),
      child: const Center(child: Icon(Icons.help_outline, color: Colors.white)),
    );
  }
}

// Models for betting dialog

class _Bid {
  final int quantity, face;
  _Bid(this.quantity, this.face);
}

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
