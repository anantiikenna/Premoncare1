import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  int _selectedCategoryIndex = 0;
  bool _postAnonymously = false;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'General Health', 'icon': Icons.monitor_heart_outlined, 'color': const Color(0xFF10B981)},
    {'name': 'Nutrition', 'icon': Icons.apple_outlined, 'color': const Color(0xFFF59E0B)},
    {'name': 'Mental Health', 'icon': Icons.psychology_outlined, 'color': const Color(0xFFA855F7)},
    {'name': 'Fitness', 'icon': Icons.fitness_center_outlined, 'color': const Color(0xFF3B82F6)},
    {'name': 'Pregnancy', 'icon': Icons.pregnant_woman_outlined, 'color': const Color(0xFFEC4899)},
    {'name': 'Ask Doctors', 'icon': Icons.medical_services_outlined, 'color': const Color(0xFF14B8A6)},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2042)),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monitor_heart_outlined, color: Color(0xFF0F62FE)),
            const SizedBox(width: 8),
            const Text('Premon', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold)),
            Text('Care', style: TextStyle(color: Colors.cyan[600], fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draft saved'), backgroundColor: Color(0xFF10B981)),
              );
            },
            child: const Text('Save Draft', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create a Post', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F2042))),
            const SizedBox(height: 4),
            Text('Ask a question, share your experience or start a discussion.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 32),
            
            // 1. Select Category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text.rich(TextSpan(children: [
                  TextSpan(text: '1. Select Category ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
                  TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                ])),
                Text('View all', style: TextStyle(color: const Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = index == _selectedCategoryIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = index),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0F62FE).withValues(alpha: 0.05) : Colors.white,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0F62FE) : Colors.grey[200]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat['icon'], color: cat['color'], size: 28),
                          const SizedBox(height: 8),
                          Text(
                            cat['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? const Color(0xFF0F62FE) : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // 2. Post Title
            const Text.rich(TextSpan(children: [
              TextSpan(text: '2. Post Title ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
              TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
            ])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _titleController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'Write a clear and short title for your post',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  counterText: '',
                  suffix: Text('0/100', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 3. Describe Your Question or Topic
            const Text.rich(TextSpan(children: [
              TextSpan(text: '3. Describe Your Question or Topic ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
              TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
            ])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _bodyController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Provide more details about your question or topic. Include symptoms, background, or anything relevant.',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Text('0/2000', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFF0F62FE), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: The more details you provide, the better and more helpful the responses you\'ll receive.',
                    style: TextStyle(color: const Color(0xFF0F62FE), fontSize: 11, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 4. Add Attachments
            const Text.rich(TextSpan(children: [
              TextSpan(text: '4. Add Attachments ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
              TextSpan(text: '(Optional)', style: TextStyle(color: Colors.grey, fontSize: 15)),
            ])),
            const SizedBox(height: 4),
            Text('You can upload images or documents to provide more context.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildAttachmentButton(Icons.image_outlined, 'Add Photo', const Color(0xFF0F62FE))),
                const SizedBox(width: 8),
                Expanded(child: _buildAttachmentButton(Icons.description_outlined, 'Add Document', Colors.teal)),
                const SizedBox(width: 8),
                Expanded(child: _buildAttachmentButton(Icons.science_outlined, 'Add Lab Result', Colors.purple)),
                const SizedBox(width: 8),
                Expanded(child: _buildAttachmentButton(Icons.attach_file, 'Add Other', Colors.grey[600]!)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Supported formats: JPG, PNG, PDF, DOC • Max size: 10MB per file', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            const SizedBox(height: 32),

            // Post Anonymously Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[100]!),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.teal[50], shape: BoxShape.circle),
                    child: Icon(Icons.shield_outlined, color: Colors.teal[600], size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Post Anonymously', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2042))),
                        const SizedBox(height: 2),
                        Text('Your name will be hidden from other members.', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Switch(
                    value: _postAnonymously,
                    onChanged: (v) => setState(() => _postAnonymously = v),
                    activeThumbColor: Colors.teal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Community Guidelines
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC), // Very light slate
                border: Border.all(color: Colors.blue[50]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                    child: const Icon(Icons.verified_user_outlined, color: Color(0xFF0F62FE), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Community Guidelines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2042))),
                        const SizedBox(height: 4),
                        Text(
                          'Please be respectful and follow our community guidelines. Do not share any personal or sensitive information.',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('View Guidelines', style: TextStyle(color: const Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Bottom Actions
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F62FE), Color(0xFF00B4D8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: const Color(0xFF0F62FE).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post submitted for review'), backgroundColor: Color(0xFF10B981)),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Post Question', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                final title = _titleController.text.trim();
                final body = _bodyController.text.trim();
                if (title.isEmpty && body.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Post Preview'),
                      content: const Text('Write something to preview'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(title.isNotEmpty ? title : 'Untitled Post'),
                      content: Text(body.isNotEmpty ? body : 'No description provided.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: BorderSide(color: Colors.grey[200]!, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_outlined, color: Color(0xFF0F62FE), size: 20),
                  SizedBox(width: 8),
                  Text('Preview Post', style: TextStyle(color: Color(0xFF0F62FE), fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[100]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
