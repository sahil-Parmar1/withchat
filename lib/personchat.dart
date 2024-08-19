import 'package:file_picker/file_picker.dart';

import 'homescreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';



class PersonChatScreen extends StatefulWidget
{
  String name;
  String phoneNumber;
  PersonChatScreen({required this.name,required this.phoneNumber});
  @override
  State<PersonChatScreen> createState() => _PersonChatScreenState();
}

class _PersonChatScreenState extends State<PersonChatScreen> {
  TextEditingController _messagecontroller=TextEditingController();
   ScrollController _scrollController = ScrollController();
   String my_phone="12";
   String myname='';
  @override
  void initState()
  {
    super.initState();
    print("in init state ${widget.phoneNumber}");
    fecthchat();
  }
  void fecthchat()async
  {
    SharedPreferences prefs=await SharedPreferences.getInstance();
    my_phone=prefs.getString('phoneNumber')??'92';
    myname=prefs.getString('name')??'sahil2';
    setState(() {});
  }

   void _scrollToBottom(){
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(_scrollController.hasClients)
        {
          _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut);
        }

    });
   }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              generateLogo(widget.name),
              SizedBox(width: 10,),
              Text("${widget.name}",style: TextStyle(fontSize: 17),),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(child:
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("$my_phone")
                  .doc("${widget.phoneNumber}")
                  .collection('chat')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshots) {
                if (snapshots.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshots.hasError) {
                  print("Error: ${snapshots.error}");
                  return Center(child: Text("Something went wrong, please restart the app"));
                } else if (!snapshots.hasData || snapshots.data!.docs.isEmpty) {
                  print("${snapshots.data!.docs}");
                  return AnimatedStartChattingButton(phoneNumber_send: my_phone,phoneNumber_rec: widget.phoneNumber,name_reciver: widget.name,);

                } else if(snapshots.hasData){
                  var chatDocs = snapshots.data!.docs;

                   WidgetsBinding.instance.addPostFrameCallback((_)=>_scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: chatDocs.length,
                    itemBuilder: (BuildContext context, int index) {
                      var data = chatDocs[index].data() as Map<String, dynamic>;
                      bool isam=data['sender']==my_phone;
                      String docid=chatDocs[index].id;
                      print("document id is ${docid}");
                      if(!isam)
                      markbyread(widget.phoneNumber,my_phone,'chat',docid);//for read message to sender
                      DateTime time=DateTime.parse(data['time']);
                      DateFormat formatdate=DateFormat('hh:mm a dd/MM ');
                      String formateddate=formatdate.format(time);
                      return Align(
                        alignment: isam?Alignment.centerRight:Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isam?CrossAxisAlignment.end:CrossAxisAlignment.start,
                          children: [
                            Container(

                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),



                              child: data['media']=='No'?Text('${data['message']}',style: TextStyle(fontSize: 18),):TextButton(onPressed: ()async{
                                if (await canLaunchUrl(Uri.parse(data['media']))) {
                                  await launchUrl(Uri.parse(data['media']));
                                } else {
                                  throw 'Could not launch ${data['media']}';

                                }
                                //await launchUrl(Uri.parse(data['media']),mode:LaunchMode.externalApplication);


                              }, child: Text("${data['media']}",style:TextStyle(color:Colors.blue))),
                              decoration: BoxDecoration(
                                color: isam?Colors.grey:Colors.blue,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.only(
                                  topLeft: isam?Radius.circular(10):Radius.circular(0),
                                  topRight: isam?Radius.circular(0):Radius.circular(10),
                                  bottomLeft:Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),





                              ),
                            ),
                            Row(
                              mainAxisAlignment: isam?MainAxisAlignment.end:MainAxisAlignment.start,
                              children: [
                                Text("$formateddate"),
                                isam?data['read']==false?Icon(Icons.done):Icon(Icons.done_all_outlined,color: Colors.blue,):SizedBox.shrink(),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                else
                  {
                    return AnimatedStartChattingButton(phoneNumber_send: my_phone,phoneNumber_rec: widget.phoneNumber,name_reciver: widget.name,);
                  }
              },
            ),


            ),

            Row(
              children: [
                SizedBox(width: 5,),
                Consumer<ismessage>(
                    builder:(context,ismgs,child)
                    {
                      return !ismgs.ismessageType?Row(
                        children: [
                          IconButton(onPressed: ()async{
                             File? _imageFile;
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                            if (pickedFile != null) {
                              _imageFile = File(pickedFile.path);
                              final fileSize=await _imageFile.length();
                              showfiledetails(context,_imageFile,fileSize,widget.phoneNumber);

                            }

                          }, icon: Icon(Icons.image)),
                          IconButton(onPressed: ()async{
                            File? _videoFile;
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

                            if (pickedFile != null) {
                              _videoFile = File(pickedFile.path);
                              final fileSize=await _videoFile.length();
                              showfiledetails(context,_videoFile,fileSize,widget.phoneNumber);


                            }
                          }, icon: Icon(Icons.video_collection)),
                          IconButton(onPressed: ()async{
                               FilePickerResult? result=await FilePicker.platform.pickFiles();
                               if(result != null)
                                 {
                                   File file=File(result.files.single.path!);
                                   final fileSize=await file.length();
                                   showfiledetails(context, file, fileSize, widget.phoneNumber);
                                 }
                          }, icon: Icon(Icons.add)),
                          SizedBox(width: 5,),
                        ],
                      ):SizedBox(width: 5,);
                    }
                ),

                Expanded(
                  child: TextFormField(
                    controller: _messagecontroller,
                    decoration: InputDecoration(
                        hintText: "Type a Message.."
                    ),
                    onChanged: (value)
                    {

                      if(value.isNotEmpty && value.length>0 && value!='')
                        Provider.of<ismessage>(context,listen: false).istrue();
                      if(value.isEmpty || value.length==0 || value=='')
                        Provider.of<ismessage>(context,listen: false).isfalse();
                    },
                  ),
                ),
                Consumer<ismessage>(
                    builder:(context,ismgs,child)
                    {
                      return ismgs.ismessageType?IconButton(onPressed: ()async{

                        sendMsg(_messagecontroller.text, widget.phoneNumber,myname,widget.name);
                      }, icon: Icon(Icons.send)):SizedBox.shrink();;
                    }
                ),

              ],
            )
          ],
        )

    );
  }
  void sendMsg(String msg,String phoneNumber_rec,String name_sender,String name_reciver,{String link="No",String dropboxPath="No"})async
  {
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String? phoneNumber_sender=await prefs.getString('phoneNumber')??'92';
    Timestamp timestamp=Timestamp.fromDate(DateTime.now());
    String time=timestamp.toDate().toIso8601String();
    //for testing
    //phoneNumber_sender='92';
    //
    await FirebaseFirestore.instance.collection('$phoneNumber_sender').doc('$phoneNumber_rec').set({
      'Name':name_reciver,
    },
      SetOptions(merge: true),
    );
    await FirebaseFirestore.instance.collection('$phoneNumber_sender').doc('$phoneNumber_rec').collection("chat").doc(time).set({
      'sender':phoneNumber_sender,
      'reciver':phoneNumber_rec,
      'message':msg,
      'time':time,
      'read':false,
      'media':link,
      'dropboxPath':dropboxPath,
    }).then(
            (value){
          print("message send successfully");
        }).catchError(
            (e){
          print("fail to send message $e");
        }
    );
    await FirebaseFirestore.instance.collection('$phoneNumber_rec').doc('$phoneNumber_sender').set({
      'Name':name_sender,
    },
      SetOptions(merge: true),
    );
    await FirebaseFirestore.instance.collection('$phoneNumber_rec').doc('$phoneNumber_sender').collection("chat").doc(time).set({
      'sender':phoneNumber_sender,
      'reciver':phoneNumber_rec,
      'message':msg,
      'time':time,
      'read':false,
      'media':link,
    }).then(
            (value){
          print("message send successfully");
        }).catchError(
            (e){
          print("fail to send message $e");
        }
    );
    _messagecontroller.clear();
    Provider.of<ismessage>(context,listen: false).isfalse();
  }

  void showfiledetails(BuildContext context,File filepath,int fileSize,String phoneNumber_rec)
  {
     final isSizeValid=fileSize<=100*1024*1024;
     String filename=path.basename(filepath.path);
     final dropboxPath='/${my_phone}/${DateTime.now}/${filename}';
     final DropboxApi _dropboxApi=DropboxApi();
     String link='';
     bool isUploading=false;
     showModalBottomSheet(
         isDismissible: false,
         context: context,
         builder: (context)
        {
           return StatefulBuilder(builder: (BuildContext context,StateSetter setState)
             {
               return Padding(padding: EdgeInsets.all(16.0),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text("File details",style: TextStyle(fontSize: 20,fontWeight:FontWeight.bold ),),
                     SizedBox(height: 16,),
                     Text("File Path:${filepath.path}"),
                     SizedBox(height: 8,),
                     Text("File Size:${fileSize/(1024*1024)} MB"),
                     SizedBox(height: 16,),
                     if(isUploading)
                       Row(
                         children: [
                           CircularProgressIndicator(),
                           Text("Sending"),
                         ],
                       )
                       else
                         if(isSizeValid)
                       ElevatedButton(onPressed: ()async{
                         setState((){
                           isUploading=true;
                         });
                         await _dropboxApi.uploadFile(filepath, dropboxPath);
                         link=await _dropboxApi.getShareableLink(dropboxPath);
                         sendMsg("No", phoneNumber_rec,myname,widget.name,link: link,dropboxPath: dropboxPath);
                          Navigator.pop(context);
                       }, child: Row(
                         children: [
                           Icon(Icons.send),
                           Text("send"),
                         ],
                       ))
                     else
                       Column(
                         children: [
                           ElevatedButton(onPressed: (){}, child: Row(
                             children: [
                               Icon(Icons.send),
                               Text("send"),
                             ],
                           )),
                           Text("FileSize<=100MB",style: TextStyle(color: Colors.red),),
                         ],
                       ),
                     SizedBox(height: 8,),
                     if(isUploading)
                       SizedBox.shrink()
                     else
                     ElevatedButton(onPressed: (){
                       Navigator.pop(context);
                     }, child: Row(
                       children: [
                         Icon(Icons.cancel),
                         Text("cancel")
                       ],
                     ))



                   ],
                 ),
               );
            });

        }
       );
  }
}
void sayhi(String phoneNumber_sender,String phoneNumber_rec,name_reciver)async
{

  Timestamp timestamp=Timestamp.fromDate(DateTime.now());
  String time=timestamp.toDate().toIso8601String();
  //for testing
  //phoneNumber_sender='92';
  //

  print("in say hi${phoneNumber_sender}");
  print("in say hi${phoneNumber_rec}");
  String myname;
  SharedPreferences prefs=await SharedPreferences.getInstance();
  myname=prefs.getString('Name')??"sahil2";
  await FirebaseFirestore.instance.collection('$phoneNumber_rec').doc('$phoneNumber_sender').set({
    'Name':myname,
  },
    SetOptions(merge: true),
  );
  await FirebaseFirestore.instance.collection('$phoneNumber_sender').doc('$phoneNumber_rec').set({
    'Name':name_reciver,
  },
    SetOptions(merge: true),
  );
  await FirebaseFirestore.instance.collection('$phoneNumber_sender').doc('$phoneNumber_rec').collection("chat").doc(time).set({
    'sender':phoneNumber_sender,
    'reciver':phoneNumber_rec,
    'message':"👋!Hi",
    'time':time,
    'read':false,
    'media':'No'
  }).then(
          (value){
        print("message send successfully");
      }).catchError(
          (e){
        print("fail to send message $e");
      }
  );
  await FirebaseFirestore.instance.collection('$phoneNumber_rec').doc('$phoneNumber_sender').collection("chat").doc(time).set({
    'sender':phoneNumber_sender,
    'reciver':phoneNumber_rec,
    'message':"👋!Hi",
    'time':time,
    'read':false,
    'media':'No'
  }).then(
          (value){
        print("message send successfully");
      }).catchError(
          (e){
        print("fail to send message $e");
      }
  );
}
void markbyread(String sender,String reciver,String collation,String document)
{
  print("${document} is changed");
  DocumentReference ref=FirebaseFirestore.instance.collection(sender).doc(reciver).collection(collation).doc(document);
  ref.set(
  {
    'read':true,
  },
    SetOptions(merge: true),
  );
  DocumentReference ref2=FirebaseFirestore.instance.collection(reciver).doc(sender).collection(collation).doc(document);
  ref2.set(
    {
      'read':true,
    },
    SetOptions(merge: true),
  );
}

