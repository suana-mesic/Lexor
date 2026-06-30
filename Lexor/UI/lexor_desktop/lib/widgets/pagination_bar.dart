import 'package:flutter/material.dart';

/// Reusable "Prikazano X od Y" footer with Prethodna/Sljedeća buttons,
/// shared by every paginated list screen.
class PaginationBar extends StatelessWidget {
  final int shownCount;
  final int totalCount;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const PaginationBar({
    super.key,
    required this.shownCount,
    required this.totalCount,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Prikazano $shownCount od $totalCount rezultata',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: hasPrev ? onPrev : null,
                child: const Text('Prethodna'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: hasNext ? onNext : null,
                child: const Text('Sljedeća'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
