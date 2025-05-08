import 'dart:async';
import 'package:final_4330/Databaseservice.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class dice_pageMultiUSER extends StatefulWidget {
  final String userName;
  final String userID;
  final String gameID;

  const dice_pageMultiUSER({
    super.key,
    required this.userName,
    required this.userID,
    required this.gameID,
  });

  @override
  State<dice_pageMultiUSER> createState() => _dicePlayer();
}
class _dicePlayer extends State<dice_pageMultiUSER> with SingleTickerProviderStateMixin{
  final int lives = 0;
  late List<int> dice;

  late AnimationController _controller;
  late Animation<double> _animation;
  StreamSubscription<DatabaseEvent>? _currentPlayerListener;
  StreamSubscription<DatabaseEvent>? _gameEndListener;

  @override
  void initState(){
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _animation = Tween<double>(begin: 0.0,end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _animation.addListener((){
      setState(() {});
    });

  }

  void _runPlayerGame(String decision){

  }
  void rollDice() async{
    DatabaseService x = DatabaseService();
    dice = await x.writeDiceForAll(widget.userID, widget.gameID);
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text("dice multi")),
      body: Center(
        child:Column(
          children: [
            ElevatedButton(onPressed: onPressed, child: child),
            
          ],
        ),
      ),
    );
  }


}
