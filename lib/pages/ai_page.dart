// ai_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:budget_bear/widgets/bottom_nav_bar.dart';
import 'package:budget_bear/services/firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  late final String openRouterApiKey;

  @override
  void initState() {
    super.initState();
    loadHistory();

    // Load API key from .env
    openRouterApiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    if (openRouterApiKey.isEmpty) { //gracefully handle errror
      throw Exception("OPENROUTER_API_KEY not found in .env!");
    }
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

    setState(() {
      messages.add({"role": "user", "text": userMessage});
      isLoading = true;
    });

    await firestoreService.saveAIMessage("user", userMessage);

    _controller.clear();
    _scrollToBottom();

    // Call OpenRouter DeepSeek API
    final aiResponse = await callDeepSeekAPI(userMessage);

    setState(() {
      messages.add({"role": "assistant", "text": aiResponse});
      isLoading = false;
    });

    await firestoreService.saveAIMessage("assistant", aiResponse);
    _scrollToBottom();
  }

  Future<String> callDeepSeekAPI(String userMessage) async {
    final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");

    final body = {
      "model": "deepseek/deepseek-r1:free",
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": userMessage}
      ],
      "temperature": 0.7,
      "max_tokens": 500
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $openRouterApiKey",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data["choices"]?[0]?["message"]?["content"];
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "BudgetBear AI",
          style: TextStyle(color: textColor),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 64,
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Ask BudgetBear AI anything!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Get financial tips and budgeting advice",
                          style: TextStyle(
                            fontSize: 14,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg["role"] == "user";

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? accent.withOpacity(0.2)
                                : isDark
                                    ? const Color(0xFF2C2C2C)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isDark
                                ? []
                                : [
                                    const BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Text(
                            msg["text"] ?? "",
                            style: TextStyle(
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDark
                          ? []
                          : [
                              const BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Thinking...",
                          style: TextStyle(
                            fontSize: 14,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: isDark
                  ? []
                  : [
                      const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Ask BudgetBear something...",
                      hintStyle: TextStyle(color: subtextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: accent, width: 1.5),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => isLoading ? null : sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.grey.shade400 : accent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: isLoading ? null : sendMessage,
                  ),
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
