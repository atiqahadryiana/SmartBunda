import 'package:flutter/material.dart';
import 'package:smartbunda/theme/app_theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add initial AI message
    _addMessage(
      ChatMessage(
        text: 'Hello! I am your AI Nutrition Assistant. How can I help you today?',
        isUser: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBase,
      appBar: AppBar(
        title: const Text('AI Nutrition Assistant'),
        backgroundColor: AppTheme.darkPink,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment:
                      message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? AppTheme.darkPink
                          : AppTheme.cardBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(message.isUser ? 16 : 0),
                        topRight: Radius.circular(message.isUser ? 0 : 16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser
                            ? Colors.white
                            : AppTheme.primaryText,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 0.078)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: AppTheme.darkPink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addMessage(ChatMessage message) {
    setState(() => _messages.add(message));
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _addMessage(ChatMessage(text: text, isUser: true));
    // Simulate AI response after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      _addMessage(
        ChatMessage(
          text: _getAiResponse(text),
          isUser: false,
        ),
      );
    });
  }

  String _getAiResponse(String userMessage) {
    // Very simple response logic - in reality, this would call an AI service
    final lower = userMessage.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi')) {
      return 'Hello! How can I assist you with your pregnancy nutrition today?';
    } else if (lower.contains('food') || lower.contains('eat') || lower.contains('meal')) {
      return 'For meal suggestions, I recommend scanning your food or logging your meals in the Log section. Would you like help with that?';
    } else if (lower.contains('water') || lower.contains('hydration')) {
      return 'Staying hydrated is important! Aim for at least 8 glasses of water per day. You can track your water intake in the Log section.';
    } else if (lower.contains('appointment') || lower.contains('doctor')) {
      return 'You can view and schedule appointments in the Appointment section. Is there a specific appointment you need help with?';
    } else if (lower.contains('history') || lower.contains('log')) {
      return 'You can view your past meals, hydration, and other health logs in the History section.';
    } else {
      return 'I am here to help with your pregnancy nutrition and health. You can ask me about meals, hydration, appointments, or general pregnancy questions.';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}