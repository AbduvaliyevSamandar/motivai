import 'package:flutter/material.dart';
import '../models/models.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initial AI greeting
    _messages.add({
      'sender': 'ai',
      'content': 'Salom! 👋 Men sizning motivatsiya konsultantingizman. Kundalik, haftalik yoki oylik motivatsion rejani yaratishimni xohlaysizmi?',
      'timestamp': DateTime.now(),
    });
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add({
        'sender': 'user',
        'content': userMessage,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });

    // Simulate AI response with delay
    Future.delayed(Duration(seconds: 2), () {
      _generateMotivationPlan(userMessage);
    });
  }

  void _generateMotivationPlan(String userInput) {
    String aiResponse = '';

    if (userInput.toLowerCase().contains('kundalik') || userInput.toLowerCase().contains('daily')) {
      aiResponse = '''📋 **Kundalik Motivatsion Rejangiz**

🌅 **Ertalab (8:00-10:00)**
- 10 min: Yoga yoki meditatsiya
- 30 min: Eng qiyin fanni o'qish
- 20 min: Istirahat va qahva

☀️ **Kunning o'rtasi (12:00-15:00)**
- 45 min: Asosiy dars
- 15 min: Yum yum snack
- 30 min: Practical work

🌆 **Kechasi (17:00-20:00)**
- 30 min: Exercise/Walk
- 45 min: Homework
- 15 min: Relax va reading

⭐ **Bugungi Maqsadlar:**
✅ 3 soat o'qish
✅ 100 belgi topish
✅ 1 proyekt tugatish

**Motivatsiyaga yaxshi qo'shimcha:** Har 2 soatda 15 min tanaffus oling!''';
    } else if (userInput.toLowerCase().contains('hafta') || userInput.toLowerCase().contains('week')) {
      aiResponse = '''📅 **Haftalik Motivatsion Rejangiz**

**Dushanba-Chorshanba:** Asosiy darslar (6 soat)
**Payshanba-Juma:** Practical kunlari (4 soat)
**Shanba:** Review va test (3 soat)
**Yakshanba:** Rest day + Planning

**Haftalik Maqsadlar:**
🎯 20 soat o'qish
🎯 5000 belgi olish
🎯 2 proyekt yakunlash
🎯 Streakni 7 kunga yetkazish

**Motivatsiyangizni saqlash uchun:**
💪 Her kuni 10 min exercise
📖 Kitob o'qishga 30 min bag'ishlang
🎉 Shanba oqshomi o'zingizni mukofotlang!''';
    } else if (userInput.toLowerCase().contains('oylik') || userInput.toLowerCase().contains('monthly')) {
      aiResponse = '''📊 **Oylik Motivatsion Rejangiz**

**1-2-HAFTA:** Foundation
- Asosiy konseptlarni o'zlashtirish
- Kundalik rutini o'rnatish
- Target: 30 soat o'qish

**3-4-HAFTA:** Acceleration
- Murakkab mavzularni o'zlashtirish
- Proyekt ishlari boshlash
- Target: 35 soat o'qish

**5-6-HAFTA:** Mastery
- Barcha mavzularni takrorlash
- Proyektlarni tugatish
- Target: 40 soat o'qish

**OY OXIRI:** Celebration
- Test va imtixonna tayyorgarlik
- Oshkorlamalarni yakunlash
- O'zingizni mukofotlang!

**Oylik Challenge:** 
🏆 Streakni 30 kunga yetkazish
🏆 10,000+ belgi topish
🏆 Reyting TOP 20 ga kiritilish''';
    } else {
      aiResponse = '''🤖 **AI Motivatsiya Konsultanti**

Iltimos, quyidagilardan birini tanlang:

1️⃣ **Kundalik reja** - 3-6 soat davomiyligi
2️⃣ **Haftalik reja** - 7 kunlik plan
3️⃣ **Oylik reja** - 30 kunlik strategy
4️⃣ **Shaxsiy maqsad** - O'zingizni belgilang

Misol: "Kundalik motivatsion rejani tuzib ber" yoki "Oylik plan chizib ber"

📌 **Tips:** Rejalaringiz avtomatik taskga qo'shiladi va notifikatsiya olasiz!''';
    }

    setState(() {
      _messages.add({
        'sender': 'ai',
        'content': aiResponse,
        'timestamp': DateTime.now(),
      });
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 12),
            Text('MotivAI Assistant'),
          ],
        ),
        backgroundColor: Color(0xFF2563EB),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isUser = message['sender'] == 'user';
                return _buildMessageBubble(message['content'], isUser);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Reja tuzilmoqda...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Rejani so\'rang...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _isLoading ? null : _sendMessage,
                  backgroundColor: Color(0xFF2563EB),
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Color(0xFF2563EB) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
