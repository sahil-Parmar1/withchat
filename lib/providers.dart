import 'package:flutter/cupertino.dart';

class ismessage with ChangeNotifier
{
  bool _ismessageType=false;
  bool get ismessageType=>_ismessageType;
  void istrue()
  {
    _ismessageType=true;
    notifyListeners();
  }
  void isfalse()
  {
    _ismessageType=false;
    notifyListeners();
  }
}