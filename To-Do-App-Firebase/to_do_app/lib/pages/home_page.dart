import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:to_do_app/util/dialog_box.dart';
import 'package:to_do_app/util/todo_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  late List<DocumentSnapshot> users = []; // Variable to hold user data

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  final _controller = TextEditingController();

  Future<void> addUser(String name, String task, bool marked) {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    return users
        .add({
          'name': name,
          'task': task,
          'marked': marked,
        })
        .then((value) => fetchUsers())
        .catchError((error) => print("Failed to add user: $error"));
  }

  Future<void> fetchUsers() async {
    try {
      CollectionReference usersRef =
          FirebaseFirestore.instance.collection('users');
      QuerySnapshot snapshot = await usersRef.get();
      setState(() {
        users = snapshot.docs; // Update the users variable with fetched data
      });
    } catch (error) {
      print("Failed to fetch users: $error");
    }
  }

  void saveNewTask() {
    setState(() {
      addUser(_controller.text, _controller.text, false);
      _controller.clear();
    });
    Navigator.of(context).pop();
    //db.updateData();
  }

  Future<void> deleteTaskByName(String taskName) async {}

  void createNewTask() {
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          controller: _controller,
          onSave: saveNewTask,
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[200],
      appBar: AppBar(
        title: Text("TO DO"),
        centerTitle: true,
        backgroundColor: Colors.yellow,
        elevation: 0, // Remove shadow from top bar
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Icon(Icons.add),
        backgroundColor: Colors.yellow,
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          var userData = users[index].data() as Map<String, dynamic>;
          return ToDoTile(
            taskName: userData['task'] ?? '',
            taskCompleted: userData['marked'] ?? false,
            onChanged: (value) =>
                updateMarkedValue(userData['task'] ?? '', !userData['marked']),
            deleteFunction: (context) =>
                deleteUserByTask(userData['task'] ?? ''),
          );
        },
      ),
    );
  }

  Future<void> updateMarkedValue(String task, bool newValue) async {
    CollectionReference usersRef =
        FirebaseFirestore.instance.collection('users');

    try {
      // Query Firestore to find the documents where the "task" field is equal to the specified task
      QuerySnapshot querySnapshot =
          await usersRef.where('task', isEqualTo: task).get();

      // Loop through the documents that match the query and update the "marked" value for each one
      for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
        // Get a reference to the Firestore document
        DocumentReference docRef = usersRef.doc(docSnapshot.id);

        // Update the "marked" field with the new value
        await docRef.update({'marked': newValue});
        setState(() {
          fetchUsers();
        });
      }

      print('Marked value updated successfully for documents with task $task!');
    } catch (error) {
      print('Failed to update marked value: $error');
    }
  }

  Future<void> deleteUserByTask(String taskName) async {
    CollectionReference usersRef =
        FirebaseFirestore.instance.collection('users');

    try {
      // Query Firestore to find the documents where the "task" field is equal to userId
      QuerySnapshot querySnapshot =
          await usersRef.where('task', isEqualTo: taskName).get();

      // Create a list of Futures representing the deletion of each document
      List<Future<void>> deletionFutures = [];

      // Loop through the documents that match the query and add a deletion Future for each one
      for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
        deletionFutures.add(documentSnapshot.reference.delete());
      }

      // Wait for all deletion Futures to complete
      await Future.wait(deletionFutures);

      // Update the widget state after all documents are deleted
      setState(() {
        fetchUsers();
      });

      print('Users with task $taskName deleted successfully!');
    } catch (error) {
      print('Failed to delete users: $error');
    }
  }
}
