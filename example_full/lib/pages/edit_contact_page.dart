import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_contacts_example/pages/form_components/address_form.dart';
import 'package:flutter_contacts_example/pages/form_components/email_form.dart';
import 'package:flutter_contacts_example/pages/form_components/event_form.dart';
import 'package:flutter_contacts_example/pages/form_components/name_form.dart';
import 'package:flutter_contacts_example/pages/form_components/note_form.dart';
import 'package:flutter_contacts_example/pages/form_components/organization_form.dart';
import 'package:flutter_contacts_example/pages/form_components/phone_form.dart';
import 'package:flutter_contacts_example/pages/form_components/social_media_form.dart';
import 'package:flutter_contacts_example/pages/form_components/website_form.dart';
import 'package:flutter_contacts_example/util/avatar.dart';
import 'package:image_picker/image_picker.dart';

class EditContactPage extends StatefulWidget {
  @override
  _EditContactPageState createState() => _EditContactPageState();
}

class _EditContactPageState extends State<EditContactPage>
    with AfterLayoutMixin<EditContactPage> {
  Contact contact = Contact();
  bool isEdit = false;
  void Function()? _onUpdate;

  final _imagePicker = ImagePicker();

  @override
  void afterFirstLayout(BuildContext context) {
    if (ModalRoute.of(context) != null &&
        ModalRoute.of(context)!.settings.arguments != null) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      setState(() {
        contact = args['contact'];
        isEdit = true;
        _onUpdate = args['onUpdate'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${isEdit ? 'Edit' : 'New'} contact'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.remove_red_eye),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  content: Text(
                      contact.toJson(withPhoto: false, withThumbnail: false).toString()),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.file_present),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  content: Text(
                      contact.toVCard(withPhoto: false, includeDate: true)),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              if (isEdit) {
                await contact.update(withGroups: true);
              } else {
                await contact.insert();
              }
              if (_onUpdate != null) _onUpdate!();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Form(
          child: Column(
            children: _contactFields(),
          ),
        ),
      ),
    );
  }

  List<Widget> _contactFields() => [
        _photoField(),
        _starredField(),
        _nameCard(),
        _phoneCard(),
        _emailCard(),
        _addressCard(),
        _organizationCard(),
        _websiteCard(),
        _socialMediaCard(),
        _eventCard(),
        _noteCard(),
        _groupCard(),
      ];

  Future _pickPhoto() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() {
        contact.photo = bytes;
      });
    }
  }

  Widget _photoField() => Stack(children: [
        Center(
            child: InkWell(
          onTap: _pickPhoto,
          child: avatar(contact, 48, Icons.add),
        )),
        contact.photo == null
            ? Container()
            : Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'Delete', child: Text('Delete photo'))
                  ],
                  onSelected: (_) => setState(() {
                    contact.photo = null;
                  }),
                ),
              ),
      ]);

  Card _fieldCard(
    String fieldName,
    List<dynamic> fields,
    Function()? addField,
    Widget Function(int, dynamic) formWidget,
    void Function()? clearAllFields, {
    bool createAsync = false,
  }) {
    var forms = <Widget>[
      Text(fieldName, style: TextStyle(fontSize: 18)),
    ];
    fields.asMap().forEach((int i, dynamic p) => forms.add(formWidget(i, p)));
    void Function() onPressed;
    if (createAsync) {
      onPressed = () async {
        await addField?.call();
        setState(() {});
      };
    } else {
      onPressed = () => setState(() {
            addField?.call();
          });
    }
    var buttons = <ElevatedButton>[];
    buttons.add(
      ElevatedButton(
        onPressed: onPressed,
        child: Text('+ New'),
      ),
    );
      buttons.add(ElevatedButton(
      onPressed: () {
        clearAllFields!();
        setState(() {});
      },
      child: Text('Delete all'),
    ));
      if (buttons.isNotEmpty) {
      forms.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons,
      ));
    }

    return Card(
      margin: EdgeInsets.all(12.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: forms,
          ),
        ),
      ),
    );
  }

  Card _nameCard() => _fieldCard(
        'Name',
        [contact.name],
        (){},
        (int i, dynamic n) => NameForm(
          n,
          onUpdate: (name) => contact.name = name,
          key: UniqueKey(),
        ),
        (){},
      );

  Card _phoneCard() => _fieldCard(
        'Phones',
        contact.phones,
        () => contact.phones = contact.phones + [Phone('')],
        (int i, dynamic p) => PhoneForm(
          p,
          onUpdate: (phone) => contact.phones[i] = phone,
          onDelete: () => setState(() => contact.phones.removeAt(i)),
          key: UniqueKey(),
        ),
        () => contact.phones = [],
      );

  Card _emailCard() => _fieldCard(
        'Emails',
        contact.emails,
        () => contact.emails = contact.emails + [Email('')],
        (int i, dynamic e) => EmailForm(
          e,
          onUpdate: (email) => contact.emails[i] = email,
          onDelete: () => setState(() => contact.emails.removeAt(i)),
          key: UniqueKey(),
        ),
        () => contact.emails = [],
      );

  Card _addressCard() => _fieldCard(
        'Addresses',
        contact.addresses,
        () => contact.addresses = contact.addresses + [Address('')],
        (int i, dynamic a) => AddressForm(
          a,
          onUpdate: (address) => contact.addresses[i] = address,
          onDelete: () => setState(() => contact.addresses.removeAt(i)),
          key: UniqueKey(),
        ),
        () => contact.addresses = [],
      );

  Card _organizationCard() => _fieldCard(
        'Organizations',
        contact.organizations,
        () =>
            contact.organizations = contact.organizations + [Organization()],
        (int i, dynamic o) => OrganizationForm(
          o,
          onUpdate: (organization) => contact.organizations[i] = organization,
          onDelete: () => setState(() => contact.organizations.removeAt(i)),
          key: UniqueKey(),
        ),
        () => contact.organizations = [],
      );

  Card _websiteCard() => _fieldCard(
        'Websites',
        contact.websites,
        () => contact.websites = contact.websites + [Website('')],
        (int i, dynamic w) => WebsiteForm(
          w,
          onUpdate: (website) => contact.websites[i] = website,
          onDelete: () => setState(() => contact.websites.removeAt(i)),
          key: UniqueKey(),
        ),
        () => contact.websites = [],
      );

  Card _socialMediaCard() => _fieldCard(
        'Social medias',
        contact.socialMedias,
        () => contact.socialMedias = contact.socialMedias + [SocialMedia('')],
        (int i, dynamic w) => SocialMediaForm(
          w,
          onUpdate: (socialMedia) => contact.socialMedias[i] = socialMedia,
          onDelete: () => setState(() => contact.socialMedias.removeAt(i)),
          key: UniqueKey(),
        ),
        () => contact.socialMedias = [],
      );

  Future<DateTime?> _selectDate(BuildContext context) async => showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(3000));

  Card _eventCard() => _fieldCard(
        'Events',
        contact.events,
        () async {
          final date = await _selectDate(context);
          if(date != null)
          contact.events = contact.events +
              [Event(year: date.year, month: date.month, day: date.day)];
                },
        (int i, dynamic w) => EventForm(
          w,
          onUpdate: (event) => contact.events[i] = event,
          onDelete: () => setState(() => contact.events.removeAt(i)),
          key: UniqueKey(),
        ),
        () => contact.events = [],
        createAsync: true,
      );

  Card _noteCard() => _fieldCard(
        'Notes',
        contact.notes,
        () => contact.notes = contact.notes + [Note('')],
        (int i, dynamic w) => NoteForm(
          w,
          onUpdate: (n){},
          onDelete: () => setState(() => contact.groups.removeAt(i)),
          key: UniqueKey(),
        ),
        () => contact.notes = [],
      );

  Card _groupCard() => _fieldCard(
        'Groups',
        contact.groups,
        () async {
          final group = await _promptGroup(exclude: contact.groups);
          if(group != null)
          setState(() => contact.groups = contact.groups + [group]);
                },
        (int i, dynamic w) => ListTile(
          title: Text(contact.groups[i].name),
          trailing: IconButton(
            onPressed: () => setState(() => contact.groups.removeAt(i)),
            icon: Icon(Icons.delete),
          ),
        ),
        () => setState(() => contact.groups = []),
      );

  Card _starredField() => Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Starred'),
            SizedBox(width: 24.0),
            Checkbox(
              value: contact.isStarred,
              onChanged: (bool? isStarred) {
                if(isStarred != null)
                setState(() => contact.isStarred = isStarred);
              },
            ),
          ],
        ),
      );

  Future<Group?> _promptGroup({required List<Group> exclude}) async {
    final excludeIds = exclude.map((x) => x.id).toSet();
    final groups = (await FlutterContacts.getGroups())
        .where((g) => !excludeIds.contains(g.id))
        .toList();
    Group? selectedGroup;
    await showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        content: Container(
          height: 300.0,
          width: 300.0,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groups.length,
            itemBuilder: (BuildContext ctx, int i) => ListTile(
              title: Text(groups[i].name),
              onTap: () {
                selectedGroup = groups[i];
                Navigator.of(ctx).pop();
              },
            ),
          ),
        ),
      ),
    );
    return selectedGroup;
  }
}
