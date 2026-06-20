import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'forum_provider.dart';
import 'forum_utils.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  String? _selectedCategoryId;
  bool _postAnonymously = false;
  bool _isSubmitting = false;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));
    _loadDraft();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final title = prefs.getString('forum_draft_title') ?? '';
    final body = prefs.getString('forum_draft_body') ?? '';
    if (title.isNotEmpty) _titleController.text = title;
    if (body.isNotEmpty) _bodyController.text = body;
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('forum_draft_title', _titleController.text);
    await prefs.setString('forum_draft_body', _bodyController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved'), backgroundColor: Color(0xFF10B981)),
      );
    }
  }

  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your question'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ForumService.createPost(
        title: title,
        content: body,
        categoryId: _selectedCategoryId,
        isAnonymous: _postAnonymously,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('forum_draft_title');
      await prefs.remove('forum_draft_body');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post submitted for review'), backgroundColor: Color(0xFF10B981)),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
        title: const Text('Create Post', style: TextStyle(color: Color(0xFF0F2042), fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saveDraft,
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
            const Text.rich(TextSpan(children: [
              TextSpan(text: '1. Select Category ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2042))),
              TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
            ])),
            const SizedBox(height: 16),
            _buildCategoryPicker(),
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
                  suffix: Text('${_titleController.text.length}/100', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 3. Describe
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
                      hintText: 'Provide more details about your question or topic.',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Text('${_bodyController.text.length}/2000', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
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

            // 4. Attachments
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

            // Anonymous Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[100]!),
                borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 32),

            // Submit
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
                onPressed: _isSubmitting ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Post Question', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    final categoriesAsync = ref.watch(forumCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategoryId == cat.id;
              final iconData = ForumUtils.getCategoryIcon(cat.iconName);
              final color = ForumUtils.getCategoryColor(cat.iconName);

              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryId = cat.id),
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
                      Icon(iconData, color: color, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
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
        );
      },
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SizedBox(height: 100, child: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildAttachmentButton(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label: Coming soon'), backgroundColor: Colors.blue),
        );
      },
      child: Container(
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
      ),
    );
  }
}
