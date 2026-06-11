import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:espenseai/core/constants/colors.dart';
import 'package:espenseai/core/services/firestore_sync_service.dart';
import 'package:espenseai/core/storage/hive_helper.dart';
import 'package:espenseai/features/expense/presentation/providers/expense_provider.dart';
import 'package:espenseai/core/widgets/vector_illustrations.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final FirestoreSyncService _syncService = FirestoreSyncService();

  List<Map<String, dynamic>> _selectedMembers = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // Current user info
  late Map<String, dynamic> _currentUserMember;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    final userName = Hive.box(HiveHelper.settingsBox).get('user_name', defaultValue: 'You') as String;
    _currentUserMember = {
      'uid': currentUser?.uid ?? 'local_user',
      'displayName': userName,
      'email': currentUser?.email ?? '',
      'isMe': true,
    };
    // Pre-add current user as default
    _selectedMembers = [_currentUserMember];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    final results = await _syncService.searchUsersByName(query);
    // Filter out current user and already-selected members
    final selectedUids = _selectedMembers.map((m) => m['uid'] as String).toSet();
    final filtered = results.where((u) => !selectedUids.contains(u['uid'])).toList();
    setState(() { _searchResults = filtered; _isSearching = false; });
  }

  void _addMember(Map<String, dynamic> user) {
    setState(() {
      _selectedMembers.add(user);
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _removeMember(Map<String, dynamic> member) {
    if (member['isMe'] == true) return; // Can't remove yourself
    setState(() => _selectedMembers.remove(member));
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name'), backgroundColor: AppColors.accentPink),
      );
      return;
    }
    if (_selectedMembers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one more member'), backgroundColor: AppColors.accentPink),
      );
      return;
    }

    ref.read(groupsProvider.notifier).addGroup(name, _selectedMembers);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Text('Group "$name" created!'),
        ]),
        backgroundColor: AppColors.emeraldGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;

    final avatarColors = [
      AppColors.primaryPurple,
      AppColors.electricBlue,
      AppColors.emeraldGreen,
      AppColors.accentPink,
      AppColors.accentOrange,
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Group',
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: AppBackground(
        type: PageBg.group,
        child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Group icon + name
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? const LinearGradient(
                              colors: [AppColors.primaryPurple, AppColors.electricBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                AppColors.primaryPurple.withValues(alpha: 0.12),
                                AppColors.electricBlue.withValues(alpha: 0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(24),
                      border: isDark
                          ? null
                          : Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : AppColors.primaryPurple.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.group_rounded,
                            color: isDark ? Colors.white : AppColors.primaryPurple,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Group Name',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : AppColors.textSecondaryLight.withValues(alpha: 0.6),
                              fontSize: 20,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : AppColors.primaryPurple.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedMembers.length} member${_selectedMembers.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondaryLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Members section
                  Row(
                    children: [
                      Icon(Icons.people_rounded, color: AppColors.primaryPurple, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'MEMBERS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_selectedMembers.length}',
                          style: const TextStyle(
                            color: AppColors.primaryPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Member chips row
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedMembers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final member = _selectedMembers[index];
                        final isMe = member['isMe'] == true;
                        final name = member['displayName'] as String? ?? 'User';
                        final initials = name.trim().split(' ').take(2)
                            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
                        final color = avatarColors[index % avatarColors.length];

                        return Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [color, color.withValues(alpha: 0.6)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials.isNotEmpty ? initials : 'U',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                if (!isMe)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _removeMember(member),
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: bgColor, width: 2),
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 10),
                                      ),
                                    ),
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
                                        border: Border.all(color: bgColor, width: 2),
                                      ),
                                      child: const Icon(Icons.check, color: Colors.white, size: 10),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isMe ? 'You' : name.split(' ').first,
                              style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Search field
                  Row(
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, color: AppColors.electricBlue, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'ADD MEMBERS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.electricBlue,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by username...',
                      hintStyle: TextStyle(color: subColor, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, color: subColor, size: 20),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.electricBlue),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.electricBlue, width: 2),
                      ),
                    ),
                    onChanged: _searchUsers,
                  ),

                  // Search results
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final res = _searchResults[index];
                          final name = res['displayName'] as String? ?? 'User';
                          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.electricBlue.withValues(alpha: 0.12),
                              child: Text(initial, style: const TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(res['email'] ?? '', style: TextStyle(color: subColor, fontSize: 11)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.electricBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_rounded, color: AppColors.electricBlue, size: 16),
                                  const SizedBox(width: 4),
                                  Text('Add', style: GoogleFonts.inter(color: AppColors.electricBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            onTap: () => _addMember(res),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: bgColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 16, offset: const Offset(0, -4)),
              ],
            ),
            child: SizedBox(
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryPurple.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5)),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.group_add_rounded, color: Colors.white, size: 20),
                  label: Text(
                    'Create Group',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
