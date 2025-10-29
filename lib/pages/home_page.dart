// ignore_for_file: unused_import, unused_local_variable, non_constant_identifier_names, collection_methods_unrelated_type, prefer_const_constructors, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:budget_bear/services/firestore.dart';
import 'package:google_fonts/google_fonts.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final user = FirebaseAuth.instance.currentUser!;
  FirestoreService firestoreservice = FirestoreService();
  late Future<List<Note>> userNotes;
  late Memo memo;
  late String memoId;
  List<String> trashCan=[];
  exitsInTrashCan(Note note) => trashCan.contains(note);
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 40, fontWeight: FontWeight.w500);
  static const List<Widget> _widgetOptions = <Widget>[
  Padding(
    padding: const EdgeInsets.only(left: 20.0, top: 15.0, bottom: 5.0), // Adjust padding as needed
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'All Notes',
        style: TextStyle(
        color: Color.fromARGB(255, 31, 46, 0),
        fontSize: 40,
        fontWeight: FontWeight.bold// Setting underline color
      ),
      ),
    ),
  ),
  Padding(
    padding: const EdgeInsets.only(left: 20.0, top: 15.0, bottom: 5.0), // Adjust padding as needed
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Favorites',
        style: TextStyle( 
        color: Color.fromARGB(255, 31, 46, 0),
        fontSize: 40,
        fontWeight: FontWeight.bold// Setting underline color
      ),
      ),
    ),
  ),
];


      void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

    void toggleTrashCan(String docID) {
    setState(() {
      if (trashCan.contains(docID)) {
        trashCan.remove(docID);
      } else {
        trashCan.add(docID);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    userNotes = fetchNotes();
    memo = Memo(title: '', description: '', timestamp: DateTime.now(), mood: 0); // Initialize memo with default values
    firestoreservice.getOrCreateMemoForToday().then((data) {
      final memoData = data['memo'] as Memo;
      final id = data['id'] as String;
      setState(() {
        memo = memoData;
        memoId = id;
      });
    }).catchError((error) {
      // Handle error if getOrCreateMemoForToday() fails
      print("Error getting or creating memo for today: $error");
    });
  }

  Future<List<Note>> fetchNotes() async {
    return firestoreservice.getNotes(user.uid);
  }

Future<List<dynamic>> fetchMemo() async {
  final data = await firestoreservice.getOrCreateMemoForToday();
  memo = data['memo'] as Memo;
  final docID = data['id'] as String;
  return [memo,docID];
}

  void SignUserOut() {
    try {
    FirebaseAuth.instance.signOut();
    // Navigate to the login screen
    Navigator.pop(context); 
  } catch (e) {
    print("Error signing out: $e");
    // Handle error, show a snackbar, etc.
  }
  }

  /*void createNote() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => CreateNote(onNewNoteCreated: onNewNoteCreated,),
    ));
  }

  void editNote( String docID, Note note){
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => EditNote(
        note: note,
        id: docID,
        onNoteEdited: onNoteEdited,
        )
      )
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: CupertinoColors.systemGroupedBackground,
      appBar: trashCan.isEmpty ? AppBar(
        backgroundColor: Color.fromRGBO(120, 144, 72, 1),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
                  icon: Icon(
                    Icons.menu,
                    size: 35,
                    color: Colors.white, // Adjust the size as needed
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState!.openDrawer();
                  },
                ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: PopupMenuButton(
              offset: const Offset(0, 45), // Adjust the values as needed
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.account_circle, size: 40, color: Color.fromRGBO(120, 144, 72, 1)),
                        SizedBox(width: 8),
                        Text(
                          FirebaseAuth.instance.currentUser!.email!,
                          style: TextStyle(fontSize: 15),
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                ];
              },
              icon: const Icon(Icons.account_circle, size: 40, color: Colors.white),
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ):AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromRGBO(184, 202, 148, 1),
                actions: [Padding(
          padding: const EdgeInsets.only(right: 1.0),
          child: IconButton(
            onPressed: (){
              setState(() {
                for(String docID in trashCan){
                  firestoreservice.toggleLocked(docID);
                }
                trashCan.clear();
              });
            }, 
            icon: Icon(Icons.lock_open, size: 27, color: const Color.fromARGB(255, 69, 69, 69),)),
        ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(Icons.delete, size: 30, color: const Color.fromARGB(255, 69, 69, 69),),
              onPressed:(){
              
              setState((){
                for(String docID in trashCan){
                  firestoreservice.deleteNote(docID);
                }
                trashCan.clear();
              });
            }),
          )],      
      ),
      body: Column(
        children:[
          Padding(
  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
  child: SizedBox(
    width: double.infinity,
        height: 180,
    child: GestureDetector(
     /* onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => MemoPage(
        memo: memo,
        id: memoId,
        onMemoEdited: onMemoEdited,
        )
      )
    );
                 
      },*/
      child: Card(
        color: const Color.fromARGB(255, 120, 144, 72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 8, 18, 8),
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8, top: 7),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          memo.title,
                          style: GoogleFonts.patrickHand(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ),SizedBox(height: 15,),
                    Container(
                      padding: EdgeInsets.all( 7),
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGroupedBackground,
                        borderRadius: BorderRadius.circular(5)
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                           memo.description,
                          style: GoogleFonts.patrickHand(
                            fontSize: 20,
                            color:  Colors.black,
                            fontWeight: FontWeight.w200
                          ),
                          
                        ),
                      ),
                    ),
                  ],
                )
            
          ),
        ),
      ),
    ),
  ),

         /* _widgetOptions[_selectedIndex],
          NotesList(
            user: user,
            firestoreservice: firestoreservice,
            onNoteSelected: editNote,
            trashCan: trashCan,
            toggleTrashCan: toggleTrashCan,
            listType: _selectedIndex,
          ),*/
        ],
      ),
      drawer: trashCan.isEmpty ? Drawer(
      backgroundColor: const Color.fromARGB(255, 120, 144, 72),
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(         
        // Important: Remove any padding from the ListView.
        children: [
          SizedBox(height: 30,),
          SizedBox(
            height: 90,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white, // Set the background color to white
                border: Border(
                  bottom: Divider.createBorderSide(
                    context,
                    color: Colors.white,
                    width: 2.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/matcha.png',
                    height: 40,
                    width: 40,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  //Row(
                    //children: [
                      Text(
                        'MATCHA-NOTE',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 120, 144, 72),
                        ),
                      ),
                      /*Text(
                        '-',
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),
                      ),*/
                    //],
                  //),
                ],
              ),
            ),
          ),           
          ListTile(
            leading: const Icon(
              Icons.home,
              color: Colors.white,
              ),
            title: Text(
                'All Notes',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            selected: _selectedIndex == 0,
            onTap: () {
              // Update the state of the app
              _onItemTapped(0);
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
          const Divider(
            color: Colors.white,
            ),
          ListTile(
            leading: const Icon(
              Icons.star,
              color: Colors.white,
              ),
            title: Text(
                'Favorites',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            selected: _selectedIndex == 1,
            onTap: () {
              // Update the state of the app
              _onItemTapped(1);
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
          const Divider(
            color: Colors.white,
            ),
          ListTile(
            leading: const Icon(
              Icons.lock,
              color: Colors.white,
              ),
            title: const Text('Locked Notes',
            style: TextStyle(fontSize: 20, color: Colors.white)),
            onTap: () {
              showReauthenticationDialog(context);              
            },
          ),
          const Divider(
            color: Colors.white,
            ),
          const SizedBox(
            height: 470,
          ),
          const Divider(
            color: Colors.white,
            ),
          ListTile(
              leading: const Icon(
                Icons.logout,
                size: 25,
                color: Colors.white,
                ),
              title: const Text('Log Out',
              style: TextStyle(fontSize: 20, color: Colors.white)),
              onTap: () {
                // Update the state of the app
                SignUserOut();
                
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
        ],
      ),
    ):null,
      /*floatingActionButton: _selectedIndex == 1 // Check if it's the favorites screen
        ? null // If it's the favorites screen, set FloatingActionButton to null
        : trashCan.isEmpty ? FloatingActionButton(
            backgroundColor: Color.fromRGBO(120, 144, 72, 1),
            onPressed: createNote,
            child: const Icon(Icons.add, color: Colors.white,),
          ):null,*/
    );
  }

  Future<void> onNewNoteCreated() async {
    userNotes = fetchNotes(); 
    setState(() {  
       
      },
    );
  }

  Future<void> onNoteEdited() async {
    userNotes = fetchNotes();
    setState(() {
      
    });
  }

  Future<void> onMemoEdited() async {
    var data = await fetchMemo();

    setState((){    memo = data[0];
    memoId = data[1];});
  }

  void showReauthenticationDialog(BuildContext context) async {
  String? password;
  String? errorMessage;

  await showDialog(
  context: context,
  builder: (BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('Enter Your Account Password!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorMessage != null) // Display error message if not null
                Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icon(Icons.lock),
                ),
                onChanged: (value) => password = value,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            /*ElevatedButton(
              onPressed: () async {
                try {
                  // Sign in the user with the provided password
                  final UserCredential userCredential =
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: FirebaseAuth.instance.currentUser!.email!,
                    password: password!,
                  );

                  // If reauthentication is successful, close the dialog
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => LockPage(),
                  ));
                } catch (e) {
                  // Display an error message if reauthentication fails
                  setState(() {
                    errorMessage = 'Reauthentication failed: $e';
                  });
                }
              },
              child: Text('Submit'),
            ),*/
          ],
        );
      },
    );
  },
);
}
}
