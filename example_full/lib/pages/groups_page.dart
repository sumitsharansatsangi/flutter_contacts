import 'package:after_layout/after_layout.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import 'package:prompt_dialog/prompt_dialog.dart';

class GroupsPage extends StatefulWidget {
  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage>
    with AfterLayoutMixin<GroupsPage> {
  List<Group> groups = [];

  @override
  void afterFirstLayout(BuildContext context) {
    _fetchGroups();
  }

  Future _fetchGroups() async {
    final _groups = await FlutterContacts.getGroups();
    setState(() => groups = _groups);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('flutter_contacts_example - groups'),
        ),
        body: _body(),
        floatingActionButton: FloatingActionButton(
          onPressed: _newGroup,
          child: Icon(Icons.add),
        ),
      );

  Widget _body() {
    if (groups.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final group = groups[i];
          return ListTile(
            title: Text('${group.name} (id=${group.id})'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _renameGroup(group),
                  icon: Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () => _deleteGroup(group),
                  icon: Icon(Icons.delete),
                ),
              ],
            ),
            onTap: () => _renameGroup(group),
          );
        });
  }

  Future<void> _newGroup() async {
    final name = await prompt(context);
    if (name?.isNotEmpty == true) {
      final group = await FlutterContacts.insertGroup(Group('', name!));
      print('Inserted group $group');
      await _fetchGroups();
    }
  }

  Future<void> _renameGroup(Group group) async {
    final name = await prompt(context, initialValue: group.name);
    if (name?.isNotEmpty == true) {
      final updatedGroup =
          await FlutterContacts.updateGroup(Group(group.id, name!));
      print('Updated group $updatedGroup');
      await _fetchGroups();
    }
  }

  Future<void> _deleteGroup(Group group) async {
    await FlutterContacts.deleteGroup(group);
    print('Deleted group $group');
    await _fetchGroups();
  }
}
