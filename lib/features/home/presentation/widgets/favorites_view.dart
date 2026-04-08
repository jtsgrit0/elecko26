import 'package:flutter/material.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/features/home/presentation/widgets/member_card.dart';

class FavoritesView extends StatelessWidget {
  final Stream<List<Member>> membersStream;
  final List<Member> cachedMembers;
  final Function(Member) onMemberSelected;

  const FavoritesView({
    Key? key,
    required this.membersStream,
    required this.cachedMembers,
    required this.onMemberSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Member>>(
      stream: membersStream,
      builder: (context, snapshot) {
        final members = snapshot.data ?? cachedMembers;
        final favoriteMembers = members.where((m) => m.isFavorite).toList();

        if (favoriteMembers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_border, size: 64, color: AppColors.grey),
                const SizedBox(height: 16),
                Text(
                  '즐겨찾기한 의원이 없습니다',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoriteMembers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MemberCard(
                member: favoriteMembers[index],
                onTap: () => onMemberSelected(favoriteMembers[index]),
              ),
            );
          },
        );
      },
    );
  }
}
