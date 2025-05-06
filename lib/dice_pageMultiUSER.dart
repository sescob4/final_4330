import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:final_4330/Databaseservice.dart';
class dice_pageMultiUSER extends StatefulWidget{
  final userName;
  final userID;
  final gameID;
  const dice_pageMultiUSER({super.key, required this.userName, required this.userID, required this.gameID})
  @override
  State<dice_pageMultiUSER> createState() => _diceMultiPlayer();
}

class _diceMultiPlayer extends State<dice_pageMultiUSER> with SingleTickerProviderStateMixin{
  final int lives = 2;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState(){
    super.initState();
    
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }
  Future<void> _playGame() async {
    print("startListenting **");
    StreamSubscription<DatabaseEvent>? _currentPlayerListener;

    _currentPlayerListener = FirebaseDatabase.instance.ref("dice/gameSessions/$widget.gameID/currentPlayer").onChildChanged.listen((event){

      final data = event.snapshot.value;
      if(data is String && data == widget.userID){


      }


    });
  }
}