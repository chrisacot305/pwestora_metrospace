import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'tickets_list_screen.dart';

class TicketCreateScreen extends StatefulWidget {
  const TicketCreateScreen({super.key});

  @override
  State<TicketCreateScreen> createState() => _TicketCreateScreenState();
}

class _TicketCreateScreenState extends State<TicketCreateScreen> {
  String? _category;
  String _priority = 'medium';
  final _titleCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  final _categories = const [
    ('plumbing', 'Plumbing'),
    ('electrical', 'Electrical'),
    ('structural', 'Structural'),
    ('internet', 'Internet'),
    ('hvac', 'HVAC / AC'),
    ('cleaning', 'Cleaning'),
    ('security', 'Security'),
    ('lighting', 'Lighting'),
  ];

  final _priorities = const [
    ('low', 'Low'),
    ('medium', 'Medium'),
    ('high', 'High'),
    ('urgent', 'Urgent'),
  ];

  Future<void> _submit() async {
    if (_category == null) {
      setState(() => _error = 'Please select a category.');
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please describe the issue in detail.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.createTicket(
        category: _category!,
        priority: _priority,
        title: _titleCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Report an Issue'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 20, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Step 1: Category Selection
              const Text(
                '1. Select Issue Category',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink900),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
                children: _categories.map((c) {
                  final active = _category == c.$1;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _category = c.$1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active ? AppColors.primary : AppColors.border,
                          width: active ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF102340).withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            kCategoryIcons[c.$1] ?? Icons.build_outlined,
                            size: 22,
                            color: active ? Colors.white : AppColors.primaryLight,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.$2,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                              color: active ? Colors.white : AppColors.ink900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Step 2: Priority Level
              const Text(
                '2. Priority Level',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink900),
              ),
              const SizedBox(height: 12),
              Row(
                children: _priorities.map((p) {
                  final active = _priority == p.$1;
                  final (color, bg) = kPriorityColors[p.$1]!;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _priority = p.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: active ? color : bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active ? color : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            p.$2,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: active ? Colors.white : color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Step 3: Issue Description
              const Text(
                '3. Describe the Problem',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please mention exact location (unit, floor) and when the issue started.',
                style: TextStyle(fontSize: 12.5, color: AppColors.ink500),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "E.g., Water leakage under the sink in Unit 204. Started this morning...",
                ),
              ),
              const SizedBox(height: 20),

              // Photo Placeholder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.accent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Attach Photos or Receipts (Optional)',
                      style: TextStyle(color: AppColors.ink700, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Submit Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
