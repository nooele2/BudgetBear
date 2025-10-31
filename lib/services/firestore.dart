import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Note {
  String title;
  String description;
  DateTime timestamp;
  bool isFavourtie;
  bool isLocked;

  Note({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isFavourtie,
    required this.isLocked
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'isFavourite': isFavourtie,
      'isLocked': isLocked,
    };
  }
}

class Memo{

  String title;
  String description;
  DateTime timestamp;
  int mood;

  Memo({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.mood
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'mood': mood,
    };
  }

    factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      mood: json['mood'] ?? 0,
    );
  }
}

class FirestoreService {
  final user = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //get collection of notes
        CollectionReference userNotesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('notes');
        
        CollectionReference userMemoCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('memos');


  //create
Future<void> addNote(String userId, Note note) async {
    try {
      // Reference to the notes subcollection under the user's document

      // Add the note document to the user's notes subcollection
      userNotesCollection.add(note.toMap());

      print('Note added successfully!');
    } catch (e) {
      print('Error adding note: $e');
    }
  }

Future<Map<String, dynamic>> getOrCreateMemoForToday() async {
  try {
    DateTime today = DateTime.now();
    DateTime startOfDay = DateTime(today.year, today.month, today.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await userMemoCollection
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
            .get() as QuerySnapshot<Map<String, dynamic>>;

    if (querySnapshot.docs.isNotEmpty) {
      // Memo already exists for today, return the first one found with its ID
      final id = querySnapshot.docs.first.id;
      final memoData = querySnapshot.docs.first.data();
      return {'id': id, 'memo': Memo.fromJson(memoData)};
    } else {
      // No memo exists for today, create a new one and return its ID
      Memo newMemo = Memo(title: "Daily Memo", description: "Write your memo here!", timestamp: startOfDay, mood: 0);
      DocumentReference docRef = await userMemoCollection.add(newMemo.toMap());
      return {'id': docRef.id, 'memo': newMemo};
    }
  } catch (e) {
    print("Error getting or creating memo for today: $e");
    throw e; // Rethrow the error to handle it outside
  }
}

  // Function to edit the memo
  Future<void> editMemo(String memoId, String newTitle, String newDescription) async {
    try {
      await userMemoCollection.doc(memoId).update({
        'title': newTitle,
        'description': newDescription,
      });
      print('edit success');
    } catch (e) {
      print("Error editing memo: $e");
    }
  }

Future<Memo?> getMemoForDate(DateTime date) async {
  try {
    DateTime _selectedDate= date;
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));
    
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await userMemoCollection
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
      .get() as QuerySnapshot<Map<String, dynamic>>;
    
    if(querySnapshot.docs.isNotEmpty){
      Map<String,dynamic> memoData = querySnapshot.docs.first.data();
      return Memo.fromJson(memoData);
    } else {
      return null;
    }
  } catch (e) {
    print('Error fetching memo for date: $e');
    return null;
  }      
}


  Future<List<Note>> getNotes(String userId) async {
  List<Note> notes = [];
  try {
    QuerySnapshot querySnapshot = await userNotesCollection.orderBy('timestamp',descending: true).get();

    querySnapshot.docs.forEach((doc) {
      Note note = Note(
        title: doc['title'],
        description: doc['description'],
        timestamp: doc['timestamp'].toDate(),
        isFavourtie: doc['isFavourite'],
        isLocked: doc['isLocked']
      );
      notes.add(note);
    });
  } catch (e) {
    print('Error getting notes: $e');
  }
  return notes;
  }

  Future<void> updateNote(String docID, Note note) async {
    try{
      userNotesCollection.doc(docID).update(note.toMap());
      print('Note updated successfully');
    } catch (e){
      print('Error updating note $e');
    }
  }

  Stream<QuerySnapshot> getNotesStream(){
    final notesStream = 
      userNotesCollection.orderBy('timestamp',descending: true).snapshots();
    return notesStream;
  }

  Future<void> deleteNote(String docID){
    return userNotesCollection.doc(docID).delete();
  }

  Future<void> toggleFavourite(String docID) async{
    try{
      DocumentReference noteRef = userNotesCollection.doc(docID);
      DocumentSnapshot snapshot = await noteRef.get();
      bool currentFavourite = snapshot.get('isFavourite');
      await noteRef.update({'isFavourite': !currentFavourite});
      print('Favourite status toggled successfully');
    }catch(e){
      print('Error toggling favourite status: $e');
    }
  }

  Future<void> toggleLocked(String docID) async{
    try{
      DocumentReference noteRef = userNotesCollection.doc(docID);
      DocumentSnapshot snapshot = await noteRef.get();
      bool currentLocked = snapshot.get('isLocked');
      await noteRef.update({'isLocked': !currentLocked});
      print('Locked status toggled successfully');
    }catch(e){
      print('Error toggling Locked status: $e');
    }
  }
}