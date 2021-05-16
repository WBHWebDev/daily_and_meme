import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Daily and Meme',
      builder: (context, child) {
        double myResponsiveFontSize = MediaQuery.of(context).size.height / myFontSizeScaleFactor;
        return Theme(
          data: ThemeData(
            backgroundColor: Colors.amber,
            scaffoldBackgroundColor: Colors.blueGrey,
            bottomAppBarColor: Colors.amber,
            dialogBackgroundColor: Colors.blueGrey,
            primarySwatch: Colors.amber,
            textTheme: GoogleFonts.robotoMonoTextTheme(textTheme).copyWith(
              bodyText1: GoogleFonts.robotoMono(fontSize: myResponsiveFontSize),
              bodyText2: GoogleFonts.robotoMono(fontSize: myResponsiveFontSize),
              caption: GoogleFonts.robotoMono(fontSize: myResponsiveFontSize),
              button: GoogleFonts.robotoMono(fontSize: myResponsiveFontSize),
              headline6: GoogleFonts.robotoMono(fontSize: myResponsiveFontSize),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(primary: Colors.amber),
            ),
            // primaryColor only for appbar on smartphone?
            primaryColor: Colors.blueGrey,
          ),
          child: child!,
        );
      },
      initialRoute: "/",
      routes: {
        "/": (context) => HomePage(),
        "timer": (context) => TimerPage(),
        "meme": (context) => MemePage(),
        "work": (context) => WorkPage(),
        "zebra": (context) => ZebraPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

// global variables are fun
int nMeetingMinutes = 15;
Duration durationPerPerson = Duration(seconds: 1);
int currentSpeaker = 0;
bool isTimePaused = false;
Duration durationExtraTime = Duration(seconds: 30);
bool isExtraTime = false;
// styling
Color color1 = Color(0xff004489);
Color color2 = Color(0xffF9B200);
Color colorPaused = Colors.black;
// gets overwritten by mediaquery
double myFontSizeScaleFactor = 30;
// meme stuff
int magicNumberForMemeHeight = 32 + 32 + 0 + 16 + 32 + 32 + 8 + 32 + 8 + 100;
int memeCounter = 0;
String currentMemeTitle = "";
String currentMemeImage = "";
bool isLanguageGerman = false;
String githubURL = "https://github.com/mw3155/DailyAndMeme";

List<String> meetingPersons = ["Sebastian", "Florian", "Markus", "Thomas", "Alex"];
String newMeetingPerson = "";

Widget buildBottomSheet() {
  return AnimatedContainer(
    duration: Duration(seconds: 1),
    color: isTimePaused ? colorPaused : Colors.blueGrey,
    padding: EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          color: Colors.black,
          tooltip: "Zebra",
          icon: Icon(Icons.audiotrack),
          iconSize: 32,
          onPressed: () {
            navigatorKey.currentState?.pushNamed("zebra");
          },
        ),
        IconButton(
          color: Colors.black,
          icon: Icon(Icons.home),
          tooltip: "Zur Startseite",
          iconSize: 32,
          onPressed: () {
            // TODO reset global vars
            navigatorKey.currentState?.pushNamed("/");
          },
        ),
        IconButton(
          color: Colors.black,
          icon: Icon(Icons.pest_control),
          tooltip: "Github",
          iconSize: 32,
          onPressed: () async {
            await canLaunch(githubURL)
                ? await launch(githubURL)
                : throw 'Could not launch $githubURL';
          },
        ),
      ],
    ),
  );
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: buildBottomSheet(),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: _buildHomepage(),
        ),
      ),
    );
  }

  Widget _buildHomepage() {
    double myResponsiveFontSize = MediaQuery.of(context).size.height / myFontSizeScaleFactor;

    return Column(
      //crossAxisAlignment: CrossAxisAlignment.center, // no effect?
      children: [
        Text(
          "Teilnehmer:",
          textAlign: TextAlign.left,
        ),
        SizedBox(
          //height: MediaQuery.of(context).size.height * 0.4,
          width: MediaQuery.of(context).size.width * 0.3,
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: meetingPersons.length,
            itemBuilder: (context, index) {
              final item = meetingPersons[index];
              return Dismissible(
                // Each Dismissible must contain a Key. Keys allow Flutter to
                // uniquely identify widgets.
                key: Key(item),
                // Provide a function that tells the app
                // what to do after an item has been swiped away.
                onDismissed: (direction) {
                  // Remove the item from the data source.
                  setState(() {
                    meetingPersons.removeAt(index);
                  });

                  // Then show a snackbar.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("RIP $item"),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                // Show a red background as the item is swiped away.
                background: Container(color: Colors.red),
                child: ListTile(
                  title: Text(
                    //TextStyle(fontSize: myResponsiveFontSize, color: Colors.amber),
                    '$item',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: myResponsiveFontSize * 0.7,
                      color: Colors.amber,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.1,
          width: MediaQuery.of(context).size.height * 0.2,
          child: TextField(
            onChanged: (String newName) {
              // TODO: this seems like a hack, how to do better?
              newMeetingPerson = newName;
            },
            onSubmitted: (value) {
              setState(() {
                meetingPersons.add(newMeetingPerson);
              });
            },
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'Neuer Teilnehmer',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              meetingPersons.shuffle();
            });
          },
          child: Icon(Icons.shuffle),
        ),
        Padding(padding: EdgeInsets.all(32)),
        Text("Gesamtdauer (Minuten):"),
        NumberPicker(
            selectedTextStyle: TextStyle(
              fontSize: myResponsiveFontSize,
              color: Colors.amber,
            ),
            value: nMeetingMinutes,
            minValue: 1,
            maxValue: 100,
            step: 1,
            haptics: true,
            axis: Axis.horizontal,
            onChanged: (newValue) => setState(() => nMeetingMinutes = newValue)),
        Padding(padding: EdgeInsets.all(32)),
        ElevatedButton(
          onPressed: () {
            int nSecondsPerPerson = nMeetingMinutes * 60 ~/ meetingPersons.length;
            durationPerPerson = Duration(seconds: nSecondsPerPerson);
            _showConfirmDialog();
          },
          child: Text(
            "Meeting starten",
          ),
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }

  Future<void> _showConfirmDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              'Es gibt ${meetingPersons.length} Teilnehmer\nJeder hat eine Redezeit von ${durationPerPerson.inMinutes} Minuten und ${durationPerPerson.inSeconds.remainder(60)} Sekunden.'),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: EdgeInsets.all(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(), child: Text("Abbrechen")),
                  ElevatedButton(
                      child: Text('Starten'),
                      onPressed: () {
                        currentSpeaker = 0;
                        Navigator.pushNamed(context, "timer");
                      }),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void updateIsSelectedList(int index, List<bool> isSelected) {
    setState(
      () {
        for (int buttonIndex = 0; buttonIndex < isSelected.length; buttonIndex++) {
          if (buttonIndex == index) {
            isSelected[buttonIndex] = true;
          } else {
            isSelected[buttonIndex] = false;
          }
        }
      },
    );
  }
}

class TimerPage extends StatefulWidget {
  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // disable going back
      onWillPop: () => Future.value(false),
      child: Scaffold(
        bottomSheet: buildBottomSheet(),
        body: Center(
          child: AnimatedContainer(
            duration: Duration(seconds: 1),
            color: isTimePaused ? colorPaused : Colors.blueGrey,
            padding: const EdgeInsets.all(32),
            child: _buildTimerPage(),
          ),
        ),
      ),
    );
  }

  late AnimationController _controller;
  late Animation<double> animation;
  late Tween<double> tween;
  bool isDismissed = false;

  @override
  void initState() {
    super.initState();

    Duration currentDuration = isExtraTime
        ? Duration(seconds: durationExtraTime.inSeconds)
        : Duration(seconds: durationPerPerson.inSeconds);

    _controller = AnimationController(
      vsync: this,
      duration: currentDuration,
    );
    tween = Tween(begin: 0, end: currentDuration.inSeconds.toDouble());
    animation = tween.animate(_controller);

    _controller.forward();

    _controller.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed) {
          _showTimerFinishedDialog();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildTimerPage() {
    // BUG: before memepage, flutter builds a timerpage again with speaker > meetingPersons; idk why...
    String speakerName =
        meetingPersons.length <= currentSpeaker ? "null" : meetingPersons[currentSpeaker];

    int totalSeconds = _controller.duration!.inSeconds;

    double memeHeight = MediaQuery.of(context).size.height -
        magicNumberForMemeHeight +
        90; // magic number + another magic number == :)
    double stepSizePerSecond = memeHeight / totalSeconds;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              alignment: Alignment.topCenter,
              child: _buildMeme(),
            ),
            AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  Duration durationLeft = Duration(seconds: totalSeconds - animation.value.toInt());
                  return Positioned(
                    top: isDismissed ? memeHeight : animation.value * stepSizePerSecond,
                    child: AnimatedContainer(
                      duration: Duration(seconds: 1),
                      color: isTimePaused ? colorPaused : Colors.blueGrey,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: Column(
                        children: [
                          Container(
                            alignment: Alignment.topCenter,
                            child: Text(
                              "${speakerName}, "
                              "du hast noch ${durationLeft.inMinutes} Min "
                              "${durationLeft.inSeconds.remainder(60)} Sek",
                              style: TextStyle(color: Colors.amber),
                            ),
                          ),
                          ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isDismissed = true;
                                });
                              },
                              child: Icon(Icons.arrow_downward)),
                        ],
                      ),
                    ),
                  );
                })
          ],
        ),
        Padding(padding: EdgeInsets.all(32)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (isTimePaused) {
                      isTimePaused = false;
                      _controller.forward();
                    } else {
                      isTimePaused = true;
                      _controller.stop();
                    }
                  });
                },
                child: Text(
                  isTimePaused ? "Fortsetzen" : "Pause",
                )),
            ElevatedButton(
              child: Text(
                "Fertig",
              ),
              onPressed: () {
                _goToNextSpeaker();
              },
            ),
          ],
        ),
      ],
    );
  }

  void _goToNextSpeaker() {
    memeCounter++;
    isExtraTime = false;
    isTimePaused = false;
    currentSpeaker++;

    currentSpeaker >= meetingPersons.length
        ? Navigator.pushNamed(context, "meme")
        : Navigator.pushNamed(context, "timer");
  }

  Future<void> _showTimerFinishedDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '${meetingPersons[currentSpeaker]}, deine Zeit ist abgelaufen',
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                child: Text(
                  "+30 Sekunden",
                ),
                onPressed: () {
                  isExtraTime = true;
                  Navigator.pushNamed(context, "timer");
                },
              ),
              ElevatedButton(
                child: Text(
                  "Fertig",
                ),
                onPressed: () => _goToNextSpeaker(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CountdownClock extends AnimatedWidget {
  // not sure what this key thing does, but "?" seems like a good fix
  CountdownClock({Key? key, required this.animation, required this.maxDuration})
      : super(key: key, listenable: animation);
  Animation<double> animation;
  Duration maxDuration;

  @override
  Widget build(BuildContext context) {
    double currentValueInSeconds = (1 - animation.value) * maxDuration.inSeconds;
    Duration currentDuration = Duration(seconds: currentValueInSeconds.toInt());

    double clockSize = MediaQuery.of(context).size.shortestSide * 0.6;

    return SizedBox(
      height: clockSize,
      child: Stack(
        children: [
          Center(
            child: Container(
              height: clockSize,
              width: clockSize,
              child: CircularProgressIndicator(
                // if animation is exactly 0, then drawArc fails
                value: (1 - animation.value) > 0.001 ? (1 - animation.value) : 0.001,
                strokeWidth: 10,
              ),
            ),
          ),
          Center(
            child: Container(
              alignment: FractionalOffset.center,
              child: Text(
                  "Du hast noch\n${currentDuration.inMinutes} Min ${currentDuration.inSeconds.remainder(60)} Sek"),
            ),
          ),
        ],
      ),
    );
  }
}

class MemePage extends StatefulWidget {
  @override
  _MemePageState createState() => _MemePageState();
}

class _MemePageState extends State<MemePage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // disable going back
      onWillPop: () => Future.value(false),
      child: Scaffold(
        bottomSheet: buildBottomSheet(),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: _buildMemePage(),
          ),
        ),
      ),
    );
  }

  Widget _buildMemeOptions() {
    // TODO: somehow stack this on top of memetitle
    return Container(
      alignment: Alignment.topRight,
      child: TextButton(
        style: TextButton.styleFrom(backgroundColor: Colors.white70),
        onPressed: () {
          setState(() {
            isLanguageGerman ^= true;
            memeCounter = 0;
          });
        },
        child: Flag(
          isLanguageGerman ? "US" : "DE",
          height: 32,
          width: 32,
          fit: BoxFit.scaleDown,
        ),
      ),
    );
  }

  Widget _buildMemePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMeme(),
        Padding(padding: EdgeInsets.all(16)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, "work"),
              child: Text(
                "Ran an die Arbeit!",
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  memeCounter++;
                });
              },
              child: Text(
                "Noch ein Meme!",
              ),
            ),
          ],
        )
      ],
    );
  }
}

