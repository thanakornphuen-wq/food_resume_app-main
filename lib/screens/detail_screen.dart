import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_resume.dart';
import '../services/firestore_service.dart';

class DetailScreen extends StatelessWidget {
  final String resumeId;
  const DetailScreen({super.key, required this.resumeId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      body: FutureBuilder<FoodResume>(
        future: firestore.getResume(resumeId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 52, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('กลับหน้าหลัก'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = snapshot.data!;
          final isOwner = r.ownerId == firestore.currentUid;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: r.imageUrl.isNotEmpty
                      ? Image.network(
                          r.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                actions: isOwner
                    ? [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await firestore.deleteResume(r.id);
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ]
                    : null,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.menuName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Chip(label: Text(r.category)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 4),
                          Expanded(child: Text('${r.likeCount} คนถูกใจเมนูนี้')),
                          Text(
                            DateFormat('d MMM y', 'th_TH').format(r.createdAt),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Text('โดย ${r.ownerName}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      if (r.description.isNotEmpty) ...[
                        const Text('เรื่องราวของเมนูนี้',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(r.description),
                        const SizedBox(height: 16),
                      ],
                      if (r.highlights.isNotEmpty) ...[
                        const Text('จุดเด่น', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: r.highlights
                              .map((h) => Chip(
                                    avatar: const Icon(Icons.star, size: 16),
                                    label: Text(h),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (r.ingredients.isNotEmpty) ...[
                        const Text('วัตถุดิบ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...r.ingredients.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('•  '),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (r.instructions.isNotEmpty) ...[
                        const Text('วิธีทำ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...r.instructions.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  child: Text('${entry.key + 1}',
                                      style: const TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(entry.value)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('ถูกใจ'),
                  onPressed: () => firestore.toggleLike(resumeId),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('บันทึก'),
                  onPressed: () => firestore.toggleSave(resumeId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: Colors.orange[50],
        child: const Center(
          child: Icon(Icons.restaurant, size: 72, color: Colors.orangeAccent),
        ),
      );
}
