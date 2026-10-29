import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ResultsSkeleton extends StatelessWidget {
  const ResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 390,
        mainAxisExtent: 292,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: const Color(0xFFE4EAF2),
        highlightColor: const Color(0xFFF6F8FC),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Container(height: 14, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 10, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(height: 12, color: Colors.white),
                const SizedBox(height: 12),
                Container(height: 12, width: 180, color: Colors.white),
                const Spacer(),
                Container(height: 34, width: 110, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
