import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../domain/entities/settings.dart';
import '../../domain/usecases/settings_usecases.dart';
import '../../data/repositories/settings_repository_impl.dart';

class SettingsPage extends StatefulWidget {
  final auth.User currentUser;

  const SettingsPage({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsRepositoryImpl _settingsRepository;
  late final GetAppSettingsUseCase _getAppSettingsUseCase;
  late final SaveAppSettingsUseCase _saveAppSettingsUseCase;
  late final ToggleNotificationsUseCase _toggleNotificationsUseCase;
  late final ToggleDarkModeUseCase _toggleDarkModeUseCase;
  late final ChangeLanguageUseCase _changeLanguageUseCase;
  late final ResetSettingsUseCase _resetSettingsUseCase;

  AppSettings? _settings;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _settingsRepository = SettingsRepositoryImpl();
    _getAppSettingsUseCase = GetAppSettingsUseCase(_settingsRepository);
    _saveAppSettingsUseCase = SaveAppSettingsUseCase(_settingsRepository);
    _toggleNotificationsUseCase =
        ToggleNotificationsUseCase(_settingsRepository);
    _toggleDarkModeUseCase = ToggleDarkModeUseCase(_settingsRepository);
    _changeLanguageUseCase = ChangeLanguageUseCase(_settingsRepository);
    _resetSettingsUseCase = ResetSettingsUseCase(_settingsRepository);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings =
          await _getAppSettingsUseCase.execute(widget.currentUser.id);
      setState(() => _settings = settings);
    } catch (e) {
      setState(() => _errorMessage = '설정을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(
      Future<SettingsUpdateResult> Function() updateFunction) async {
    try {
      final result = await updateFunction();
      if (result.isSuccess && result.updatedSettings != null) {
        setState(() => _settings = result.updatedSettings);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정이 저장되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? '설정 저장에 실패했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정 저장 중 오류가 발생했습니다.')),
      );
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('설정 초기화'),
        content: const Text('모든 설정을 기본값으로 초기화하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('초기화'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateSetting(
          () => _resetSettingsUseCase.execute(widget.currentUser.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F3B5C),
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
              onPressed: _loadSettings,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_settings == null) {
      return const Center(
        child: Text('설정을 불러올 수 없습니다.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('알림'),
          _buildSwitchSetting(
            title: '푸시 알림',
            subtitle: '앱 알림을 받습니다',
            value: _settings!.notificationsEnabled,
            onChanged: (value) => _updateSetting(
              () => _toggleNotificationsUseCase.execute(
                  widget.currentUser.id, value),
            ),
          ),
          const SizedBox(height: 8),
          _buildSwitchSetting(
            title: '소리',
            subtitle: '알림 소리를 재생합니다',
            value: _settings!.soundEnabled,
            onChanged: (value) async {
              final updatedSettings = _settings!.copyWith(soundEnabled: value);
              await _updateSetting(
                () => _saveAppSettingsUseCase.execute(
                    widget.currentUser.id, updatedSettings),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('화면'),
          _buildSwitchSetting(
            title: '다크 모드',
            subtitle: '어두운 테마를 사용합니다',
            value: _settings!.darkModeEnabled,
            onChanged: (value) => _updateSetting(
              () =>
                  _toggleDarkModeUseCase.execute(widget.currentUser.id, value),
            ),
          ),
          const SizedBox(height: 8),
          _buildSwitchSetting(
            title: '이미지 표시',
            subtitle: '콘텐츠 이미지를 표시합니다',
            value: _settings!.showImages,
            onChanged: (value) async {
              final updatedSettings = _settings!.copyWith(showImages: value);
              await _updateSetting(
                () => _saveAppSettingsUseCase.execute(
                    widget.currentUser.id, updatedSettings),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('데이터'),
          _buildSwitchSetting(
            title: '자동 새로고침',
            subtitle: '데이터를 자동으로 업데이트합니다',
            value: _settings!.autoRefreshEnabled,
            onChanged: (value) async {
              final updatedSettings =
                  _settings!.copyWith(autoRefreshEnabled: value);
              await _updateSetting(
                () => _saveAppSettingsUseCase.execute(
                    widget.currentUser.id, updatedSettings),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildDropdownSetting(
            title: '새로고침 간격',
            subtitle: '데이터 자동 업데이트 간격',
            value: _settings!.refreshIntervalMinutes,
            items: const [15, 30, 60, 120],
            itemLabelBuilder: (minutes) => '$minutes분',
            onChanged: (value) async {
              final updatedSettings =
                  _settings!.copyWith(refreshIntervalMinutes: value);
              await _updateSetting(
                () => _saveAppSettingsUseCase.execute(
                    widget.currentUser.id, updatedSettings),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('언어'),
          _buildDropdownSetting(
            title: '언어 설정',
            subtitle: '앱 표시 언어를 선택합니다',
            value: _settings!.language,
            items: const ['ko', 'en'],
            itemLabelBuilder: (code) => code == 'ko' ? '한국어' : 'English',
            onChanged: (value) => _updateSetting(
              () =>
                  _changeLanguageUseCase.execute(widget.currentUser.id, value),
            ),
          ),
          const SizedBox(height: 32),
          _buildActionButton(
            title: '설정 초기화',
            subtitle: '모든 설정을 기본값으로 되돌립니다',
            onPressed: _resetSettings,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F3B5C),
        ),
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF1F3B5C),
        ),
      ),
    );
  }

  Widget _buildDropdownSetting<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    required String Function(T) itemLabelBuilder,
    required ValueChanged<T> onChanged,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: DropdownButton<T>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(itemLabelBuilder(item)),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onPressed,
      ),
    );
  }
}
