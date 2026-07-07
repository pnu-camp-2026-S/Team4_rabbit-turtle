import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../services/magazine_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/magazine_shelf.dart';

class StandPage extends StatefulWidget {
  const StandPage({super.key});

  @override
  State<StandPage> createState() => _StandPageState();
}

class _StandPageState extends State<StandPage> {
  late final Future<List<Magazine>> _magazinesFuture = _loadMagazines();

  static Future<List<Magazine>> _loadMagazines() async {
    try {
      final magazines = await MagazineService().fetchMagazines();
      return magazines.isEmpty ? kMagazines : magazines;
    } catch (_) {
      return kMagazines;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LogzineTopBar(showBack: true, showBell: false),
            Expanded(
              child: FutureBuilder<List<Magazine>>(
                future: _magazinesFuture,
                builder: (context, snapshot) {
                  final magazines = snapshot.data ?? const <Magazine>[];
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: magazines.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final magazine = magazines[index];
                      return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, '/discover/why'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 94,
                              height: 126,
                              child: MagazineCover(magazine: magazine),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    magazine.title,
                                    style: logoStyle(
                                      size: 24,
                                      weight: FontWeight.w600,
                                      letterSpacingEm: 0.04,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    magazine.tagline,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.5,
                                      color: AppColors.body,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    magazine.issue,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Row(
                                    children: [
                                      Text(
                                        'Open issue',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.forest,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: AppColors.forest,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
