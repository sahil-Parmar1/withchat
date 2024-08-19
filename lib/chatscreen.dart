import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:withchat/homescreen.dart';
import 'package:withchat/personchat.dart';

class contact_list
{
  String name;
  String number;
  int? read=0;
  contact_list({required this.name,required this.number,this.read});
}
class ChatsScreen extends StatefulWidget {
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>  {
  String myPhone = "";
  List<contact_list> phones = [];

  @override
  void initState() {
    super.initState();
    print("initState is called");
    getPhone();
  }

  Future<void> getPhone() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    myPhone = pref.getString('phoneNumber') ?? "92";
    print("getphone is called");
    await refreshPhones();
  }

  Future<void> refreshPhones() async {
    phones = [];
    contact_list ai=new contact_list(name: 'WithChat AI', number: '128');
    phones.add(ai);
    QuerySnapshot myPhoneSnapshot = await FirebaseFirestore.instance.collection('$myPhone').get();
     print("${myPhone}");
      print("${myPhoneSnapshot.docs}");
    for (DocumentSnapshot phone in myPhoneSnapshot.docs) {
      print("${phone.id}");
      int read=0;
      read=await getunread(phone.id.toString(), myPhone);
      contact_list temp=new contact_list(name: phone['Name'], number: phone.id,read: read);
      phones.add(temp);

    }
    for(int i=0;i<phones.length;i++)
      {
        for(int j=i;j<phones.length;j++)
          {
            int readI = phones[i].read ?? 0;
            int readJ = phones[j].read ?? 0;

            if(readI < readJ)
              {
                contact_list temp;
                temp=phones[i];
                phones[i]=phones[j];
                phones[j]=temp;
              }
          }
      }


    print("refreshphone is called");
    if (mounted) {
      setState(() {
        // Update your state here
      });
    }


  }

  @override
  Widget build(BuildContext context) {
      // This is important when using AutomaticKeepAliveClientMixin
    return RefreshIndicator(
      onRefresh:refreshPhones,
      child: ListView.builder(
            itemCount: phones.length,
            itemBuilder: (BuildContext context, int index) {
              contact_list temp=phones[index];
              if(temp.name=='WithChat AI' && temp.number=='128')
                return ListTile(
                  leading: RoundedLeadingIcon(
                    child:Image.asset('assets/1.png'),
                    size: 40,
                    backgroundColor: Colors.black,
                  ),
                  title:Text("${temp.name} ✅",style: TextStyle(fontSize: 19),) ,
                );
          else
          return GestureDetector(
            onTap: (){
              Navigator.push(context,
              MaterialPageRoute(builder: (context)=>PersonChatScreen(name: temp.name, phoneNumber: temp.number))
              );
            },
            child:  ListTile(
                    leading: generateLogo(temp.name),
                  title: Text(
                        "${temp.name}",
                        style: TextStyle(fontSize: 19),
                        ),
                      trailing: temp.read == 0 ? SizedBox.shrink() :  Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                          color: Colors.green, // WhatsApp-like green color
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                      ),
                      child: Text(
                              "${temp.read}",
                              style: TextStyle(
                                    color: Colors.white, // White text color
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    ),
                              ),
                      ),
              ),

          );
        },
      ),
    );
  }


}




class RoundedLeadingIcon extends StatelessWidget {
  final Widget child;
  final double size;
  final Color backgroundColor;

  RoundedLeadingIcon({
    required this.child,
    this.size = 40.0, // default size
    this.backgroundColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: child,
        ),
      ),
    );
  }
}

Future<int> getunread(String number,String myphone)async
{
  int count=0;
  QuerySnapshot data=await FirebaseFirestore.instance.collection('$myphone').doc('$number').collection('chat').get();
  List<DocumentSnapshot> doc=await data.docs;
  for(DocumentSnapshot datafor in doc)
    {
      if(datafor['sender']==number)
        {
          if(datafor['read']==false)
            count++;
        }

    }
  return count;
}

