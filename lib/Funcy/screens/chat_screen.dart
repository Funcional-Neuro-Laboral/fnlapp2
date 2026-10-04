import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config.dart';
import '../../theme/app_colors.dart';
import '../../theme/funcy.dart';
import '../../Util/api_service.dart';
import '../widgets/chat_box_footer.dart';
import '../widgets/chat_message.dart';

enum _ConnectionState { connecting, online, offline }

class ChatScreen extends StatefulWidget {
  final int userId;
  final String username;

  /// Si es verdadero, el chat se muestra como pestaña (sin botón para volver).
  final bool embedded;

  ChatScreen({required this.userId, required this.username, this.embedded = false});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _quickReplies = [
    'Me siento con mucho estrés',
    'Quiero una pausa rápida',
    '¿Cómo funciona mi plan?',
  ];

  List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final int _limit = 20;
  int _offset = 0;
  bool _loadingMore = false;
  bool _botIsTyping = false;
  String _currentBotMessage = '';
  Timer? _typingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  _ConnectionState _connection = _ConnectionState.connecting;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _scrollController.addListener(_onScroll);
    _fetchMessages();
  }

  Map<String, dynamic> _createWelcomeMessage() {
    final now = DateTime.now();
    return {
      'id': 'welcome_message',
      'text': '¡Hola, ${widget.username}! Soy Funcy. ¿En qué te puedo ayudar hoy?',
      'time': DateFormat('HH:mm').format(now),
      'user_id': 1,
      'created_at': now.toString(),
      'isWelcome': true,
    };
  }

  Future<void> _connectWebSocket() async {
    _reconnectTimer?.cancel();
    if (mounted) setState(() => _connection = _ConnectionState.connecting);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted) setState(() => _connection = _ConnectionState.offline);
        return;
      }

      final channel = WebSocketChannel.connect(Uri.parse('${Config.wsUrl}?token=$token'));
      await channel.ready;
      if (!mounted) {
        channel.sink.close(status.goingAway);
        return;
      }

      _channel = channel;
      _reconnectAttempts = 0;
      setState(() => _connection = _ConnectionState.online);

      _subscription = channel.stream.listen(
        (message) {
          try {
            _handleIncomingMessage(jsonDecode(message));
          } catch (e) {
            debugPrint('Mensaje de chat no válido: $e');
          }
        },
        onDone: _onDisconnected,
        onError: (error) => _onDisconnected(),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('No se pudo conectar al chat: $e');
      _onDisconnected();
    }
  }

  void _onDisconnected() {
    if (!mounted) return;
    setState(() {
      _connection = _ConnectionState.offline;
      _botIsTyping = false;
    });
    // Reintento automático con espera creciente (2, 4, 8… hasta 30 s).
    _reconnectAttempts++;
    final seconds = (1 << _reconnectAttempts.clamp(1, 5)).clamp(2, 30);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: seconds), _connectWebSocket);
  }

  void _showTypingEffect(String fullMessage) {
    if (!mounted || fullMessage.isEmpty) return;

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
    var currentWordIndex = 0;

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (currentWordIndex < words.length) {
        setState(() {
          _currentBotMessage += (currentWordIndex == 0 ? '' : ' ') + words[currentWordIndex];
          final index = messages.indexWhere((msg) => msg['id'] == botMessageId);
          if (index != -1) messages[index]['text'] = _currentBotMessage;
        });
        currentWordIndex++;
      } else {
        timer.cancel();
        setState(() {
          final index = messages.indexWhere((msg) => msg['id'] == botMessageId);
          if (index != -1) messages[index]['isTyping'] = false;
        });
      }
    });
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    if (!mounted) return;
    if (data['type'] == 'status') {
      if (data['status'] == 'processing') setState(() => _botIsTyping = true);
    } else if (data['type'] == 'bot_message') {
      setState(() => _botIsTyping = false);
      _showTypingEffect(data['data']?['response'] ?? '');
    } else if (data['type'] == 'error') {
      setState(() => _botIsTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcy no pudo responder. Inténtalo de nuevo.')),
      );
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 40 && !_loadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _fetchMessages({bool isLoadMore = false}) async {
    if (isLoadMore) setState(() => _loadingMore = true);

    try {
      final response =
          await ApiService().get('chat/messages?userId=${widget.userId}&limit=$_limit&offset=$_offset');
      final List<dynamic> data = json.decode(response.body);
      final newMessages = data.map<Map<String, dynamic>>((item) {
        final createdAt = item['created_at'] != null ? DateTime.tryParse(item['created_at']) : null;
        return {
          'id': item['id']?.toString() ?? '',
          'text': item['content'] ?? '',
          'time': createdAt != null ? DateFormat('HH:mm').format(createdAt.toLocal()) : '',
          'user_id': item['sender'] == 'FUNCY' ? 1 : widget.userId,
          'created_at': item['created_at'] ?? '',
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        if (isLoadMore) {
          messages.addAll(newMessages);
          if (newMessages.length < _limit) messages.add(_createWelcomeMessage());
          _loadingMore = false;
        } else {
          messages = newMessages;
          messages.add(_createWelcomeMessage());
        }
        _offset += _limit;
      });
    } catch (error) {
      debugPrint('Error al obtener mensajes: $error');
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        if (!isLoadMore) messages = [_createWelcomeMessage()];
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_loadingMore) return;
    if (messages.any((msg) => msg['isWelcome'] == true)) return;
    await _fetchMessages(isLoadMore: true);
  }

  bool get _hasUserMessages => messages.any((m) => m['user_id'] != 1);

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (_connection != _ConnectionState.online || _channel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión con Funcy. Reintentando…')),
      );
      return;
    }

    setState(() {
      messages.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': trimmed,
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'user_id': widget.userId,
        'created_at': DateTime.now().toString(),
      });
    });

    _channel!.sink.add(jsonEncode({
      'type': 'send_message',
      'prompt': trimmed,
      'userId': widget.userId,
      'username': widget.username,
    }));
    _controller.clear();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = messages.length + (_botIsTyping ? 1 : 0) + 1; // +1: aviso al inicio

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: !widget.embedded,
        child: Column(
          children: [
            _ChatHeader(
              connection: _connection,
              showBack: !widget.embedded,
              onRetry: _connectWebSocket,
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (_botIsTyping && index == 0) return const _TypingIndicator();
                  final messageIndex = _botIsTyping ? index - 1 : index;
                  if (messageIndex == messages.length) return const _Disclaimer();
                  final message = messages[messageIndex];
                  final userId = message['user_id'] is int ? message['user_id'] as int : 1;
                  return ChatMessage(
                    key: ValueKey(message['id']),
                    message: message['text'] ?? '',
                    time: message['time'] ?? '',
                    userId: userId,
                    userType: userId == widget.userId ? userId : 1,
                  );
                },
              ),
            ),
            if (!_hasUserMessages && messages.isNotEmpty)
              _QuickReplies(
                replies: _quickReplies,
                enabled: _connection == _ConnectionState.online,
                onTap: _sendMessage,
              ),
            ChatBoxFooter(
              textEditingController: _controller,
              enabled: _connection == _ConnectionState.online,
              onSendMessage: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.connection, required this.showBack, required this.onRetry});

  final _ConnectionState connection;
  final bool showBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (connection) {
      _ConnectionState.online => ('En línea', const Color(0xFF1E9E6A)),
      _ConnectionState.connecting => ('Conectando…', AppColors.streak),
      _ConnectionState.offline => ('Sin conexión · reintentando', AppColors.error),
    };
    return Container(
      padding: EdgeInsets.fromLTRB(showBack ? 4 : 16, 10, 8, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child: const OverflowBox(
              maxWidth: 80,
              maxHeight: 80,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 6, right: 4),
                child: FuncyImage(FuncyPose.seguro, size: 80),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Funcy', style: TextStyle(fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w800)),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w600,
                            color: connection == _ConnectionState.online ? AppColors.successText : AppColors.inkSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (connection == _ConnectionState.offline)
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 4, 24, 12),
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(12)),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryDeep),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Funcy es un asistente de bienestar. No reemplaza la atención de un profesional de salud.',
                style: TextStyle(fontSize: 12, height: 17 / 12, fontWeight: FontWeight.w500, color: AppColors.primaryDeep),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Funcy está escribiendo',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 64, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.borderSoft),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Funcy está escribiendo…',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.inkSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.replies, required this.enabled, required this.onTap});

  final List<String> replies;
  final bool enabled;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => OutlinedButton(
          onPressed: enabled ? () => onTap(replies[index]) : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            backgroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          child: Text(replies[index]),
        ),
      ),
    );
  }
}
