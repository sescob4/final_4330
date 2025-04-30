import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

// MODEL
enum CardType { ace, jack, queen, king, joker }

class DeckCard {
  final CardType type;
  DeckCard(this.type);
  String get assetPath => switch (type) {
        CardType.ace => 'assets/ace.svg',
        CardType.jack => 'assets/jack.svg',
        CardType.queen => 'assets/queen.svg',
        CardType.king => 'assets/king.svg',
        CardType.joker => 'assets/joker.svg',
      };
}

class Player {
  final String name;
  final bool isAI;
  List<DeckCard> hand = [];
  int rouletteChambers = 1;
  bool eliminated = false;
  Player(this.name, {this.isAI = false});
  bool spin(Random rng) {
    final shot = rng.nextInt(6) < rouletteChambers;
    rouletteChambers = min(6, rouletteChambers + 1);
    eliminated |= shot;
    return shot;
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
    players = [
      Player('You'),
      Player('AI1', isAI: true),
      Player('AI2', isAI: true),
      Player('AI3', isAI: true),
    ];
  }

  void startRound() {
    _ensurePlayers();
    final deck = <DeckCard>[
      ...List.generate(6, (_) => DeckCard(CardType.king)),
      ...List.generate(6, (_) => DeckCard(CardType.queen)),
      ...List.generate(6, (_) => DeckCard(CardType.jack)),
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

    const tables = [CardType.ace, CardType.jack, CardType.queen, CardType.king];
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
    _advanceTurn();
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

  void _advanceTurn() =>
      currentPlayer = _nextAlive((currentPlayer + 1) % players.length);
}

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

  bool started = false, aiBusy = false;
  static const aiDelay = Duration(seconds: 3);

  String? overlayMsg;
  double overlayOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    game = LiarsDeckGameState();
  }

  void _addLog(String s) {
    history.add(s);
    SchedulerBinding.instance.addPostFrameCallback(
        (_) => _scroll.jumpTo(_scroll.position.maxScrollExtent));
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
    if (alive.length == 1) {
      _showOverlay('${alive.first.name} WINS!');
      game.roundOver = true;
      aiBusy = false;
    }
  }

  void _startGame() {
    setState(() => started = true);
    _nextRound();
  }

  void _nextRound() {
    setState(() {
      game.startRound();
      selected.clear();
      _addLog('New round: ${game.tableType.name.toUpperCase()}s');
    });
    _maybeScheduleAI();
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

    final prevIdx =
        (game.currentPlayer - 1 + game.players.length) % game.players.length;
    final prevPlayer = game.players[prevIdx];
    final prevDumped = !prevPlayer.eliminated &&
        prevPlayer.hand.isEmpty &&
        game.tableCards.isNotEmpty;

    final ai = game.players[game.currentPlayer];
    final bluff =
        prevDumped || (game.tableCards.isNotEmpty && game.rng.nextBool());

    final msg = bluff
        ? game.callBluff(ai)
        : game.playCards(
            ai,
            ai.hand
                .take(min(
                    ai.hand.length,
                    game.rng.nextInt(ai.hand
                                .where((c) => c.type != CardType.joker)
                                .isEmpty
                            ? 1
                            : 4) +
                        1))
                .toList());

    _showOverlay(bluff ? '${ai.name} CALLED BLUFF!' : '${ai.name} PLAYED');
    setState(() => _addLog(msg));
    _checkWinner();
    aiBusy = false;
    _maybeScheduleAI();
  }

  void _tapCard(DeckCard c) {
    if (!game.isHumanTurn()) return;
    setState(() => selected.contains(c) ? selected.remove(c) : selected.add(c));
  }

  void _playSelected() {
    if (selected.isEmpty) return;
    final msg = game.playCards(game.players[0], selected.toList());
    setState(() {
      _addLog(msg);
      selected.clear();
    });
    _maybeScheduleAI();
  }

  void _callBluff() {
    _showOverlay('You CALLED BLUFF!');
    final msg = game.callBluff(game.players[0]);
    setState(() => _addLog(msg));
    _checkWinner();
  }

