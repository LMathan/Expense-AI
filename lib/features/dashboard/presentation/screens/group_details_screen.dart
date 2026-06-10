import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:espenseai/core/storage/hive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:espenseai/core/constants/colors.dart';
import 'package:espenseai/core/constants/text_styles.dart';
import 'package:espenseai/core/widgets/glass_card.dart';
import 'package:espenseai/core/models/group_model.dart';
import 'package:espenseai/core/services/firestore_sync_service.dart';
import 'package:espenseai/features/expense/presentation/providers/expense_provider.dart';
import 'package:espenseai/features/dashboard/presentation/screens/tabs/home_tab.dart';
import 'package:intl/intl.dart';
import 'package:espenseai/core/utils/category_emoji_helper.dart';
import 'package:espenseai/core/widgets/vector_illustrations.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;
  final GroupModel initialGroup;

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    required this.initialGroup,
  });

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  final _searchController = TextEditingController();
  final FirestoreSyncService _syncService = FirestoreSyncService();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });
    final results = await _syncService.searchUsersByName(query);

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final groups = ref.read(groupsProvider);
    final group = groups.firstWhere(
      (g) => g.id == widget.groupId,
      orElse: () => widget.initialGroup,
    );

    // Filter out current user and anyone already in the group
    final filtered = results.where((user) =>
        user['uid'] != currentUid &&
        !group.memberUids.contains(user['uid'])).toList();

    setState(() {
      _searchResults = filtered;
      _isSearching = false;
    });
  }

  void _addFriend(GroupModel group, Map<String, dynamic> user) async {
    await ref.read(groupsProvider.notifier).addMemberToGroup(group.id, user);
    setState(() {
      _searchController.clear();
      _searchResults = [];
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user['displayName']} added to the group!'),
          backgroundColor: AppColors.emeraldGreen,
        ),
      );
    }
  }

  void _showAddGroupExpense(GroupModel group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddGroupExpenseSheet(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final groups = ref.watch(groupsProvider);
    final group = groups.firstWhere(
      (g) => g.id == widget.groupId,
      orElse: () => widget.initialGroup,
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          group.name,
          style: GoogleFonts.outfit(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        type: PageBg.group,
        child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Group Info Summary
                    GlassCard(
                      gradientColors: isDark
                          ? [
                              AppColors.primaryPurple.withOpacity(0.15),
                              AppColors.electricBlue.withOpacity(0.05),
                            ]
                          : [
                              Colors.grey[200]!,
                              Colors.grey[100]!,
                            ],
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.group_rounded,
                              color: AppColors.primaryPurple,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${group.memberNames.length} members sharing expenses',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Add Friends Section
                    Text(
                      'ADD MEMBERS',
                      style: AppTextStyles.caption(isDark: isDark).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search user by username...',
                        hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
                        suffixIcon: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.electricBlue,
                                  ),
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: _searchUsers,
                    ),

                    if (_searchResults.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey[300]!,
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final res = _searchResults[index];
                            return ListTile(
                              leading: (res['photoUrl'] != null && res['photoUrl'].toString().isNotEmpty)
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(res['photoUrl'] as String),
                                      backgroundColor: Colors.transparent,
                                    )
                                  : CircleAvatar(
                                      backgroundColor: AppColors.electricBlue.withOpacity(0.12),
                                      child: Text(
                                        (res['displayName'] ?? 'U').toString().isNotEmpty
                                            ? (res['displayName'] as String)[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: AppColors.electricBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                              title: Text(
                                res['displayName'] ?? '',
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                res['email'] ?? '',
                                style: TextStyle(color: textSecondary, fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.electricBlue,
                                ),
                                onPressed: () => _addFriend(group, res),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Members List Section
                    Row(
                      children: [
                        Text(
                          'GROUP MEMBERS',
                          style: AppTextStyles.caption(isDark: isDark).copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${group.memberNames.length}',
                            style: const TextStyle(
                              color: AppColors.primaryPurple,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: group.memberNames.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final name = group.memberNames[index];
                          final uid = group.memberUids.length > index ? group.memberUids[index] : '';
                          final isMe = uid == FirebaseAuth.instance.currentUser?.uid;
                          final initials = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
                          final avatarColors = [
                            AppColors.primaryPurple,
                            AppColors.electricBlue,
                            AppColors.emeraldGreen,
                            AppColors.accentPink,
                            AppColors.accentOrange,
                          ];
                          final avatarColor = avatarColors[index % avatarColors.length];
                          final displayName = isMe ? 'You' : name.split(' ').first;

                          return SizedBox(
                            width: 70,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  children: [
                                    GroupMemberAvatar(
                                      uid: uid,
                                      initials: initials,
                                      avatarColor: avatarColor,
                                      radius: 29,
                                    ),
                                    if (isMe)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: AppColors.emeraldGreen,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark ? AppColors.bgDark : Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Group Transaction History
                    _GroupTransactionHistory(
                      group: group,
                      isDark: isDark,
                      textColor: textColor,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDark : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddGroupExpense(group),
                  icon: const Icon(Icons.call_split_rounded, color: Colors.white),
                  label: Text(
                    'Add Group Expense',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _GroupTransactionHistory extends ConsumerWidget {
  final GroupModel group;
  final bool isDark;
  final Color textColor;
  final Color textSecondary;

  const _GroupTransactionHistory({
    required this.group,
    required this.isDark,
    required this.textColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTxs = ref.watch(transactionProvider);
    // Show transactions belonging to any group member
    final groupTxs = allTxs
        .where((tx) => tx.splitWith.any((uid) => group.memberUids.contains(uid)) || group.memberUids.contains(tx.splitWith.firstOrNull))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Also show all transactions by the group creator (current user) that have splitWith
    final splitTxs = allTxs
        .where((tx) => tx.splitWith.isNotEmpty)
        .where((tx) => !groupTxs.contains(tx))
        .toList();
    final combined = [...groupTxs, ...splitTxs]..sort((a, b) => b.date.compareTo(a.date));
    final display = combined.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.electricBlue, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'GROUP TRANSACTIONS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.electricBlue,
                letterSpacing: 1.0,
              ),
            ),
            if (display.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${display.length}',
                  style: const TextStyle(color: AppColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        if (display.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark.withValues(alpha: 0.4) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_outlined, size: 36, color: textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text('No group expenses yet.', style: TextStyle(color: textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Add a group expense using the button below.', style: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: display.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tx = display[index];
              final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(tx.date);
              final perHead = tx.splitWith.isNotEmpty
                  ? tx.amount / (tx.splitWith.length + 1)
                  : tx.amount;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(getCategoryEmoji(tx.category), style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.merchant.isEmpty ? tx.category : tx.merchant,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                              ),
                              const SizedBox(height: 2),
                              Text(formattedDate, style: TextStyle(fontSize: 10, color: textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${tx.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.accentPink,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (tx.splitWith.isNotEmpty)
                              Text(
                                '÷ ${tx.splitWith.length + 1} = ₹${perHead.toStringAsFixed(0)}/person',
                                style: TextStyle(color: textSecondary, fontSize: 9),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (tx.splitWith.isNotEmpty || tx.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(tx.category, style: const TextStyle(color: AppColors.primaryPurple, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.electricBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(tx.paymentMethod, style: const TextStyle(color: AppColors.electricBlue, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                          if (tx.splitWith.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Split ${tx.splitWith.length + 1} ways',
                                style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class GroupMemberAvatar extends StatefulWidget {
  final String uid;
  final String initials;
  final Color avatarColor;
  final double radius;

  const GroupMemberAvatar({
    super.key,
    required this.uid,
    required this.initials,
    required this.avatarColor,
    this.radius = 29,
  });

  @override
  State<GroupMemberAvatar> createState() => _GroupMemberAvatarState();
}

class _GroupMemberAvatarState extends State<GroupMemberAvatar> {
  static final Map<String, String?> _avatarCache = {}; // Global memory cache for member avatars
  bool _loading = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  void _loadAvatar() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (widget.uid.isEmpty) return;

    if (widget.uid == currentUid) {
      // Load from local Hive
      final box = Hive.box(HiveHelper.settingsBox);
      final localPath = box.get('profile_picture_path') as String?;
      final localUrl = box.get('profile_picture_url') as String?;
      if (mounted) {
        setState(() {
          _photoUrl = localPath ?? localUrl;
        });
      }
      return;
    }

    // Check memory cache first
    if (_avatarCache.containsKey(widget.uid)) {
      if (mounted) {
        setState(() {
          _photoUrl = _avatarCache[widget.uid];
        });
      }
      return;
    }

    // Fetch from Firestore
    setState(() {
      _loading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (doc.exists) {
        final data = doc.data();
        final url = data?['photoUrl'] as String?;
        _avatarCache[widget.uid] = url;
        if (mounted) {
          setState(() {
            _photoUrl = url;
            _loading = false;
          });
        }
      } else {
        _avatarCache[widget.uid] = null;
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      ImageProvider imageProvider;
      if (!_photoUrl!.startsWith('http') && File(_photoUrl!).existsSync()) {
        imageProvider = FileImage(File(_photoUrl!));
      } else {
        imageProvider = NetworkImage(_photoUrl!);
      }

      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: imageProvider,
        backgroundColor: Colors.transparent,
      );
    }

    // Fallback: Initials text avatar
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.avatarColor.withOpacity(0.9),
            widget.avatarColor.withOpacity(0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.avatarColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        widget.initials.isNotEmpty ? widget.initials : 'U',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: widget.radius * 0.62,
        ),
      ),
    );
  }
}
