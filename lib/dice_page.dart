// ─────────────────────────────────────────────────────────────────────────────
// Imports
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/dice_face.dart';
import 'widgets/player_profile.dart';
import 'widgets/player_area.dart';
import 'game/game_logic.dart';

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
  late final GameLogic _gameLogic;
  final ScrollController _scrollController = ScrollController();
  bool _showComments = false;

  // Animation controller (reserved)
  late AnimationController _controller;
  late Animation<double> _animation;

  // ───────────────────────────────────────────────────────────────────────────
  // Initialization & disposal
  @override
  void initState() {
    super.initState();
    _gameLogic = GameLogic();
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
  // Logging utility: append to history and scroll
  void _addLog(String entry) {
    setState(() {
      _gameLogic.addLog(entry);
    });
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
    if (_gameLogic.turnIndex != 0 || _gameLogic.hasRolled || _gameLogic.rolling) return;

    setState(() {
      _gameLogic.rolling = true;
    });

    final finalRoll = _gameLogic.rollDice();
    int ticks = (_gameLogic.rollAnimDuration.inMilliseconds ~/ _gameLogic.rollAnimInterval.inMilliseconds);
    int count = 0;
    Timer.periodic(_gameLogic.rollAnimInterval, (timer) {
      count++;
      setState(() {
        _gameLogic.updateDiceRoll();
      });
      if (count >= ticks) {
        timer.cancel();
        setState(() {
          _gameLogic.finalizeDiceRoll(finalRoll);
        });
        _addLog('You rolled: ${_gameLogic.allDice[0].join(', ')}');
        _addLog('Your turn: Bet or Call');
      }
    });
  }

  void _userBet() {
    if (_gameLogic.turnIndex != 0 || !_gameLogic.hasRolled) return;
    setState(() {
      _gameLogic.showBetControls = true;
      _gameLogic.prepareBet();
    });
  }

  void _confirmBet() {
    if (_gameLogic.turnIndex != 0 || !_gameLogic.hasRolled) return;
    setState(() {
      _gameLogic.confirmBet();
      _addLog('You bet ${_gameLogic.bidQuantity} × ${_gameLogic.bidFace}');
    });
    if (_gameLogic.turnIndex != 0) Future.delayed(const Duration(milliseconds: 400), _gameLogic.cpuAction);
  }

  void _cancelBet() => setState(() => _gameLogic.showBetControls = false);

  void _userCall() {
    if (_gameLogic.turnIndex != 0 || !_gameLogic.hasRolled || _gameLogic.bidQuantity == null) return;
    _addLog('You called bluff on ${_gameLogic.bidQuantity!} × ${_gameLogic.bidFace!}');
    _gameLogic.resolveCall(0);
  }

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // transparent status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final media = MediaQuery.of(context).size;
    final baseSize = min(media.width * 0.6, media.height * 0.6);
    final tableSize = baseSize * 0.8;
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
          _buildHeartBox(_gameLogic.lives[0]),
          _buildHeartBox(_gameLogic.lives[0]),
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
            top: MediaQuery.of(context).padding.top + 40,
            left: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayerProfile(
                  name: 'CPU 1',
                  roleNumber: 1,
                  lives: _gameLogic.lives[1],
                  isCurrentTurn: _gameLogic.turnIndex == 1,
                ),
                PlayerProfile(
                  name: 'CPU 2',
                  roleNumber: 2,
                  lives: _gameLogic.lives[2],
                  isCurrentTurn: _gameLogic.turnIndex == 2,
                ),
                PlayerProfile(
                  name: 'CPU 3',
                  roleNumber: 3,
                  lives: _gameLogic.lives[3],
                  isCurrentTurn: _gameLogic.turnIndex == 3,
                ),
                PlayerProfile(
                  name: 'You',
                  roleNumber: 4,
                  lives: _gameLogic.lives[0],
                  isCurrentTurn: _gameLogic.turnIndex == 0,
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 0),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PlayerArea(
                                        name: '',
                                        isCurrent: true,
                                        diceValues: _gameLogic.allDice[0],
                                        small: false,
                                        lives: _gameLogic.lives[0],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!_gameLogic.hasRolled && !_gameLogic.rolling) _buildRollButton(),
                                      if (_gameLogic.turnIndex == 0 && _gameLogic.hasRolled && !_gameLogic.showBetControls)
                                        _buildUserControls(),
                                      if (_gameLogic.showBetControls) _buildInlineBetControls(),
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _showComments ? MediaQuery.of(context).size.width * 0.25 : 50,
                child: Column(
                  children: [
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
                    if (_showComments)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 35),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Scrollbar(
                            controller: _scrollController,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: _gameLogic.history.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  _gameLogic.history[i],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
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
          child: _gameLogic.alive[i]
            ? PlayerArea(
                name: i == 0 ? 'You' : 'CPU $i',
                isCurrent: i == 0,
                diceValues: i == 0 ? _gameLogic.allDice[0] : null,
                small: i != 0,
                lives: _gameLogic.lives[i],
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
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.brown.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text('${_gameLogic.tempQty}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_drop_up,
                  color: Colors.amber,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 20),
                onPressed: () {
                  setState(() {
                    _gameLogic.incrementTempQty();
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.arrow_drop_down,
                  color: Colors.amber,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 20),
                onPressed: () {
                  setState(() {
                    _gameLogic.decrementTempQty();
                  });
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Text('×', style: TextStyle(color: Colors.amber, fontSize: 24)),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.brown.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text('${_gameLogic.tempFace}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_drop_up,
                  color: Colors.amber,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 20),
                onPressed: () {
                  setState(() {
                    _gameLogic.incrementTempFace();
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.arrow_drop_down,
                  color: Colors.amber,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 20),
                onPressed: () {
                  setState(() {
                    _gameLogic.decrementTempFace();
                  });
                },
              ),
            ],
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: (_gameLogic.tempQty > (_gameLogic.bidQuantity ?? 0) || _gameLogic.tempFace > (_gameLogic.bidFace ?? 1))
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

  Alignment _playerAlignment(int idx) {
    switch (idx) {
      case 0: return const Alignment(0.0, 0.8);
      case 1: return const Alignment(-0.8, 0.0);
      case 2: return const Alignment(0.0, -0.8);
      case 3: return const Alignment(0.8, 0.0);
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
                  size: 30,
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
