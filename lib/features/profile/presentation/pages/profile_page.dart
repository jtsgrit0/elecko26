import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../domain/entities/profile.dart';
import '../../domain/usecases/profile_usecases.dart';
import '../../data/repositories/profile_repository_impl.dart';
import 'edit_profile_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class ProfilePage extends StatefulWidget {
  final auth.User currentUser;

  const ProfilePage({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileRepositoryImpl _profileRepository;
  late final GetUserProfileUseCase _getUserProfileUseCase;
  late final InitializeUserProfileUseCase _initializeUserProfileUseCase;

  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _profileRepository = ProfileRepositoryImpl();
    _getUserProfileUseCase = GetUserProfileUseCase(_profileRepository);
    _initializeUserProfileUseCase = InitializeUserProfileUseCase(_profileRepository);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _getUserProfileUseCase.execute(widget.currentUser.id);

      if (profile == null) {
        // 프로필이 없으면 초기화
        final result = await _initializeUserProfileUseCase.execute(
          widget.currentUser.id,
          displayName: widget.currentUser.displayName,
        );

        if (result.isSuccess) {
          _userProfile = result.updatedProfile;
        } else {
          _errorMessage = result.errorMessage;
        }
      } else {
        _userProfile = profile;
      }
    } catch (e) {
      _errorMessage = '프로필을 불러오는 중 오류가 발생했습니다.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F3B5C),
        actions: [
          IconButton(
            onPressed: () => _navigateToSettings(),
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () => _navigateToEditProfile(),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_userProfile == null) {
      return const Center(
        child: Text('프로필 정보를 불러올 수 없습니다.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildProfileInfo(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: _userProfile!.avatarUrl != null
              ? NetworkImage(_userProfile!.avatarUrl!)
              : null,
          child: _userProfile!.avatarUrl == null
              ? const Icon(Icons.person, size: 60, color: Colors.white)
              : null,
          backgroundColor: const Color(0xFF1F3B5C),
        ),
        const SizedBox(height: 16),
        Text(
          _userProfile!.displayName ?? '이름 없음',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getProviderColor(widget.currentUser.provider),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getProviderDisplayName(widget.currentUser.provider),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('이메일', widget.currentUser.email ?? '정보 없음'),
            const Divider(),
            _buildInfoRow('전화번호', _userProfile!.phoneNumber ?? '정보 없음'),
            const Divider(),
            _buildInfoRow('생년월일', _userProfile!.birthDate != null
                ? '${_userProfile!.birthDate!.year}-${_userProfile!.birthDate!.month.toString().padLeft(2, '0')}-${_userProfile!.birthDate!.day.toString().padLeft(2, '0')}'
                : '정보 없음'),
            const Divider(),
            _buildInfoRow('성별', _userProfile!.gender ?? '정보 없음'),
            const Divider(),
            _buildInfoRow('지역', _userProfile!.location ?? '정보 없음'),
            if (_userProfile!.bio != null && _userProfile!.bio!.isNotEmpty) ...[
              const Divider(),
              _buildInfoRow('자기소개', _userProfile!.bio!, isMultiline: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              maxLines: isMultiline ? null : 1,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProviderColor(auth.AuthProvider provider) {
    switch (provider) {
      case auth.AuthProvider.google:
        return Colors.red;
      case auth.AuthProvider.apple:
        return Colors.black;
      case auth.AuthProvider.facebook:
        return Colors.blue;
      case auth.AuthProvider.kakao:
        return Colors.yellow[700]!;
      case auth.AuthProvider.email:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getProviderDisplayName(auth.AuthProvider provider) {
    switch (provider) {
      case auth.AuthProvider.google:
        return 'Google';
      case auth.AuthProvider.apple:
        return 'Apple';
      case auth.AuthProvider.facebook:
        return 'Facebook';
      case auth.AuthProvider.kakao:
        return 'Kakao';
      case auth.AuthProvider.email:
        return '이메일';
      default:
        return '기타';
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(currentUser: widget.currentUser),
      ),
    );
  }

  void _navigateToEditProfile() async {
    if (_userProfile == null) return;

    final result = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          currentUser: widget.currentUser,
          userProfile: _userProfile!,
        ),
      ),
    );

    // 편집 결과가 있으면 프로필 새로고침
    if (result != null) {
      setState(() => _userProfile = result);
    }
  }
}