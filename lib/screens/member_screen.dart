import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// ข้อมูลสมาชิกกลุ่ม — แก้ไขชื่อ/รหัสนิสิต/ตำแหน่งให้ตรงกับกลุ่มจริงของคุณได้ที่นี่
class GroupMember {
  final String name;
  final String studentId;
  final String role;
  const GroupMember({required this.name, required this.studentId, required this.role});
}

const groupMembers = <GroupMember>[
  GroupMember(
    name: 'ชื่อ-นามสกุล สมาชิกคนที่ 1',
    studentId: '6xxxxxxxxx',
    role: 'หัวหน้ากลุ่ม / Flutter Dev',
  ),
  GroupMember(
    name: 'ชื่อ-นามสกุล สมาชิกคนที่ 2',
    studentId: '6xxxxxxxxx',
    role: 'Backend / Firebase',
  ),
  GroupMember(
    name: 'ชื่อ-นามสกุล สมาชิกคนที่ 3',
    studentId: '6xxxxxxxxx',
    role: 'UI/UX Design',
  ),
];

class MemberScreen extends StatelessWidget {
  const MemberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('สมาชิกกลุ่ม'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // Team Intro Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ทีมผู้พัฒนาแอปพลิเคชัน 👥',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'โครงงาน Food Resume App • รวมสูตรอาหารและเรซูเม่เมนูเด็ด',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary.withValues(alpha: 0.9),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Members List / Responsive Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 640;

                    if (isWide) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: groupMembers.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 130,
                        ),
                        itemBuilder: (context, i) => _buildMemberCard(groupMembers[i], i),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groupMembers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _buildMemberCard(groupMembers[i], i),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(GroupMember m, int index) {
    // Theme colors per member index
    final (Color badgeBg, Color badgeColor, IconData roleIcon) = switch (index % 3) {
      0 => (AppColors.primaryLight, AppColors.primaryDark, Icons.code_rounded),
      1 => (AppColors.accentAmberLight, const Color(0xFFB45309), Icons.storage_rounded),
      _ => (AppColors.accentGreenLight, const Color(0xFF047857), Icons.palette_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Member Number / Avatar Badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
              border: Border.all(color: badgeColor.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Member Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Full Name
                Text(
                  m.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),

                // Student ID Pill
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'รหัส: ${m.studentId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Role Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(roleIcon, size: 12, color: badgeColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          m.role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
