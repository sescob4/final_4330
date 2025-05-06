// ─────────────────────────────────────────────────────────────────────────────
// Imports
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/dice_face.dart';
import 'widgets/player_profile.dart';
import 'widgets/player_area.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
enum _LockMode { none, qty, face }
const int numPlayers = 4;       // Total players: You + 3 CPUs
const int dicePerPlayer = 5;    // Dice per player

// ─────────────────────────────────────────────────────────────────────────────
// DicePage: Main game screen widget
class DicePage extends StatefulWidget {
  const DicePage({super.key});

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> with SingleTickerProviderStateMixin {
  // ───────────────────────────────────────────────────────────────────────────
  // State fields
  late List<List<int>> allDice;         // All players' dice values
  late List<bool> alive;                // Alive flags per player
  late List<int> lives;                 // Lives remaining per player
  int turnIndex = 0;                    // 0 = You, 1–3 = CPUs
  bool hasRolled = false;               // Has current player rolled?
  int? bidQuantity;                     // Current bid quantity
  int? bidFace;                         // Current bid face
  _LockMode _lockMode = _LockMode.none;

  // Rolling animation state
  bool _rolling = false;
  final Duration _rollAnimDuration = Duration(milliseconds: 800);
  final Duration _rollAnimInterval = Duration(milliseconds: 100);
  Timer? _rollTimer;

  // Inline betting UI state
  bool _showBetControls = false;
  bool _betRaiseQuantity = true;
  late int _tempQty;
  late int _tempFace;
  late int _origQty;
  late int _origFace;

  // Random generator for CPU actions
  final Random _rand = Random();

  // Animation controller (reserved)
  late AnimationController _controller;
  late Animation<double> _animation;

  // History log / comments panel
  final List<String> history = [];
  final ScrollController _scrollController = ScrollController();
  bool _showComments = false;

  // ───────────────────────────────────────────────────────────────────────────
  // Initialization & disposal
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

  // ───────────────────────────────────────────────────────────────────────────
  // Game state setup
  void _initGameState() {
    allDice = List.generate(numPlayers, (_) => List.filled(dicePerPlayer, 1));
    alive = List.filled(numPlayers, true);
    lives = List.filled(numPlayers, 3);
    turnIndex = 0;
    hasRolled = false;
    bidQuantity = null;
    bidFace = null;
    _showBetControls = false;
    history.clear();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Logging utility: append to history and scroll
  void _addLog(String entry) {
    history.add(entry);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Game menu dialog
  void _showGameMenu() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3E2723),
        title: const Text('Game Menu', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.settings, color: Colors.white),
              label: const Text('Settings', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text('Main Menu', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // User actions: roll, bet, call
  void rollDice() {
    if (turnIndex != 0 || hasRolled || _rolling) return;
    _rolling = true;
    final finalRoll = List.generate(dicePerPlayer, (_) => _rand.nextInt(6) + 1);
    int ticks = (_rollAnimDuration.inMilliseconds ~/ _rollAnimInterval.inMilliseconds);
    int count = 0;
    Timer.periodic(_rollAnimInterval, (timer) {
      count++;
      setState(() {
        allDice[0] = List.generate(dicePerPlayer, (_) => _rand.nextInt(6) + 1);
      });
      if (count >= ticks) {
        timer.cancel();
        setState(() {
          allDice[0] = finalRoll;
          for (var i = 1; i < numPlayers; i++) {
            allDice[i] = List.generate(dicePerPlayer, (_) => _rand.nextInt(6) + 1);
          }
          hasRolled = true;
          _rolling = false;
        });
        _addLog('You rolled: ${allDice[0].join(', ')}');
        _addLog('Your turn: Bet or Call');
      }
    });
  }

  void _userBet() {
    if (turnIndex != 0 || !hasRolled) return;
    setState(() {
      _showBetControls = true;
      _tempQty = bidQuantity ?? 1;  // Start from last bid quantity or 1
      _tempFace = bidFace ?? 1;      // Start from last bid face or 1
      _origQty = _tempQty;
      _origFace = _tempFace;
      _lockMode = _LockMode.none;
    });
  }

  void _confirmBet() {
    if (turnIndex != 0 || !hasRolled) return;
    // Only confirm if quantity or face is incremented
    if (!(_tempQty > (bidQuantity ?? 0) || _tempFace > (bidFace ?? 1))) return;

    setState(() {
      bidQuantity = _tempQty;
      bidFace = _tempFace;

      _addLog('You bet $bidQuantity × $bidFace');
      _showBetControls = false;

      // Advance to next alive player
      do {
        turnIndex = (turnIndex + 1) % numPlayers;
      } while (!alive[turnIndex]);
    });

    if (turnIndex != 0) {
      Future.delayed(const Duration(milliseconds: 400), _cpuAction);
    }
  }

  void _cancelBet() => setState(() => _showBetControls = false);
  void _userCall() {
    if (turnIndex != 0 || !hasRolled || bidQuantity == null) return;
    _addLog('You called bluff on ${bidQuantity!} × ${bidFace!}');
    _resolveCall(0);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CPU actions: bet or call
  void _cpuAction() {
    if (bidQuantity != null && bidFace != null) {
      final totalDice = numPlayers * dicePerPlayer;
      final expected = totalDice / 6;
      final rawChance = (bidQuantity! - expected) / (totalDice - expected);
      final callChance = rawChance.clamp(0.0, 1.0);
      if (_rand.nextDouble() < callChance) { _handleCpuCall(); return; }
    }
    _handleCpuBet();
  }

  void _handleCpuCall() {
    final cpuIdx = turnIndex;
    _addLog('CPU $cpuIdx calls bluff');
    // immediately resolve the call (this resets turnIndex, hasRolled, etc.)
    _resolveCall(turnIndex);
  }

  void _handleCpuBet() {
    final cpuIdx = turnIndex;
    final oldQty = bidQuantity ?? 0;
    final oldFace = bidFace ?? 1;
    bool raiseQty = _rand.nextBool();
    if (!raiseQty && oldFace >= 6) raiseQty = true;
    final newQty = raiseQty ? oldQty + 1 : oldQty;
    final newFace = raiseQty ? oldFace : min(oldFace + 1, 6);
    setState(() { bidQuantity = newQty; bidFace = newFace; });
    final msg = 'CPU $cpuIdx bets $newQty × $newFace';
    _addLog(msg);
    ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)))
      .closed
      .then((_) => _nextTurn());
  }

  void _resolveCall(int caller) {
    // ─── count dice ─────────────────────────────────────────────
    final counts = <int,int>{};
    for (var hand in allDice) for (var v in hand) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    final qty    = bidQuantity!;
    final face   = bidFace!;
    final actual = counts[face] ?? 0;
    final last   = (turnIndex + numPlayers - 1) % numPlayers;
    final loser  = actual < qty ? last : caller;
    final loserName = loser == 0 ? 'You' : 'CPU $loser';

    // ─── decrement lives / eliminate ───────────────────────────
    setState(() {
      lives[loser]--;              // – subtract one life
      if (lives[loser] > 0) {
        _addLog('$loserName lost a life! (${lives[loser]} left)');
      } else {
        alive[loser] = false;
        _addLog('$loserName has no lives left and is eliminated');
      }
    });

    // ─── show the snackbar ──────────────────────────────────────
    final resultMsg = lives[loser] > 0
      ? '$loserName lost a life! (${lives[loser]} left)'
      : '$loserName eliminated';

    ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(content: Text(
          'Call: needed $qty×$face, found $actual — $resultMsg'
        ))
      )
      .closed
      .then((_) {
        setState(() {
          // clear the previous bid
          bidQuantity = null;
          bidFace     = null;
          // mark roll phase again
          hasRolled   = false;
          // always start next round with the user
          turnIndex   = 0;
        });
        _addLog('New round: roll the dice');
      });
  }

  /// Advance to the next alive player and kick off CPU or your turn.
  void _nextTurn() {
    setState(() {
      // step to the next index that’s still alive
      do {
        turnIndex = (turnIndex + 1) % numPlayers;
      } while (!alive[turnIndex]);
    });

    // if it’s your turn again, log it
    if (turnIndex == 0 && hasRolled) {
      _addLog('Your turn again: Bet or Call');
    }

    // if it’s a CPU’s turn, schedule its move
    if (turnIndex != 0) {
      Future.delayed(const Duration(milliseconds: 400), _cpuAction);
    }
  }
  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // transparent status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final media    = MediaQuery.of(context).size;
    final baseSize = min(media.width * 0.6, media.height * 0.6);
    final tableSize   = baseSize * 0.8;
    final tableOffset = Offset(0, -baseSize * 0.1);

    return Scaffold(
       body: Stack( 
        children: [
          
        Positioned.fill(
        child: Image.asset(
          'assets/table1.png',
          fit: BoxFit.cover,
        ),
      ),
_buildHeartBox(lives[0]),
_buildHeartBox(lives[0]),
      Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        child: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 32),
          onPressed: _showGameMenu,
          tooltip: 'Game Menu',
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).padding.top + 40, // Changed from 60 to 40
        left: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerProfile(
              name: 'CPU 1',
              roleNumber: 1,
              lives: lives[1],
              isCurrentTurn: turnIndex == 1,
            ),
            PlayerProfile(
              name: 'CPU 2',
              roleNumber: 2,
              lives: lives[2],
              isCurrentTurn: turnIndex == 2,
            ),
            PlayerProfile(
              name: 'CPU 3',
              roleNumber: 3,
              lives: lives[3],
              isCurrentTurn: turnIndex == 3,
            ),
            PlayerProfile(
              name: 'You',
              roleNumber: 4,
              lives: lives[0],
              isCurrentTurn: turnIndex == 0,
            ),
          ],
        ),
      ),
      Row(
        children: [
          // ── LEFT: game area in a scrollable SafeArea ────────────────
          Expanded(
            flex: 2,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Container(
                      width: double.infinity, // Take full width
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 0),
                          
                          // Center dice area
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PlayerArea(
                                    name: '',
                                    isCurrent: true,
                                    diceValues: allDice[0],
                                    small: false,
                                    lives: lives[0],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Center controls
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!hasRolled && !_rolling) _buildRollButton(),
                                  if (turnIndex == 0 && hasRolled && !_showBetControls) 
                                    _buildUserControls(),
                                  if (_showBetControls) _buildInlineBetControls(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── RIGHT: collapsible history log ───────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _showComments ? MediaQuery.of(context).size.width * 0.25 : 50,
            child: Column(
              children: [
                // Comments toggle button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      _showComments ? Icons.comment : Icons.comment_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _showComments = !_showComments;
                      });
                    },
                    tooltip: _showComments ? 'Hide Comments' : 'Show Comments',
                  ),
                ),
                // Comments list
                if (_showComments)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 35),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),    // ← this is the translucent fill
                      borderRadius: BorderRadius.circular(8),  // ← round the corners
                      ),
                      child: Scrollbar(
                        controller: _scrollController,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: history.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              history[i],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
        ],
    ),
    );
  }

  Widget _buildTable(double size) => SizedBox(
    width: size,
    height: size,
    child: Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(
        child: Container(decoration: const BoxDecoration(color: Color(0x99795000), shape: BoxShape.circle)),
      ),
      for (var i = 0; i < numPlayers; i++)
        Align(
          alignment: _playerAlignment(i),
          child: alive[i]
            ? PlayerArea(
                name: i == 0 ? 'You' : 'CPU $i',
                isCurrent: i == 0,
                diceValues: i == 0 ? allDice[0] : null,
                small: i != 0,
                 lives: lives[i],
              )
            : _outBox(label: i == 0 ? 'You' : 'CPU ${i + 1}'),
        ),
    ]),
  );

  Widget _buildRollButton() => ElevatedButton(
    onPressed: rollDice,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.amber,
      foregroundColor: Colors.brown.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
    ),
    child: const Text('Roll Dice'),
  );

  Widget _buildUserControls() => Align(
    alignment: Alignment.center,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      ElevatedButton(onPressed: _userBet, child: const Text('Bet')),
      const SizedBox(width: 16),
      ElevatedButton(onPressed: _userCall, child: const Text('Call')),
    ]),
  );

 