class AnimatedStartChattingButton extends StatefulWidget {
  String phoneNumber_rec;
  String phoneNumber_send;
  String name_reciver;
  AnimatedStartChattingButton({required this.phoneNumber_send,required this.phoneNumber_rec,required this.name_reciver});
  @override
  _AnimatedStartChattingButtonState createState() => _AnimatedStartChattingButtonState();
}

class _AnimatedStartChattingButtonState extends State<AnimatedStartChattingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () {
            // Add your action here, e.g., navigate to chat screen
            print('Start chatting pressed');
            sayhi(widget.phoneNumber_send, widget.phoneNumber_rec,widget.name_reciver);

          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
              decoration: BoxDecoration(
                color: Colors.blue.shade400,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '👋 ',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.blue.shade900,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Start chatting!\nSay Hi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//for upload the file
class DropboxApi
{
  final String accessToken="sl.B6uc9yqr8HS8krHUbQyWj3nlxdmRuosMdfHIpRBx2iceoFnPYkHVOeOqlK0yHItzEYyrgcbKM3rLhV4h2n7QJiIsIWCeocVjalZblWcU7uljam1kmgi37owkL9uYzV2_F_Orr0QwxMDSPWa6qwhiXeg";
  Future<void> uploadFile(File file,String dropboxPath)async
  {
    final String uploadUrl="https://content.dropboxapi.com/2/files/upload";
    final uploadResponse=await http.post(
      Uri.parse(uploadUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/octet-stream',
        'Dropbox-API-Arg': jsonEncode({
          'path': dropboxPath,
          'mode': 'add',
          'autorename': true,
          'mute': false,
        }),
      },
      body: await file.readAsBytes()
    );
    if (uploadResponse.statusCode != 200) {
      throw Exception('Failed to upload file: ${uploadResponse.body}');
    }
  }
  Future<String> getShareableLink(String dropboxPath)async
  {
    final String createShareLinkUrl =
        'https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings';
    final shareLinkResponse = await http.post(
      Uri.parse(createShareLinkUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'path': dropboxPath,
        'settings': {
          'requested_visibility': 'public',
        }
      }),
    );
    if (shareLinkResponse.statusCode != 200) {
      throw Exception('Failed to create share link: ${shareLinkResponse.body}');
    }

    final Map<String, dynamic> shareLinkData =
    jsonDecode(shareLinkResponse.body);
    print("${shareLinkData['url']}");
    return shareLinkData['url'];

  }
  Future<void> deleteFile(String dropboxPath) async {
    final String deleteUrl = 'https://api.dropboxapi.com/2/files/delete_v2';

    final deleteResponse = await http.post(
      Uri.parse(deleteUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'path': dropboxPath,
      }),
    );

    if (deleteResponse.statusCode != 200) {
      throw Exception('Failed to delete file: ${deleteResponse.body}');
    }
  }

}