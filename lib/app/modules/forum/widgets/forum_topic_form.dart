import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/modules/forum/controllers/forum_controller.dart';
import 'package:classroom_mini/app/modules/forum/design/forum_design_system.dart';
import 'package:classroom_mini/app/shared/widgets/shared_file_attachment_picker.dart';
import 'package:classroom_mini/app/shared/models/uploaded_attachment.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';

/**
 * Enhanced Forum Topic Form Widget
 * Implements advanced form design with real-time validation and smart defaults
 */
class ForumTopicForm extends StatefulWidget {
  const ForumTopicForm({super.key});

  @override
  State<ForumTopicForm> createState() => _ForumTopicFormState();
}

class _ForumTopicFormState extends State<ForumTopicForm>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isPosting = false;
  bool _canPostTopic = false;
  String? _titleError;
  String? _contentError;
  int _charCount = 0;
  List<SubmissionAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupListeners();
    _setupSmartDefaults();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: ForumDesignSystem.animationNormal,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: ForumDesignSystem.animationFast,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: ForumAnimations.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: ForumAnimations.easeInOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  void _setupListeners() {
    _titleController.addListener(_validateTitle);
    _contentController.addListener(_validateContent);
    _titleFocusNode.addListener(_onTitleFocusChanged);
    _contentFocusNode.addListener(_onContentFocusChanged);
  }

  void _setupSmartDefaults() {
    // Auto-focus on title field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_validateTitle);
    _contentController.removeListener(_validateContent);
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    _contentFocusNode.removeListener(_onContentFocusChanged);

    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();

    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _validateTitle() {
    final title = _titleController.text.trim();
    String? error;

    if (title.isEmpty) {
      error = null; // Don't show error when empty
    } else if (title.length < 5) {
      error = 'Title must be at least 5 characters';
    } else if (title.length > 100) {
      error = 'Title must be less than 100 characters';
    }

    if (error != _titleError) {
      setState(() => _titleError = error);
    }

    _validateForm();
  }

  void _validateContent() {
    final content = _contentController.text.trim();
    String? error;

    setState(() => _charCount = content.length);

    if (content.isEmpty) {
      error = null; // Don't show error when empty
    } else if (content.length < 10) {
      error = 'Content must be at least 10 characters';
    } else if (content.length > 1000) {
      error = 'Content must be less than 1000 characters';
    }

    if (error != _contentError) {
      setState(() => _contentError = error);
    }

    _validateForm();
  }

  void _validateForm() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final canPost = title.isNotEmpty &&
        content.isNotEmpty &&
        _titleError == null &&
        _contentError == null;

    if (canPost != _canPostTopic) {
      setState(() => _canPostTopic = canPost);
    }
  }

  void _onTitleFocusChanged() {
    if (_titleFocusNode.hasFocus && _titleController.text.isEmpty) {
      HapticFeedback.lightImpact();
    }
  }

  void _onContentFocusChanged() {
    if (_contentFocusNode.hasFocus && _contentController.text.isEmpty) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: ForumDesignSystem.getSurfaceColor(context, isElevated: true),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(ForumDesignSystem.radiusXL),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: ForumDesignSystem.spacingMD,
                right: ForumDesignSystem.spacingMD,
                top: ForumDesignSystem.spacingMD,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    ForumDesignSystem.spacingMD,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  SizedBox(height: ForumDesignSystem.spacingLG),
                  _buildForm(context),
                  SizedBox(height: ForumDesignSystem.spacingLG),
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(ForumDesignSystem.spacingSM),
          decoration: BoxDecoration(
            color: ForumDesignSystem.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
          ),
          child: Icon(
            Icons.edit_note,
            color: ForumDesignSystem.primary,
            size: ForumDesignSystem.iconMD,
          ),
        ),
        SizedBox(width: ForumDesignSystem.spacingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Topic',
                style: ForumDesignSystem.headingStyle.copyWith(
                  color: ForumDesignSystem.getTextColor(context),
                ),
              ),
              Text(
                'Start a new discussion',
                style: ForumDesignSystem.captionStyle.copyWith(
                  color: ForumDesignSystem.getTextColor(context,
                      isSecondary: true),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close,
            color: ForumDesignSystem.getTextColor(context, isSecondary: true),
          ),
          style: IconButton.styleFrom(
            backgroundColor: ForumDesignSystem.getSurfaceColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        _buildTitleField(context),
        SizedBox(height: ForumDesignSystem.spacingMD),
        _buildContentField(context),
        SizedBox(height: ForumDesignSystem.spacingMD),
        _buildAttachmentSection(context),
      ],
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topic Title',
          style: ForumDesignSystem.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: ForumDesignSystem.getTextColor(context),
          ),
        ),
        SizedBox(height: ForumDesignSystem.spacingSM),
        TextField(
          controller: _titleController,
          focusNode: _titleFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _contentFocusNode.requestFocus(),
          decoration: InputDecoration(
            hintText: 'Enter a clear, descriptive title...',
            hintStyle: ForumDesignSystem.bodyStyle.copyWith(
              color: ForumDesignSystem.getTextColor(context, isSecondary: true),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              borderSide: BorderSide(
                color:
                    ForumDesignSystem.getTextColor(context, isSecondary: true),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              borderSide: BorderSide(
                color:
                    ForumDesignSystem.getTextColor(context, isSecondary: true),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              borderSide: BorderSide(
                color: ForumDesignSystem.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              borderSide: BorderSide(
                color: ForumDesignSystem.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              borderSide: BorderSide(
                color: ForumDesignSystem.error,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.all(ForumDesignSystem.spacingMD),
            prefixIcon: Icon(
              Icons.title,
              color: ForumDesignSystem.getTextColor(context, isSecondary: true),
            ),
            suffixText: '${_titleController.text.length}/100',
            suffixStyle: ForumDesignSystem.captionStyle.copyWith(
              color: ForumDesignSystem.getTextColor(context, isSecondary: true),
            ),
            errorText: _titleError,
            errorStyle: ForumDesignSystem.captionStyle.copyWith(
              color: ForumDesignSystem.error,
            ),
          ),
          maxLength: 100,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildContentField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content',
          style: ForumDesignSystem.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: ForumDesignSystem.getTextColor(context),
          ),
        ),
        SizedBox(height: ForumDesignSystem.spacingSM),
        TextField(
          controller: _contentController,
          focusNode: _contentFocusNode,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText:
                'What would you like to discuss? Be specific and clear...',
            hintStyle: ForumDesignSystem.bodyStyle.copyWith(
              color: ForumDesignSystem.getTextColor(context, isSecondary: true),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              borderSide: BorderSide(
                color:
                    ForumDesignSystem.getTextColor(context, isSecondary: true),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              borderSide: BorderSide(
                color:
                    ForumDesignSystem.getTextColor(context, isSecondary: true),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              borderSide: BorderSide(
                color: ForumDesignSystem.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              borderSide: BorderSide(
                color: ForumDesignSystem.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              borderSide: BorderSide(
                color: ForumDesignSystem.error,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.all(ForumDesignSystem.spacingMD),
            prefixIcon: Icon(
              Icons.description,
              color: ForumDesignSystem.getTextColor(context, isSecondary: true),
            ),
            suffixText: '$_charCount/1000',
            suffixStyle: ForumDesignSystem.captionStyle.copyWith(
              color: _charCount > 1000
                  ? ForumDesignSystem.error
                  : ForumDesignSystem.getTextColor(context, isSecondary: true),
            ),
            errorText: _contentError,
            errorStyle: ForumDesignSystem.captionStyle.copyWith(
              color: ForumDesignSystem.error,
            ),
          ),
          maxLength: 1000,
          maxLines: 6,
          minLines: 3,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding:
                  EdgeInsets.symmetric(vertical: ForumDesignSystem.spacingMD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              ),
              side: BorderSide(
                color:
                    ForumDesignSystem.getTextColor(context, isSecondary: true),
              ),
            ),
            child: Text(
              'Cancel',
              style: ForumDesignSystem.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: ForumDesignSystem.getTextColor(context),
              ),
            ),
          ),
        ),
        SizedBox(width: ForumDesignSystem.spacingMD),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _canPostTopic && !_isPosting ? _postTopic : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ForumDesignSystem.primary,
              foregroundColor: Colors.white,
              padding:
                  EdgeInsets.symmetric(vertical: ForumDesignSystem.spacingMD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              ),
              elevation: _canPostTopic ? ForumDesignSystem.elevationMD : 0,
            ),
            child: _isPosting
                ? SizedBox(
                    width: ForumDesignSystem.iconMD,
                    height: ForumDesignSystem.iconMD,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send,
                        size: ForumDesignSystem.iconSM,
                      ),
                      SizedBox(width: ForumDesignSystem.spacingSM),
                      Text(
                        'Post Topic',
                        style: ForumDesignSystem.bodyStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentSection(BuildContext context) {
    return SharedFileAttachmentPicker(
      tag: 'forum_topic_${DateTime.now().millisecondsSinceEpoch}',
      onAttachmentsChanged: _onAttachmentsChanged,
      maxFiles: 10,
      maxFileSizeMB: 10,
      allowedExtensions: [
        // Images
        'jpg', 'jpeg', 'png', 'gif', 'webp',
        // Documents
        'pdf', 'doc', 'docx', 'txt',
        // Spreadsheets
        'xls', 'xlsx', 'csv',
        // Presentations
        'ppt', 'pptx',
        // Archives
        'zip', 'rar',
        // Code files
        'py', 'js', 'ts', 'html', 'css', 'json',
      ],
    );
  }

  void _onAttachmentsChanged(List<UploadedAttachment> attachments) {
    setState(() {
      _attachments = attachments
          .where((att) => att.isUploaded && att.attachmentId != null)
          .map((att) => SubmissionAttachment(
                id: att.attachmentId!,
                fileName: att.fileName,
                fileUrl: att.fileUrl!,
                fileSize: att.fileSize,
                fileType: att.fileType,
                createdAt: DateTime.now(),
              ))
          .toList();
    });
  }

  Future<void> _postTopic() async {
    if (!_canPostTopic || _isPosting) return;

    setState(() => _isPosting = true);
    HapticFeedback.mediumImpact();

    try {
      final controller = Get.find<ForumController>();
      await controller.createTopic(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        attachmentIds: _attachments.isNotEmpty
            ? _attachments.map((att) => att.id).toList()
            : null,
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      Get.snackbar(
        'Error',
        'Failed to create topic: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ForumDesignSystem.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }
}
