import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
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
        const SnackBar(content: Text\('Draft\ saved'\), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your question'), backgroundColor: AppColors.warning),
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
          const SnackBar(content: Text('Post submitted for review'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimaryOf(context)),
          onPressed: () => context.pop(),
        ),
        title: Text('Create Post', style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saveDraft,
            child: const Text('Save Draft', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create a Post', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
            const SizedBox(height: 4),
            Text('Ask a question, share your experience or start a discussion.', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13)),
            const SizedBox(height: 32),

            Text.rich(TextSpan(children: [
              TextSpan(text: '1. Select Category ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimaryOf(context))),
              const TextSpan(text: '*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 15)),
            ])),
            const SizedBox(height: 16),
            _buildCategoryPicker(),
            const SizedBox(height: 32),

            Text.rich(TextSpan(children: [
              TextSpan(text: '2. Post Title ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimaryOf(context))),
              const TextSpan(text: '*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 15)),
            ])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                border: Border.all(color: AppColors.borderOf(context)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _titleController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'Write a clear and short title for your post',
                  hintStyle: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14),
                  border: InputBorder.none,
                  counterText: '',
                  suffix: Text('${_titleController.text.length}/100', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text.rich(TextSpan(children: [
              TextSpan(text: '3. Describe Your Question or Topic ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimaryOf(context))),
              const TextSpan(text: '*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 15)),
            ])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                border: Border.all(color: AppColors.borderOf(context)),
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
                      hintStyle: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14, height: 1.5),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Text('${_bodyController.text.length}/2000', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: The more details you provide, the better and more helpful the responses you\'ll receive.',
                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text.rich(TextSpan(children: [
              TextSpan(text: '4. Add Attachments ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimaryOf(context))),
              TextSpan(text: '(Optional)', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 15)),
            ])),
            const SizedBox(height: 4),
            Text('You can upload images or documents to provide more context.', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildAttachmentButton(Icons.image_outlined, 'Add Photo', AppColors.primary)),
                const SizedBox(width: 8),
                Expanded(child: _buildAttachmentButton(Icons.description_outlined, 'Add Document', AppColors.teal)),
                const SizedBox(width: 8),
                Expanded(child: _buildAttachmentButton(Icons.science_outlined, 'Add Lab Result', AppColors.pink)),
                const SizedBox(width: 8),
                Expanded(child: _buildAttachmentButton(Icons.attach_file, 'Add Other', AppColors.textSecondaryOf(context))),
              ],
            ),
            const SizedBox(height: 12),
            Text('Supported formats: JPG, PNG, PDF, DOC • Max size: 10MB per file', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 10)),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                border: Border.all(color: AppColors.borderLightOf(context)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.successLightOf(context), shape: BoxShape.circle),
                    child: Icon(Icons.shield_outlined, color: AppColors.teal, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Post Anonymously', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryOf(context))),
                        const SizedBox(height: 2),
                        Text('Your name will be hidden from other members.', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context))),
                      ],
                    ),
                  ),
                  Switch(
                    value: _postAnonymously,
                    onChanged: (v) => setState(() => _postAnonymously = v),
                    activeThumbColor: AppColors.teal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.info],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
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
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 2.5))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, color: AppColors.textInverse, size: 20),
                          SizedBox(width: 8),
                          Text('Post Question', style: TextStyle(color: AppColors.textInverse, fontSize: 16, fontWeight: FontWeight.bold)),
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
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surfaceOf(context),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.borderOf(context),
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
                          color: isSelected ? AppColors.primary : AppColors.textPrimaryOf(context),
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
          SnackBar(content: Text('$label: Coming soon'), backgroundColor: AppColors.info),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          border: Border.all(color: AppColors.borderLightOf(context)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4))],
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
