import 'package:elecko26_new/core/constants/app_colors.dart';
import 'package:elecko26_new/core/constants/app_text_styles.dart';
import 'package:elecko26_new/core/constants/app_constants.dart';
import 'package:elecko26_new/core/utils/app_utils.dart';
import 'package:elecko26_new/core/utils/date_time_utils.dart';
import 'package:elecko26_new/core/utils/image_utils.dart';
import 'package:elecko26_new/core/utils/ui_utils.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/party.dart';
import 'package:elecko26_new/domain/entities/party_support_rate.dart';
import 'package:elecko26_new/domain/entities/poll.dart';
import 'package:elecko26_new/domain/entities/vote_rate.dart';
import 'package:elecko26_new/features/home/presentation/bloc/member_detail/member_detail_bloc.dart';
import 'package:elecko26_new/features/home/presentation/bloc/member_detail/member_detail_event.dart';
import 'package:elecko26_new/features/home/presentation/bloc/member_detail/member_detail_state.dart';
import 'package:elecko26_new/features/home/presentation/widgets/member_detail_widgets.dart';
import 'package:elecko26_new/features/home/presentation/widgets/party_support_rate_chart.dart';
import 'package:elecko26_new/features/home/presentation/widgets/policy_item.dart';
import 'package:elecko26_new/features/home/presentation/widgets/poll_item.dart';
import 'package:elecko26_new/features/home/presentation/widgets/sns_link_item.dart';
import 'package:elecko26_new/features/home/presentation/widgets/vote_rate_chart.dart';
import 'package:elecko26_new/features/home/presentation/widgets/vote_rate_item.dart';
import 'package:elecko26_new/app/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class MemberDetailPage extends StatefulWidget {
  final Member member;
  final VoidCallback? onBack;

  const MemberDetailPage({super.key, required this.member, this.onBack});

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MemberDetailBloc _memberDetailBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _memberDetailBloc = sl<MemberDetailBloc>();
    _memberDetailBloc.add(GetMemberDetail(widget.member.id));
    _memberDetailBloc.add(GetMemberPolicies(widget.member.id));
    _memberDetailBloc.add(GetMemberPolls(widget.member.id));
    _memberDetailBloc.add(GetMemberPartySupportRates(widget.member.id));
    _memberDetailBloc.add(GetMemberVoteRates(widget.member.id));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memberDetailBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member.name),
        leading: BackButton(
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '정보'),
            Tab(text: '정책'),
            Tab(text: '여론조사'),
          ],
        ),
      ),
      body: BlocProvider<MemberDetailBloc>(
        create: (context) => _memberDetailBloc,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildPoliciesTab(),
            _buildPollsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return BlocBuilder<MemberDetailBloc, MemberDetailState>(
      builder: (context, state) {
        if (state is MemberDetailLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MemberDetailLoaded) {
          final member = state.member;
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(member),
                SizedBox(height: 20.h),
                _buildSectionTitle('기본 정보'),
                _buildInfoRow('소속 정당', member.party.isEmpty ? '무소속' : member.party),
                _buildInfoRow('지역구', member.constituency),
                _buildInfoRow(
                  '당선 횟수',
                  member.electionCount > 0 ? '${member.electionCount}회' : '정보 없음',
                ),
                _buildInfoRow(
                  '재임 기간',
                  '${DateTimeUtils.formatDate(member.termStartDate)} ~ ${DateTimeUtils.formatDate(member.termEndDate)}',
                ),
                _buildInfoRow('생년월일', DateTimeUtils.formatDate(member.birthDate)),
                _buildInfoRow(
                  '성별',
                  member.gender.isEmpty
                      ? '정보 없음'
                      : (member.gender == 'M' || member.gender == '남성'
                          ? '남성'
                          : member.gender == 'F' || member.gender == '여성'
                              ? '여성'
                              : member.gender),
                ),
                _buildInfoRow('학력', member.education),
                _buildInfoRow('경력', member.career),
                SizedBox(height: 20.h),
                _buildSectionTitle('당선 가능성'),
                _buildPossibilityMeter(member.electionPossibility),
                SizedBox(height: 20.h),
                _buildSectionTitle('SNS'),
                _buildSnsLinks(member),
                SizedBox(height: 20.h),
                _buildSectionTitle('정당 지지율'),
                _buildPartySupportRateChart(state.partySupportRates),
                SizedBox(height: 20.h),
                _buildSectionTitle('득표율'),
                _buildVoteRateChart(state.voteRates),
              ],
            ),
          );
        } else if (state is MemberDetailError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader(Member member) {
    final ImageProvider<Object> imageProvider;
    if (member.imageUrl.isEmpty) {
      imageProvider = const AssetImage('assets/images/avatar.png');
    } else if (member.imageUrl.startsWith('assets/')) {
      imageProvider = AssetImage(member.imageUrl);
    } else {
      imageProvider = NetworkImage(
        ImageUtils.getProxyUrl(member.imageUrl, width: 120, height: 120),
      );
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 40.w,
          backgroundImage: imageProvider,
        ),
        SizedBox(width: 16.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.name, style: AppTextStyles.headline2),
            Text(member.party.isEmpty ? '무소속' : member.party, style: AppTextStyles.bodyText1),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(title, style: AppTextStyles.headline3),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(title,
                style: AppTextStyles.bodyText2.copyWith(color: AppColors.grey)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyText2),
          ),
        ],
      ),
    );
  }

  Widget _buildSnsLinks(Member member) {
    final snsLinks = {
      if (member.facebookUrl != null) 'Facebook': member.facebookUrl!,
      if (member.twitterUrl != null) 'Twitter': member.twitterUrl!,
      if (member.youtubeUrl != null) 'YouTube': member.youtubeUrl!,
      if (member.blogUrl != null) 'Blog': member.blogUrl!,
    };

    if (snsLinks.isEmpty) {
      return Text('등록된 SNS 정보가 없습니다.', style: AppTextStyles.bodyText2);
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: snsLinks.entries
          .map((entry) => _buildSnsLink(entry.key, entry.value))
          .toList(),
    );
  }

  Widget _buildSnsLink(String platform, String url) {
    return SnsLinkItem(
      platform: platform,
      onTap: () async {
        final uri = Uri.parse(url);
        if (await url_launcher.canLaunchUrl(uri)) {
          await url_launcher.launchUrl(uri);
        } else {
          UiUtils.showSnackBar(context, '링크를 열 수 없습니다: $url');
        }
      },
    );
  }

  Widget _buildPossibilityMeter(double rawPossibility) {
    final possibility = rawPossibility > 1.0 ? rawPossibility / 100.0 : rawPossibility;
    final clamped = possibility.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: clamped,
          minHeight: 8,
          backgroundColor: AppColors.lightGrey,
          valueColor: AlwaysStoppedAnimation(
            clamped >= 0.6 ? AppColors.success : AppColors.warning,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '당선 가능성 ${(clamped * 100).toStringAsFixed(2)}%',
          style: AppTextStyles.bodyText2.copyWith(
            color: clamped >= 0.6 ? AppColors.success : AppColors.warning,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPartySupportRateChart(List<PartySupportRate> rates) {
    if (rates.isEmpty) {
      return Text('정당 지지율 정보가 없습니다.', style: AppTextStyles.bodyText2);
    }
    return PartySupportRateChart(rates: rates);
  }

  Widget _buildVoteRateChart(List<VoteRate> rates) {
    if (rates.isEmpty) {
      return Text('득표율 정보가 없습니다.', style: AppTextStyles.bodyText2);
    }
    return VoteRateChart(rates: rates);
  }

  Widget _buildPoliciesTab() {
    return BlocBuilder<MemberDetailBloc, MemberDetailState>(
      builder: (context, state) {
        if (state is MemberPoliciesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MemberPoliciesLoaded) {
          if (state.policies.isEmpty) {
            return const Center(child: Text('등록된 정책이 없습니다.'));
          }
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: state.policies.length,
            itemBuilder: (context, index) {
              final policy = state.policies[index];
              return PolicyItem(policy: policy);
            },
          );
        } else if (state is MemberDetailError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPollsTab() {
    return BlocBuilder<MemberDetailBloc, MemberDetailState>(
      builder: (context, state) {
        if (state is MemberPollsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MemberPollsLoaded) {
          if (state.polls.isEmpty) {
            return const Center(child: Text('등록된 여론조사가 없습니다.'));
          }
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: state.polls.length,
            itemBuilder: (context, index) {
              final poll = state.polls[index];
              return PollItem(poll: poll);
            },
          );
        } else if (state is MemberDetailError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox.shrink();
      },
    );
  }
}
