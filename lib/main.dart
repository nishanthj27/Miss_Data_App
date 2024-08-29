import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Miss Data',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => FileSelectionScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 1.0, end: 0.0),
          duration: Duration(seconds: 3),
          builder: (BuildContext context, double value, Widget? child) {
            return Opacity(
              opacity: value,
              child: child,
            );
          },
          child: Text(
            'Welcome to Miss Data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class FileSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select File'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            String? filePath = await _pickFile();
            if (filePath != null) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => FileProcessingScreen(filePath: filePath)));
            }
          },
          child: Text('Select CSV or Excel File'),
        ),
      ),
    );
  }

  Future<String?> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    if (result != null) {
      return result.files.single.path;
    }
    return null;
  }
}

class FileProcessingScreen extends StatefulWidget {
  final String filePath;

  FileProcessingScreen({required this.filePath});

  @override
  _FileProcessingScreenState createState() => _FileProcessingScreenState();
}

class _FileProcessingScreenState extends State<FileProcessingScreen> {
  bool _processing = false;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> _processFile() async {
  setState(() {
    _processing = true;
  });

  String fileContent = await File(widget.filePath).readAsString();
  List<List<dynamic>> csvTable = CsvToListConverter().convert(fileContent);

  String additionalInfo = _textEditingController.text; // Get additional text from the user
  
  for (int i = 0; i < csvTable.length; i++) {
    for (int j = 0; j < csvTable[i].length; j++) {
      if (csvTable[i][j] == '' || csvTable[i][j] == '??' || csvTable[i][j] == '????' || csvTable[i][j] == additionalInfo) {
        csvTable[i][j] = 'NaN'; // Replace empty strings, additionalInfo, and '??', '????' with 'NaN'
      }
    }
  }

  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => FileDownloadScreen(csvData: csvTable)));
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Processing File'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _textEditingController,
              decoration: InputDecoration(
                labelText: 'Enter anyother values to be replaced:',
              ),
            ),
            SizedBox(height: 20),
            _processing
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _processFile,
                    child: Text('Process File'),
                  ),
          ],
        ),
      ),
    );
  }
}

class FileDownloadScreen extends StatelessWidget {
  final List<List<dynamic>> csvData;

  FileDownloadScreen({required this.csvData});

  Future<void> _downloadProcessedFile(BuildContext context) async {
  try {
    // Convert processed data to CSV format
    String csvString = ListToCsvConverter().convert(csvData);

    // Get the Download directory
    Directory downloadDirectory = Directory('/storage/emulated/0/Download');
    if (!(await downloadDirectory.exists())) {
      await downloadDirectory.create(recursive: true);
    }

    String filePath = '${downloadDirectory.path}/processed_file.csv';

    // Write CSV data to a file in the Download directory
    File file = File(filePath);
    await file.writeAsString(csvString);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('File Downloaded'),
          content: Text('The processed file has been downloaded to: $filePath'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  } catch (e) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Failed to download the file: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download File'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _downloadProcessedFile(context),
          child: Text('Download Processed File'),
        ),
      ),
    );
  }
}
