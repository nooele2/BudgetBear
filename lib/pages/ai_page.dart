import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:budget_bear/widgets/bottom_nav_bar.dart';
import 'package:budget_bear/services/firestore.dart';

class AIPage extends StatefulWidget {
  const AIPage({Key? key}) : super(key: key);

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreService firestoreService = FirestoreService();

  List<Map<String, String>> messages = [];
  bool isLoading = false;

  final String systemPrompt =
      "You are BudgetBear AI, a friendly financial assistant. "
      "Give short, practical financial tips. Explain budgeting concepts simply. "
      "Also answer questions about how to use the BudgetBear app.";

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final history = await firestoreService.getAIChatHistory();

    setState(() {
      messages = history;
    });

    _scrollToBottom();
  }

  Future<void> sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    // Add user message locally
    setState(() {
      messages.add({"role": "user", "text": userMessage});
      isLoading = true;
    });

    // Save to Firestore
    await firestoreService.saveAIMessage("user", userMessage);

    _controller.clear();
    _scrollToBottom();

    // Call Gemini API
    final aiResponse = await callGeminiAPI(userMessage);

    // Add assistant message locally
    setState(() {
      messages.add({"role": "assistant", "text": aiResponse});
      isLoading = false;
    });

    // Save assistant response
    await firestoreService.saveAIMessage("assistant", aiResponse);

    _scrollToBottom();
  }

  // Gemini API call
  Future<String> callGeminiAPI(String userMessage) async {
    const apiKey = "AIzaSyCMP7Xd5m9Fs8htyP5W6prf-wwnUqxkxkQ";
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey";

    final body = {
      "contents": [
        {
          "parts": [
            {"text": "$systemPrompt\nUser: $userMessage"}
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final result = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

        return result ?? "Sorry, I couldn't generate a response.";
      } else {
        return "Error: ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      return "Error calling API: $e";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color accent = Color.fromRGBO(71, 168, 165, 1);
    const Color bgColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "BudgetBear AI",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? accent.withOpacity(0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask BudgetBear something...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: accent),
                  onPressed: isLoading ? null : sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
