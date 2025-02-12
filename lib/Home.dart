import 'package:direct_dialer/direct_dialer.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Contact> _contacts = const [];
  bool isTamil = true;

  List<Contact> get contacts {
    return _contacts.where((c) {
      final displayName = c.displayName;

      final containsEnglish = RegExp(r'[a-zA-Z]').hasMatch(displayName);
      return isTamil ? !containsEnglish : containsEnglish;
    }).toList();
  }

  bool _isLoading = false;
  String selectedAlphabet = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // appBar: appBar(),
        body: body(),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      title: Text('Caller'),
      centerTitle: true,
    );
  }

  Widget body() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else {
      return column();
    }
  }

  Widget column() {
    return ListView(
      physics: BouncingScrollPhysics(),
      children: [
        langaugeSwitch(),
        filterBoard(),
        listView(),
      ],
    );
  }

  Widget filterBoard() {
    List<String> alphabets = [];
    for (Contact contact in contacts) {
      String firstLetter = contact.displayName.trim().characters.firstOrNull ?? '';
      if (firstLetter.isNotEmpty && !alphabets.contains(firstLetter)) {
        alphabets.add(firstLetter);
      }
    }

    alphabets.sort();

    return GridView.builder(
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      padding: EdgeInsets.all(8),
      itemCount: alphabets.length,
      itemBuilder: (BuildContext context, int index) {
        String a = alphabets[index];
        bool isSelected = selectedAlphabet == a;
        Color color = isSelected ? Colors.purple : Colors.transparent;
        return InkWell(
          onTap: () {
            setState(() {
              selectedAlphabet = isSelected ? '' : a;
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Text(
              a,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontSize: 28,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget langaugeSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'தமிழ்',
          style: TextStyle(fontSize: 24),
        ),
        Switch(
          value: isTamil,
          onChanged: (value) {
            setState(() {
              isTamil = value;
              selectedAlphabet = '';
            });
          },
        ),
      ],
    );
  }

  Widget listView() {
    List<Contact> list = contacts.where((c) {
      String firstLetter = c.displayName.characters.firstOrNull ?? '';
      return selectedAlphabet.isEmpty ? true : firstLetter == selectedAlphabet;
    }).toList();
    return ListView.builder(
      physics: BouncingScrollPhysics(),
      shrinkWrap: true,
      controller: _scrollController,
      itemCount: list.length,
      itemBuilder: (context, index) {
        final Contact contact = list[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100),
            ),
          ),
          child: ListTile(
            title: Text(
              contact.displayName,
              style: TextStyle(
                fontSize: 35,
              ),
            ),
            trailing: callButton(contact.phones.first.number),
          ),
        );
      },
    );
  }

  Widget callButton(String number) {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.green.shade800,
      child: IconButton(
        icon: Icon(Icons.call, color: Colors.white),
        onPressed: () async {
          final DirectDialer dialer = await DirectDialer.instance;
          await dialer.dial(number);
        },
      ),
    );
  }

  Future<void> loadContacts() async {
    try {
      await Permission.contacts.request();
      _isLoading = true;
      if (mounted) setState(() {});
      final sw = Stopwatch()..start();
      _contacts = await FastContacts.getAllContacts();
      sw.stop();
    } on PlatformException catch (e) {
      'Failed to get contacts:\n${e.details}';
    } finally {
      _isLoading = false;
    }
    if (!mounted) return;
    setState(() {});
  }
}