// Inline‐bet controls (mutually resetting fields)
Widget _buildInlineBetControls() {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.brown.shade800,
      border: Border.all(color: Colors.amber),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Qty display + arrows ────────────────────────────
        Container(
          width: 40, height: 20,
          decoration: BoxDecoration(
            color: Colors.brown.shade700,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text('$_tempQty',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Qty ↑
            IconButton(
              icon: Icon(Icons.arrow_drop_up,
                color: Colors.amber,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 20),
              onPressed: () {
                setState(() {
                  // 1) reset face to original
                  _tempFace = _origFace;
                  // 2) now lock qty and increment
                  _lockMode = _LockMode.qty;
                  if (_tempQty < dicePerPlayer * numPlayers) _tempQty++;
                });
              },
            ),
            // Qty ↓
            IconButton(
              icon: Icon(Icons.arrow_drop_down,
                color: Colors.amber,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 20),
              onPressed: () {
                setState(() {
                  // 1) reset face
                  _tempFace = _origFace;
                  // 2) lock qty and decrement
                  _lockMode = _LockMode.qty;
                  if (_tempQty > (bidQuantity ?? 0) + 1) _tempQty--;
                });
              },
            ),
          ],
        ),

        const SizedBox(width: 8),
        const Text('×', style: TextStyle(color: Colors.amber, fontSize: 24)),
        const SizedBox(width: 8),

        // ── Face display + arrows ────────────────────────────
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.brown.shade700,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text('$_tempFace',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Face ↑
            IconButton(
              icon: Icon(Icons.arrow_drop_up,
                color: Colors.amber,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 20),
              onPressed: () {
                setState(() {
                  // reset qty first
                  _tempQty = _origQty;
                  // lock face and increment only if less than 6
                  _lockMode = _LockMode.face;
                  if (_tempFace < 6) _tempFace++;
                });
              },
            ),
            // Face ↓
            IconButton(
              icon: Icon(Icons.arrow_drop_down,
                color: Colors.amber,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 20),
              onPressed: () {
                setState(() {
                  // reset qty
                  _tempQty = _origQty;
                  // lock face and decrement
                  _lockMode = _LockMode.face;
                  if (_tempFace > (bidFace ?? 1) + 1) _tempFace--;
                });
              },
            ),
          ],
        ),

        const SizedBox(width: 12),
        // ── Confirm / Cancel ─────────────────────────────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: (_tempQty > (bidQuantity ?? 0) || _tempFace > (bidFace ?? 1))
                ? _confirmBet
                : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Confirm'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _cancelBet,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    ),
  );
}



  /// 0→You, 1→CPU1, 2→CPU2, 3→CPU3
  Alignment _playerAlignment(int idx) {
    switch (idx) {
      case 0: return const Alignment( 0.0,  0.8); // You at bottom
      case 1: return const Alignment(-0.8,  0.0); // CPU1 on left
      case 2: return const Alignment( 0.0, -0.8); // CPU2 on top
      case 3: return const Alignment( 0.8,  0.0); // CPU3 on right
      default: return Alignment.center;
  }
}

  Widget _outBox({required String label}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: const TextStyle(color: Colors.white)),
  );

  Widget _buildHeartBox(int lives) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.only(top: 6, bottom: 6, left: 12, right: 12),
          decoration: BoxDecoration(
            color: Colors.brown.shade800,
            border: Border(
              left: const BorderSide(color: Colors.amber, width: 3),
              right: const BorderSide(color: Colors.amber, width: 3),
              bottom: const BorderSide(color: Colors.amber, width: 3),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              lives,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  Icons.favorite,
                  size: 30, // Reduced heart size
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}