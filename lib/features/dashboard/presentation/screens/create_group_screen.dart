import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:io';
import 'package:espenseai/core/constants/colors.dart';
import 'package:espenseai/core/services/firestore_sync_service.dart';
import 'package:espenseai/core/services/notification_service.dart';
import 'package:espenseai/core/storage/hive_helper.dart';
import 'package:espenseai/features/expense/presentation/providers/expense_provider.dart';
import 'package:espenseai/core/widgets/vector_illustrations.dart';
import 'package:espenseai/core/widgets/glass_card.dart';

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
    final box = Hive.box(HiveHelper.settingsBox);
    final userName = box.get('user_name', defaultValue: 'You') as String;
    final profilePicPath = box.get('profile_picture_path') as String?;
    final profilePicUrl = box.get('profile_picture_url') as String?;
    _currentUserMember = {
      'uid': currentUser?.uid ?? 'local_user',
      'displayName': userName,
      'email': currentUser?.email ?? '',
      'isMe': true,
      'profilePicPath': profilePicPath,
      'profilePicUrl': profilePicUrl,
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
    
    // Trigger notification
    ref.read(notificationServiceProvider).showInstantNotification(
      'Group Created! 👥',
      'You were added to the "$name" group.',
    );

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

  Widget _buildMemberAvatar(Map<String, dynamic> member, double radius) {
    final String name = member['displayName'] as String? ?? 'User';
    final String email = member['email'] as String? ?? '';
    final String? picPath = member['profilePicPath'] as String?;
    final String? picUrl = member['profilePicUrl'] as String?;

    if (picPath != null && picPath.startsWith('data:image')) {
      try {
        final base64String = picPath.split('base64,').last;
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(base64Decode(base64String)),
          backgroundColor: Colors.transparent,
        );
      } catch (_) {}
    } else if (picPath != null && !picPath.startsWith('http') && File(picPath).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(picPath)),
        backgroundColor: Colors.transparent,
      );
    } else if (picPath != null && picPath.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(picPath),
        backgroundColor: Colors.transparent,
      );
    } else if (picUrl != null && picUrl.startsWith('data:image')) {
      try {
        final base64String = picUrl.split('base64,').last;
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(base64Decode(base64String)),
          backgroundColor: Colors.transparent,
        );
      } catch (_) {}
    } else if (picUrl != null && picUrl.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(picUrl),
        backgroundColor: Colors.transparent,
      );
    }

    // Fallback: local avatar asset
    final isMe = member['isMe'] == true;
    final String gender;
    if (isMe) {
      gender = Hive.box(HiveHelper.settingsBox).get('user_gender', defaultValue: 'male') as String;
    } else {
      gender = member['user_gender'] as String? ?? 'male';
    }
    return CircleAvatar(
      radius: radius,
      backgroundImage: AssetImage(gender == 'female' ? 'assets/images/avatar_girl.png' : 'assets/images/avatar_boy.png'),
      backgroundColor: Colors.transparent,
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
                    // Group icon + name header in a beautiful GlassCard
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryPurple, AppColors.accentPink],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryPurple.withValues(alpha: 0.35),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Stylized Input Field for Group Name
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.borderLight,
                                width: 1.2,
                              ),
                            ),
                            child: TextField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter Group Name',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.textSecondaryLight.withValues(alpha: 0.4),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_selectedMembers.length} member${_selectedMembers.length != 1 ? 's' : ''} added',
                              style: const TextStyle(
                                color: AppColors.primaryPurple,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Members section
                    Row(
                      children: [
                        const Icon(Icons.people_rounded, color: AppColors.primaryPurple, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'MEMBERS',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPurple,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Member chips row
                    SizedBox(
                      height: 100,
                      child: _selectedMembers.isEmpty
                          ? Center(
                              child: Text(
                                'No members added yet.',
                                style: TextStyle(color: subColor, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedMembers.length,
                              itemBuilder: (context, index) {
                                final member = _selectedMembers[index];
                                final isMe = member['isMe'] == true;
                                final name = member['displayName'] as String? ?? 'User';
                                final color = avatarColors[index % avatarColors.length];

                                return Container(
                                  width: 64,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [color, color.withValues(alpha: 0.4)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: _buildMemberAvatar(member, 22),
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
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.2),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
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
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Search field section
                    Row(
                      children: [
                        const Icon(Icons.person_add_alt_1_rounded, color: AppColors.electricBlue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'ADD MEMBERS',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.electricBlue,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Premium styled search input
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
                        fillColor: isDark ? AppColors.cardDark.withValues(alpha: 0.6) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
                        ),
                      ),
                      onChanged: _searchUsers,
                    ),

                    // Search results
                    if (_searchResults.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 240),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight, height: 1),
                          itemBuilder: (context, index) {
                            final res = _searchResults[index];
                            final name = res['displayName'] as String? ?? 'User';
                            final email = res['email'] as String? ?? '';

                            return ListTile(
                              leading: _buildMemberAvatar(res, 20),
                              title: Text(
                                name,
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                email,
                                style: TextStyle(color: subColor, fontSize: 11),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.electricBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_rounded, color: AppColors.electricBlue, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Add',
                                      style: GoogleFonts.inter(
                                        color: AppColors.electricBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: BouncyGestureDetector(
                onTap: _submit,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_add_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Create Group',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
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

// Bouncy interaction helper widget for high-end aesthetic feedback
class BouncyGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncyGestureDetector({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<BouncyGestureDetector> createState() => _BouncyGestureDetectorState();
}

class _BouncyGestureDetectorState extends State<BouncyGestureDetector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
