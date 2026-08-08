import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/support_chats_repository.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';

final supportChatsListProvider = StreamProvider.autoDispose<List<ChatModel>>((ref) {
  final repo = ref.watch(supportChatsRepositoryProvider);
  return repo.getSupportChatsStream();
});

final supportChatStreamProvider = StreamProvider.autoDispose.family<ChatModel?, String>((ref, String chatId) {
  final repo = ref.watch(supportChatsRepositoryProvider);
  return repo.getChatStream(chatId);
});

final supportChatMessagesProvider = StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, String chatId) {
  final repo = ref.watch(supportChatsRepositoryProvider);
  return repo.getMessagesStream(chatId);
});
