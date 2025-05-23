import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:final_4330/screens/settings.dart';
import 'package:final_4330/Databaseservice.dart';
import 'widgets/profile_picture_deck.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// MODEL
enum CardType { ace, queen, king, joker }

class DeckCard {
  final CardType type;
  DeckCard(this.type);
  String get assetPath => switch (type) {
        CardType.ace => 'assets/ace.svg',
        // CardType.jack => 'assets/jack.svg',
        CardType.queen => 'assets/queen.svg',
        CardType.king => 'assets/king.svg',
        CardType.joker => 'assets/joker.svg',
      };
}

class Player {
  final String name;
  final bool isAI;
  final int roleNumber;
  List<DeckCard> hand = [];
  int rouletteChambers = 1;
  bool eliminated = false;

  Player(this.name, {this.isAI = false, required this.roleNumber});

  bool spin(Random rng) {
    if (rouletteChambers >= 6) return true;
    return rng.nextInt(6) < rouletteChambers;
  }
}

// GAME STATE
class LiarsDeckGameState {
  final Random rng = Random();
  static const cardsPerPlayer = 5;

  late List<Player> players;
  late CardType tableType;
  late int currentPlayer;
  int lastPlayerIdx = -1;
  List<DeckCard> tableCards = [];
  bool roundOver = false;

  LiarsDeckGameState() {
    players = [];
    startRound();
  }

  void _ensurePlayers() {
    if (players.isNotEmpty) return;

    final rng = Random();
    final aiRoles = [1, 2, 4]..shuffle();

    players = [
      Player('You', roleNumber: 3),
      Player('AI1', isAI: true, roleNumber: aiRoles[0]),
      Player('AI2', isAI: true, roleNumber: aiRoles[1]),
      Player('AI3', isAI: true, roleNumber: aiRoles[2]),
    ];
  }

  void startRound() {
    _ensurePlayers();
    final deck = <DeckCard>[
      ...List.generate(6, (_) => DeckCard(CardType.king)),
      ...List.generate(6, (_) => DeckCard(CardType.queen)),
      // ...List.generate(6, (_) => DeckCard(CardType.jack)),
      ...List.generate(6, (_) => DeckCard(CardType.ace)),
      ...List.generate(2, (_) => DeckCard(CardType.joker)),
    ]..shuffle(rng);

    for (final p in players) {
      p.hand.clear();
    }
    for (var i = 0; i < cardsPerPlayer; i++) {
      for (final p in players.where((pl) => !pl.eliminated)) {
        p.hand.add(deck.removeLast());
      }
    }

    const tables = [CardType.ace, CardType.queen, CardType.king];
    tableType = tables[rng.nextInt(tables.length)];
    currentPlayer = _nextAlive(rng.nextInt(players.length));
    tableCards.clear();
    lastPlayerIdx = -1;
    roundOver = false;
  }

  int _nextAlive(int idx) {
    while (players[idx].eliminated) {
      idx = (idx + 1) % players.length;
    }
    return idx;
  }

  bool isHumanTurn() => !players[currentPlayer].isAI && !roundOver;

  String playCards(Player p, List<DeckCard> cards) {
    for (final c in cards) {
      p.hand.remove(c);
    }
    tableCards = List.of(cards);
    lastPlayerIdx = players.indexOf(p);
    final msg =
        '${p.name} played ${cards.length} ${tableType.name}${cards.length == 1 ? '' : 's'}.';
    advanceTurn();
    return msg;
  }

  String callBluff(Player caller) {
    roundOver = true;
    final correct = tableCards
        .where((c) => c.type == tableType || c.type == CardType.joker)
        .length;
    final lied = correct != tableCards.length;
    final accused = players[lastPlayerIdx];
    final spinner = lied ? accused : caller;
    final shot = spinner.spin(rng);
    return '${caller.name} ${lied ? "correctly" : "incorrectly"} called bluff. '
        '${spinner.name} ${shot ? "was ELIMINATED!" : "survived."}';
  }

  void advanceTurn() {
    int attempts = 0;
    do {
      currentPlayer = (currentPlayer + 1) % players.length;
      attempts++;
    } while ((players[currentPlayer].eliminated ||
            players[currentPlayer].hand.isEmpty) &&
        attempts < players.length);
  }
}

// Test
// UI PAGE
class LiarsDeckGamePage extends StatefulWidget {
  final String gameId;
  const LiarsDeckGamePage({required this.gameId, super.key});
  @override
  State<LiarsDeckGamePage> createState() => _LiarsDeckGamePageState();
}

class _LiarsDeckGamePageState extends State<LiarsDeckGamePage> {
  late LiarsDeckGameState game;
  final Set<DeckCard> selected = {};
  final List<String> history = [];
  final ScrollController _scroll = ScrollController();

