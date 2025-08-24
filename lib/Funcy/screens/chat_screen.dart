import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../widgets/chat_message.dart';
import '../widgets/chat_box_footer.dart';
import '../widgets/custom_app_bar.dart';
import '../../config.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final int userId;
  final String username;

  ChatScreen({required this.userId, required this.username});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> messages = [];
  TextEditingController _controller = TextEditingController();
  ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  int _limit = 20;
  int _offset = 0;
  bool _loadingMore = false;
  dynamic _webSocket;
  bool _isConnected = false;
  bool _botIsTyping = false;
  String _currentBotMessage = '';
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _scrollController.addListener(_onScroll);
    _fetchMessages();
  }

  late WebSocketChannel _channel;

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(Config.wsUrl));

      if (mounted) {
        setState(() => _isConnected = true);
      }
      print("✅ Conectado al WebSocket");

      _channel.stream.listen((message) {
        final data = jsonDecode(message);
        _handleIncomingMessage(data);
      }, onDone: () {
        print("⚠ WebSocket cerrado");
        if (mounted) {
          setState(() => _isConnected = false);
        }
      }, onError: (error) {
        print("❌ Error WebSocket: $error");
      });
    } catch (e) {
      print("No se pudo conectar: $e");
    }
  }


  void _showTypingEffect(String fullMessage) {
    if (!mounted || fullMessage.isEmpty) return; // Verificar mounted

    final botMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      messages.insert(0, {
        'id': botMessageId,
        'text': '',
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'user_id': 1,
        'created_at': DateTime.now().toString(),
        'isTyping': true,
      });
      _currentBotMessage = '';
    });

    final words = fullMessage.split(' ');
    int currentWordIndex = 0;

    _typingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted) { // Verificar mounted en cada iteración
        timer.cancel();
        return;
      }

      if (currentWordIndex < words.length) {
        setState(() {
          _currentBotMessage += (currentWordIndex == 0 ? '' : ' ') + words[currentWordIndex];
          final messageIndex = messages.indexWhere((msg) => msg['id'] == botMessageId);
          if (messageIndex != -1) {
            messages[messageIndex]['text'] = _currentBotMessage;
          }
        });
        currentWordIndex++;
      } else {
        timer.cancel();
        if (mounted) { // Verificar mounted antes del setState final
          setState(() {
            final messageIndex = messages.indexWhere((msg) => msg['id'] == botMessageId);
            if (messageIndex != -1) {
              messages[messageIndex]['isTyping'] = false;
            }
          });
        }
      }
    });
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    if (!mounted) return;

    if (data['type'] == 'status') {
      print("Estado: ${data['status']} - ${data['message']}");

      if (data['status'] == 'processing') {
        setState(() {
          _botIsTyping = true;
        });
      }
    }
    else if (data['type'] == 'bot_message') {
      setState(() {
        _botIsTyping = false;
      });

      final botResponse = data['data']['response'] ?? '';
      _showTypingEffect(botResponse);
    }
    else if (data['type'] == 'error') {
      setState(() {
        _botIsTyping = false;
      });
      print("Error: ${data['message']}");
    }
  }


  @override
  @override
  void dispose() {
    _typingTimer?.cancel();
    _channel.sink.close(status.goingAway);
    _scrollController.dispose();
    super.dispose();
  }


  void _onScroll() {
    _scrollOffset = _scrollController.offset;
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        !_loadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _fetchMessages({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() {
        _loadingMore = true;
      });
    }

    final url = Uri.parse('${Config.apiUrl2}/chat/messages?userId=${widget.userId}&limit=$_limit&offset=$_offset');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          if (isLoadMore) {
            messages.addAll(data.map((item) {
              return {
                'id': item['id']?.toString() ?? '',
                'text': item['content'] ?? '',
                'time': item['created_at'] != null
                    ? DateFormat('HH:mm').format(DateTime.parse(item['created_at']))
                    : '',
                // Mapear según el sender: FUNCY = 1 (bot), USER = userId actual
                'user_id': item['sender'] == 'FUNCY' ? 1 : widget.userId,
                'created_at': item['created_at'] ?? '',
              };
            }).toList());
            _loadingMore = false;
          } else {
            messages = data.map((item) {
              return {
                'id': item['id']?.toString() ?? '',
                'text': item['content'] ?? '',
                'time': item['created_at'] != null
                    ? DateFormat('HH:mm').format(DateTime.parse(item['created_at']))
                    : '',
                // Mapear según el sender: FUNCY = 1 (bot), USER = userId actual
                'user_id': item['sender'] == 'FUNCY' ? 1 : widget.userId,
                'created_at': item['created_at'] ?? '',
              };
            }).toList();
          }
          _offset += _limit;
        });
      } else {
        print('Error al obtener mensajes: ${response.statusCode}');
      }
    } catch (error) {
      print('Error en la solicitud HTTP: $error');
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_loadingMore) return;
    await _fetchMessages(isLoadMore: true);
  }

  Future<void> _sendMessage(String text) async {
    if (!_isConnected) {
      print("No conectado al WebSocket");
      return;
    }

    setState(() {
      messages.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'user_id': widget.userId,
        'created_at': DateTime.now().toString(),
      });
    });

    final message = {
      'type': 'send_message',
      'prompt': text,
      'userId': widget.userId,
      'username': widget.username
    };

    _channel.sink.add(jsonEncode(message));

    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /*
  Future<void> _getBotResponse(String userMessage) async {
    if (userMessage.isEmpty) {
      print('Mensaje del usuario es nulo o vacío');
      return;
    }

    final List<Map<String, dynamic>> chatHistory = messages.map((msg) {
      return {
        'role': msg['user_id'] == widget.userId ? 'user' : 'assistant',
        'content': msg['text']
      };
    }).toList();

    final url = Uri.parse('${Config.apiUrl}/ask'); // Usar Config.apiUrl
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': userMessage,
          'userId': widget.userId,
          'chatHistory': chatHistory
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final botMessage = responseData['response']?.toString().trim() ?? '';

        final saveBotMessageResponse = await http.post(
          Uri.parse('${Config.apiUrl}/guardarMensajeFromBot'), // Usar Config.apiUrl
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'content': botMessage,
            'userId': widget.userId,
          }),
        );

        if (saveBotMessageResponse.statusCode == 201) {
          final responseData = json.decode(saveBotMessageResponse.body);
          setState(() {
            messages.insert(
              0,
              {
                'id': responseData['id']?.toString() ?? '',
                'text': botMessage,
                'time': DateFormat('HH:mm').format(DateTime.now()),
                'user_id': 1,
                'created_at': responseData['created_at'] ?? '',
              },
            );
          });

          _scrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          print('Error al guardar el mensaje del bot: ${saveBotMessageResponse.statusCode}');
        }
      } else {
        print('Error al obtener respuesta del bot: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
      }
    } catch (error) {
      print('Error en la solicitud HTTP: $error');
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(
            scrollOffset: _scrollOffset,
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                    child: Container(
                      color: Color(0xFFF6F6F6),
                    )
                ),
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        cacheExtent: 1000,
                        itemCount: messages.length + (_botIsTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Mostrar indicador de "analizando" en la primera posición
                          if (_botIsTyping && index == 0) {
                            return _buildTypingIndicator();
                          }

                          final messageIndex = _botIsTyping ? index - 1 : index;
                          final text = messages[messageIndex]['text'] ?? '';
                          final time = messages[messageIndex]['time'] ?? '';
                          final user_id = messages[messageIndex]['user_id'] ??
                              '';
                          final userType = user_id == widget.userId
                              ? user_id
                              : 1;

                          return ChatMessage(
                            key: ValueKey(messages[messageIndex]['id']),
                            message: text,
                            time: time,
                            userId: user_id,
                            userType: userType,
                          );
                        },
                      ),
                    ),
                    ChatBoxFooter(
                      textEditingController: _controller,
                      onSendMessage: (text) {
                        _sendMessage(text);
                        _controller.clear();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.0,
            backgroundColor: Colors.transparent,
            child: ClipOval(
              child: Image.network(
                'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_chat.jpg',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFEAE5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Funcy está pensando...',
                  style: TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF351A8B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
