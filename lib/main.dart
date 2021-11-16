import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_down/Style/my_colors.dart';
import 'package:youtube_down/Style/text_style.dart';
import 'package:youtube_down/models/youtube.dart';
import 'animated_toggle.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

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
  final videoURL = TextEditingController();
  var datas = {};
  int _toggleValue = 0;
  bool freeze = false;
  String title = "";

  Map<String, String> headers = {
    "X-Requested-With": "XMLHttpRequest",
  };

  Map<String, String>? body;
  void insertBody(String videoURL) {
    body = {"url": videoURL, "ajax": "1"};
  }

  @override
  void dispose() {
    // * Clean up the controller when the widget is disposed.
    videoURL.dispose();
    super.dispose();
  }

  // ? action text changed
  Future<void> ytActionTextChanged() async {
    insertBody(videoURL.text);
    setState(() {
      title = "Tunggu...";
    });

    try {
      var response = await http.post(
          Uri.parse("https://www.y2mate.com/mates/downloader/ajax"),
          body: {"url": videoURL.text, "ajax": "1"},
          headers: headers);

      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        datas = Result.convertResult(data["result"]);
        setState(() {
          String temp = datas["duration"].split(":");
          var duration =
              "Durasi: ${temp[0]} jam ${temp[1]} menit ${double.parse(temp[2]).ceil()} detik";
          title = datas["v_title"] + "\n" + duration;
        });
      }
    } on SocketException catch (e) {
      setState(() {
        title = "Pastikan Anda terhubung dengan internet!";
      });
    } catch (e) {
      setState(() {
        title = "Url tidak valid!";
      });
    }
  }

  // ? reset
  void reset({bool clear = false}) {
    setState(() {
      if (clear) {
        videoURL.clear();
      }
      title = "Url tidak valid!";
    });
  }

  // ? ytDownloadAction
  Future<void> ytBtnDownloadAction() async {
    try {
      // * default audio
      var bodies = {
        "type": "youtube",
        "_id": datas['id'],
        "v_id": datas['v_id'],
        "ajax": "1",
        "token": "",
        "ftype": "mp3",
        "fquality": "128",
      };
      // * video
      if (_toggleValue == 1) {
        bodies["ftype"] = "mp4";
        bodies["fquality"] = "480";
      }

      var response = await http.post(
          Uri.parse("https://www.y2mate.com/mates/convert"),
          body: bodies);

      String tempUrl = RegExp(r'"http.*?"')
          .stringMatch(response.body)
          .toString()
          .replaceAll('"', "");
      if (tempUrl == "null") {
        setState(() {
          title = "Coba lagi nanti!";
        });
        return;
      }
      String urlDownload = Uri.decodeFull(tempUrl);
      downloadVideo(urlDownload.replaceAll("\\", ""));
    } catch (e) {
      setState(() {
        title = "Coba lagi nanti!";
      });
    }
  }

  Future<void> downloadVideo(urlDownload) async {
    setState(() {
      title = "Tunggu...";
      freeze = true;
    });
    var status = await Permission.storage.status;
    if (status.isDenied) await Permission.storage.request();
    try {
      Dio dio = Dio();
      var fileName = (_toggleValue == 0)
          ? "${datas['v_title']}.mp3"
          : "${datas['v_title']}'.mp4";
      Directory('/storage/emulated/0/Download/YoutubeDown/').createSync();
      var file = File('/storage/emulated/0/Download/YoutubeDown/$fileName');
      if (file.existsSync()) {
        file.deleteSync();
      }
      await dio.download(
        urlDownload,
        "/storage/emulated/0/Download/YoutubeDown/$fileName",
        onReceiveProgress: (rec, total) => {
          setState(() {
            title =
                "Mengunduh..." + ((rec / total) * 100).toStringAsFixed(0) + "%";
          })
        },
      );
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            width: double.infinity,
            height: Get.height * 0.4,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2.0),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xff730006),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: double.infinity * 0.2,
                    child: ElevatedButton(
                      onPressed: null,
                      child: Text(
                        "Pemberitahuan",
                        style: GoogleFonts.robotoMono(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                          ),
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(
                            primary500.withOpacity(0.74)),
                        padding: MaterialStateProperty.all<EdgeInsets>(
                            const EdgeInsets.symmetric(vertical: 10)),
                      ),
                    ),
                  ),
                  // ? text
                  Text(
                    'Unduh selesai ^_^, audio atau video secara otomatis disimpan pada penyimpanan internal di folder Download/YoutubeDown/',
                    style: GoogleFonts.robotoMono(
                      textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // ? closed btn
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Tutup",
                      style: GoogleFonts.robotoMono(
                        textStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: primary500.withOpacity(0.67),
                    ),
                  ),
                ]),
          ),
        ),
      );
      setState(() {
        title = "";
        freeze = false;
      });
    } catch (e) {
      setState(() {
        title = "Coba lagi nanti!";
      });
    }
  }

  // ! main
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
              btnDownload(context),
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
        RobotoMonoText(
          'Unduh ',
          textAlign: TextAlign.center,
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 30,
        ),
        (_toggleValue == 0)
            ? const Icon(Icons.headphones_outlined,
                color: Colors.white, size: 60)
            : const Icon(Icons.smart_display_outlined,
                color: Colors.white, size: 60)
      ],
    );
    // ? text title
    var textTitle = RobotoMonoText(
      (title != "") ? title : "",
      textAlign: TextAlign.center,
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 18,
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
            fontSize: 18, fontWeight: FontWeight.w400, color: primary300));
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
        onChanged: (v) => ytActionTextChanged(), // mainActionTextChanged(),
        controller: videoURL,
        decoration: InputDecoration(
          // errorText: _urlNotValid ? "Url not valid!" : null,
          border: outLineBorder,
          suffixIcon: IconButton(
            onPressed: () => reset(clear: true),
            color: Colors.white,
            icon: const Icon(Icons.clear),
          ),
          // ? alignment content of textfield
          contentPadding: contentPadding,
          fillColor: primary400,
          filled: true,
          hintText: "Tempel Urlnya Disini",
          hintStyle: hintStyle,
        ),
      ),
    );
  }

  btnDownload(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Get.width * 0.2),
      child: ElevatedButton(
        style: TextButton.styleFrom(
            primary: Colors.white,
            backgroundColor: primary400,
            minimumSize: Size(Get.width * 0.2361111111111111, Get.width / 8)),
        onPressed: () =>
            ytBtnDownloadAction(), // btnDownloadMainAction(context)
        child: Text(
          "Unduh",
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
