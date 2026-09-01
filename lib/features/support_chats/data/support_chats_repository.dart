import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'models/chat_model.dart';
import 'models/message_model.dart';

class SupportChatsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  SupportChatsRepository(this._firestore, this._storage);

  Stream<List<ChatModel>> getSupportChatsStream() {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: 'admin')
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .where((chat) => chat.type == 'support')
          .toList();
      
      // Sort locally by lastUpdated descending to avoid requiring a composite index
      chats.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
      
      return chats;
    });
  }

  Stream<ChatModel?> getChatStream(String chatId) {
    return _firestore.collection('chat_rooms').doc(chatId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return ChatModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> sendMessage(String chatId, MessageModel message, {String? recipientId}) async {
    final batch = _firestore.batch();
    
    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .doc(message.id);
        
    final chatRef = _firestore.collection('chat_rooms').doc(chatId);

    batch.set(messageRef, message.toMap());
    
    String lastMessageText = message.text;
    if (message.messageType == 'image' && lastMessageText.isEmpty) {
      lastMessageText = 'Image sent';
    }

    final updates = <String, dynamic>{
      'lastMessageText': lastMessageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
    };

    if (recipientId != null) {
      updates['unreadCount.$recipientId'] = FieldValue.increment(1);
    }

    batch.update(chatRef, updates);

    await batch.commit();
  }

  Future<void> clearUnreadCount(String chatId, String userId) async {
    await _firestore.collection('chat_rooms').doc(chatId).update({
      'unreadCount.$userId': 0,
    });
  }

  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    await _firestore.collection('chat_rooms').doc(chatId).update({
      'typingStatus.$userId': isTyping,
    });
  }

  Future<String> uploadImage(String chatId, File imageFile) async {
    final fileName = const Uuid().v4();
    final ref = _storage.ref().child('chats/$chatId/$fileName');
    
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }
}

final supportChatsRepositoryProvider = Provider<SupportChatsRepository>((ref) {
  return SupportChatsRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
});
