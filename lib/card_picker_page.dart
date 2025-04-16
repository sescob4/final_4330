import 'dart:math';
import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';

class CardPickerPage extends StatefulWidget {
  const CardPickerPage({super.key});

  @override
  State<CardPickerPage> createState() => _CardPickerPageState();
}

class _CardPickerPageState extends State<CardPickerPage> {
  final List<PlayingCard> _customDeck = [
    ...List.filled(6, PlayingCard(Suit.spades, CardValue.ace)),
    ...List.filled(6, PlayingCard(Suit.hearts, CardValue.jack)),
    ...List.filled(6, PlayingCard(Suit.clubs, CardValue.queen)),
    ...List.filled(6, PlayingCard(Suit.diamonds, CardValue.king)),
  ];

  PlayingCard? _selectedCard;

  void _drawCard() {
    final random = Random();
    final card = _customDeck[random.nextInt(_customDeck.length)];
    setState(() {
      _selectedCard = card;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Card Picker"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedCard != null)
              SizedBox(
                height: 200,
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: PlayingCardView(
                    card: _selectedCard!,
                    showBack: false,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              const Text('Press the button to draw a card'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _drawCard,
              child: const Text("Draw Card"),
            ),
          ],
        ),
      ),
    );
  }
}
