/*
 * @Author: Kingtous
 * @Date: 2020-10-19 21:17:42
 * @LastEditors: Kingtous
 * @LastEditTime: 2020-10-19 22:58:59
 * @Description: Kingtous' Code
 */
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:one_chat/sms_page.dart';
import 'package:one_chat/sqlite_page.dart';
import 'package:sa_stateless_animation/sa_stateless_animation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '移动端实验',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      //home: MyHomePage(title: '聊天界面'),
      initialRoute: "/",
      routes: <String, WidgetBuilder>{
        "/": (context) => HomePage(),
        "/chat": (context) => MyHomePage(title: '聊天界面'),
        "/database": (context) => NameDataBasePage(),
        "/sms": (context) => SmsPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("实验-CS170217"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "功能列表",
              style: TextStyle(fontSize: 24),
            ),
          ),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.start,
              runSpacing: 16,
              spacing: 16,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FlatButton.icon(
                      padding: EdgeInsets.all(8),
                        color: Colors.blue,
                        onPressed: () => _handleNavigate(context, "/chat"),
                        icon: Icon(Icons.message,color: Colors.white,),
                        label: Text("聊天",style: TextStyle(color: Colors.white),)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FlatButton.icon(
                        padding: EdgeInsets.all(8),
                        color: Colors.blue,
                        onPressed: () => _handleNavigate(context, "/database"),
                        icon: Icon(Icons.message,color: Colors.white,),
                        label: Text("编号数据库",style: TextStyle(color: Colors.white),)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FlatButton.icon(
                        padding: EdgeInsets.all(8),
                        color: Colors.blue,
                        onPressed: () => _handleNavigate(context, "/sms"),
                        icon: Icon(Icons.message,color: Colors.white,),
                        label: Text("短信管理器",style: TextStyle(color: Colors.white),)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _handleNavigate(BuildContext context, String s) {
    Navigator.of(context).pushNamed(s);
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/// 消息类型，自己、他人
enum MsgType { self, other }

class Msg {
  MsgType type;
  String text;
}

class _MyHomePageState extends State<MyHomePage> {
  var _textEditingController = TextEditingController();

  List<Msg> _msgs = List();
  String _msg = "";

  var _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _msgs.add(Msg()
      ..type = MsgType.self
      ..text = "Hello?");
    _msgs.add(Msg()
      ..type = MsgType.other
      ..text = "有什么事?");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
                child: Container(
                    alignment: Alignment.center,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemBuilder: _buildMsgItem,
                      itemCount: _msgs.length,
                    ))),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: _textEditingController,
                    onChanged: (s) {
                      _msg = s;
                    },
                  )),
                  FlatButton.icon(
                      onPressed: _handleMessageSent,
                      icon: Icon(Icons.add),
                      label: Text("发送"))
                ],
              ),
            )
          ],
        ));
  }

  Widget _buildMsgItem(BuildContext context, int index) {
    return PlayAnimation<double>(
      tween: Tween(begin: 1,end: 16),
      duration: Duration(milliseconds: 200),
      builder:(context,child,value) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          alignment: _msgs[index].type == MsgType.self
              ? WrapAlignment.end
              : WrapAlignment.start,
          children: [
            SizedBox(
              width: _msgs[index].type == MsgType.self ? 60 : 0,
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                  borderRadius: _msgs[index].type == MsgType.other
                      ? BorderRadius.only(
                          topRight: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                          bottomLeft: Radius.circular(30),
                        )
                      : BorderRadius.only(
                          topLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                          bottomLeft: Radius.circular(30),
                        ),
                  color: _msgs[index].type == MsgType.self
                      ? Colors.blueAccent
                      : Colors.purple),
              child: Text(
                _msgs[index].text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: value
                ),
                softWrap: true,
                overflow: TextOverflow.clip,
              ),
            ),
            SizedBox(
              width: _msgs[index].type == MsgType.other ? 60 : 0,
            ),
          ],
        ),
      ),
    );
  }

  void _handleMessageSent() {
    setState(() {
      _textEditingController.text = "";
      _msgs.add(Msg()
        ..type = MsgType.self
        ..text = _msg);
    });
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController?.animateTo(
        _scrollController.position.maxScrollExtent, //滚动到底部
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _msgs.add(Msg()
          ..type = MsgType.other
          ..text = "复读机：我正在忙，请稍后联系");
      });
    });

    Future.delayed(Duration(milliseconds: 1500), () {
      _scrollController?.animateTo(
        _scrollController.position.maxScrollExtent, //滚动到底部
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}
