import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../theme/app_colors.dart';

class ChatPage extends StatefulWidget {
  final int jobId;
  final String title;

  const ChatPage({
    super.key,
    required this.jobId,
    required this.title,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isSending = false;
  bool _showScrollFab = false;
  String? _error;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _loadMessages(silent: true),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final distanceFromBottom =
        _scrollController.position.maxScrollExtent -
            _scrollController.position.pixels;
    final shouldShow = distanceFromBottom > 200;
    if (shouldShow != _showScrollFab) {
      setState(() => _showScrollFab = shouldShow);
    }
  }

  // ============================================================
  // LOAD MESSAGES
  // ============================================================

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final list = await ChatService.getMessages(widget.jobId);
      if (!mounted) return;

      final hasNew = list.length != _messages.length;
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
        _isLoading = false;
        _error = null;
      });

      if (hasNew || !silent) _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!silent) _error = 'Gagal memuat pesan: $e';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final temp = ChatMessage(
      id: -1,
      message: text,
      isMine: true,
      senderName: 'Saya',
      senderRole: '',
      time: _formatNow(),
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(temp);
      _isSending = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final sent = await ChatService.sendMessage(widget.jobId, text);
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == -1);
        if (idx != -1) _messages[idx] = sent;
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == -1);
        _isSending = false;
      });
      _showSnack('Gagal kirim pesan: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.chat_rounded,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Chat koordinasi',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildContent(),
                if (_showScrollFab)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      onPressed: _scrollToBottom,
                      backgroundColor: Colors.white,
                      elevation: 3,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT SWITCHER
  // ============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      );
    }

    if (_error != null) return _buildError();

    if (_messages.isEmpty) return _buildEmptyState();

    return _buildMessageList();
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat pesan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey500,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 38,
                color: AppColors.primaryTeal.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada pesan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulai chat untuk koordinasi\ndengan mitra / pelanggan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.grey500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE LIST + DATE SEPARATOR
  // ============================================================

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final m = _messages[i];
        final prev = i > 0 ? _messages[i - 1] : null;

        // Apakah perlu date separator sebelum bubble ini?
        final needDateSep = prev == null ||
            !_isSameDay(prev.createdAt, m.createdAt);

        // Apakah sender berbeda dari sebelumnya? (untuk tampil avatar)
        final showAvatar = !m.isMine &&
            (prev == null ||
                prev.isMine ||
                prev.senderName != m.senderName);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (needDateSep) _buildDateSeparator(m.createdAt),
            _buildBubble(m, showAvatar: showAvatar),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ============================================================
  // DATE SEPARATOR
  // ============================================================

  Widget _buildDateSeparator(DateTime dt) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    String label;
    if (_isSameDay(dt, now)) {
      label = 'Hari Ini';
    } else if (_isSameDay(dt, yesterday)) {
      label = 'Kemarin';
    } else {
      const bulan = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      label = '${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.grey500,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUBBLE
  // ============================================================

  Widget _buildBubble(ChatMessage m, {bool showAvatar = false}) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            m.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (hanya untuk pesan lawan)
          if (!m.isMine)
            SizedBox(
              width: 30,
              child: showAvatar
                  ? _buildAvatar(m)
                  : const SizedBox.shrink(),
            ),
          if (!m.isMine) const SizedBox(width: 8),

          // Bubble
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: m.isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: m.isMine ? AppColors.primaryTeal : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(m.isMine ? 16 : 4),
                        bottomRight: Radius.circular(m.isMine ? 4 : 16),
                      ),
                      border: m.isMine
                          ? null
                          : Border.all(color: AppColors.grey200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      m.message,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: m.isMine ? Colors.white : AppColors.grey900,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Waktu + centang
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.time,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.grey500,
                          ),
                        ),
                        if (m.isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            m.id == -1
                                ? Icons.schedule_rounded
                                : Icons.done_all_rounded,
                            size: 13,
                            color: m.id == -1
                                ? AppColors.grey400
                                : AppColors.primaryTeal,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (m.isMine) const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ============================================================
  // AVATAR INISIAL
  // ============================================================

    Widget _buildAvatar(ChatMessage m) {
    final name = m.senderName;
    final photoUrl = m.senderPhoto;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // Warna konsisten per user (hash nama)
    final colors = [
      const Color(0xFF0EA5E9),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
      const Color(0xFF6366F1),
    ];
    final color = colors[name.hashCode.abs() % colors.length];

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: (photoUrl != null && photoUrl.isNotEmpty)
            ? Image.network(
                photoUrl,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                // Jika gambar error / gagal dimuat, kembali ke inisial
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // INPUT BAR
  // ============================================================

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.grey200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 1000,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: const InputDecoration(
                    hintText: 'Tulis pesan...',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.grey500,
                    ),
                    isDense: true,
                    counterText: '', // sembunyikan counter default
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 46,
              height: 46,
              child: ElevatedButton(
                onPressed: _isSending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primaryTeal.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  elevation: 2,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}