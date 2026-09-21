import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

class MessagesScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const MessagesScreen({super.key, this.onNavigateTab});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _loading = true;
  bool _sending = false;
  String _lessorName = 'Building Management';
  List<Map<String, dynamic>> _messages = [];
  List<dynamic> _tickets = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadData(initial: true);
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && !_sending) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
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
      final parsedMsgs = rawMsgs.map((m) => Map<String, dynamic>.from(m as Map)).toList();

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
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: false));
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
      _scrollCtrl.animateTo(pos, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _isReportMessage(String body) {
    return body.contains('🛠️ Maintenance Report') ||
        body.contains('Maintenance Report') ||
        body.contains('#SL-') ||
        body.contains('#MT-');
  }

  @override
  Widget build(BuildContext context) {
    // If no messages yet, provide an initial friendly greeting and sample report thread
    final displayMessages = _messages.isNotEmpty
        ? _messages
        : [
            {
              'sender': 'lessor',
              'body': 'Hello Juan! Welcome to Pwestora. How can we help you today?',
              'sent_at': '9:24 AM',
            },
            {
              'sender': 'tenant',
              'body': '🛠️ Maintenance Report (#SL-02481)\nCategory: Comfort Room • Water leakage\nDescription: Water is leaking from the toilet bowl and the floor is wet.\nStatus: Approved',
              'sent_at': '9:25 AM',
            },
            {
              'sender': 'lessor',
              'body': 'We received your report. The plumber has been scheduled for Sep 24 at 10:00 AM.',
              'sent_at': '9:28 AM',
            },
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            // Lessor Avatar with online badge
            Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1B3D),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.business_rounded, color: Colors.white, size: 22),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 11,
                    height: 11,
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
                      fontSize: 16,
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
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: _loading && _messages.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: displayMessages.length,
                      itemBuilder: (context, index) {
                        final msg = displayMessages[index];
                        final isMe = msg['sender'] == 'tenant';
                        final body = msg['body'] ?? '';
                        final isReport = _isReportMessage(body);

                        if (isReport) {
                          return _buildSpecialReportBubble(body, isMe);
                        }

                        return _buildStandardMessageBubble(body, isMe);
                      },
                    ),
            ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type a message to management...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Send button with electric glow
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: _sending ? null : _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: AppDecorations.electricGlowButton(radius: 999),
                      child: Center(
                        child: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SPECIAL INTERACTIVE REPORT BUBBLE =================
  IconData _getReportCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('elect') || cat.contains('light') || cat.contains('power')) {
      return Icons.bolt_rounded;
    } else if (cat.contains('plumb') || cat.contains('water') || cat.contains('leak') || cat.contains('pipe')) {
      return Icons.water_drop_rounded;
    } else if (cat.contains('comfort') || cat.contains('cr') || cat.contains('toilet') || cat.contains('bath')) {
      return Icons.bathtub_outlined;
    } else if (cat.contains('ac') || cat.contains('hvac') || cat.contains('cool')) {
      return Icons.ac_unit_rounded;
    } else if (cat.contains('door') || cat.contains('lock') || cat.contains('key')) {
      return Icons.lock_outline_rounded;
    } else if (cat.contains('clean') || cat.contains('trash') || cat.contains('pest')) {
      return Icons.cleaning_services_outlined;
    }
    return Icons.build_rounded;
  }

  Widget _buildSpecialReportBubble(String body, bool isMe) {
    bool isApproved = body.contains('Approved') ||
        body.contains('Scheduled') ||
        body.toLowerCase().contains('completed') ||
        _tickets.any((t) => (t['stage'] as num? ?? 0) >= 2);

    String ticketNumber = body.contains('#SL-')
        ? body.substring(body.indexOf('#SL-'), (body.indexOf('#SL-') + 9).clamp(0, body.length))
        : '#SL-02481';

    String description = 'Water is leaking from the toilet bowl and the floor is wet.';
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
              color: isApproved ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isApproved ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
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
                        color: isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isApproved ? Icons.check_rounded : Icons.access_time_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isApproved ? 'Report Approved & Scheduled' : 'Report Filed (Pending Review)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isApproved ? const Color(0xFF065F46) : const Color(0xFF92400E),
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
                            const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF1E6BFF)),
                            const SizedBox(width: 6),
                            Text(
                              isApproved ? 'Scheduled: Sep 24 • 10:00 AM' : 'Expected update: Today',
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
                              widget.onNavigateTab!(1); // Switch to Schedule tab
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Switched to Schedule for Sep 24!')),
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
                              Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF1E6BFF)),
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

  // Standard chat bubble
  Widget _buildStandardMessageBubble(String body, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF0B1B3D) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: Border.all(
            color: isMe ? const Color(0xFF0B1B3D) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B1B3D).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          body,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.35,
            color: isMe ? Colors.white : const Color(0xFF0B1B3D),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}