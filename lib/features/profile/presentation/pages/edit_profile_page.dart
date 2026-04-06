import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../domain/entities/profile.dart';
import '../../domain/usecases/profile_usecases.dart';
import '../../data/repositories/profile_repository_impl.dart';

class EditProfilePage extends StatefulWidget {
  final auth.User currentUser;
  final UserProfile userProfile;

  const EditProfilePage({
    Key? key,
    required this.currentUser,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final ProfileRepositoryImpl _profileRepository;
  late final UpdateUserProfileUseCase _updateUserProfileUseCase;

  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedBirthDate;
  String? _selectedGender;
  bool _isLoading = false;

  final List<String> _genderOptions = ['남성', '여성', '기타', '선택 안함'];

  @override
  void initState() {
    super.initState();
    _profileRepository = ProfileRepositoryImpl();
    _updateUserProfileUseCase = UpdateUserProfileUseCase(_profileRepository);

    // 기존 데이터로 초기화
    _displayNameController.text = widget.userProfile.displayName ?? '';
    _bioController.text = widget.userProfile.bio ?? '';
    _phoneController.text = widget.userProfile.phoneNumber ?? '';
    _locationController.text = widget.userProfile.location ?? '';
    _selectedBirthDate = widget.userProfile.birthDate;
    _selectedGender = widget.userProfile.gender;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = widget.userProfile.copyWith(
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        birthDate: _selectedBirthDate,
        gender: _selectedGender == '선택 안함' ? null : _selectedGender,
      );

      final result = await _updateUserProfileUseCase.execute(
        widget.currentUser.id,
        updatedProfile,
      );

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프로필이 저장되었습니다.')),
          );
          Navigator.of(context).pop(result.updatedProfile);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage ?? '저장 중 오류가 발생했습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F3B5C),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text(
              '저장',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _displayNameController,
                      label: '이름',
                      hint: '표시할 이름을 입력하세요',
                      validator: (value) {
                        if (value != null && value.length > 50) {
                          return '이름은 50자 이하로 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _bioController,
                      label: '자기소개',
                      hint: '간단한 자기소개를 입력하세요',
                      maxLines: 3,
                      validator: (value) {
                        if (value != null && value.length > 200) {
                          return '자기소개는 200자 이하로 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: '전화번호',
                      hint: '010-1234-5678',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildBirthDateField(),
                    const SizedBox(height: 16),
                    _buildGenderField(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _locationController,
                      label: '지역',
                      hint: '거주 지역을 입력하세요',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: widget.userProfile.avatarUrl != null
                ? NetworkImage(widget.userProfile.avatarUrl!)
                : null,
            child: widget.userProfile.avatarUrl == null
                ? const Icon(Icons.person, size: 60, color: Colors.white)
                : null,
            backgroundColor: const Color(0xFF1F3B5C),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // TODO: 이미지 선택 기능 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 이미지 변경 기능은 곧 추가됩니다.')),
              );
            },
            child: const Text('프로필 이미지 변경'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildBirthDateField() {
    return InkWell(
      onTap: _selectBirthDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '생년월일',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedBirthDate != null
                  ? '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}'
                  : '생년월일을 선택하세요',
              style: TextStyle(
                color: _selectedBirthDate != null ? Colors.black : Colors.grey,
              ),
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: const InputDecoration(
        labelText: '성별',
        border: OutlineInputBorder(),
      ),
      items: _genderOptions.map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Text(gender),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedGender = value);
      },
    );
  }
}