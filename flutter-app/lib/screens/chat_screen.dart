import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/side_menu.dart';
import '../widgets/buttons.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _controller = TextEditingController();
  ScrollController _scrollController = ScrollController();
  int _buttonSet = 0;
  // List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Escuchar el proveedor para desplazarse cuando cambia el estado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BluetoothProvider>(context, listen: false).addListener(_scrollToBottom);
    });
  }

  void _sendMessage() {
    String message = _controller.text.trim();
    if (message.isNotEmpty) {
      Provider.of<BluetoothProvider>(context, listen: false).sendMessage(message);
      _scrollToBottom();
    }
  }

  void _sendPredefinedMessage(String message) {
    Provider.of<BluetoothProvider>(context, listen: false).sendMessage(message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Control"),
        actions: [
          Consumer<BluetoothProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(provider.isConnected
                    ? Icons.bluetooth_connected
                    : provider.isConnecting
                    ? Icons.bluetooth_searching
                    : Icons.bluetooth_disabled),
                color: provider.isConnected
                    ? Colors.green
                    : provider.isConnecting
                    ? Colors.white
                    : Colors.red,
                onPressed: () {
                  if (!provider.isConnecting && !provider.isConnected) {
                    // provider.connectToHC08();
                    provider.connectToLastDevice();
                  }
                  if (provider.isConnected){
                    provider.disconnectDevice();
                  }
                },
              );
            },
          ),
          Consumer<BluetoothProvider>(
            builder: (context, provider, _) {
              return IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                  provider.clearMessages();
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      drawer: SideMenu(),
      body: Consumer<BluetoothProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(
                      message: provider.messages[index]["message"],
                      isSentByMe: provider.messages[index]["isSentByMe"],
                    );
                  },
                ),
              ),
              if (provider.isGenerating)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Generando CSV...",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              ControlButtons(buttonSet: _buttonSet),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Enter a message...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: IconTheme(
          data: IconThemeData(color: primaryColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
            IconButton(
              tooltip: 'Estado',
              icon: const Icon(Icons.home),
              onPressed: () {
                setState(() {
                  _buttonSet = 0;
                });
              },
            ),
              IconButton(
                tooltip: 'On/Off',
                icon: const Icon(Icons.power_settings_new),
                onPressed: () {
                  setState(() {
                    _buttonSet = 1;
                  });
                },
              ),
            IconButton(
              tooltip: 'Calibración',
              icon: Icon(Icons.build_outlined),
              // icon: SvgPicture.asset('assets/icons/ph-meter-lab.svg',
              //   color: primaryColor,
              //   height: 25,
              //   width: 25,),
              onPressed: () {
                setState(() {
                  _buttonSet = 2;
                });
              },
            ),
            // IconButton(
            //   tooltip: 'Calibrate OD',
            //   icon: const Icon(Icons.bubble_chart_outlined),
            //   onPressed: () {
            //     setState(() {
            //       _buttonSet = 1;
            //     });
            //   },
            // ),
            IconButton(
              tooltip: 'Sensores',
              icon: const Icon(Icons.sensor_window),
              onPressed: () {
                setState(() {
                  _buttonSet = 3;
                });
              },
            ),
            IconButton(
              tooltip: 'Sensado',
              icon: const Icon(Icons.science),
              onPressed: () {
                setState(() {
                  _buttonSet = 4;
                });
              },
            ),
            IconButton(
              tooltip: 'Manejo de datos',
              icon: const Icon(Icons.description),
              onPressed: () {
                setState(() {
                  _buttonSet = 5;
                });
              },
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isSentByMe;

  ChatBubble({required this.message, required this.isSentByMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isSentByMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: SelectableText(
          message,
          style: TextStyle(color: isSentByMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}

