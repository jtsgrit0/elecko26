import 'package:flutter/material.dart';

/// 이용약관 & 개인정보처리방침 동의 모달
/// - 각 약관을 끝까지 스크롤해야 체크 가능
/// - 전체 동의 기능
/// - 모바일 웹 스타일 UX 벤치마킹
class TermsAgreementModal extends StatefulWidget {
  const TermsAgreementModal({super.key});

  /// 모달을 표시하고, 유저가 모두 동의하면 true를 반환
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TermsAgreementModal(),
    );
    return result ?? false;
  }

  @override
  State<TermsAgreementModal> createState() => _TermsAgreementModalState();
}

class _TermsAgreementModalState extends State<TermsAgreementModal>
    with SingleTickerProviderStateMixin {
  bool _termsScrolledToEnd = false;
  bool _privacyScrolledToEnd = false;
  bool _termsAgreed = false;
  bool _privacyAgreed = false;

  // 어떤 약관을 현재 펼쳐서 보고 있는지
  int? _expandedIndex;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _allAgreed => _termsAgreed && _privacyAgreed;

  void _toggleAll(bool? value) {
    if (value == null) return;
    // 전체동의는 모든 약관을 다 읽었을 때만 가능
    if (value && (!_termsScrolledToEnd || !_privacyScrolledToEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('각 약관 내용을 끝까지 읽어주세요.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF9A3412),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _termsAgreed = value;
      _privacyAgreed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
        margin: EdgeInsets.only(bottom: bottomPadding),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 30,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(),
            const Divider(height: 1, color: Color(0xFFEDE8E1)),
            _buildAllAgreeRow(),
            const Divider(height: 1, color: Color(0xFFEDE8E1)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildTermsItem(
                      index: 0,
                      title: '이용약관',
                      subtitle: '(필수)',
                      isAgreed: _termsAgreed,
                      hasScrolledToEnd: _termsScrolledToEnd,
                      content: _termsOfServiceText,
                      onAgreedChanged: (v) =>
                          setState(() => _termsAgreed = v),
                      onScrolledToEnd: () =>
                          setState(() => _termsScrolledToEnd = true),
                    ),
                    const SizedBox(height: 12),
                    _buildTermsItem(
                      index: 1,
                      title: '개인정보처리방침',
                      subtitle: '(필수)',
                      isAgreed: _privacyAgreed,
                      hasScrolledToEnd: _privacyScrolledToEnd,
                      content: _privacyPolicyText,
                      onAgreedChanged: (v) =>
                          setState(() => _privacyAgreed = v),
                      onScrolledToEnd: () =>
                          setState(() => _privacyScrolledToEnd = true),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFD5CFC7),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B241C), Color(0xFFD35400)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '서비스 이용 동의',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '서비스 이용을 위해 아래 약관에 동의해주세요.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.close_rounded, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF3EFEA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAgreeRow() {
    return InkWell(
      onTap: () => _toggleAll(!_allAgreed),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _allAgreed
                    ? const Color(0xFF9A3412)
                    : const Color(0xFFF3EFEA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _allAgreed
                      ? const Color(0xFF9A3412)
                      : const Color(0xFFD5CFC7),
                  width: 1.5,
                ),
              ),
              child: _allAgreed
                  ? const Icon(Icons.check_rounded,
                      size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            const Text(
              '전체 동의',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '필수 항목 포함',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9A3412),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsItem({
    required int index,
    required String title,
    required String subtitle,
    required bool isAgreed,
    required bool hasScrolledToEnd,
    required String content,
    required ValueChanged<bool> onAgreedChanged,
    required VoidCallback onScrolledToEnd,
  }) {
    final isExpanded = _expandedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isExpanded ? const Color(0xFFFCFAF7) : const Color(0xFFF9F6F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAgreed
              ? const Color(0xFF9A3412).withOpacity(0.3)
              : const Color(0xFFE9E3DA),
          width: isAgreed ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // 헤더 행 (체크박스 + 제목 + 펼치기 버튼)
          InkWell(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Row(
                children: [
                  // 체크박스
                  GestureDetector(
                    onTap: () {
                      if (!hasScrolledToEnd && !isAgreed) {
                        // 아직 끝까지 안 읽었으면 펼쳐서 약관을 보여줌
                        setState(() => _expandedIndex = index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('약관 내용을 끝까지 스크롤해주세요.'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: const Color(0xFF9A3412),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      onAgreedChanged(!isAgreed);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isAgreed
                            ? const Color(0xFF9A3412)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isAgreed
                              ? const Color(0xFF9A3412)
                              : const Color(0xFFCCC6BC),
                          width: 1.5,
                        ),
                        boxShadow: isAgreed
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF9A3412).withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isAgreed
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isAgreed
                                ? const Color(0xFF9A3412)
                                : const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const Spacer(),
                        if (hasScrolledToEnd && !isAgreed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '확인 완료',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        if (!hasScrolledToEnd && !isExpanded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '미확인',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 약관 내용 (펼쳐졌을 때)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildScrollableContent(
              content: content,
              hasScrolledToEnd: hasScrolledToEnd,
              onScrolledToEnd: onScrolledToEnd,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableContent({
    required String content,
    required bool hasScrolledToEnd,
    required VoidCallback onScrolledToEnd,
  }) {
    return Column(
      children: [
        Container(
          height: 220,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E1DB)),
          ),
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (!hasScrolledToEnd &&
                      notification is ScrollUpdateNotification) {
                    final metrics = notification.metrics;
                    if (metrics.pixels >=
                        metrics.maxScrollExtent - 20) {
                      onScrolledToEnd();
                    }
                  }
                  return false;
                },
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(4),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF4B5563),
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
              ),
              // 하단 그라데이션 + 스크롤 안내
              if (!hasScrolledToEnd)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(11)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0),
                          Colors.white.withOpacity(0.95),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swipe_down_rounded,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '끝까지 스크롤해주세요',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // 스크롤 완료 표시
              if (hasScrolledToEnd)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: Color(0xFF15803D)),
                        SizedBox(width: 4),
                        Text(
                          '모두 확인',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: _allAgreed
                  ? const LinearGradient(
                      colors: [Color(0xFF7B241C), Color(0xFFD35400)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: _allAgreed ? null : const Color(0xFFE5E1DB),
              boxShadow: _allAgreed
                  ? [
                      BoxShadow(
                        color: const Color(0xFF9A3412).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: _allAgreed
                  ? () => Navigator.pop(context, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFFA39E96),
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _allAgreed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _allAgreed ? '동의하고 계속하기' : '약관에 모두 동의해주세요',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 약관 텍스트 (실제 서비스에 맞게 수정)
// ─────────────────────────────────────────────────────────

const String _termsOfServiceText = '''
엘렉코26 이용약관

제1조 (목적)
본 약관은 엘렉코26(이하 "서비스")이 제공하는 2026년 지방선거 관련 정보 서비스의 이용 조건 및 절차, 서비스 제공자와 이용자의 권리·의무·책임 사항을 규정함을 목적으로 합니다.

제2조 (정의)
① "서비스"란 엘렉코26이 제공하는 선거 후보자 정보 조회, 여론조사 데이터 열람, 당선 예측 분석, 투표 참여 등 일체의 기능을 말합니다.
② "이용자"란 본 약관에 따라 서비스를 이용하는 회원 및 비회원을 말합니다.
③ "회원"이란 서비스에 가입하여 아이디(계정)를 부여받은 이용자를 말합니다.
④ "콘텐츠"란 서비스에서 제공하는 후보자 프로필, 선거구 정보, 여론조사 결과, 분석 데이터 등의 정보를 말합니다.

제3조 (약관의 효력 및 변경)
① 본 약관은 서비스 화면에 게시하거나 기타 방법으로 공지함으로써 효력이 발생합니다.
② 회사는 관련 법령을 위반하지 않는 범위에서 약관을 개정할 수 있으며, 개정 시 적용일자 및 개정 사유를 명시하여 최소 7일 전에 공지합니다.
③ 변경된 약관에 동의하지 않을 경우 이용자는 탈퇴할 수 있습니다.

제4조 (회원 가입)
① 회원 가입은 이용자가 본 약관에 동의한 후 회원 정보를 기입하고 서비스가 이를 승인함으로써 체결됩니다.
② 회원 가입 시 이메일 주소 또는 소셜 로그인 계정(Google, Apple 등)을 통해 가입할 수 있습니다.
③ 다음 각호에 해당하는 경우 가입을 거부하거나 사후에 이용 제한을 할 수 있습니다:
  1. 타인의 정보를 도용한 경우
  2. 허위 정보를 기재한 경우
  3. 기타 서비스 이용 약관을 위반한 경우

제5조 (서비스 이용)
① 서비스는 연중무휴 24시간 제공을 원칙으로 하나, 시스템 점검 등의 사유로 일시 중단될 수 있습니다.
② 서비스에서 제공하는 선거 관련 정보는 참고용이며, 실제 선거 결과와 다를 수 있습니다.
③ 여론조사 데이터는 국가선거여론조사심의위원회(NESDC) 공개 데이터를 기반으로 하며, 서비스가 자체 제작한 것이 아닙니다.

제6조 (이용자의 의무)
① 이용자는 서비스 이용 시 관련 법령과 본 약관을 준수해야 합니다.
② 이용자는 다음 행위를 하여서는 안 됩니다:
  1. 허위 정보 등록 또는 타인 정보 도용
  2. 서비스 정보를 무단으로 변경, 삭제하는 행위
  3. 서비스에 대한 비정상적이거나 과도한 요청
  4. 다른 이용자의 개인정보를 수집하는 행위
  5. 기타 관련 법령에 위반되는 행위

제7조 (서비스 제공자의 의무)
① 서비스는 관련 법령과 본 약관이 정하는 바에 따라 지속적이고 안정적으로 서비스를 제공합니다.
② 서비스는 이용자의 개인정보 보호를 위해 개인정보처리방침을 수립하고 이를 준수합니다.
③ 이용자가 안전하게 서비스를 이용할 수 있도록 보안 시스템을 구축·운영합니다.

제8조 (지적재산권)
① 서비스가 작성한 콘텐츠에 대한 저작권은 서비스에 귀속됩니다.
② 이용자는 서비스 콘텐츠를 개인적 비영리 목적으로만 이용할 수 있으며, 상업적 이용 시 사전 동의가 필요합니다.

제9조 (면책조항)
① 서비스는 천재지변, 전쟁, 기간통신사업자의 서비스 장애 등 불가항력으로 인한 서비스 중단에 대하여 책임을 지지 않습니다.
② 서비스에서 제공하는 당선 예측, 분석 결과는 통계적 추정이며, 이를 기반으로 한 판단에 대해 어떠한 법적 책임도 지지 않습니다.
③ 이용자가 서비스에 게시한 투표, 의견 등에 의해 발생한 손해에 대해 서비스는 책임을 지지 않습니다.

제10조 (분쟁 해결)
① 서비스와 이용자 간 발생한 분쟁은 대한민국 법률에 따라 해결합니다.
② 서비스 이용으로 발생한 분쟁에 대해 소송이 제기되는 경우, 서비스 소재지를 관할하는 법원을 관할법원으로 합니다.

부칙
본 약관은 2026년 4월 1일부터 시행합니다.
''';

const String _privacyPolicyText = '''
엘렉코26 개인정보처리방침

엘렉코26(이하 "서비스")은 이용자의 개인정보를 중요시하며, 「개인정보 보호법」 등 관련 법률을 준수합니다. 본 개인정보처리방침은 서비스가 수집하는 개인정보의 항목, 이용 목적, 보유 기간, 제3자 제공 여부 등을 안내합니다.

제1조 (수집하는 개인정보 항목)
① 필수 수집 항목:
  - 이메일 주소
  - 비밀번호 (암호화 저장)
  - 서비스 이용 기록 (로그인 일시, 접속 IP)

② 소셜 로그인 시 추가 수집 항목:
  - Google: 이름, 이메일, 프로필 사진 URL
  - Apple: 이름, 이메일 (사용자 선택에 따름)

③ 자동 수집 항목:
  - 기기 정보 (OS 유형, 버전)
  - 앱 사용 통계 (접속 빈도, 기능 이용 패턴)

제2조 (개인정보의 이용 목적)
수집된 개인정보는 다음 목적으로 이용됩니다:
  ① 회원 가입 및 관리: 본인 확인, 계정 관리, 부정 이용 방지
  ② 서비스 제공: 맞춤형 선거 정보 제공, 관심 후보 저장, 투표 참여 기능
  ③ 통계 분석: 서비스 개선을 위한 이용 패턴 분석 (비식별화 처리)
  ④ 고객 지원: 문의 응대, 공지사항 전달

제3조 (개인정보의 보유 및 이용 기간)
① 회원 탈퇴 시까지 보유하며, 탈퇴 즉시 파기합니다.
② 단, 관련 법령에 의해 보존이 필요한 경우 해당 기간 동안 보관합니다:
  - 전자상거래 등에서의 소비자 보호에 관한 법률: 계약 또는 청약 철회 등에 관한 기록 5년
  - 통신비밀보호법: 서비스 이용 관련 기록 3개월

제4조 (개인정보의 제3자 제공)
① 서비스는 원칙적으로 이용자의 개인정보를 제3자에게 제공하지 않습니다.
② 다만, 다음의 경우에는 예외로 합니다:
  - 이용자가 사전에 동의한 경우
  - 법률에 특별한 규정이 있는 경우
  - 수사 목적으로 법령에 정해진 절차에 따라 요청이 있는 경우

제5조 (개인정보 처리 위탁)
서비스는 원활한 서비스 제공을 위해 다음과 같이 개인정보 처리를 위탁합니다:
  - Firebase (Google LLC): 인증 관리, 데이터 저장
  - Google Analytics: 서비스 이용 통계

제6조 (이용자의 권리)
① 이용자는 언제든지 자신의 개인정보를 조회, 수정, 삭제할 수 있습니다.
② 회원 탈퇴를 요청할 경우 즉시 처리되며, 개인정보는 지체 없이 파기됩니다.
③ 개인정보 열람, 정정, 삭제 요청은 서비스 내 설정 메뉴 또는 이메일을 통해 할 수 있습니다.

제7조 (개인정보의 파기)
① 보유 기간이 경과하거나 처리 목적이 달성된 개인정보는 지체 없이 파기합니다.
② 전자적 파일 형태: 복구 불가능한 방법으로 영구 삭제
③ 기록물, 인쇄물, 서면: 파쇄 또는 소각

제8조 (개인정보 보호를 위한 기술적·관리적 대책)
① 개인정보 암호화: 비밀번호는 단방향 암호화(해시)로 저장됩니다.
② 접근 통제: 개인정보 처리 시스템에 대한 접근 권한을 최소화합니다.
③ 보안 프로그램: 해킹, 바이러스 등에 대응하기 위한 보안 시스템을 운영합니다.

제9조 (쿠키 및 자동 수집 장치)
① 서비스는 이용자의 편의를 위해 쿠키(Cookie)를 사용할 수 있습니다.
② 이용자는 브라우저 설정을 통해 쿠키 저장을 거부할 수 있습니다.

제10조 (개인정보 보호책임자)
개인정보 보호에 관한 문의사항은 아래 연락처로 문의해주세요:
  - 담당자: 개인정보 보호 담당
  - 이메일: privacy@elecko26.kr

제11조 (개정 이력)
본 개인정보처리방침은 2026년 4월 1일부터 시행합니다.
변경 사항이 있을 경우 시행 7일 전에 공지합니다.
''';
