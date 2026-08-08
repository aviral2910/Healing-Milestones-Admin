import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_palette.dart';
import '../../data/models/message_model.dart';
import '../../data/support_chats_repository.dart';
import '../providers/support_chats_providers.dart';
import 'support_chats_list_screen.dart';

class SupportChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  const SupportChatDetailScreen({super.key, required this.chatId});

  @override
  ConsumerState<SupportChatDetailScreen> createState() => _SupportChatDetailScreenState();
}

class _SupportChatDetailScreenState extends ConsumerState<SupportChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isSending = false;

  final String adminId = 'admin';

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      ref.read(supportChatsRepositoryProvider).updateTypingStatus(widget.chatId, adminId, true);
    }
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        setState(() => _isTyping = false);
        ref.read(supportChatsRepositoryProvider).updateTypingStatus(widget.chatId, adminId, false);
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;
    
    setState(() => _isSending = true);
    
    try {
      final repo = ref.read(supportChatsRepositoryProvider);
      String? imageUrl;
      
      if (_selectedImage != null) {
        imageUrl = await repo.uploadImage(widget.chatId, _selectedImage!);
      }
      
      final message = MessageModel(
        id: const Uuid().v4(),
        text: text,
        senderId: adminId,
        timestamp: DateTime.now(),
        messageType: _selectedImage != null ? 'image' : 'text',
        fileUrl: imageUrl,
      );
      
      // The recipient is the non-admin user
      final chat = ref.read(supportChatStreamProvider(widget.chatId)).value;
      final recipientId = chat?.participants.firstWhere((p) => p != 'admin', orElse: () => '') ?? '';
      await repo.sendMessage(widget.chatId, message, recipientId: recipientId.isNotEmpty ? recipientId : null);
      
      _textController.clear();
      setState(() {
        _selectedImage = null;
        _isSending = false;
        _isTyping = false;
      });
      repo.updateTypingStatus(widget.chatId, adminId, false);
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.getThemeData(ThemePalette.goldenDark);
    final chatAsync = ref.watch(supportChatStreamProvider(widget.chatId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: chatAsync.when(
          data: (chat) {
            if (chat == null) return const Text('Chat Not Found');
            final userId = chat.participants.firstWhere((id) => id != 'admin', orElse: () => 'Unknown');
            final userAsync = ref.watch(chatUserProvider(userId));
            return userAsync.when(
              data: (user) => Text(user?.displayName ?? 'Support Chat'),
              loading: () => const Text('Loading...'),
              error: (_, __) => const Text('Support Chat'),
            );
          },
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final messagesAsync = ref.watch(supportChatMessagesProvider(widget.chatId));

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Text('No messages yet.', style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          reverse: true,
          controller: _scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isAdmin = msg.senderId == adminId;
            
            return Align(
              alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAdmin ? ThemePalette.goldenDark.accentPrimary : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomRight: isAdmin ? const Radius.circular(0) : const Radius.circular(16),
                    bottomLeft: isAdmin ? const Radius.circular(16) : const Radius.circular(0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.messageType == 'image' && msg.fileUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          msg.fileUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (msg.text.isNotEmpty) const SizedBox(height: 8),
                    ],
                    if (msg.text.isNotEmpty)
                      Text(
                        msg.text,
                        style: TextStyle(
                          color: isAdmin ? Colors.black : Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
    );
  }

  Widget _buildTypingIndicator() {
    final chatAsync = ref.watch(supportChatStreamProvider(widget.chatId));
    
    return chatAsync.when(
      data: (chat) {
        if (chat == null) return const SizedBox.shrink();
        final userId = chat.participants.firstWhere((id) => id != 'admin', orElse: () => 'Unknown');
        if (chat.typingStatus[userId] == true) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'User is typing...',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[400],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.black26)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_selectedImage != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.grey),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onChanged: _onTextChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ),
                if (_isSending)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.send, color: ThemePalette.goldenDark.accentPrimary),
                    onPressed: _sendMessage,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
