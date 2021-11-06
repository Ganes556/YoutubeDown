import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'animated_toggle.dart';
import 'package:get/get.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: "YoutubeDown",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF280002),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.white,
        ),
      ),
      home: HomeMain(),
    );
  }
}

class HomeMain extends StatefulWidget {
  @override
  _HomeMainState createState() => _HomeMainState();
}

class _HomeMainState extends State<HomeMain> {
  final txt = TextEditingController();
  int _toggleValue = 0;
  bool _urlNotValid = false;
  bool freeze = false;
  String title = "";
  String id = "";

  @override
  void dispose() {
    // * Clean up the controller when the widget is disposed.
    txt.dispose();
    super.dispose();
  }

  void actionTextSubmitted() {
    try {
      var uri = Uri.parse(txt.text);

      if (uri.isScheme("https") && uri.host.contains("youtube")) {
        if (uri.queryParameters.keys.first == "v" &&
            uri.queryParameters.values.first.isNotEmpty) {
          String idVid = uri.queryParameters.values.first;

          ytManifest(idVid);
          id = idVid;
          _urlNotValid = false;
        }
      } else
        reset();
    } on Exception {}
    ;
  }

  void reset({bool clear = false}) {
    setState(() {
      if (clear) {
        txt.clear();
      }
      title = "Url tidak valid!";
      _urlNotValid = true;
    });
  }

  void wait() {
    setState(() {
      title = "Tunggu...";
    });
  }

  Future<void> ytManifest(String idVid) async {
    try {
      var yt = YoutubeExplode();
      wait();
      var metadata = await yt.videos.get(idVid);
      // ? get
      setState(() {
        var temp = metadata.duration.toString().split(":");
        var duration =
            "Durasi: ${temp[0]} jam ${temp[1]} menit ${double.parse(temp[2]).ceil()} detik";
        title = metadata.title + "\n" + duration;
        _urlNotValid = false;
      });
      yt.close();
    } catch (e) {
      setState(() {
        title = "Tidak ditemukan!";
      });
    }
  }

  Future<void> ytDownload(String idVid) async {
    // ? get status permission
    var status = await Permission.storage.status;
    if (status.isDenied) await Permission.storage.request();
    // ? wait
    setState(() {
      title = "Tunggu...";
      freeze = true;
    });
    var yt = YoutubeExplode();
    var metadata = await yt.videos.get(idVid);
    var manifest = await yt.videos.streamsClient.getManifest(idVid);
    var streams;
    // * audio
    if (_toggleValue == 0) {
      streams = manifest.audioOnly.withHighestBitrate();
      // * video
    } else {
      streams = manifest.muxed.withHighestBitrate();
    }

    // var audioStream = yt.videos.streamsClient.get(streams);
    var fileNames = '${metadata.title}.${streams.container.name.toString()}'
        .replaceAll(r'\', '')
        .replaceAll('/', '')
        .replaceAll('*', '')
        .replaceAll('?', '')
        .replaceAll('"', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('|', '');

    Directory('/storage/emulated/0/Download/').createSync();

    var file = File('/storage/emulated/0/Download/$fileNames');
    if (file.existsSync()) {
      file.deleteSync();
    }

    // ? progress
    var len = streams.size.totalBytes;
    var count = 0;

    var output = file.openWrite(mode: FileMode.writeOnlyAppend);
    var stream = yt.videos.streamsClient.get(streams);
    // await stream.pipe(ouput);
    await for (final data in stream) {
      count += data.length;
      setState(() {
        int persen = ((count / len) * 100).ceil();
        title = "Mengunduh...$persen%";
      });
      output.add(data);
      // await stream.pipe(output);
    }
    setState(() {
      title = "Selesai!";
      freeze = false;
    });
    await output.flush();
    await output.close();
    yt.close();
  }

  // Future<void> ytTitle(String idVid) async {
  //   var yt = YoutubeExplode();
  //   var manifest = await yt.videos.get(idVid);
  //   setState(() {
  //     title = manifest.title;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 20);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SizedBox(
          height: Get.height * 0.65,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              toggleAndText()["toggle"],
              toggleAndText()["textDownload"],
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  toggleAndText()["textTitle"],
                  gap,
                  textField(),
                ],
              ),
              btnDownload(),
            ],
          ),
        ),
      ),
    );
  }

  toggleAndText() {
    var toggle = AnimatedToggle(
      values: const ['mp3', 'mp4'],
      onToggleCallback: (value) {
        setState(() {
          _toggleValue = value;
        });
      },
    );
    // ? text unduh
    var textDownload = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Unduh ',
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 30,
            ),
          ),
        ),
        (_toggleValue == 0)
            ? Icon(Icons.audiotrack_outlined, color: Colors.white, size: 60)
            : Icon(Icons.slow_motion_video_rounded,
                color: Colors.white, size: 60)
      ],
    );
    // ? text title
    var textTitle = Text(
      (title != "") ? title : "",
      textAlign: TextAlign.center,
      style: GoogleFonts.robotoMono(
        textStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
    return {
      "textDownload": textDownload,
      "textTitle": textTitle,
      "toggle": toggle
    };
  }

  textField() {
    // * hint style
    var hintStyle = GoogleFonts.roboto(
        textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Color(0xFFE88493)));
    // * outline border
    var outLineBorder = OutlineInputBorder(
        borderSide: BorderSide.none, borderRadius: BorderRadius.circular(5));
    // * content padding
    var contentPadding = EdgeInsets.only(
        left: Get.width * 0.1, top: Get.width * 0.03, bottom: Get.width * 0.03);
    // ! return value
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Get.width * 0.1),
      child: TextField(
        enabled: (freeze) ? !freeze : true,
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.left,
        onChanged: (v) => actionTextSubmitted(),
        controller: txt,
        decoration: InputDecoration(
          // errorText: _urlNotValid ? "Url not valid!" : null,
          border: outLineBorder,
          suffixIcon: IconButton(
            onPressed: () => reset(clear: true),
            color: Colors.white,
            icon: Icon(Icons.clear),
          ),
          // ? alignment content of textfield
          contentPadding: contentPadding,
          fillColor: const Color(0xFFEF4A62),
          filled: true,
          hintText: "Paste Link Here",
          hintStyle: hintStyle,
        ),
      ),
    );
  }

  btnDownload() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Get.width * 0.2),
      child: ElevatedButton(
        style: TextButton.styleFrom(
            primary: Colors.white,
            backgroundColor: Color(0xFFEF4A62),
            minimumSize: Size(Get.width * 0.2361111111111111, Get.width / 8)),
        onPressed: () => (id != "") ? ytDownload(id) : null,
        child: Text(
          "Download",
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
