import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:mychatbot/ChatService.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

class LanguageTutorBot extends StatefulWidget {
  const LanguageTutorBot({super.key});

  @override
  State<LanguageTutorBot> createState() => _LanguageTutorBotState();
}

class _LanguageTutorBotState extends State<LanguageTutorBot> {
  TextEditingController _controller = TextEditingController();
  var results = "results to be shown here!";
  List<Map<String, Object>> chatHistory = [];
  List<ChatMessage> messages = [];
  ChatService chatService = ChatService();
  FlutterTts flutterTts = FlutterTts();
  final ImagePicker picker = ImagePicker();
  Color fgColor = Color(0xff75d3ff);
  Color bgColor = Color(0xff090d47);


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // exploreTTS();
  }


  bool isImageSelected = false;
  late File selectedFile;
  pickImage() async{
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image == null)
      return;
    isImageSelected = true;
    selectedFile = File(image.path);
    messages.insert(
      0,
      ChatMessage(
          user: myUser, createdAt: DateTime.now(),
          medias: [ChatMedia(url: image.path, fileName: "gemini.png", type: MediaType.image)]
      ),
    );
    setState(() {
      messages;
    });
  }

  exploreTTS() async {
    List<dynamic> languages = await flutterTts.getLanguages;
    languages.forEach((language){
      print("language = $language");
    });
    flutterTts.setLanguage("en-US");
    List<dynamic> voices = await flutterTts.getVoices;
    voices.forEach((voice){
      print("voice = ${voice.toString()}");
    });
    await flutterTts.setVoice({"name": "Google US English", "locale": "en-US"});
  }

  askGemini() async {
    var inputText = _controller.text;
    chatHistory.add({
      "role": "user",
      "parts": [
        {"text": inputText},
      ],
    });
    messages.insert(
      0,
      ChatMessage(user: myUser, createdAt: DateTime.now(), text: inputText),
    );
    setState(() {
      messages;
    });
    _controller.clear();
    results = await chatService.askGemini(chatHistory);
    chatHistory.add({
      "role": "model",
      "parts": [
        {"text": results},
      ],
    });
    messages.insert(
      0,
      ChatMessage(user: gemini, createdAt: DateTime.now(), text: results),
    );
    setState(() {
      isLoading = false;
      messages;
    });
    if(isTTS){
      flutterTts.speak(results);
    }
  }

  generateImage() async {
    var inputText = _controller.text;

    messages.insert(
      0,
      ChatMessage(user: myUser, createdAt: DateTime.now(), text: inputText),
    );
    setState(() {
      messages;
    });
    _controller.clear();
    if(isImageSelected){
      results = await chatService.editImage(inputText, selectedFile);
      isImageSelected = false;
    }
    else {
      results = await chatService.generateImage(inputText);
    }
    // var bytes = convert.base64Decode(results);
    // var dir = await getTemporaryDirectory();
    // final file = File("${dir.path}/gemini${DateTime.now().millisecondsSinceEpoch}.png");
    // file.writeAsBytes(bytes);
    // messages.insert(
    //   0,
    //   ChatMessage(
    //     user: gemini, createdAt: DateTime.now(),
    //     medias: [ChatMedia(url: file.path, fileName: "gemini.png", type: MediaType.image)]
    //   ),
    // );
    // setState(() {
    //   messages;
    // });
// Temporarly...
    chatHistory.add({
      "role": "model",
      "parts": [
        {"text": results},
      ],
    });
    messages.insert(
      0,
      ChatMessage(user: gemini, createdAt: DateTime.now(), text: results),
    );
    setState(() {
      isLoading = false;
      messages;
    });
    if(isTTS){
      flutterTts.speak(results);
    }
  }

  ChatUser myUser = ChatUser(id: "1", firstName: "Spark", lastName: "the dog",);
  ChatUser gemini = ChatUser(id: "2", firstName: "Tom", profileImage: "http://images.seeklogo.com/logo-png/62/2/google-gemini-icon-logo-png_seeklogo-623016.png");
  bool isTTS = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: fgColor,
          title: Text("Language Tutor", style: TextStyle(color: Colors.white)),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(child: Icon(isTTS?Icons.record_voice_over:Icons.voice_over_off,color: Colors.white,), onTap: (){
                if(isTTS){
                  flutterTts.stop();
                }
                setState(() {
                  isTTS = !isTTS;
                });
              },),
            )
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: DashChat(
                      currentUser: myUser,
                      onSend: (m) {},
                      messages: messages,
                      messageOptions: MessageOptions(
                        messageTextBuilder: (message, previousMessage, nextMessage) {
                          // You can detect if this message is from the bot or user
                          bool isUserMessage = message.user.id == myUser.id;

                          return Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isUserMessage ? Colors.white : Colors.blue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: MarkdownBody(  // <- render the message.text as Markdown
                              data: message.text ?? "",
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                h1: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black ,
                                ),
                                h2: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:Colors.black,
                                ),
                                h3: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black ,
                                ),
                                listBullet: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black ,
                                ),
                              ),
                            ),
                          );
                        },
                        currentUserContainerColor: Colors.white,
                        containerColor: Colors.blue,
                        currentUserTextColor: Colors.black,
                        textColor: Colors.black,
                      ),
                      readOnly: true,
                    ),
                  ),
                ),
                Container(
                  height: 50,
                  margin: EdgeInsets.only(left: 15, right: 15),
                  child: Card(
                    color: fgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              pickUnderstandImage();
                            },
                            icon: Icon(Icons.image, color: Colors.blue[900], size: 20,),
                          ),
                          IconButton(
                            onPressed: () {
                              pickDocument();
                            },
                            icon: Icon(Icons.file_copy, color: Colors.blue[900], size: 20,),
                          ),
                          IconButton(
                            onPressed: () {
                              pickAudio();
                            },
                            icon: Icon(Icons.audiotrack, color: Colors.blue[900], size: 20,),
                          ),
                          IconButton(
                            onPressed: () {
                              pickVideo();
                            },
                            icon: Icon(Icons.video_camera_back, color: Colors.blue[900], size: 20,),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  color: Colors.white,
                  margin: EdgeInsets.only(left: 15, bottom: 15, right: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            pickImage();
                          },
                          icon: Icon(Icons.attach_file, color: Colors.blue[900]),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              filled: false,
                              hintText: "ask here",
                              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.transparent)),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                            });
                            if(isImageSelected || _controller.text.startsWith("generate image")){
                              generateImage();
                            }
                            else if(isUnderstandingImageSelected || isDocumentSelected || isAudioSelected || isVideoSelected){
                              understandFiles();
                            }
                            else{
                              askGemini();
                            }
                          },
                          icon: Icon(Icons.send, color: Colors.blue[900]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            (isLoading && messages.isEmpty) || messages.isEmpty?Center(child: Padding(
              padding: const EdgeInsets.only(bottom: 90.0),
              child: Lottie.asset('assets/langAnim.json'),
            )) : Container()
          ],
        ),
      ),
    );
  }
  bool isUnderstandingImageSelected = false;
  pickUnderstandImage() async{
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image == null)return;
    isUnderstandingImageSelected = true;
    isImageSelected = true;
    selectedFile = File(image.path);
    messages.insert(
      0,
      ChatMessage(
          user: myUser, createdAt: DateTime.now(),
          medias: [ChatMedia(url: image.path, fileName: "gemini.png", type: MediaType.image)]
      ),
    );
    setState(() {
      messages;
    });
  }

  bool isDocumentSelected = false;
  pickDocument() async{
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null) {
      selectedFile = File(result.files.single.path!);
      isDocumentSelected = true;
      isUnderstandingImageSelected =false;
      messages.insert(
        0,
        ChatMessage(
            user: myUser, createdAt: DateTime.now(),
            medias: [ChatMedia(url: selectedFile.path, fileName: "gemini.pdf", type: MediaType.file)]
        ),
      );
      setState(() {
        messages;
      });
    } else {
      // User canceled the picker
    }
  }

  bool isAudioSelected = false;
  pickAudio() async{
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.audio);

    if (result != null) {
      selectedFile = File(result.files.single.path!);
      isAudioSelected = true;
      isDocumentSelected = false;
      isUnderstandingImageSelected =false;
      messages.insert(
        0,
        ChatMessage(
            user: myUser, createdAt: DateTime.now(),
            medias: [ChatMedia(url: selectedFile.path, fileName: "gemini.mp3", type: MediaType.file)]
        ),
      );
      setState(() {
        messages;
      });
    } else {
      // User canceled the picker
    }
  }

  bool isVideoSelected = false;
  pickVideo() async{
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.video);

    if (result != null) {
      selectedFile = File(result.files.single.path!);
      isVideoSelected =true;
      isAudioSelected = false;
      isDocumentSelected = false;
      isUnderstandingImageSelected =false;
      messages.insert(
        0,
        ChatMessage(
            user: myUser, createdAt: DateTime.now(),
            medias: [ChatMedia(url: selectedFile.path, fileName: "gemini.mp4", type: MediaType.video)]
        ),
      );
      setState(() {
        messages;
      });
    } else {
      // User canceled the picker
    }
  }

  understandFiles() async {
    var inputText = _controller.text;

    messages.insert(
      0,
      ChatMessage(user: myUser, createdAt: DateTime.now(), text: inputText),
    );
    setState(() {
      messages;
    });
    _controller.clear();
    if(isUnderstandingImageSelected){
      results = await chatService.understandImage(inputText, selectedFile);
      isUnderstandingImageSelected = false;
    }else if(isDocumentSelected){
      results = await chatService.understandDocument(inputText, selectedFile);
      isDocumentSelected =false;
    }else if(isAudioSelected){
      results = await chatService.understandAudio(selectedFile,inputText);
      isAudioSelected = false;
    }else if(isVideoSelected){
      results = await chatService.understandVideo(selectedFile,inputText);
      isVideoSelected = false;
    }
    messages.insert(
      0,
      ChatMessage(
          user: gemini, createdAt: DateTime.now(), text: results
      ),
    );
    setState(() {
      messages;
    });
// Temporarly...
    chatHistory.add({
      "role": "model",
      "parts": [
        {"text": results},
      ],
    });
    messages.insert(
      0,
      ChatMessage(user: gemini, createdAt: DateTime.now(), text: results),
    );
    setState(() {
      isLoading = false;
      messages;
    });
    if(isTTS){
      flutterTts.speak(results);
    }
  }
}
