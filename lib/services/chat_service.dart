import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chat_message.dart';

class ChatService {
  // Helper method to ensure IDs are strings
  String _ensureStringId(dynamic id) {
    if (id == null) return '';
    return id.toString();
  }

  // Get chat messages between worker and contractor
  Future<List<ChatMessage>> getChatMessages(
      dynamic workerId, dynamic contractorId) async {
    try {
      String stringWorkerId = _ensureStringId(workerId);
      String stringContractorId = _ensureStringId(contractorId);

      if (stringWorkerId.isEmpty || stringContractorId.isEmpty) {
        throw Exception('WorkerId and ContractorId are required');
      }
      final url =
          '${ApiConfig.baseUrl}/api/chats/$stringWorkerId/$stringContractorId/messages/';
      print(
          'Fetching messages from: $url with workerId: $stringWorkerId, contractorId: $stringContractorId');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['messages'] != null) {
          final List<dynamic> messages = responseData['messages'];
          print(
              'Successfully parsed ${messages.length} messages from API response');
          return messages.map((json) => ChatMessage.fromJson(json)).toList();
        }
        print('API response status was not success or messages was null');
        return [];
      } else {
        final error =
            json.decode(response.body)['error'] ?? 'Unknown error occurred';
        print('Failed to load messages: ${response.statusCode}, $error');
        throw Exception(error);
      }
    } catch (e) {
      print('Error fetching chat messages: $e');
      rethrow;
    }
  }

  // Send a new message
  Future<ChatMessage?> sendMessage({
    required dynamic senderId,
    required dynamic receiverId,
    required String message,
    String? attachmentUrl,
  }) async {
    try {
      if (message.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      String stringSenderId = _ensureStringId(senderId);
      String stringReceiverId = _ensureStringId(receiverId);

      if (stringSenderId.isEmpty || stringReceiverId.isEmpty) {
        throw Exception('Invalid sender or receiver ID');
      }

      final url = '${ApiConfig.baseUrl}/api/chats/send/';
      print(
          'Sending message to: $url with senderId: $stringSenderId, receiverId: $stringReceiverId');

      final messageData = {
        'sender_id': stringSenderId,
        'receiver_id': stringReceiverId,
        'message': message.trim(),
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(messageData),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['message'] != null) {
          return ChatMessage.fromJson(responseData['message']);
        }
        throw Exception('Invalid response format');
      } else {
        final error =
            json.decode(response.body)['error'] ?? 'Failed to send message';
        print('Failed to send message: ${response.statusCode}, $error');
        throw Exception(error);
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<bool> markMessagesAsRead(
      dynamic workerId, dynamic contractorId) async {
    try {
      String stringWorkerId = _ensureStringId(workerId);
      String stringContractorId = _ensureStringId(contractorId);

      if (stringWorkerId.isEmpty || stringContractorId.isEmpty) {
        throw Exception('WorkerId and ContractorId are required');
      }

      final url =
          '${ApiConfig.baseUrl}/api/chats/$stringWorkerId/$stringContractorId/read/';
      print('Marking messages as read at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['status'] == 'success';
      } else {
        final error = json.decode(response.body)['error'] ??
            'Failed to mark messages as read';
        print(
            'Failed to mark messages as read: ${response.statusCode}, $error');
        throw Exception(error);
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }
}
