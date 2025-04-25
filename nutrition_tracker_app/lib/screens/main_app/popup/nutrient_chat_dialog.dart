import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class NutrientChatDialog extends StatefulWidget {
  final MealEntity meal;
  final Map<String, dynamic> nutritionTableData;
  final String projectFoodFactsLink;
  final Map<String, dynamic> userProfileData;

  const NutrientChatDialog({
    super.key,
    required this.meal,
    required this.nutritionTableData,
    required this.projectFoodFactsLink,
    required this.userProfileData,
  });

  @override
  State<NutrientChatDialog> createState() => _NutrientChatDialogState();
}

class _NutrientChatDialogState extends State<NutrientChatDialog> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late GenerativeModel _model;
  late String _initialPrompt;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _sendInitialPrompt();
  }

  void _initializeGemini() {
    const apiKey =
        'ENTER_GEMINI_API_KEY';
    _model = GenerativeModel(
      model: 'ENTER_GEMINI_MODEL',
      apiKey: apiKey,
    );
  }

  void _sendInitialPrompt() async {
    setState(() {
      _isLoading = true;
    });

    // Format meal details with nutrition table data
    final mealDetails = """
Name: ${widget.meal.name}
Brand: ${widget.meal.brand}
Quantity: ${widget.meal.quantity} ${widget.meal.unit}
Serving Size: ${widget.meal.servingQuantity} ${widget.meal.servingUnit}
""";

    // Format detailed nutrition information
    final nutritionInfo = """
Energy: ${widget.nutritionTableData['energy'] ?? 'N/A'} kcal
Carbohydrates: ${widget.nutritionTableData['carbohydrates'] ?? 'N/A'} g
  of which sugars: ${widget.nutritionTableData['sugars'] ?? 'N/A'} g
Fat: ${widget.nutritionTableData['fat'] ?? 'N/A'} g
  of which saturated: ${widget.nutritionTableData['saturated_fat'] ?? 'N/A'} g
Protein: ${widget.nutritionTableData['protein'] ?? 'N/A'} g
Fiber: ${widget.nutritionTableData['fiber'] ?? 'N/A'} g
Salt: ${widget.nutritionTableData['salt'] ?? 'N/A'} g
""";

    // Format user profile data
    final userProfile = """
Birthday: ${widget.userProfileData['birthday'] ?? 'N/A'}
Height: ${widget.userProfileData['heightCM'] ?? 'N/A'} cm
Weight: ${widget.userProfileData['weightKG'] ?? 'N/A'} kg
Gender: ${widget.userProfileData['gender'] ?? 'N/A'}
Goal: ${widget.userProfileData['goal'] ?? 'N/A'}
Activity Level: ${widget.userProfileData['pal'] ?? 'N/A'}
""";

    // Remove lines with 'N/A' values
    final filteredMealDetails = mealDetails
        .split('\n')
        .where((line) => !line.contains('N/A'))
        .join('\n');
    final filteredNutritionInfo = nutritionInfo
        .split('\n')
        .where((line) => !line.contains('N/A'))
        .join('\n');
    final filteredUserProfile = userProfile
        .split('\n')
        .where((line) => !line.contains('N/A'))
        .join('\n');

    _initialPrompt = """
As a Nutrition Advisor, please analyze the following information:

Meal Details:
$filteredMealDetails

Detailed Nutrition Information:
$filteredNutritionInfo

User Profile and Health Data:
$filteredUserProfile

Please provide:
1. A detailed analysis of this meal's nutritional content and how it fits into the user's daily calorie target
2. Whether this meal is suitable considering the user's diet type, and health goals
3. Health implications and specific recommendations based on the user's profile
4. Suggestions for portion adjustments or complementary foods to better meet the user's needs
5. Any potential concerns regarding allergens or dietary restrictions

Try to keep details simple as possible so that user dont get overwhelmed with too much information.
Dont provide disclaimer, just provide the information.
Also dont mention the above points in respons next time when u get request from user(second time and so on).
""";

    final content = [
      Content.text("You are a qualified Nutrition Advisor. $_initialPrompt"),
    ];
    final response = await _model.generateContent(content);

    setState(() {
      _messages.add(
        ChatMessage(
          text: response.text ?? 'Sorry, no advice available right now.',
          isUser: false,
        ),
      );
      _isLoading = false;
    });
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: _messageController.text, isUser: true));
      _isLoading = true;
    });

    // Maintain context by appending the user's query to the initial prompt
    final userQuery = """
User Query: ${_messageController.text}

Remember the following context:
$_initialPrompt
""";

    final content = [Content.text(userQuery)];
    final response = await _model.generateContent(content);

    setState(() {
      _messages.add(
        ChatMessage(
          text: response.text ?? 'No response available.',
          isUser: false,
        ),
      );
      _isLoading = false;
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          Colors.grey.shade900,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Chat about Nutrients',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ChatBubble(message: message);
                },
              ),
            ),
            if (_isLoading) const CircularProgressIndicator(),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Ask about nutrients...',
                        hintStyle: TextStyle(
                          color: Colors.white70,
                        ), 
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white70,
                          ), 
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white70,
                          ), 
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                          ), 
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.red,
                    ),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              message.isUser
                  ? Colors.red
                  : Colors
                      .grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class MealEntity {
  final String name;
  final String brand; 
  final double quantity;
  final String unit;
  final double servingQuantity;
  final String servingUnit;
 

  MealEntity({
    required this.name,
    required this.brand,
    required this.quantity,
    required this.unit,
    required this.servingQuantity,
    required this.servingUnit,

  });
}
