import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:libphonenumber/libphonenumber.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homescreen.dart';
//for phone authentication
class PhoneAuthScreen extends StatefulWidget
{
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}
void _savePhoneNumber(String phoneNumber,String Name)async
{
  SharedPreferences prefs=await SharedPreferences.getInstance();
  await prefs.setString('phoneNumber', phoneNumber);
  await prefs.setString('Name', Name);
}
class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController=TextEditingController();
  final _nameController=TextEditingController();
  final _codeController=TextEditingController();
  String _verificationId='';
  bool _isCodeSent=false;
  final _formkey=GlobalKey<FormState>();
  @override
  void initState()
  {
    super.initState();
    _checkSavedPhoneNumber();
  }
  void _checkSavedPhoneNumber()async
  {
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String? savedPhoneNumber=prefs.getString('phoneNumber');
    if(savedPhoneNumber != null)
    {
      _phoneController.text=savedPhoneNumber;
      _verifyPhoneNumber();
    }
  }
  void _verifyPhoneNumber()async
  {
    final phoneNumber=_phoneController.text.trim();
    final normalizedPhoneNumber=await PhoneNumberUtil.normalizePhoneNumber(phoneNumber: phoneNumber, isoCode: 'IN');
    print("$normalizedPhoneNumber");
    if(!_isCodeSent)
    {
      //initiate phone number verification
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: normalizedPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential)async{
          UserCredential userCredential=await FirebaseAuth.instance.signInWithCredential(credential);
          _savePhoneNumber(_phoneController.text.trim(),_nameController.text);
          await FirebaseFirestore.instance.collection('users').doc('$normalizedPhoneNumber').set({
            'phoneNumber':normalizedPhoneNumber,
            'Name':_nameController.text,
          });
          _navigateToHome();
        },
        verificationFailed: (FirebaseAuthException e){
          if (e.code == 'invalid-phone-number') {
            print('The provided phone number is not valid.');
          } else {
            print('Verification failed with error: ${e.message}');
          }
        },
        codeSent: (String verificationId, int? resendToken)async{
          setState(() {
            _verificationId = verificationId;
            _isCodeSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId){
          setState(() {
            _verificationId = verificationId;
          });
        },

      );
    }
    else
    {
      //sign in with verification code
      final code=_codeController.text.trim();
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId:_verificationId,
          smsCode:code);
      UserCredential userCredential=await FirebaseAuth.instance.signInWithCredential(credential);
      _savePhoneNumber(_phoneController.text.trim(),_nameController.text);
      await FirebaseFirestore.instance.collection('users').doc('$normalizedPhoneNumber').set({
        'phoneNumber':normalizedPhoneNumber,
        'Name':_nameController.text,
      });
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }
  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Authentication'),
      ),
      body: Form(
        key: _formkey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (!_isCodeSent) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Enter Your Name'),
                  validator: (value){
                    if(value==null||value.isEmpty)
                      return "Enter your name";
                    return null;
                  },
                ),
                Row(
                  children: [
                    Text("+91"),
                    SizedBox(width: 10,),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(labelText: 'Phone number'),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: (value){
                          if(value==null||value.isEmpty)
                            return "Please!Enter Phone Number";
                          if(value.length<10)
                            return "Enter valid Phone Number";
                          return null;

                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed:(){
                    if(_formkey.currentState!.validate())
                    {
                      _verifyPhoneNumber();
                    }

                  } ,
                  child: Text('Verify Phone Number'),
                ),
              ] else ...[
                TextFormField(
                  controller: _codeController,
                  validator: (value){
                    if(value==null||value.isEmpty)
                      return "Enter code";
                  },
                  decoration: InputDecoration(labelText: 'Verification code'),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed:(){
                    if(_formkey.currentState!.validate())
                    {
                      _verifyPhoneNumber();
                    }

                  },
                  child: Text('Sign in with Phone Number'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}