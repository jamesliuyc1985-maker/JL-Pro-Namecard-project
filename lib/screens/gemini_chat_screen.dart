import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/theme.dart';

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({super.key});
  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  late GenerativeModel _model;
  late ChatSession _chat;

  static const _apiKey = 'AIzaSyBMTKwBDxjH2JakRFMhFRWxltXXjE-hk4A';

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.text(
        '你是Deal Navigator CRM的AI助手。你的主要职责是帮助用户管理客户关系、分析销售数据、提供商业建议。'
        '用户是James Liu，从事金融、股权投融资、交易、外泌体生产及销售、医药保健品业务。'
        '你需要用专业、简洁的中文回答，适当使用金融和商业术语。'
        '当涉及产品时，主要产品线包括：外泌体原液（300億/500億/1000億）、NAD+注射液、NMN点鼻/吸入、NMN胶囊。'
        '公司：能道再生株式会社（東京都千代田区神田佐久間町）。'
      ),
    );
    _chat = _model.startChat();
    _messages.add(_ChatMessage(
      text: '你好 James！我是你的AI商务助手。\n\n我可以帮你：\n'
          '📊 分析客户和销售数据\n'
          '💡 提供商业策略建议\n'
          '📝 撰写商务邮件和方案\n'
          '🔬 解答外泌体/NAD+/NMN产品问题\n'
          '💰 分析投融资和交易机会\n\n'
          '有什么可以帮你的？',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final reply = response.text ?? '抱歉，无法获取回复。';
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: '请求失败: $e', isUser: false, isError: true));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 22),
          SizedBox(width: 8),
          Text('Gemini AI 助手'),
        ]),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: () {
              setState(() {
                _chat = _model.startChat();
                _messages.clear();
                _messages.add(_ChatMessage(text: '对话已重置。有什么可以帮你的？', isUser: false));
              });
            },
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) return _buildLoadingBubble();
              return _buildMessageBubble(_messages[index]);
            },
          ),
        ),
        _buildQuickActions(),
        _buildInputBar(),
      ]),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isUser ? AppTheme.primaryPurple : (msg.isError ? AppTheme.danger.withValues(alpha: 0.2) : AppTheme.cardBg),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: SelectableText(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : (msg.isError ? AppTheme.danger : AppTheme.textPrimary),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryPurple)),
          SizedBox(width: 10),
          Text('思考中...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildQuickActions() {
    final quickQuestions = [
      '分析客户需求',
      '写商务邮件',
      '产品卖点整理',
      '投资建议',
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: quickQuestions.map((q) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(q, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
            backgroundColor: AppTheme.cardBgLight,
            onPressed: () {
              _inputCtrl.text = q;
              _sendMessage();
            },
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: AppTheme.darkBg,
          border: Border(top: BorderSide(color: AppTheme.cardBgLight.withValues(alpha: 0.5))),
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: '输入消息...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppTheme.cardBg,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(gradient: AppTheme.gradient, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ]),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  _ChatMessage({required this.text, required this.isUser, this.isError = false});
}