  bool gameOver = false; // true when full game ends, not just round
  bool showRevealedCards = false;

  bool started = false, aiBusy = false;
  static const aiDelay = Duration(seconds: 3);

  String? overlayMsg;
  double overlayOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    game = LiarsDeckGameState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAssets();
    });
  }

  Future<void> _preloadAssets() async {
    // Preload SVG card and splat assets
    final svgAssets = [
      'assets/cardback.svg',
      'assets/ace.svg',
      'assets/queen.svg',
      'assets/king.svg',
      'assets/joker.svg',
      'assets/splat1.svg',
      'assets/splat2.svg',
      'assets/splat3.svg',
    ];

    for (final path in svgAssets) {
      final loader = SvgAssetLoader(path);
      await svg.cache
          .putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
    }

    // Preload PNG table background
    await precacheImage(const AssetImage('assets/tab2.png'), context);
  }

  void _addLog(String s) {
    setState(() {
      history.add(s);
    });

    // Delay scroll after rebuild safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showOverlay(String msg) {
    setState(() {
      overlayMsg = msg;
      overlayOpacity = 1.0;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => overlayOpacity = 0.0);
      Future.delayed(const Duration(milliseconds: 400),
          () => mounted ? setState(() => overlayMsg = null) : null);
    });
  }

  void _checkWinner() {
    final alive = game.players.where((p) => !p.eliminated).toList();
    if (alive.length == 1 || game.players[0].eliminated) {
      final winner = alive.first;
      game.roundOver = true;
      aiBusy = false;
      gameOver = true;

      final db = DatabaseService();
      if (winner.name == 'You') {
        db.recordGameResult(didWin: true);
        _showOverlay('YOU WIN!');
      } else {
        db.recordGameResult(didWin: false);
        _showOverlay('YOU LOSE!');
      }
    }
  }

  void _restartGame() {
    setState(() {
      game = LiarsDeckGameState();
      selected.clear();
      history.clear();
      gameOver = false;
      started = true;
      aiBusy = false;
    });
    _addLog('New game started.');
    _maybeScheduleAI();
  }

  void _startGame() {
    setState(() => started = true);
    _nextRound();
  }

  void _nextRound() {
    setState(() {
      showRevealedCards = false; // <-- reset here
      game.startRound();
      selected.clear();
      _addLog('New round: ${game.tableType.name.toUpperCase()}s');
    });
    _maybeScheduleAI();
  }

  void _handleBluffResult(String msg, Player spinner) {
    // 1) Reveal the cards immediately
    setState(() {
      showRevealedCards = true;
    });

    // Split the full message into "called bluff" and result parts
    final parts = msg.split('. ');
    final calledText = parts[0]; // e.g. "You correctly called bluff"
    final resultText = parts.length > 1
        ? parts[1].replaceAll(RegExp(r'[.!]'), '') // e.g. "Bob was ELIMINATED"
        : '';

    // 2) Show "<Player> called bluff"
    _showOverlay(calledText);

    // 3) After 2 seconds, show "<Player> survived" or "…was eliminated"
    Future.delayed(const Duration(seconds: 3), () {
      _showOverlay(resultText);

      // 4) After another short pause, apply the outcome + log + check
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        setState(() {
          if (resultText.contains('ELIMINATED')) {
            spinner.eliminated = true;
          } else {
            spinner.rouletteChambers = min(6, spinner.rouletteChambers + 1);
          }
          _addLog(msg); // full sentence in the console
          _checkWinner();
        });
      });
    });
  }

  void _maybeScheduleAI() {
    if (aiBusy || game.isHumanTurn() || game.roundOver) return;
    aiBusy = true;
    Future.delayed(aiDelay, _runAITurn);
  }

  void _runAITurn() {
    if (!mounted || game.isHumanTurn() || game.roundOver) {
      aiBusy = false;
      return;
    }

    final ai = game.players[game.currentPlayer];
    if (ai.hand.isEmpty) {
      game.advanceTurn();
      aiBusy = false;
      _maybeScheduleAI();
      return;
    }

    final prevIdx = game.lastPlayerIdx;
    final prevPlayer = (prevIdx >= 0 && prevIdx < game.players.length)
        ? game.players[prevIdx]
        : null;
    final prevDumped = prevPlayer != null &&
        !prevPlayer.eliminated &&
        prevPlayer.hand.isEmpty &&
        game.tableCards.isNotEmpty;
    final bluff =
        prevDumped || (game.tableCards.isNotEmpty && game.rng.nextBool());

    if (bluff) {
      final msg = game.callBluff(ai);
      _showOverlay('${ai.name} CALLED BLUFF!');
      final spinner = msg.contains('${ai.name} was')
          ? ai
          : game.players[game.lastPlayerIdx];
      _handleBluffResult(msg, spinner);
      aiBusy = false;
    } else {
      // AI plays cards normally
      final count = min(
        ai.hand.length,
        game.rng.nextInt(
              ai.hand.where((c) => c.type != CardType.joker).isEmpty ? 1 : 4,
            ) +
            1,
      );
      final cards = ai.hand.take(count).toList();
      final msg = game.playCards(ai, cards);
      _showOverlay('${ai.name} PLAYED');
      setState(() {
        _addLog(msg);
      });
      _checkWinner();
      aiBusy = false;
      _maybeScheduleAI();
    }
  }

  void _tapCard(DeckCard c) {
    if (!game.isHumanTurn()) return;
    // 1) update UI immediately
    setState(() {
      selected.contains(c) ? selected.remove(c) : selected.add(c);
    });
    // 2) fire-and-forget sound
    _player.play(AssetSource('sound/card_sound_effect.mp3'));
  }

  void _playSelected() {
    if (selected.isEmpty) return;
    final msg = game.playCards(game.players[0], selected.toList());
    setState(() {
      showRevealedCards = false;
      _addLog(msg);
      selected.clear();
    });
    Future.delayed(const Duration(milliseconds: 800), _maybeScheduleAI);
  }

  void _callBluff() {
    _showOverlay('You CALLED BLUFF!');
    final msg = game.callBluff(game.players[0]);
    final spinner = msg.contains('You was')
        ? game.players[0]
        : game.players[game.lastPlayerIdx];
    _handleBluffResult(msg, spinner);
  }

  Widget _card(DeckCard c, {bool selectable = false}) {
    final isSelected = selected.contains(c);

    return GestureDetector(
      onTap: selectable ? () => _tapCard(c) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(4),
        width: 48,
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.7),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Transform.scale(
          scale: isSelected ? 1.05 : 1.0,
          child: SvgPicture.asset(
            c.assetPath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _hand(Player p,
      {required bool horizontal,
      required bool selectable,
      required bool highlight}) {
    final isUser = p.name == 'You';

    // Hardcoded width for eliminated AI splats to match expected position
    const fixedAIWidth = 100.0;

    if (!isUser && p.eliminated) {
      String splatAsset;
      switch (p.name) {
        case 'AI1':
          splatAsset = 'assets/splat1.svg';
          break;
        case 'AI2':
          splatAsset = 'assets/splat2.svg';
          break;
        case 'AI3':
          splatAsset = 'assets/splat3.svg';
          break;
        default:
          splatAsset = 'assets/splat3.svg';
      }

      return SizedBox(
        width: fixedAIWidth,
        height: 80,
        child: Center(
          child: SvgPicture.asset(
            splatAsset,
            width: 80,
            height: 80,
          ),
        ),
      );
    }

    final cardOffset = isUser ? 0.0 : -30.0;
    final cards = isUser
        ? p.hand.map((c) => _card(c, selectable: selectable)).toList()
        : List.generate(
            p.hand.length,
            (i) => Positioned(
              left: cardOffset + i * 20.0,
              child: SvgPicture.asset(
                'assets/cardback.svg',
                width: 38,
                height: 56,
              ),
            ),
          );

    final totalWidth = _handWidth(p.hand.length);
    final label = '${p.name} (${p.rouletteChambers}/6)';
    final lblCol = highlight ? Colors.green : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Name and (x/6)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    p.name,
                    style: TextStyle(
                      color: highlight ? Colors.green : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '(${p.rouletteChambers}/6)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(width: 6),
            // Profile picture
            PlayerProfileSimple(
              roleNumber: p.roleNumber,
              isCurrentTurn: highlight,
            ),
          ],
        ),
        const SizedBox(height: 6),
        isUser
            ? Row(mainAxisSize: MainAxisSize.min, children: cards)
            : SizedBox(
                width: totalWidth,
                height: 62,
                child: Stack(children: cards),
              ),
      ],
    );
  }

  double _handWidth(int count) {
    if (count <= 1) return 42;
    return 42 + (count - 1) * 20.0;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF3E2723),
        body: _buildTable(context),
      );
  final AudioPlayer _player = AudioPlayer();

  Widget _buildTable(BuildContext ctx) {
    final padTop = MediaQuery.of(ctx).padding.top;
    const consoleW = 150.0;
    return LayoutBuilder(builder: (context, constraints) {
      final radius = constraints.maxWidth * 0.10;
      final center =
          Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

      return Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/tab2.png', fit: BoxFit.cover),
          ),
          // Header
          Positioned(
            top: padTop,
            left: 8,
            child: Text('TABLE: ${game.tableType.name.toUpperCase()}S',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          // Settings button
          Positioned(
            top: padTop,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () async {
                await _player.play(AssetSource('sound/click-4.mp3'));
                if (!mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
                setState(() {}); // Refresh state after return
              },
            ),
          ),
          // Played cards at center (face down until bluff is called)
          Positioned(
            top: center.dy - 44,
            left: center.dx - ((game.tableCards.length - 1) * 20 + 95) / 2,
            child: SizedBox(
              width: (game.tableCards.length - 1) * 20.0 + 100,
              height: 62,
              child: Stack(
                children: List.generate(game.tableCards.length, (i) {
                  return Positioned(
                    left: i * 20.0,
                    child: SvgPicture.asset(
                      showRevealedCards
                          ? game.tableCards[i].assetPath
                          : 'assets/cardback.svg',
                      width: 42,
                      height: 62,
                      fit: BoxFit.cover,
                    ),
                  );
                }),
              ),
            ),
          ),
          // AI players
          Positioned(
            left: 190,
            top: center.dy - 80,
            child: _hand(
              game.players[1],
              horizontal: true,
              selectable: false,
              highlight: game.currentPlayer == 1 && !game.roundOver,
            ),
          ),
          Positioned(
            left: 395,
            top: 20,
            child: _hand(
              game.players[2],
              horizontal: true,
              selectable: false,
              highlight: game.currentPlayer == 2 && !game.roundOver,
            ),
          ),
          Positioned(
            right: 180,
            top: center.dy - 80,
            child: _hand(
              game.players[3],
              horizontal: true,
              selectable: false,
              highlight: game.currentPlayer == 3 && !game.roundOver,
            ),
          ),
          // You (bottom center)
          Positioned(
            top: center.dy + radius - 10,
            left: 10,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Text(
                            game.players[0].name,
                            style: TextStyle(
                              color: game.currentPlayer == 0 && !game.roundOver
                                  ? Colors.green
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '(${game.players[0].rouletteChambers}/6)',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    PlayerProfileSimple(
                      roleNumber: game.players[0].roleNumber,
                      isCurrentTurn: game.currentPlayer == 0 && !game.roundOver,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (game.players[0].eliminated)
                  SvgPicture.asset(
                    'assets/splat3.svg',
                    width: 90,
                    height: 90,
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: game.players[0].hand
                          .map((c) => _card(c, selectable: game.isHumanTurn()))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
          // Console
          Positioned(
            top: padTop + 40,
            right: 8,
            bottom: 100,
            width: consoleW,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.black38,
                  border: Border.all(color: Colors.white54)),
              padding: const EdgeInsets.all(6),
              child: Scrollbar(
                controller: _scroll,
                child: ListView.builder(
                  controller: _scroll,
                  itemCount: history.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(history[i],
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ),
            ),
          ),
          // Turn label
          Positioned(
            right: 8,
            bottom: 60,
            child: Text('Turn: ${game.players[game.currentPlayer].name}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          // Action buttons
          Positioned(
            left: 8,
            bottom: 8,
            child: gameOver
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await _player.play(AssetSource('sound/click-4.mp3'));
                          Navigator.pushNamed(context, '/home');
                        },
                        child: const Text('Go Home'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _player.play(AssetSource('sound/click-4.mp3'));
                          _restartGame();
                        },
                        child: const Text('Play Again'),
                      ),
                    ],
                  )
                : game.roundOver
                    ? ElevatedButton(
                        onPressed: () async {
                          await _player.play(AssetSource('sound/click-4.mp3'));
                          _nextRound();
                        },
                        child: const Text('Next Round'),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: game.isHumanTurn() && selected.isNotEmpty
                                ? () {
                                    // 1) run game logic + UI
                                    _playSelected();
                                    // 2) play click sound without blocking
                                    _player
                                        .play(AssetSource('sound/click-4.mp3'));
                                  }
                                : null,
                            child: const Text('Play Cards'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: game.isHumanTurn() &&
                                    game.tableCards.isNotEmpty
                                ? () {
                                    _callBluff();
                                    _player
                                        .play(AssetSource('sound/click-4.mp3'));
                                  }
                                : null,
                            child: const Text('Call Bluff'),
                          ),
                        ],
                      ),
          ),
          // Overlay for WIN or BLUFF
          if (overlayMsg != null)
            AnimatedOpacity(
              opacity: overlayOpacity,
              duration: const Duration(milliseconds: 500),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    overlayMsg!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
            ),

          // Start Button overlay
          if (!started)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                    onPressed: () async {
                      await _player.play(AssetSource('sound/click-4.mp3'));
                      _startGame();
                    },
                    child: const Text(
                      "Start Liar's Deck",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