  Widget _card(DeckCard c, {bool selectable = false}) => GestureDetector(
        onTap: selectable ? () => _tapCard(c) : null,
        child: Container(
          width: 36,
          height: 54,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(
                color: selectable && selected.contains(c)
                    ? Colors.blueAccent
                    : Colors.transparent,
                width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SvgPicture.asset(c.assetPath, fit: BoxFit.cover),
        ),
      );

  Widget _hand(Player p,
      {required bool horizontal,
      required bool selectable,
      required bool highlight}) {
    final label = p.eliminated
        ? '${p.name}  ⚠ ELIMINATED ⚠'
        : '${p.name} (${p.rouletteChambers}/6)';
    final lblCol = p.eliminated
        ? Colors.orangeAccent
        : highlight
            ? Colors.green
            : Colors.white;
    final cards = p.hand.map((c) => _card(c, selectable: selectable)).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                color: lblCol, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        if (!p.eliminated)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.black45,
              border: Border.all(color: highlight ? Colors.green : Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: horizontal
                ? Row(mainAxisSize: MainAxisSize.min, children: cards)
                : Column(mainAxisSize: MainAxisSize.min, children: cards),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF3E2723),
        body: started ? _buildTable(context) : _buildIntro(),
      );

  Widget _buildIntro() => Center(
        child: ElevatedButton(
            onPressed: _startGame, child: const Text("Start Liar's Deck")),
      );

  Widget _buildTable(BuildContext ctx) {
    final padTop = MediaQuery.of(ctx).padding.top;
    const consoleW = 150.0;
    return LayoutBuilder(builder: (context, constraints) {
      final radius = constraints.maxWidth * 0.10;
      final center =
          Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

      const cardH = 54.0, cardW = 36.0, gap = 4.0, pad = 4.0;
      double vTop(Player p) =>
          center.dy - ((p.hand.length * (cardH + gap)) / 2) - pad;
      double hLeft(Player p) =>
          center.dx - ((p.hand.length * (cardW + gap)) / 2) - pad;

      return Stack(
        children: [
          // Header
          Positioned(
            top: padTop,
            left: 8,
            child: Text('TABLE: ${game.tableType.name.toUpperCase()}S',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          // Table center circle
          Positioned(
            left: center.dx - radius,
            top: center.dy - radius,
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: const BoxDecoration(
                  color: Color(0xFFBCAAA4), shape: BoxShape.circle),
            ),
          ),
          // Played cards at center
          Positioned(
            left: center.dx - (game.tableCards.length * cardW) / 2,
            top: center.dy - cardH / 2,
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: game.tableCards.map(_card).toList()),
          ),
          // AI1 (left)
          Positioned(
            left: center.dx - radius - 140,
            top: vTop(game.players[1]),
            child: _hand(game.players[1],
                horizontal: false,
                selectable: false,
                highlight: game.currentPlayer == 1 && !game.roundOver),
          ),
          // AI2 (top)
          Positioned(
            left: hLeft(game.players[2]),
            top: center.dy - radius - cardH - 25,
            child: _hand(game.players[2],
                horizontal: true,
                selectable: false,
                highlight: game.currentPlayer == 2 && !game.roundOver),
          ),
          // AI3 (right)
          Positioned(
            left: center.dx + radius + 20,
            top: vTop(game.players[3]),
            child: _hand(game.players[3],
                horizontal: false,
                selectable: false,
                highlight: game.currentPlayer == 3 && !game.roundOver),
          ),
          // You (bottom)
          Positioned(
            left: hLeft(game.players[0]),
            top: center.dy + radius + 25,
            child: _hand(game.players[0],
                horizontal: true,
                selectable: game.isHumanTurn(),
                highlight: game.currentPlayer == 0 && !game.roundOver),
          ),
          // Console (right side)
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
          // Bottom controls
          Positioned(
            left: 8,
            bottom: 8,
            child: game.roundOver
                ? ElevatedButton(
                    onPressed: _nextRound, child: const Text('Next Round'))
                : Row(children: [
                    ElevatedButton(
                        onPressed: game.isHumanTurn() && selected.isNotEmpty
                            ? _playSelected
                            : null,
                        child: const Text('Play')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                        onPressed:
                            game.isHumanTurn() && game.tableCards.isNotEmpty
                                ? _callBluff
                                : null,
                        child: const Text('Call Bluff')),
                  ]),
          ),
          // Overlay for "WIN" or "BLUFF"
          if (overlayMsg != null) ...[
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
          ],
        ],
      );
    });
  }
}
