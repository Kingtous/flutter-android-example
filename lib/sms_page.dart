import 'dart:async';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sms_maintained/sms.dart';

class SmsPage extends StatefulWidget {
  @override
  _SmsPageState createState() => _SmsPageState();
}

class SmsDataEntity {
  String address;
  String content;

  SmsDataEntity({this.address, this.content});

  Map<String, dynamic> toJson() {
    return {"address": address, "content": content};
  }
}

class _SmsPageState extends State<SmsPage> {
  var _formKey = GlobalKey<FormState>();
  var _idKey = GlobalKey<FormFieldState>();
  var _nameKey = GlobalKey<FormFieldState>();
  var _scfKey = GlobalKey<ScaffoldState>();
  SmsDataEntity _entity = SmsDataEntity();
  StreamSubscription<SmsMessageState> _subscription;
  StreamSubscription<SmsMessage> _onMsgsubscription;

  var _idController = TextEditingController();
  var _nameController = TextEditingController();

  SmsSender _smsSender;
  SmsReceiver _smsReceiver;
  SimCardsProvider provider = new SimCardsProvider();
  List<SimCard> _cards = List();
  DeviceInfoPlugin _deviceInfoPlugin;

  @override
  void initState() {
    super.initState();
    _deviceInfoPlugin = DeviceInfoPlugin();
    _smsSender = SmsSender();
    _smsReceiver = SmsReceiver();

    _deviceInfoPlugin.androidInfo.then((value){
      if (value.version.sdkInt >= 29){
        // sms插件在安卓10+手机卡不支持获取
      } else {
        provider.getSimCards().then((cards){
          setState(() {
            _cards = cards;
          });
        });
      }
    });
    _onMsgsubscription = _smsReceiver.onSmsReceived.listen((msg) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        // false = user must tap button, true = tap outside dialog
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('收到信息'),
            content: Text('发信人：${msg.sender}\n发信内容：${msg.body}'),
            actions: <Widget>[
              FlatButton(
                child: Text('确定'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Dismiss alert dialog
                },
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scfKey,
      appBar: AppBar(
        title: Text("短信管理器"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _idController,
                      key: _idKey,
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.contact_phone),
                          hintText: "联系人"),
                      validator: (text) {
                        if (text.isEmpty) {
                          return "联系人不能为空";
                        }
                        if (int.tryParse(text) == null) return "联系人应该为数据";
                        return null;
                      },
                      onSaved: (id) {
                        _entity.address = int.parse(id).toString();
                      },
                    ),
                  )
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      key: _nameKey,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.nine_k),
                        hintText: "短信内容",
                      ),
                      validator: (text) {
                        if (text.trim().isEmpty) {
                          return "短信内容不能为空";
                        }
                        return null;
                      },
                      onSaved: (content) {
                        _entity.content = content;
                      },
                    ),
                  )
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _cards==null? _cards.map((e){
                  return FlatButton.icon(
                      onPressed: () {
                        _handleSend(e);
                      },
                      icon: Icon(Icons.add_circle_outline),
                      label: Text("发送(卡${e.slot})"));
                }).toList(): [FlatButton.icon(
                    onPressed: () {
                      _handleSend(null);
                    },
                    icon: Icon(Icons.add_circle_outline),
                    label: Text("发送"))],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _onMsgsubscription?.cancel();
    debugPrint("canceled.");
    super.dispose();
  }

  /// 发送listener
  void _handleSend(SimCard card) {
    if (_formKey.currentState.validate()) {
      debugPrint(
          "sending sms to ${_entity.address}, content: ${_entity.content}");
      _formKey.currentState.save();
      var message = SmsMessage(_entity.address, _entity.content);
      _subscription = message.onStateChanged.listen((state) {
        if (state == SmsMessageState.Sent) {
          showMsg("短信已发送！");
        } else if (state == SmsMessageState.Sending) {
          showMsg("正在发送...");
        } else if (state == SmsMessageState.Delivered) {
          showMsg("短信已送达！");
        }
      });
      if (card == null){
        _smsSender?.sendSms(message);
      } else {
        _smsSender?.sendSms(message,simCard: card);
      }
    }
  }

  void showMsg(String msg) {
    _scfKey.currentState.hideCurrentSnackBar();
    _scfKey.currentState.showSnackBar(SnackBar(content: Text(msg)));
  }
}
