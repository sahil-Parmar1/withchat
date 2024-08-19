

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:withchat/personchat.dart';
import 'chatscreen.dart';
import 'callsscreen.dart';
import 'videocallsscreen.dart';
import 'package:flutter/services.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    ChatsScreen(),
    CallScreen(),
    VideoCallScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ChatApp'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              title: Text("Hello"),
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call),
            label: 'VoiceCalls',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_call),
            label: 'VideoCalls',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.chat),
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MyContact()),
          );
        },
      ),
    );
  }
}


//more chat screen
class MyContact extends StatefulWidget {
  @override
  _MyContactState createState() => _MyContactState();
}

class _MyContactState extends State<MyContact> {
  TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<contactClass> commonContacts = [];
  List<contactClass> deviceContacts = [];
  List<contactClass> allContactList = [];
  List<contactClass> searchContact = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    var status = await Permission.contacts.status;
    print("In fetchContacts");

    if (!status.isGranted) {
      await Permission.contacts.request();
    }

    if (await Permission.contacts.isGranted) {
      Iterable<Contact> contacts = await ContactsService.getContacts();
      _contacts = contacts.toList();

      for (int i = 0; i < _contacts.length; i++) {
        contactClass temp = _convertDeviceContact(_contacts[i]);
        temp.phoneNumber = normalizePhoneNumber(temp.phoneNumber);
        print("==>>Phone numbers: ${temp.phoneNumber}");
        deviceContacts.add(temp);

        try {
          DocumentSnapshot dataFetch = await FirebaseFirestore.instance
              .collection('users')
              .doc(temp.phoneNumber)
              .get();

          if (dataFetch.exists) {
            Map<String, dynamic> data1 =
            dataFetch.data() as Map<String, dynamic>;
            print("==>>>Contact exists");

            String tempName = '';
            String tempPhoneNumber = '';

            data1.forEach((key, value) {
              if (key == "Name") tempName = value!;
              if (key == "phoneNumber") tempPhoneNumber = value!;
            });

            contactClass temp2 =
            contactClass(name: tempName, phoneNumber: tempPhoneNumber);
            commonContacts.add(temp2);
          }
        } catch (e) {
          print("Error fetching data: $e");
        }
      }

      allContactList = _mergeContacts(deviceContacts, commonContacts);
      setState(() {});
    } else {
      Fluttertoast.showToast(
        msg: "Contact Permission is denied",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 4,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MyContact"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Icon(Icons.search),
              SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(hintText: "Search..."),
                  onChanged: (value) {
                    setState(() {
                      searchContact = [];
                      for (int i = 0; i < allContactList.length; i++) {
                        if (allContactList[i].name.startsWith(value)) {
                          searchContact.add(allContactList[i]);
                        }
                      }
                      if (value.isNotEmpty) {
                        _isSearching = true;
                      }
                    });
                  },
                ),
              ),
              _isSearching
                  ? IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });
                  },
                  icon: Icon(Icons.cancel))
                  : SizedBox.shrink(),
            ],
          ),
          SizedBox(height: 20),
          allContactList.isEmpty
              ? Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Fetching Contacts"),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          )
              : Expanded(
            child: _isSearching
                ? (searchContact.isEmpty
                ? Center(child: Text("No Search Found"))
                : ListView.builder(
                itemCount: searchContact.length,
                itemBuilder: (context, index) {
                  contactClass contact = searchContact[index];
                  return ListTile(
                    onTap: () {
                      if (contact.isExit == true)
                        print(
                            "Can message them: ${contact.phoneNumber}");
                      else
                        print(
                            "Invite to link: ${contact.phoneNumber}");
                    },
                    title: Text(contact.name),
                    subtitle: Text(contact.phoneNumber),
                    leading: generateLogo(contact.name),
                    trailing: contact.isExit == true
                        ? SizedBox.shrink()
                        : Icon(Icons.share),
                  );
                }))
                : ListView.builder(
                itemCount: allContactList.length,
                itemBuilder: (context, index) {
                  contactClass contact = allContactList[index];
                  return ListTile(
                    onTap: () {
                      if (contact.isExit == true)
                        {
                          print("Can message them: ${contact.phoneNumber}");
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context)=>PersonChatScreen(name: contact.name, phoneNumber: contact.phoneNumber)));
                        }

                      else
                        {
                          print("Invite to link: ${contact.phoneNumber}");
                          sendSMS(contact.phoneNumber);
                        }

                    },
                    title: Text(contact.name),
                    subtitle: Text(contact.phoneNumber),
                    leading: generateLogo(contact.name),
                    trailing: contact.isExit == true
                        ? SizedBox.shrink()
                        : Icon(Icons.share),
                  );
                }),
          ),
        ],
      ),
    );
  }

  contactClass _convertDeviceContact(Contact contact) {
    String name = contact.displayName ?? "No Name";
    String phoneNumber = contact.phones!.first.value ?? "No Phone Number";
    return contactClass(name: name, phoneNumber: phoneNumber);
  }

  List<contactClass> _mergeContacts(
      List<contactClass> device, List<contactClass> firebase) {
    List<contactClass> temp = [];

    for (int i = 0; i < firebase.length; i++) {
      contactClass temp2 = firebase[i];
      temp2.isExit = true;
      temp.add(temp2);
    }

    for (int i = 0; i < device.length; i++) {
      contactClass temp2 = device[i];
      bool isInFirebase = firebase.any((firebaseContact) =>
      firebaseContact.phoneNumber == temp2.phoneNumber);

      if (!isInFirebase) {
        temp2.isExit = false;
        temp.add(temp2);
      }
    }

    return temp;
  }



}

//normalize phone number '+91' and '+'
String normalizePhoneNumber(String phone) {
  // Ensure the phone number starts with +91
  if ((!phone.startsWith('+91'))&&phone.length==10) {
    phone = '+91' + phone.replaceAll(RegExp(r'^\+91'), '');
  }
  if(phone.length>10 && (phone.startsWith('91')))
  {
    phone='+' + phone.replaceAll(RegExp(r'^\+'),'');
  }
  return phone;
}
//for comman contact
class contactClass
{
  String name;
  String phoneNumber;
  bool isExit=false;
  contactClass({required this.name,required this.phoneNumber,this.isExit=false});
}

//to generate logos
Widget generateLogo(String name)
{
  Color getRamdonColor()
  {
    Random random = Random();
    return Color.fromARGB(
        255,
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256));
  }
  String F=name[0].toUpperCase();
  Color backgroundColor=getRamdonColor();
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: backgroundColor,
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(F,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

    ),
  );
}

void sendSMS(String phoneNumber) async {
  final Uri smsUri = Uri(
    scheme: 'sms',
    path: phoneNumber,
    queryParameters: <String, String>{
      'body': "message to $phoneNumber",
    },
  );

  if (await canLaunchUrl(smsUri)) {
    await launchUrl(smsUri);
  } else {
    throw 'Could not launch $smsUri';
  }
}
