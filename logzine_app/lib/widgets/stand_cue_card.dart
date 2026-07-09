import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../theme.dart';

class StandCueInfo {
  const StandCueInfo({required this.magazine, required this.quote});

  final Magazine magazine;
  final String quote;
}

StandCueInfo? standCueForShelf(List<Magazine> shelf) {
  final visibleShelf = [
    for (final magazine in shelf.take(6))
      if (magazine.title.trim().isNotEmpty) magazine,
  ];
  if (visibleShelf.isEmpty) return null;

  final today = DateTime.now();
  final dayKey =
      '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
  final fingerprint = visibleShelf
      .map((m) => m.id.isEmpty ? m.title : m.id)
      .join('|');
  final index = _stableHash('$dayKey|$fingerprint') % visibleShelf.length;
  final magazine = visibleShelf[index];
  return StandCueInfo(magazine: magazine, quote: _cueQuoteFor(magazine));
}

String _cueQuoteFor(Magazine magazine) {
  final tagline = magazine.tagline.trim();
  if (tagline.isNotEmpty) return tagline;
  final issue = magazine.issue.trim();
  if (issue.isNotEmpty) return issue;
  return 'A quiet issue selected from today\'s stand.';
}

int _stableHash(String value) {
  var hash = 0;
  for (final code in value.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return hash;
}

class StandCueCard extends StatelessWidget {
  const StandCueCard({super.key, required this.info, required this.onTap});

  final StandCueInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final issue = info.magazine.issue.trim();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.format_quote_rounded,
                size: 22,
                color: AppColors.ink,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FROM TODAY\'S STAND',
                      style: eyebrowStyle(size: 10, color: AppColors.forest),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      issue.isEmpty
                          ? info.magazine.title
                          : '${info.magazine.title} · $issue',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '“${info.quote}”',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
