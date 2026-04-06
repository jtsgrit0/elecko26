import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../domain/entities/poll.dart';
import '../../domain/usecases/poll_usecases.dart';
import '../../data/repositories/poll_repository_impl.dart';

class CreatePollPage extends StatefulWidget {
  final auth.User currentUser;

  const CreatePollPage({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<CreatePollPage> createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  late final PollRepositoryImpl _pollRepository;
  late final CreatePollUseCase _createPollUseCase;

  List<String> _options = ['', '']; // 최소 2개 옵션
  List<String> _tags = [];
  bool _isAnonymous = false;
  bool _allowMultipleVotes = false;
  bool _showResultsBeforeEnd = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _pollRepository = PollRepositoryImpl();
    _createPollUseCase = CreatePollUseCase(_pollRepository);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add('');
    });
  }

  void _removeOption(int index) {
    if (_options.length > 2) {
      setState(() {
        _options.removeAt(index);
      });
    }
  }

  void _updateOption(int index, String value) {
    setState(() {
      _options[index] = value;
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _createPoll() async {
    if (!_formKey.currentState!.validate()) return;

    // 옵션 검증
    final validOptions = _options.where((option) => option.trim().isNotEmpty).toList();
    if (validOptions.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 2개의 선택지를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final poll = Poll(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        creatorId: widget.currentUser.id,
        options: validOptions.map((text) => PollOption(
          id: DateTime.now().millisecondsSinceEpoch.toString() + text.hashCode.toString(),
          text: text.trim(),
        )).toList(),
        settings: PollSettings(
          isAnonymous: _isAnonymous,
          allowMultipleVotes: _allowMultipleVotes,
          showResultsBeforeEnd: _showResultsBeforeEnd,
        ),
        status: PollStatus.active,
        createdAt: DateTime.now(),
        tags: _tags,
      );

      final result = await _createPollUseCase.execute(poll);

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('투표가 성공적으로 생성되었습니다.')),
        );
        Navigator.of(context).pop(true); // 성공 표시로 돌아가기
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? '투표 생성에 실패했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('투표 생성 중 오류가 발생했습니다.')),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('투표 만들기'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F3B5C),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createPoll,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '생성',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildOptionsSection(),
              const SizedBox(height: 24),
              _buildSettingsSection(),
              const SizedBox(height: 24),
              _buildTagsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기본 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '투표 제목',
                hintText: '투표의 제목을 입력하세요',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '투표 제목을 입력해주세요.';
                }
                if (value.length > 100) {
                  return '제목은 100자 이하로 입력해주세요.';
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명 (선택사항)',
                hintText: '투표에 대한 설명을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '선택지',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('추가'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: option,
                        decoration: InputDecoration(
                          labelText: '선택지 ${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => _updateOption(index, value),
                        validator: (value) {
                          if (index < 2 && (value == null || value.trim().isEmpty)) {
                            return '최소 2개의 선택지를 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_options.length > 2)
                      IconButton(
                        onPressed: () => _removeOption(index),
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '투표 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('익명 투표'),
              subtitle: const Text('참여자의 신원을 숨깁니다'),
              value: _isAnonymous,
              onChanged: (value) => setState(() => _isAnonymous = value),
            ),
            SwitchListTile(
              title: const Text('복수 선택 허용'),
              subtitle: const Text('여러 개의 선택지를 선택할 수 있습니다'),
              value: _allowMultipleVotes,
              onChanged: (value) => setState(() => _allowMultipleVotes = value),
            ),
            SwitchListTile(
              title: const Text('투표 전 결과 보기'),
              subtitle: const Text('투표 종료 전에도 중간 결과를 볼 수 있습니다'),
              value: _showResultsBeforeEnd,
              onChanged: (value) => setState(() => _showResultsBeforeEnd = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '태그 (선택사항)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: '태그 입력',
                      hintText: '예: 정치, 경제, 사회',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTag,
                  child: const Text('추가'),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}