Future<List<String>> fetchNextMemeTitleAndURL() async {
  // get json from programmerhumor and decode it
  String memeSite = "www.reddit.com";
  String memeSiteEnding = isLanguageGerman ? "r/ich_iel/top.json" : "/r/ProgrammerHumor/top.json";
  final response = await http.get(Uri.https(memeSite, memeSiteEnding));

  Map<String, dynamic> memeJson = jsonDecode(response.body);

  while (true) {
    bool isVideo = memeJson["data"]["children"][memeCounter]["data"]["is_video"];
    bool hasHeight = memeJson["data"]["children"][memeCounter]["data"]["thumbnail_height"] != null;
    bool isGifv = memeJson["data"]["children"][memeCounter]["data"]["url"].contains(".gifv");
    if (!isVideo && hasHeight && !isGifv) break;
    memeCounter++;
  }

  currentMemeTitle = memeJson["data"]["children"][memeCounter]["data"]["title"];
  currentMemeImage = memeJson["data"]["children"][memeCounter]["data"]["url"];

  print(currentMemeImage);
  return [currentMemeTitle, currentMemeImage];
}

class WorkPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // disable going back
      onWillPop: () => Future.value(false),
      child: Scaffold(
        bottomSheet: buildBottomSheet(),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: _buildWorkPage(),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(
          "https://media.giphy.com/media/jkSvCVEXWlOla/source.gif",
          width: 1280,
          fit: BoxFit.fill,
        ),
      ],
    );
  }
}

class ZebraPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // disable going back
      onWillPop: () => Future.value(false),
      child: Scaffold(
        bottomSheet: buildBottomSheet(),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: _buildZebraPage(),
          ),
        ),
      ),
    );
  }

  Widget _buildZebraPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(
          "https://media.giphy.com/media/10hO3rDNqqg2Xe/giphy.gif",
          width: 1280,
          fit: BoxFit.fill,
        ),
      ],
    );
  }
}

Widget _buildMemeTitleAndImage(BuildContext context) {
  return Column(
    children: [
      Container(
        alignment: Alignment.center,
        child: Text(currentMemeTitle),
      ),
      Image.network(
        currentMemeImage,
        height: MediaQuery.of(context).size.height - magicNumberForMemeHeight,
        fit: BoxFit.contain,
      ),
    ],
  );
}

Widget _buildMeme() {
  return FutureBuilder(
    builder: (context, AsyncSnapshot<List<String>> myfut) {
      if (myfut.hasData) {
        return Column(
          children: [
            _buildMemeTitleAndImage(context),
            //_buildMemeOptions(),
          ],
        );
      } else {
        return Icon(Icons.photo);
      }
    },
    future: fetchNextMemeTitleAndURL(),
  );
}
