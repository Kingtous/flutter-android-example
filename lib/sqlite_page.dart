/*
 * @Author: Kingtous
 * @Date: 2020-10-19 22:07:36
 * @LastEditors: Kingtous
 * @LastEditTime: 2020-10-19 23:06:31
 * @Description: Kingtous' Code
 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class NameDataBasePage extends StatefulWidget {
  @override
  _NameDataBasePageState createState() => _NameDataBasePageState();
}

class NameDataEntity {
  int id;
  String name;

  NameDataEntity({this.id, this.name});

  Map<String, dynamic> toJson() {
    return {"id": id, "name": name};
  }
}

class _NameDataBasePageState extends State<NameDataBasePage> {
  static Database _db;

  var _formKey = GlobalKey<FormState>();
  var _idKey = GlobalKey<FormFieldState>();
  var _nameKey = GlobalKey<FormFieldState>();
  var _scfKey = GlobalKey<ScaffoldState>();

  var _entity = NameDataEntity();

  var _idController = TextEditingController();
  var _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_db == null || !(_db is Database)) {
      openDatabase("name.db").then((value) async {
        try {
          await value.execute('''
      create table People(
        id INTEGER PRIMARY KEY,
        name TEXT
      )
      ''');
        } on DatabaseException catch (e) {
          debugPrint(e.toString());
        }

        setState(() {
          _db = value;
          debugPrint("init database success!");
        });
      });
    }
  }

  @override
  void dispose() {
    _db?.close()?.then((value) {
      _db = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scfKey,
      appBar: AppBar(
        title: Text("编号管理系统"),
        centerTitle: true,
      ),
      body: _db == null
          ? Center(
              child: Text("加载数据库中"),
            )
          : Padding(
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
                                prefixIcon: Icon(Icons.accessibility_rounded),
                                hintText: "编号"),
                            validator: (text) {
                              if (text.isEmpty) {
                                return "编号不能为空";
                              }
                              if (int.tryParse(text) == null) return "编号应该为数字";
                              return null;
                            },
                            onSaved: (id) {
                              _entity.id = int.parse(id);
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
                              hintText: "姓名",
                            ),
                            validator: (text) {
                              if (text.trim().isEmpty) {
                                return "姓名不能为空";
                              }
                              return null;
                            },
                            onSaved: (name) {
                              _entity.name = name;
                            },
                          ),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        FlatButton.icon(
                            onPressed: () {
                              _handleInsert();
                            },
                            icon: Icon(Icons.add_circle_outline),
                            label: Text("插入/更新")),
                        FlatButton.icon(
                            onPressed: () {
                              _handleQuery();
                            },
                            icon: Icon(Icons.search),
                            label: Text("查询")),
                        FlatButton.icon(
                            onPressed: () {
                              _handleDelete();
                            },
                            icon: Icon(Icons.delete),
                            label: Text("删除")),
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }

  void _handleInsert() async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      var resultList = await _db
          .query("People", where: "id = ?", whereArgs: ["${_entity.id}"]);
      if (resultList.isEmpty) {
        var rowCount = await _db.insert("People", _entity.toJson());
        if (rowCount > 0) {
          showMsg("成功插入");
        } else {
          showMsg("插入失败，请检查");
        }
      } else {
        _scfKey.currentState.showSnackBar(SnackBar(
            content: Wrap(
              alignment: WrapAlignment.spaceBetween,
          children: [
            Text("含相同编号的记录(${resultList[0]["name"]}),是否更新为${_entity.name}？"),
            GestureDetector(onTap: () async {
              _scfKey.currentState.hideCurrentSnackBar();
              var rowCount = await _db.update("People", _entity.toJson(),
                  where: "id = ?", whereArgs: ["${_entity.id}"]);
              if (rowCount > 0) {
                showMsg("成功更新");
              } else {
                showMsg("更新失败，请检查");
              }
            }, child: Text("更新",style: TextStyle(
              color: Colors.blue
            ),))
          ],
        )));
      }
      // debugPrint("ok");
    }
  }

  void _handleQuery() async {
    if (_idKey.currentState.validate()) {
      _idKey.currentState.save();
      var resultList = await _db
          .query("People", where: "id = ?", whereArgs: ["${_entity.id}"]);
      if (resultList.isEmpty) {
        showMsg("查无此人");
      } else {
        showMsg("查询到${resultList.length}条结果");
        setState(() {
          _nameController.text = resultList[0]['name'];
          _idController.text = resultList[0]['id'].toString();
        });
      }
      // debugPrint("ok");
    }
  }

  void _handleDelete() async {
    if (_idKey.currentState.validate()) {
      _idKey.currentState.save();
      // debugPrint("ok");
      var resultList = await _db
          .delete("People", where: "id=?", whereArgs: ["${_entity.id}"]);
      if (resultList == 0) {
        showMsg("没有编号为${_entity.id}的记录");
      } else {
        showMsg("已删除记录");
      }
    }
  }

  void showMsg(String msg) {
    _scfKey.currentState.hideCurrentSnackBar();
    _scfKey.currentState.showSnackBar(SnackBar(content: Text(msg)));
  }
}
