import 'package:flutter/material.dart';

/// ข้อมูลสมาชิกกลุ่ม — แก้ไขชื่อ/รหัสนิสิต/ตำแหน่งให้ตรงกับกลุ่มจริงของคุณได้ที่นี่
class GroupMember {
  final String name;
  final String studentId;
  final String role;
  const GroupMember({required this.name, required this.studentId, required this.role});
}

const groupMembers = <GroupMember>[
  GroupMember(name: 'ชื่อ-นามสกุล สมาชิกคนที่ 1', studentId: '6xxxxxxxxx', role: 'หัวหน้ากลุ่ม / Flutter Dev'),
  GroupMember(name: 'ชื่อ-นามสกุล สมาชิกคนที่ 2', studentId: '6xxxxxxxxx', role: 'Backend / Firebase'),
  GroupMember(name: 'ชื่อ-นามสกุล สมาชิกคนที่ 3', studentId: '6xxxxxxxxx', role: 'UI/UX Design'),
];

class MemberScreen extends StatelessWidget {
  const MemberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมาชิกกลุ่ม')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: groupMembers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final m = groupMembers[i];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 26,
                child: Text(m.name.isNotEmpty ? m.name[0] : '?'),
              ),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('รหัสนิสิต ${m.studentId}\n${m.role}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
