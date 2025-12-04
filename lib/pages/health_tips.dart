import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 💡 IMPORTANT: Ensure this path points to the file where GEMINI_API_KEY is defined.
// Replace with your actual key if not using a constants file.
// const String GEMINI_API_KEY = 'YOUR_GEMINI_API_KEY';
import '../../constants/api_keys.dart'; 

// --- Message Data Structure ---
class ChatMessage {
  final String text;
  final bool isUser; // true for user, false for AI
  ChatMessage({required this.text, required this.isUser});
}

class HealthTipsPage extends StatefulWidget {
  const HealthTipsPage({super.key});

  @override
  State<HealthTipsPage> createState() => _HealthTipsPageState();
}

class _HealthTipsPageState extends State<HealthTipsPage> {
  // --- State Variables ---
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  // --- Background Definitions ---
  static const List<Color> _gradientColors = [
    Color(0xFFE0F7FA), // Lightest Cyan/Teal
    Colors.white,      // White base
  ];
  static const List<IconData> _backgroundIcons = [
    Icons.medical_services_outlined,
    Icons.health_and_safety_outlined,
    Icons.receipt_long,
    Icons.calendar_month,
    Icons.add_box_outlined,
    Icons.local_pharmacy_outlined,
  ];
  // ------------------------------------------------

  @override
  void initState() {
    super.initState();
    // Initial greeting message from the AI
    _messages.add(
      ChatMessage(
        text: "Hello! I'm your AI Health Assistant. Ask me any general health and wellness question!",
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🎯 HANDLES USER INPUT AND API CALL
  void _handleSubmitted(String text) async {
    if (text.isEmpty || _isLoading) return;

    // 1. Add user message to the list
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isLoading = true;
    });

    try {
      // 2. Fetch AI response
      final aiResponse = await _fetchAiResponse(text);

      // 3. Add AI response to the list
      setState(() {
        _messages.add(ChatMessage(text: aiResponse, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      // 4. Handle error
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Error fetching response: $e",
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }
  }

  // 🎯 GEMINI API CALL FUNCTION
  Future<String> _fetchAiResponse(String userPrompt) async {
    final String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$GEMINI_API_KEY';

    // System instruction to define the chatbot's persona
    const String systemInstructionText =
        "You are a friendly, helpful, and concise health assistant. Answer general health, wellness, and basic medical questions (non-diagnostic) clearly and briefly. Use simple markdown (like **bold**) but do not output complex structures like tables or JSON.";

    final Map<String, dynamic> requestBody = {
      "systemInstruction": {
        "role": "system",
        "parts": [{"text": systemInstructionText}]
      },

      // Send the user's current prompt
      "contents": [
        {
          "role": "user",
          "parts": [{"text": userPrompt}]
        }
      ],
      
      "generationConfig": {
        "temperature": 0.5,
      },
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      
      // Extract the text content from the nested API response structure
      String textContent = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      return textContent;
    } else {
      throw Exception('Gemini API call failed with status: ${response.statusCode}');
    }
  }

  // --- Widget for the Input Field ---
  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: TextField(
                controller: _controller,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: "Ask a health question...",
                ),
                enabled: !_isLoading,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: _isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: _isLoading
                  ? null
                  : () => _handleSubmitted(_controller.text),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Health Chatbot 🧠"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. Gradient Background Container
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _gradientColors,
                ),
              ),
            ),
          ),
          
          // 2. ICON PATTERN OVERLAY (Less Dense)
          Positioned.fill(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 25, // Reduced count
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Reduced density
                childAspectRatio: 1.0,
                mainAxisSpacing: 100, // Increased spacing
                crossAxisSpacing: 100, // Increased spacing
              ),
              itemBuilder: (context, index) {
                final iconData = _backgroundIcons[index % _backgroundIcons.length];
                return Transform.rotate(
                  angle: index % 2 == 0 ? 0.1 : -0.1,
                  child: Icon(
                    iconData,
                    size: 80,
                    color: Colors.black.withOpacity(0.03),
                  ),
                );
              },
            ),
          ),
          
          // 3. Foreground Content (Chat History and Input)
          Column(
            children: <Widget>[
              Flexible(
                // Chat history list
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  reverse: true, // Show latest message at the bottom
                  itemBuilder: (_, int index) => ChatMessageBubble(
                    message: _messages[_messages.length - 1 - index],
                  ),
                  itemCount: _messages.length,
                ),
              ),
              const Divider(height: 1.0),
              // Input Composer 
              SafeArea( // Handles system bars and keyboard
                top: false, 
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom, // Use keyboard height
                    top: 5.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(color: Theme.of(context).cardColor),
                    child: _buildTextComposer(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- CHAT MESSAGE BUBBLE WIDGET ---
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: <Widget>[
          // AI Icon (on the left)
          if (!message.isUser)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.psychology_outlined, color: Colors.white),
              ),
            ),
          
          // Message Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75, // Max width
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blueAccent : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.isUser ? 15.0 : 0.0),
                  topRight: const Radius.circular(15.0),
                  bottomLeft: Radius.circular(message.isUser ? 15.0 : 0.0),
                  bottomRight: Radius.circular(message.isUser ? 0.0 : 15.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          
          // User Icon (on the right)
          if (message.isUser)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}