import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/api_service.dart';

class MessagesScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final ValueChanged<bool>? onTypingChanged;

  const MessagesScreen({super.key, this.onNavigateTab, this.onTypingChanged});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _loading = true;
  bool _sending = false;
  String _lessorName = 'Building Management';
  List<Map<String, dynamic>> _messages = [];
  List<dynamic> _tickets = [];
  Timer? _pollingTimer;
  bool _hasText = false;
  final Set<int> _expandedMessageIndices = {};

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      final isTyping = _focusNode.hasFocus || _msgCtrl.text.trim().isNotEmpty;
      widget.onTypingChanged?.call(isTyping);
    });

    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText && mounted) {
        setState(() => _hasText = hasText);
        widget.onTypingChanged?.call(_focusNode.hasFocus || hasText);
      }
    });
    _loadData(initial: true);
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && !_sending) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _focusNode.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool initial = false, bool silent = false}) async {
    if (!silent) setState(() => _loading = true);

    try {
      final res = await ApiService.fetchMessagesThread();
      final lessor = res['lessor_name'] as String?;
      final rawMsgs = (res['messages'] as List<dynamic>?) ?? [];
      final parsedMsgs = rawMsgs
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();

      // Fetch tickets to link live status to report bubbles
      try {
        final t = await ApiService.fetchTickets();
        _tickets = t;
      } catch (_) {}

      if (mounted) {
        setState(() {
          if (lessor != null && lessor.isNotEmpty) {
            _lessorName = lessor;
          }
          _messages = parsedMsgs;
          _loading = false;
        });

        if (initial && _messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(animated: false),
          );
        }
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position.maxScrollExtent;
    if (animated) {
      _scrollCtrl.animateTo(
        pos,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(pos);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      await ApiService.sendMessage(text);
      await _loadData(silent: true);
      _scrollToBottom(animated: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0B1B3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected photo: ${picked.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open photos: $e')),
        );
      }
    }
  }

  bool _isReportMessage(String body) {
    return body.contains('🛠️ Maintenance Report') ||
        body.contains('Maintenance Report') ||
        body.contains('#SL-') ||
        body.contains('#MT-');
  }

  bool _isRestructuringMessage(String body) {
    return body.contains('📋 Payment Restructuring') ||
        body.contains('Restructuring Request') ||
        body.contains('Restructuring Proposal') ||
        body.contains('Restructuring Request Revoked');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Color(0xFF0B1B3D),
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        titleSpacing: Navigator.canPop(context) ? 0 : 16,
        title: Row(
          children: [
            // Avatar matching profile_screen.dart
            Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _lessorName.trim().isNotEmpty
                          ? _lessorName.trim()[0].toUpperCase()
                          : 'M',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981), // Online green
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lessorName,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B1B3D),
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Building Management • Active Lease',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Messages List / Empty State
                Expanded(
                  child: _loading && _messages.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.electricBlue,
                          ),
                        )
                      : _messages.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final isMe = msg['sender'] == 'tenant';
                                final body = msg['body'] ?? '';
                                final sentAt = msg['sent_at']?.toString();
                                final isReport = _isReportMessage(body);
                                final isRestructure =
                                    _isRestructuringMessage(body);
                                final isExpanded =
                                    _expandedMessageIndices.contains(index);

                                Widget bubbleContent;
                                if (isReport) {
                                  bubbleContent =
                                      _buildSpecialReportBubble(body, isMe);
                                } else if (isRestructure) {
                                  bubbleContent =
                                      _buildSpecialRestructuringBubble(
                                          body, isMe);
                                } else {
                                  bubbleContent =
                                      _buildStandardMessageBubble(body, isMe);
                                }

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_expandedMessageIndices
                                          .contains(index)) {
                                        _expandedMessageIndices.remove(index);
                                      } else {
                                        _expandedMessageIndices.add(index);
                                      }
                                    });
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      bubbleContent,
                                      if (isExpanded)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: 2,
                                            bottom: 8,
                                            left: isMe ? 0 : 8,
                                            right: isMe ? 8 : 0,
                                          ),
                                          child: Text(
                                            _formatMessengerTimestamp(
                                                sentAt, isMe),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),

                // Bottom Input Bar (iOS SMS style with + options and pop-in send button)
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 12, 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      // Photo Action Button (replaces plus button)
                      InkWell(
                        onTap: _pickPhoto,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            color: Color(0xFF1E6BFF),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Pill TextField (Pure White, No grey, No hover outline)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _msgCtrl,
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0B1B3D),
                            ),
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              hintText: 'Message...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13.5,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),

                      // Send button that appears ONLY when typing
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: _hasText
                            ? Padding(
                                key: const ValueKey('send_active'),
                                padding: const EdgeInsets.only(left: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: _sending ? null : _sendMessage,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E6BFF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: _sending
                                          ? const SizedBox(
                                              width: 15,
                                              height: 15,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.arrow_upward_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('send_hidden'),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 34,
                color: AppColors.electricBlue,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Direct Management Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No messages yet. Send a direct inquiry or message below to start communicating with your lessor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.ink500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickPromptChip('👋 Hello! Just checking in.'),
                _buildQuickPromptChip('📄 Lease contract question'),
                _buildQuickPromptChip('🔧 Maintenance assistance'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPromptChip(String prompt) {
    return ActionChip(
      label: Text(
        prompt,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        _msgCtrl.text = prompt;
        _sendMessage();
      },
    );
  }

  // ================= SPECIAL INTERACTIVE REPORT BUBBLE =================
  IconData _getReportCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('elect') ||
        cat.contains('light') ||
        cat.contains('power')) {
      return Icons.bolt_rounded;
    } else if (cat.contains('plumb') ||
        cat.contains('water') ||
        cat.contains('leak') ||
        cat.contains('pipe')) {
      return Icons.water_drop_rounded;
    } else if (cat.contains('comfort') ||
        cat.contains('cr') ||
        cat.contains('toilet') ||
        cat.contains('bath')) {
      return Icons.bathtub_outlined;
    } else if (cat.contains('ac') ||
        cat.contains('hvac') ||
        cat.contains('cool')) {
      return Icons.ac_unit_rounded;
    } else if (cat.contains('door') ||
        cat.contains('lock') ||
        cat.contains('key')) {
      return Icons.lock_outline_rounded;
    } else if (cat.contains('clean') ||
        cat.contains('trash') ||
        cat.contains('pest')) {
      return Icons.cleaning_services_outlined;
    }
    return Icons.build_rounded;
  }

  Widget _buildSpecialReportBubble(String body, bool isMe) {
    bool isApproved =
        body.contains('Approved') ||
        body.contains('Scheduled') ||
        body.toLowerCase().contains('completed') ||
        _tickets.any((t) => (t['stage'] as num? ?? 0) >= 2);

    String ticketNumber = body.contains('#SL-')
        ? body.substring(
            body.indexOf('#SL-'),
            (body.indexOf('#SL-') + 9).clamp(0, body.length),
          )
        : '#SL-02481';

    String description =
        'Water is leaking from the toilet bowl and the floor is wet.';
    if (body.contains('Description:')) {
      final descPart = body.split('Description:').last.split('\n').first.trim();
      if (descPart.isNotEmpty) description = descPart;
    }

    String category = 'Comfort Room • Water leakage';
    if (body.contains('Category:')) {
      final catPart = body.split('Category:').last.split('\n').first.trim();
      if (catPart.isNotEmpty) category = catPart;
    }

    final catIcon = _getReportCategoryIcon(category);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isApproved
                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1B3D).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isApproved
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFFBEB),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isApproved
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isApproved
                            ? Icons.check_rounded
                            : Icons.access_time_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isApproved
                            ? 'Report Approved & Scheduled'
                            : 'Report Filed (Pending Review)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isApproved
                              ? const Color(0xFF065F46)
                              : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                    Text(
                      ticketNumber,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Body content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1B3D),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(catIcon, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0B1B3D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 12),

                    // Date & Calendar Direct Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: Color(0xFF1E6BFF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isApproved
                                  ? 'Scheduled: Sep 24 • 10:00 AM'
                                  : 'Expected update: Today',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),

                        // Direct Link Button to Schedule Screen
                        InkWell(
                          onTap: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(
                                1,
                              ); // Switch to Schedule tab
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Switched to Schedule for Sep 24!',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: const [
                              Text(
                                'View in Calendar',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E6BFF),
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Color(0xFF1E6BFF),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildSpecialRestructuringBubble(String body, bool isMe) {
    final isRevoked = body.contains('Revoked') || body.contains('canceled');

    String plan = 'Payment Plan';
    if (body.contains('Plan:')) {
      plan = body.split('Plan:').last.split('\n').first.trim();
    }

    String reason = 'Cash flow delay';
    if (body.contains('Reason:')) {
      final reasonPart = body.split('Reason:').last.split('\n').first.trim();
      if (reasonPart.isNotEmpty) reason = reasonPart;
    }

    String? note;
    if (body.contains('Note:')) {
      final notePart = body
          .split('Note:')
          .last
          .split('\n')
          .first
          .trim()
          .replaceAll('"', '');
      if (notePart.isNotEmpty) note = notePart;
    }

    List<String> scheduleItems = [];
    if (body.contains('Schedule:')) {
      final afterSched = body.split('Schedule:').last;
      final lines = afterSched.split('\n');
      for (final l in lines) {
        final trimmed = l.trim();
        if (trimmed.startsWith('•') || trimmed.startsWith('-')) {
          scheduleItems.add(trimmed);
        } else if (trimmed.startsWith('Status:')) {
          break;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRevoked
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFF1E6BFF).withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1B3D).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isRevoked
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFEFF6FF),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isRevoked
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF1E6BFF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRevoked
                            ? Icons.history_toggle_off_rounded
                            : Icons.handshake_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isRevoked
                            ? 'Restructuring Request Revoked'
                            : 'Payment Restructuring Proposal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isRevoked
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isRevoked
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isRevoked ? 'REVOKED' : '48H COOLING-OFF',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isRevoked
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF1E40AF),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isRevoked) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              plan,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0B1B3D),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Concession Request',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Reason: $reason',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (note != null && note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.format_quote_rounded,
                                size: 14,
                                color: Color(0xFF1E6BFF),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '"$note"',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (scheduleItems.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: scheduleItems.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0B1B3D),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'This restructuring request has been cancelled by the tenant within the 48-hour cooling-off window. The regular lease payment schedule remains active.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.shield_outlined,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Audited Proposal',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(1); // Go to Schedule tab
                            }
                          },
                          child: Row(
                            children: const [
                              Text(
                                'View in Schedule',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E6BFF),
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: Color(0xFF1E6BFF),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  // Standard chat bubble (iOS/Messenger style with Pwestora colors)
  Widget _buildStandardMessageBubble(String body, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1E6BFF) : const Color(0xFFE9EEF5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(19),
            topRight: const Radius.circular(19),
            bottomLeft: Radius.circular(isMe ? 19 : 5),
            bottomRight: Radius.circular(isMe ? 5 : 19),
          ),
          border: isMe
              ? null
              : Border.all(color: const Color(0xFFE2E8F0), width: 0.6),
        ),
        child: Text(
          body,
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: isMe ? Colors.white : const Color(0xFF0B1B3D),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Messenger-style timestamp formatter
  String _formatMessengerTimestamp(String? rawSentAt, bool isMe) {
    if (rawSentAt == null || rawSentAt.isEmpty) {
      return isMe ? 'Sent just now • Delivered' : 'Just now';
    }
    DateTime? dt;
    try {
      dt = DateTime.parse(rawSentAt);
    } catch (_) {
      dt = DateTime.now();
    }
    final localDt = dt.toLocal();
    final now = DateTime.now();

    final isToday =
        localDt.year == now.year &&
        localDt.month == now.month &&
        localDt.day == now.day;

    final hour = localDt.hour > 12
        ? localDt.hour - 12
        : (localDt.hour == 0 ? 12 : localDt.hour);
    final minute = localDt.minute.toString().padLeft(2, '0');
    final ampm = localDt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $ampm';

    final deliveredSuffix = isMe ? ' • Delivered' : '';

    if (isToday) {
      return '$timeStr$deliveredSuffix';
    }

    final diffDays = now.difference(localDt).inDays;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[localDt.weekday - 1];

    if (diffDays <= 6) {
      return '$dayName at $timeStr$deliveredSuffix';
    }

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final monthStr = months[localDt.month - 1];
    return '$monthStr ${localDt.day} AT $timeStr$deliveredSuffix';
  }
}
