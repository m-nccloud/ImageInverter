import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Inverter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File imageFile = File("");
  int _inversionShape = 0;
  double _sliderCurr = 0;
  double _sliderMin = 0;
  double _sliderMax = 100;
  String _inversionLabel = "Inversion Width";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Image Inverter'),
        ),
        body: Center(
            child: Column(children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  openFileManager();
                },
                child: Text('Select Image to Invert'),
              ),
              Text("Select Inversion Shape: \tBox"),
              Radio(
                  value: 0,
                  groupValue: _inversionShape,
                  onChanged: (value) {
                    setState(() {
                      _inversionShape = value!;
                      _inversionLabel = "Inversion Width";
                    });
                  }),
              Text("Rect"),
              Radio(
                  value: 1,
                  groupValue: _inversionShape,
                  onChanged: (value) {
                    setState(() {
                      _inversionShape = value!;
                      _inversionLabel = "Inversion Width";
                    });
                  }),
              Text("Circle"),
              Radio(
                  value: 2,
                  groupValue: _inversionShape,
                  onChanged: (value) {
                    setState(() {
                      _inversionShape = value!;
                      _inversionLabel = "Inversion Radius";
                    });
                  })
            ],
          ),
          Visibility(
              visible: imageFile.path != "",
              child: Column(
                children: [
                  Image.file(imageFile),
                  Slider(
                      value: _sliderCurr,
                      min: _sliderMin,
                      max: _sliderMax,
                      onChanged: (val) {
                        setState(() {
                          _sliderCurr = val;
                        });
                      }),
                  Text('$_inversionLabel: ${_sliderCurr.floor()}')
                ],
              )),
        ])));
  }

  Future<File> openFileManager() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        imageFile = File(result.files.single.path!);
      });
      print(imageFile.path);
    }
    return imageFile;
  }

  void setInversionShape(int selection) {
    _inversionShape = selection;
  }
}
