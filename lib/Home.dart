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
    return Column(
      children: [
        // langaugeSwitch(),

        listView(),
        filterBoard(),
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

    return Container(
      height: 350,
      color: const Color.fromARGB(255, 47, 1, 26),
      child: GridView.builder(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 2,
        ),
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
                // borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Text(
                a,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontSize: 22,
                ),
              ),
            ),
          );
        },
      ),
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
      String fullName = c.displayName;
      // String firstLetter = fullName.characters.firstOrNull ?? '';
      return selectedAlphabet.isEmpty ? true : fullName.contains(selectedAlphabet);
      // firstLetter == selectedAlphabet;
    }).toList();
    return Expanded(
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        controller: _scrollController,
        itemCount: list.length,
        itemBuilder: (context, int index) {
          final Contact contact = list[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 0.25,
                  color: Colors.yellow.withOpacity(0.25),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${index + 1}. ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: _highlightAlphabet(contact.displayName),
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                callButton(contact.phones.first.number),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget callButton(String number) {
    return CircleAvatar(
      // radius: 15,
      backgroundColor: Colors.green.shade800,
      child: IconButton(
        icon: Icon(
          Icons.call,
          size: 18,
          color: Colors.white,
        ),
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

  List<InlineSpan> _highlightAlphabet(String displayName) {
    if (selectedAlphabet.isEmpty) {
      return [TextSpan(text: displayName)];
    }
    final matches = RegExp(RegExp.escape(selectedAlphabet)).allMatches(displayName);
    if (matches.isEmpty) {
      return [TextSpan(text: displayName)];
    }
    List<InlineSpan> spans = [];
    int last = 0;
    for (final match in matches) {
      if (match.start > last) {
        spans.add(TextSpan(text: displayName.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: displayName.substring(match.start, match.end),
        style: TextStyle(
          backgroundColor: Colors.yellow.withOpacity(0.15),
          color: Colors.white,
        ),
      ));
      last = match.end;
    }
    if (last < displayName.length) {
      spans.add(TextSpan(text: displayName.substring(last)));
    }
    return spans;
  }
}
