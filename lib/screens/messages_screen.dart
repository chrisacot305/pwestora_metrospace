import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/api_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  String? _lessorName;
  List<Map<String, dynamic>> _messages = [];
  Timer? _pollingTimer;

  // Attached image state before sending
  Uint8List? _attachedImageBytes;
  String? _attachedImageName;

  final List<String> _quickPrompts = [
    'Rent payment query',
    'Maintenance update request',
    'Request lease copy',
    'Building access inquiry',
  ];

  @override
  void initState() {
    super.initState();
    _fetchMessages(initial: true);
    // Poll for new messages every 10 seconds while on this screen
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !_isSending) {
        _fetchMessages(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool initial = false, bool silent = false}) async {
    if (!silent && initial) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final res = await ApiService.fetchMessagesThread();
      if (!mounted) return;

      final lessor = res['lessor_name'] as String?;
      final rawMsgs = (res['messages'] as List<dynamic>?) ?? [];
      final parsed = rawMsgs.map((m) => Map<String, dynamic>.from(m as Map)).toList();

      final hadNewMessages = parsed.length != _messages.length;

      setState(() {
        _lessorName = lessor;
        _messages = parsed;
        _isLoading = false;
        _errorMessage = null;
      });

      if (hadNewMessages) {
        _scrollToBottom(animated: !initial);
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuad,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1440,
        maxHeight: 1440,
        imageQuality: 80,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _attachedImageBytes = bytes;
        _attachedImageName = file.name;
      });

      HapticFeedback.lightImpact();
      _focusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImageSourcePicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Attach Media',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink900),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Take Photo',
                      color: const Color(0xFF2563EB),
                      bg: const Color(0xFFEFF6FF),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Photo Gallery',
                      color: const Color(0xFF059669),
                      bg: const Color(0xFFECFDF5),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    final hasImage = _attachedImageBytes != null;

    if ((text.isEmpty && !hasImage) || _isSending) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isSending = true;
    });

    final imageBytesToSend = _attachedImageBytes;
    _controller.clear();
    setState(() {
      _attachedImageBytes = null;
      _attachedImageName = null;
    });

    // Format body with image payload if attached
    String payloadBody = text;
    if (imageBytesToSend != null) {
      final base64String = base64Encode(imageBytesToSend);
      if (text.isNotEmpty) {
        payloadBody = '[IMG:$base64String]\n$text';
      } else {
        payloadBody = '[IMG:$base64String]';
      }
    }

    // Optimistically add message to UI
    final tempMsg = {
      'sender': 'tenant',
      'body': payloadBody,
      'notice_type': null,
      'sent_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(tempMsg);
    });
    _scrollToBottom(animated: true);

    try {
      await ApiService.sendMessage(payloadBody);
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      // Refresh to synchronize with server timestamp & state
      _fetchMessages(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveLease = _lessorName != null && _lessorName!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(hasActiveLease),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildBody(hasActiveLease),
            ),
            if (hasActiveLease) _buildComposer(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool hasActiveLease) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF102340), Color(0xFF264875)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: hasActiveLease
                  ? Text(
                      _getInitials(_lessorName ?? 'Lessor'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    )
                  : const Icon(Icons.maps_home_work_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasActiveLease ? (_lessorName ?? 'Property Lessor') : 'Direct Messaging',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: hasActiveLease ? AppColors.success : AppColors.steel,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasActiveLease ? 'Verified Lessor · Active Lease' : 'Property Management',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: hasActiveLease ? AppColors.success : AppColors.ink500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.ink700, size: 22),
          tooltip: 'Refresh conversation',
          onPressed: () => _fetchMessages(silent: false),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.border.withValues(alpha: 0.6), height: 1),
      ),
    );
  }

  Widget _buildBody(bool hasActiveLease) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: AppDecorations.squircle(color: AppColors.errorSoft),
                child: const Icon(Icons.cloud_off_rounded, size: 32, color: AppColors.error),
              ),
              const SizedBox(height: 18),
              const Text(
                'Unable to load messages',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink900),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.ink500, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _fetchMessages(initial: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasActiveLease) {
      return _buildNoLeaseState();
    }

    if (_messages.isEmpty) {
      return _buildEmptyMessagesState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _fetchMessages(silent: false),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        itemCount: _messages.length + 1, // +1 for the top disclaimer banner
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSecurityBanner();
          }

          final msgIndex = index - 1;
          final msg = _messages[msgIndex];
          final prevMsg = msgIndex > 0 ? _messages[msgIndex - 1] : null;

          final showDateHeader = _shouldShowDateHeader(msg, prevMsg);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDateHeader) _buildDateHeader(msg['sent_at']),
              _buildMessageItem(msg),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Official Lessor Channel',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This is a private, direct channel with ${_lessorName ?? "your lessor"}. Formal notices, photos, and payment updates are logged here.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.ink500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLeaseState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.tint, width: 1.5),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 22),
            const Text(
              'No Active Lease Yet',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Direct messaging with property management unlocks automatically once you have an approved and active property lease.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink500,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text(
                    'Check your Applications tab for lease updates',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMessagesState() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _fetchMessages(silent: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(20),
        children: [
          _buildSecurityBanner(),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, size: 28, color: AppColors.primaryLight),
                ),
                const SizedBox(height: 18),
                Text(
                  'Say hello to ${_lessorName ?? "your Lessor"}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Send messages, questions, or attach photos of maintenance issues and payment receipts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.ink500,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _quickPrompts.map((prompt) {
                    return ActionChip(
                      label: Text(
                        prompt,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      backgroundColor: AppColors.surface,
                      elevation: 0,
                      pressElevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.tint),
                      ),
                      onPressed: () {
                        _controller.text = prompt;
                        _focusNode.requestFocus();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(dynamic sentAt) {
    final label = _formatDateDivider(sentAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.8), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.8), thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final isMe = msg['sender'] == 'tenant';
    final noticeType = msg['notice_type'] as String?;
    final rawBody = msg['body']?.toString() ?? '';
    final sentAt = msg['sent_at'];

    // Formal Lessor Notice Card
    if (noticeType != null && noticeType.isNotEmpty) {
      return _buildNoticeCard(noticeType, rawBody, sentAt);
    }

    final parsed = _parseMessageBody(rawBody);

    if (isMe) {
      return _buildMyMessageBubble(parsed, sentAt);
    } else {
      return _buildLessorMessageBubble(parsed, sentAt);
    }
  }

  Widget _buildNoticeCard(String type, String body, dynamic sentAt) {
    final (badgeBg, badgeColor, icon) = _getNoticeStyle(type);
    final parsed = _parseMessageBody(body);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: badgeColor),
                    const SizedBox(width: 5),
                    Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(sentAt),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink300,
                ),
              ),
            ],
          ),
          if (parsed.imageBytes != null || parsed.imageUrl != null) ...[
            const SizedBox(height: 12),
            _buildChatImageThumbnail(parsed, isMe: false),
          ],
          if (parsed.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              parsed.text,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.ink900,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.campaign_outlined, size: 14, color: AppColors.ink500),
              const SizedBox(width: 5),
              Text(
                'Formal Announcement from ${_lessorName ?? "Management"}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyMessageBubble(_ParsedMessage parsed, dynamic sentAt) {
    final hasImage = parsed.imageBytes != null || parsed.imageUrl != null;

    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 4, bottom: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: hasImage
              ? const EdgeInsets.fromLTRB(6, 6, 6, 10)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF102340), Color(0xFF1B3B6F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF102340).withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasImage) ...[
                _buildChatImageThumbnail(parsed, isMe: true),
                if (parsed.text.isNotEmpty) const SizedBox(height: 8),
              ],
              if (parsed.text.isNotEmpty)
                Padding(
                  padding: hasImage ? const EdgeInsets.symmetric(horizontal: 8) : EdgeInsets.zero,
                  child: Text(
                    parsed.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Padding(
                padding: hasImage ? const EdgeInsets.only(right: 6) : EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(sentAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessorMessageBubble(_ParsedMessage parsed, dynamic sentAt) {
    final hasImage = parsed.imageBytes != null || parsed.imageUrl != null;

    return Padding(
      padding: const EdgeInsets.only(right: 48, top: 4, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.tint),
              ),
              child: Center(
                child: Text(
                  _getInitials(_lessorName ?? 'L'),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Flexible(
              child: Container(
                padding: hasImage
                    ? const EdgeInsets.fromLTRB(6, 6, 6, 10)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                  ),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasImage) ...[
                      _buildChatImageThumbnail(parsed, isMe: false),
                      if (parsed.text.isNotEmpty) const SizedBox(height: 8),
                    ],
                    if (parsed.text.isNotEmpty)
                      Padding(
                        padding: hasImage ? const EdgeInsets.symmetric(horizontal: 8) : EdgeInsets.zero,
                        child: Text(
                          parsed.text,
                          style: const TextStyle(
                            color: AppColors.ink900,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: hasImage ? const EdgeInsets.only(left: 6) : EdgeInsets.zero,
                      child: Text(
                        _formatTime(sentAt),
                        style: const TextStyle(
                          color: AppColors.ink300,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatImageThumbnail(_ParsedMessage parsed, {required bool isMe}) {
    return GestureDetector(
      onTap: () => _openFullscreenImage(parsed),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 220,
            minWidth: 160,
            maxWidth: 260,
          ),
          color: Colors.black12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (parsed.imageBytes != null)
                Image.memory(
                  parsed.imageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (ctx, err, stack) => _buildImageError(),
                )
              else if (parsed.imageUrl != null)
                Image.network(
                  parsed.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (ctx, err, stack) => _buildImageError(),
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 140,
                      color: isMe ? Colors.white10 : Colors.black12,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                      ),
                    );
                  },
                ),
              // Subtle zoom hint icon overlay on hover/tap
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 120,
      color: Colors.black12,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: AppColors.ink300, size: 32),
      ),
    );
  }

  void _openFullscreenImage(_ParsedMessage parsed) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              _lessorName != null ? 'Shared with $_lessorName' : 'Image Preview',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.8,
                maxScale: 4.0,
                child: parsed.imageBytes != null
                    ? Image.memory(parsed.imageBytes!, fit: BoxFit.contain)
                    : (parsed.imageUrl != null
                        ? Image.network(parsed.imageUrl!, fit: BoxFit.contain)
                        : const SizedBox.shrink()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final hasAttachedImage = _attachedImageBytes != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview Banner if an image is selected
          if (hasAttachedImage) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.tint),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _attachedImageBytes!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _attachedImageName ?? 'Photo Attachment',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(_attachedImageBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB · Ready to send',
                          style: const TextStyle(fontSize: 11, color: AppColors.ink500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.ink500),
                    onPressed: () {
                      setState(() {
                        _attachedImageBytes = null;
                        _attachedImageName = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Media Attachment Button (Camera / Gallery)
              Container(
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                child: Material(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isSending ? null : _showImageSourcePicker,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 14, color: AppColors.ink900),
                    decoration: InputDecoration(
                      hintText: hasAttachedImage ? 'Add a caption…' : 'Type your message…',
                      hintStyle: const TextStyle(color: AppColors.ink300, fontSize: 13.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF102340), Color(0xFF264875)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: _isSending ? null : _handleSend,
                    child: Center(
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper Methods ---

  _ParsedMessage _parseMessageBody(String raw) {
    // Pattern matching for [IMG:base64 or url]
    final imgReg = RegExp(r'\[IMG:(.+?)\]');
    final match = imgReg.firstMatch(raw);

    if (match != null) {
      final imgContent = match.group(1)!.trim();
      final textWithoutImg = raw.replaceFirst(match.group(0)!, '').trim();

      if (imgContent.startsWith('http://') || imgContent.startsWith('https://')) {
        return _ParsedMessage(imageUrl: imgContent, text: textWithoutImg);
      } else {
        try {
          final cleanBase64 = imgContent.contains(',') ? imgContent.split(',').last : imgContent;
          final bytes = base64Decode(cleanBase64);
          return _ParsedMessage(imageBytes: bytes, text: textWithoutImg);
        } catch (_) {
          return _ParsedMessage(text: raw);
        }
      }
    }

    // Also handle raw data:image/... or direct URL if sent plain
    if (raw.startsWith('data:image/')) {
      try {
        final commaIdx = raw.indexOf(',');
        if (commaIdx != -1) {
          final bytes = base64Decode(raw.substring(commaIdx + 1));
          return _ParsedMessage(imageBytes: bytes, text: '');
        }
      } catch (_) {}
    }

    return _ParsedMessage(text: raw);
  }

  (Color bg, Color text, IconData icon) _getNoticeStyle(String type) {
    switch (type.toLowerCase()) {
      case 'payment reminder':
        return (AppColors.warningSoft, AppColors.warning, Icons.receipt_long_rounded);
      case 'maintenance update':
        return (AppColors.successSoft, AppColors.success, Icons.handyman_rounded);
      case 'policy update':
      case 'compliance notice':
        return (AppColors.errorSoft, AppColors.error, Icons.gavel_rounded);
      case 'general notice':
      default:
        return (AppColors.accentSoft, AppColors.primaryLight, Icons.campaign_rounded);
    }
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'L';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  bool _shouldShowDateHeader(Map<String, dynamic> current, Map<String, dynamic>? previous) {
    if (previous == null) return true;
    final curDate = _parseDate(current['sent_at']);
    final prevDate = _parseDate(previous['sent_at']);
    if (curDate == null || prevDate == null) return false;
    return curDate.year != prevDate.year || curDate.month != prevDate.month || curDate.day != prevDate.day;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDateDivider(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return 'Recent';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diffDays = today.difference(target).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return '';
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class _ParsedMessage {
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String text;

  _ParsedMessage({this.imageBytes, this.imageUrl, required this.text});
}