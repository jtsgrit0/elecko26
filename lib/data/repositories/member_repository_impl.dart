import 'package:flutter_application_1/domain/entities/member.dart';
import 'package:flutter_application_1/domain/entities/poll.dart';
import 'package:flutter_application_1/domain/repositories/member_repository.dart';
import 'package:flutter_application_1/data/datasources/nesdc_poll_data_source.dart';
import 'package:flutter_application_1/core/platform/platform_info.dart';

/// 멤버 저장소 구현체 (데이터 레이어)
class MemberRepositoryImpl implements MemberRepository {
  final NesdcPollDataSource _nesdcPollDataSource = NesdcPollDataSource();
  bool _refreshInProgress = false;
  // 더미 데이터 - 정청래 의원
  static final List<Member> _dummyMembers = [
    Member(
      id: 'member_001',
      name: '정청래',
      party: '더불어민주당',
      district: '서울 종로구',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/%EC%A0%95%EC%B2%AD%EB%9E%98_%EB%B2%99%EC%BB%A41.png/250px-%EC%A0%95%EC%B2%AD%EB%9E%98_%EB%B2%99%EC%BB%A41.png',
      bio: '대한민국 정치인, 변호사. 더불어민주당 대표로 활동 중.',
      electionDate: DateTime(2026, 6, 3),
      term: 22,
      achievementsList: [
        '국회 국방위원회 위원',
        '국회 정당심판 국민의원',
        '국회 정치관계법심사소위원회 위원',
        '더불어민주당 대표 (2024.12 ~)',
        '법무부장관 역임',
        '대검찰청 검사 (법조인으로서 30년 이상 경력)',
      ],
      actions: [
        '2024년 국정감시 활동 활발 - 국방력 강화 및 국가안보 관련 정책 제시',
        '2024년 정당 대표로서 당 통합 및 경쇄 민주당원 결집',
        '국회 국방위원회에서 국방 정책 논의 주도',
        '국민과의 소통을 위한 지역 순회 활동',
      ],
      policies: [
        '국방력 강화 및 국가안보 정책',
        '법치주의 강화 및 검경 수사권 조정',
        '민주주의 수호 및 언론 자유 보장',
        '경제 민주화 및 중소기업 지원 정책',
        '기후변화 대응 및 탄소중립 정책',
        '교육 개혁 및 청년 정책',
      ],
      pressReports: [
        PressReport(
          id: 'press_001',
          title: '정청래 더불어민주당 대표, 2026 지방선거 전략 발표',
          source: '연합뉴스',
          url: 'https://example.com/news/001',
          publishDate: DateTime(2026, 1, 15),
          summary: '정청래 더불어민주당 대표가 2026년 지방선거를 앞두고 당의 중장기 전략을 발표했다.',
          sentiment: 'positive',
        ),
        PressReport(
          id: 'press_002',
          title: '정청래, 국방력 강화 관련 담화 발표',
          source: '뉴시스',
          url: 'https://example.com/news/002',
          publishDate: DateTime(2026, 1, 20),
          summary: '국회 국방위원회 위원인 정청래 대표가 국방력 강화에 관한 의견을 제시했다.',
          sentiment: 'neutral',
        ),
        PressReport(
          id: 'press_003',
          title: '정청래 대표, 당원과의 간담회에서 국정 방향 설명',
          source: '경향신문',
          url: 'https://example.com/news/003',
          publishDate: DateTime(2026, 2, 01),
          summary: '정청래 대표가 서울 종로구에서 당원들과의 간담회를 통해 향후 정당의 방향을 설명했다.',
          sentiment: 'positive',
        ),
      ],
      polls: [
        // 갤럽 여론조사
        Poll(
          id: 'poll_001',
          pollAgency: '갤럽',
          surveyDate: DateTime(2026, 1, 20),
          supportRate: 0.65,
          partyName: '더불어민주당',
          sampleSize: 1008,
          marginOfError: 3.1,
          source: 'https://gallup.com.kr',
          notes: '전국 만 18세 이상',
        ),
        Poll(
          id: 'poll_002',
          pollAgency: '갤럽',
          surveyDate: DateTime(2026, 1, 28),
          supportRate: 0.67,
          partyName: '더불어민주당',
          sampleSize: 1010,
          marginOfError: 3.1,
          source: 'https://gallup.com.kr',
          notes: '전국 만 18세 이상',
        ),
        // 리서치앤리서치 여론조사
        Poll(
          id: 'poll_003',
          pollAgency: '리서치앤리서치',
          surveyDate: DateTime(2026, 1, 25),
          supportRate: 0.63,
          partyName: '더불어민주당',
          sampleSize: 1009,
          marginOfError: 3.1,
          source: 'https://rr.or.kr',
          notes: '지역구 당선율 분석',
        ),
        Poll(
          id: 'poll_004',
          pollAgency: '리서치앤리서치',
          surveyDate: DateTime(2026, 2, 1),
          supportRate: 0.68,
          partyName: '더불어민주당',
          sampleSize: 1012,
          marginOfError: 3.1,
          source: 'https://rr.or.kr',
          notes: '서울시 종로구 지역구',
        ),
        // 리얼미터 여론조사
        Poll(
          id: 'poll_005',
          pollAgency: '리얼미터',
          surveyDate: DateTime(2026, 1, 30),
          supportRate: 0.66,
          partyName: '더불어민주당',
          sampleSize: 1000,
          marginOfError: 3.1,
          source: 'https://realmeter.net',
          notes: '일일 추적조사',
        ),
        Poll(
          id: 'poll_006',
          pollAgency: '리얼미터',
          surveyDate: DateTime(2026, 2, 3),
          supportRate: 0.69,
          partyName: '더불어민주당',
          sampleSize: 1005,
          marginOfError: 3.1,
          source: 'https://realmeter.net',
          notes: '일일 추적조사',
        ),
        // 매일경제 여론조사
        Poll(
          id: 'poll_007',
          pollAgency: '매일경제',
          surveyDate: DateTime(2026, 2, 2),
          supportRate: 0.70,
          partyName: '더불어민주당',
          sampleSize: 1015,
          marginOfError: 3.1,
          source: 'https://mk.co.kr/poll',
          notes: '정당 지지도 및 대표 신임도',
        ),
      ],
      electionPossibility: 0.78,
      lastAnalysisDate: DateTime(2026, 2, 4),
      improvementPoints: [
        '국방 정책 외에 경제, 복지 분야 관심도 확대 필요',
        '청년층 지지도 확보를 위한 정책 개발 강화',
        '지역 주민과의 직접적인 소통 및 관계 구축 확대',
        '국제 관계 및 외교 정책에 대한 입장 명확히 할 필요',
      ],
    ),
    // 이준석 의원 (국민의힘)
    Member(
      id: 'member_002',
      name: '이준석',
      party: '국민의힘',
      district: '서울 강남구',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Lee_Jun-seok.jpg/250px-Lee_Jun-seok.jpg',
      bio: '국민의힘 의원, 전 당 대표. 서울시장 출마 예정.',
      electionDate: DateTime(2026, 6, 3),
      term: 22,
      achievementsList: [
        '국민의힘 당 대표 역임 (2021~2022)',
        '국회 외교통일위원회 위원',
        '국회 신성장동력특별위원회 위원',
        '정부혁신 및 규제개혁 정책 추진',
        '젊은 정치 리더십 확보',
        '국제 외교 협력 강화',
      ],
      actions: [
        '2024년 야당 정강정책 개발 활동',
        '국회 외교통일위원회에서 한미동맹 강화 주도',
        '부동산 정책 및 청년정책 논의 주도',
        '언론 출연과 국민 소통 확대',
      ],
      policies: [
        '서울시 경제 활성화 및 일자리 창출',
        '부동산 안정화 및 주택 공급 확대',
        '청년층 정책 개발 및 지원 강화',
        '국방력 강화 및 한미동맹 강화',
        '디지털 경제 발전 및 기술혁신',
        '환경 및 에너지 정책 개발',
      ],
      pressReports: [
        PressReport(
          id: 'press_004',
          title: '이준석, 서울시장 출마 선언 "보수 정치 쇄신하겠다"',
          source: '조선일보',
          url: 'https://example.com/news/004',
          publishDate: DateTime(2026, 1, 10),
          summary: '이준석이 2026년 서울시장 출마를 공식 선언했다.',
          sentiment: 'positive',
        ),
        PressReport(
          id: 'press_005',
          title: '이준석, 국회 외교통일위원회에서 한미동맹 강화 주장',
          source: '동아일보',
          url: 'https://example.com/news/005',
          publishDate: DateTime(2026, 1, 25),
          summary: '한미동맹의 중요성을 강조하며 국방력 강화 필요성을 제기했다.',
          sentiment: 'neutral',
        ),
        PressReport(
          id: 'press_006',
          title: '이준석 "청년 일자리 창출에 국정 중심 두겠다"',
          source: '중앙일보',
          url: 'https://example.com/news/006',
          publishDate: DateTime(2026, 2, 02),
          summary: '청년 세대의 경제 활동 기회 확대를 위한 정책을 발표했다.',
          sentiment: 'positive',
        ),
      ],
      polls: [
        Poll(
          id: 'poll_008',
          pollAgency: '리서치앤리서치',
          surveyDate: DateTime(2026, 1, 22),
          supportRate: 0.58,
          partyName: '국민의힘',
          sampleSize: 1010,
          marginOfError: 3.1,
          source: 'https://rr.or.kr',
          notes: '서울시장 후보 선호도',
        ),
        Poll(
          id: 'poll_009',
          pollAgency: '갤럽',
          surveyDate: DateTime(2026, 1, 29),
          supportRate: 0.60,
          partyName: '국민의힘',
          sampleSize: 1008,
          marginOfError: 3.1,
          source: 'https://gallup.com.kr',
          notes: '정당 지지도',
        ),
        Poll(
          id: 'poll_010',
          pollAgency: '리얼미터',
          surveyDate: DateTime(2026, 2, 02),
          supportRate: 0.62,
          partyName: '국민의힘',
          sampleSize: 1005,
          marginOfError: 3.1,
          source: 'https://realmeter.net',
          notes: '일일 추적조사',
        ),
      ],
      electionPossibility: 0.65,
      lastAnalysisDate: DateTime(2026, 2, 4),
      improvementPoints: [
        '지역구 대면 활동 강화 필요',
        '보수 진영 결집을 위한 통합 리더십 강화',
        '경제 정책 구체성 강화',
        '서울시민 관심사 세분화 분석',
      ],
    ),
    // 박형준 의원 (국민의힘)
    Member(
      id: 'member_003',
      name: '박형준',
      party: '국민의힘',
      district: '부산광역시',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Park_Heong-joon_on_24_June_2022.jpg/250px-Park_Heong-joon_on_24_June_2022.jpg',
      bio: '부산광역시장, 국민의힘 의원. 재선 출마.',
      electionDate: DateTime(2026, 6, 3),
      term: 22,
      achievementsList: [
        '부산광역시장 재임 (2022~현재)',
        '해양수도 부산 조성',
        '부산항 국제 경쟁력 강화',
        '부산-카이로 우호 도시 협력',
        '지역 경제 활성화 주도',
        '국제 교류 확대',
      ],
      actions: [
        '2025년 부산항 개발 및 해양산업 육성',
        '부산-대구-울산 광역협력 주도',
        '국제 행사 유치 및 추진 (APEC, 영상축제 등)',
        '지역 주민과의 소통 행사 정기 개최',
      ],
      policies: [
        '해양수도 부산 구현',
        '부산항 세계 5대 항만 도약',
        '신항 개발 및 항만 기능 고도화',
        '관광산업 발전 및 영상산업 육성',
        '청년 창업 및 취업 지원',
        '도시 재생 및 문화 인프라 확충',
      ],
      pressReports: [
        PressReport(
          id: 'press_007',
          title: '박형준 부산시장, 2026 지방선거 재선 출마 선언',
          source: '매일신문',
          url: 'https://example.com/news/007',
          publishDate: DateTime(2026, 1, 12),
          summary: '박형준이 부산광역시장 재선 출마 의사를 표현했다.',
          sentiment: 'positive',
        ),
        PressReport(
          id: 'press_008',
          title: '부산항, 세계 5대 항만 도약 성과 인정',
          source: '부산일보',
          url: 'https://example.com/news/008',
          publishDate: DateTime(2026, 1, 28),
          summary: '박형준 시장 재임 중 부산항이 국제 경쟁력을 갖추게 되었다.',
          sentiment: 'positive',
        ),
        PressReport(
          id: 'press_009',
          title: '박형준 시장, 국제 관광객 유치 성과 보고',
          source: '뉴시스',
          url: 'https://example.com/news/009',
          publishDate: DateTime(2026, 2, 01),
          summary: '부산이 동북아 관광 허브로서의 위상을 강화했다.',
          sentiment: 'neutral',
        ),
      ],
      polls: [
        Poll(
          id: 'poll_011',
          pollAgency: '갤럽',
          surveyDate: DateTime(2026, 1, 21),
          supportRate: 0.72,
          partyName: '국민의힘',
          sampleSize: 1010,
          marginOfError: 3.1,
          source: 'https://gallup.com.kr',
          notes: '부산시장 적극 지지',
        ),
        Poll(
          id: 'poll_012',
          pollAgency: '리서치앤리서치',
          surveyDate: DateTime(2026, 1, 27),
          supportRate: 0.70,
          partyName: '국민의힘',
          sampleSize: 1009,
          marginOfError: 3.1,
          source: 'https://rr.or.kr',
          notes: '지역 영호남 지지도',
        ),
        Poll(
          id: 'poll_013',
          pollAgency: '리얼미터',
          surveyDate: DateTime(2026, 2, 03),
          supportRate: 0.74,
          partyName: '국민의힘',
          sampleSize: 1008,
          marginOfError: 3.1,
          source: 'https://realmeter.net',
          notes: '부산권 일일 추적',
        ),
      ],
      electionPossibility: 0.78,
      lastAnalysisDate: DateTime(2026, 2, 4),
      improvementPoints: [
        '강원권 지역 경제 발전 협력 필요',
        '일자리 창출 정책 더욱 구체화',
        '환경오염 문제 개선 강화',
        '젊은 세대와의 소통 채널 확대',
      ],
    ),
    // 강선우 의원 (국민의힘)
    Member(
      id: 'member_004',
      name: '강선우',
      party: '국민의힘',
      district: '인천광역시',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Kang_Sun-woo%27s_Portrait_%282025.5%29.jpg/250px-Kang_Sun-woo%27s_Portrait_%282025.5%29.jpg',
      bio: '국민의힘 의원, 인천광역시장 출마 예정.',
      electionDate: DateTime(2026, 6, 3),
      term: 22,
      achievementsList: [
        '인천지역 국회의원 (제21,22대)',
        '국회 국방위원회 위원',
        '국회 과학기술정보통신위원회 위원',
        '인천 경제 활성화 주도',
        '중국과의 협력 강화',
        '기술혁신 정책 추진',
      ],
      actions: [
        '2024년 인천 스마트시티 프로젝트 추진',
        '한중 경제 협력 방안 논의',
        '반도체 및 첨단산업 유치 활동',
        '해외 기술 교류 및 투자 유치',
      ],
      policies: [
        '인천 경제자유구역 활성화',
        '스마트시티 구현 및 디지털 혁신',
        '항공산업 및 첨단제조업 육성',
        '청년 기술 인력 양성',
        '환동해 경제권 조성',
        '관광산업 발전 및 문화예술 지원',
      ],
      pressReports: [
        PressReport(
          id: 'press_010',
          title: '강선우, 인천광역시장 출마 공식 선언',
          source: '인천일보',
          url: 'https://example.com/news/010',
          publishDate: DateTime(2026, 1, 15),
          summary: '강선우가 인천시장 선거에 국민의힘 후보로 출마를 선언했다.',
          sentiment: 'positive',
        ),
        PressReport(
          id: 'press_011',
          title: '강선우, 인천 첨단산업 육성 정책 발표',
          source: '경인일보',
          url: 'https://example.com/news/011',
          publishDate: DateTime(2026, 1, 26),
          summary: '반도체, AI 등 첨단산업을 인천으로 유치하는 방안을 제시했다.',
          sentiment: 'neutral',
        ),
        PressReport(
          id: 'press_012',
          title: '강선우 "인천 경제자유구역 국제 경쟁력 강화하겠다"',
          source: '뉴스1',
          url: 'https://example.com/news/012',
          publishDate: DateTime(2026, 2, 03),
          summary: '인천의 국제 경쟁력을 높이기 위한 정책 공약을 발표했다.',
          sentiment: 'positive',
        ),
        PressReport(
          id: 'press_016',
          title: '강선우 여가부 장관 후보자 적합도 조사에서 부적합 의견 우세',
          source: 'MBC',
          url: 'https://imnews.imbc.com/news/2025/politics/article/6738588_36711.html',
          publishDate: DateTime(2025, 7, 23),
          summary: '보좌진 갑질 의혹 등 논란이 제기된 가운데, 적합도 조사에서 부적합 의견이 더 많다는 여론조사 결과가 보도됐다.',
          sentiment: 'negative',
        ),
      ],
      polls: [
        Poll(
          id: 'poll_014',
          pollAgency: '조원씨앤아이',
          surveyDate: DateTime(2025, 7, 21),
          supportRate: 0.322,
          partyName: '국민의힘',
          sampleSize: 2002,
          marginOfError: 2.2,
          source: 'https://imnews.imbc.com/news/2025/politics/article/6738588_36711.html',
          notes: '여가부 장관 후보자 적합도 조사(적합 32.2%, 부적합 60.2%). 스트레이트뉴스 의뢰, 무선 ARS, 응답률 3.8%, 조사기간 7/19~7/21.',
        ),
      ],
      electionPossibility: 0.30,
      lastAnalysisDate: DateTime(2026, 2, 4),
      improvementPoints: [
        '인천 지역민 대면 활동 강화',
        '구체적 경제 정책 개발 필요',
        '청년층 소통 활동 확대',
        '환경 정책 보완 필요',
      ],
    ),
    // 신상진 의원 (더불어민주당)
      Member(
        id: 'member_005',
        name: '신상진',
        party: '더불어민주당',
        district: '대전광역시',
      imageUrl: 'https://assets.bbhub.io/dotorg/sites/72/2025/01/3781_2025_headshot_sang_shin.png',
      bio: '더불어민주당 의원, 대전광역시장 출마 예정.',
      electionDate: DateTime(2026, 6, 3),
      term: 22,
      achievementsList: [
        '더불어민주당 의원 (제21,22대)',
        '국회 산업통상자원위원회 위원',
        '국회 방위사업진흥특별위원회 위원',
        '대전 과학산업 발전 주도',
        '중소기업 지원 정책 추진',
        '노동자 권익 보호 활동',
      ],
      actions: [
        '2024년 대전 첨단산업 개발 논의',
        '중소기업 육성 및 협동조합 지원',
        '노사관계 개선 활동 주도',
        '지역 투자 유치 활동',
      ],
      policies: [
        '대전 첨단산업 클러스터 조성',
        '중소기업 지원 및 기술 이전',
        '청년 일자리 창출',
        '노동자 권익 보호 강화',
        '통일 시대 준비 및 남북교류',
        '지역 문화 및 관광 발전',
      ],
      pressReports: [
        PressReport(
          id: 'press_013',
          title: '신상진, 대전시장 출마 선언 "노동자 중심 정치 펼치겠다"',
          source: '대전일보',
          url: 'https://example.com/news/013',
          publishDate: DateTime(2026, 1, 14),
          summary: '신상진이 더불어민주당 후보로서 대전시장 출마 의사를 표현했다.',
          sentiment: 'positive',
        ),
        PressReport(
          id: 'press_014',
          title: '신상진, 중소기업 지원 정책 발표 "동반성장 기반 마련"',
          source: '충청일보',
          url: 'https://example.com/news/014',
          publishDate: DateTime(2026, 1, 27),
          summary: '대전 중소기업 육성을 위한 실질적 지원 방안을 제시했다.',
          sentiment: 'neutral',
        ),
        PressReport(
          id: 'press_015',
          title: '신상진 "노동자 정책과 중소기업 지원이 양립한다"',
          source: '한겨레',
          url: 'https://example.com/news/015',
          publishDate: DateTime(2026, 2, 02),
          summary: '노동자 권익 보호와 중소기업 지원의 조화를 강조했다.',
          sentiment: 'positive',
        ),
      ],
      polls: [
        Poll(
          id: 'poll_017',
          pollAgency: '갤럽',
          surveyDate: DateTime(2026, 1, 23),
          supportRate: 0.61,
          partyName: '더불어민주당',
          sampleSize: 1009,
          marginOfError: 3.1,
          source: 'https://gallup.com.kr',
          notes: '대전시장 선호도',
        ),
        Poll(
          id: 'poll_018',
          pollAgency: '리서치앤리서치',
          surveyDate: DateTime(2026, 1, 29),
          supportRate: 0.59,
          partyName: '더불어민주당',
          sampleSize: 1011,
          marginOfError: 3.1,
          source: 'https://rr.or.kr',
          notes: '영호남 지지도',
        ),
        Poll(
          id: 'poll_019',
          pollAgency: '리얼미터',
          surveyDate: DateTime(2026, 2, 03),
          supportRate: 0.63,
          partyName: '더불어민주당',
          sampleSize: 1006,
          marginOfError: 3.1,
          source: 'https://realmeter.net',
          notes: '일일 추적조사',
        ),
      ],
      electionPossibility: 0.70,
      lastAnalysisDate: DateTime(2026, 2, 4),
        improvementPoints: [
          '진보 진영 결집을 위한 통합 리더십 강화',
          '과학산업 정책 구체화',
          '여성 정책 보강 필요',
          '통일 정책 비전 제시 필요',
        ],
      ),
      Member(
        id: 'member_006',
        name: '서영교',
        party: '더불어민주당',
        district: '서울특별시장',
        imageUrl:
            'https://img2.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202601%2F15%2Fyonhap%2F20260115112927912gbmt.jpg',
        bio: '더불어민주당 서영교 의원이 2026년 서울시장 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 22,
        achievementsList: [
          '2026 지방선거 서울시장 출마 선언',
        ],
        actions: [
          '서울시장 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_016',
            title: '與서영교 "집 걱정 없는 서울 만들겠다"…서울시장 출마 선언',
            source: '서울신문',
            url: 'https://v.daum.net/v/20260115093703613',
            publishDate: DateTime(2026, 1, 15),
            summary: '서영교 의원이 2026년 서울시장 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_007',
        name: '김교흥',
        party: '더불어민주당',
        district: '인천광역시장',
        imageUrl:
            'https://img3.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202601%2F22%2Fyonhap%2F20260122122846032zhsc.jpg',
        bio: '더불어민주당 김교흥 의원이 2026년 인천시장 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 22,
        achievementsList: [
          '2026 지방선거 인천시장 출마 선언',
        ],
        actions: [
          '인천시장 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_017',
            title: '김교흥, 인천시장 출마 선언…"인천을 한국의 메가시티로"',
            source: '연합뉴스',
            url: 'https://v.daum.net/v/20260122122803120',
            publishDate: DateTime(2026, 1, 22),
            summary: '김교흥 의원이 2026년 인천시장 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_008',
        name: '전현희',
        party: '더불어민주당',
        district: '서울특별시장',
        imageUrl:
            'https://img1.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202601%2F13%2Fhani%2F20260113112536674vnbt.jpg',
        bio: '더불어민주당 전현희 의원이 2026년 서울시장 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 22,
        achievementsList: [
          '2026 지방선거 서울시장 출마 선언',
        ],
        actions: [
          '서울시장 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_018',
            title: '전현희, 서울시장 출마 선언 “민생이 최우선”',
            source: '세계일보',
            url: 'https://v.daum.net/v/20260113112536605',
            publishDate: DateTime(2026, 1, 13),
            summary: '전현희 의원이 2026년 서울시장 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_009',
        name: '박주민',
        party: '더불어민주당',
        district: '서울특별시장',
        imageUrl:
            'https://img2.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202512%2F11%2Fkhan%2F20251211143016000xkuv.jpg',
        bio: '더불어민주당 박주민 의원이 2026년 서울시장 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 22,
        achievementsList: [
          '2026 지방선거 서울시장 출마 선언',
        ],
        actions: [
          '서울시장 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_019',
            title: '박주민 "시민 살리는 시장되겠다" 서울시장 출마 선언',
            source: '경향신문',
            url: 'https://v.daum.net/v/20251211143015993',
            publishDate: DateTime(2025, 12, 11),
            summary: '박주민 의원이 2026년 서울시장 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_010',
        name: '권칠승',
        party: '더불어민주당',
        district: '경기도지사',
        imageUrl:
            'https://img1.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202602%2F03%2Fkyeonggi%2F20260203171015337sfxt.jpg',
        bio: '더불어민주당 권칠승 의원이 2026년 경기도지사 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 22,
        achievementsList: [
          '2026 지방선거 경기도지사 출마 선언',
        ],
        actions: [
          '경기도지사 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_020',
            title: '권칠승, 경기도지사 출마 선언 "교통·경제·교육 확 바꿀 것"',
            source: '기호일보',
            url: 'https://v.daum.net/v/20260203171014996',
            publishDate: DateTime(2026, 2, 3),
            summary: '권칠승 의원이 2026년 경기도지사 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_011',
        name: '김병주',
        party: '더불어민주당',
        district: '경기도지사',
        imageUrl:
            'https://img4.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202601%2F05%2Fyonhap%2F20260105111503274bydg.jpg',
        bio: '더불어민주당 김병주 의원이 2026년 경기도지사 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 22,
        achievementsList: [
          '2026 지방선거 경기도지사 출마 선언',
        ],
        actions: [
          '경기도지사 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_021',
            title: '김병주 "출퇴근 시간 OECD 기준으로"…경기지사 출마 선언',
            source: '강원일보',
            url: 'https://v.daum.net/v/20260112160105642',
            publishDate: DateTime(2026, 1, 12),
            summary: '김병주 의원이 2026년 경기도지사 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_012',
        name: '정이한',
        party: '개혁신당',
        district: '부산광역시장',
        imageUrl:
            'https://img2.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202602%2F03%2Fyonhap%2F20260203142431064gygz.jpg',
        bio: '개혁신당 정이한 대변인이 2026년 부산시장 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 0,
        achievementsList: [
          '2026 지방선거 부산시장 출마 선언',
        ],
        actions: [
          '부산시장 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_022',
            title: '개혁신당 정이한 대변인 "부산시장 출마…젊은 부산 만들 것"',
            source: '연합뉴스',
            url: 'https://v.daum.net/v/20260203142430232',
            publishDate: DateTime(2026, 2, 3),
            summary: '정이한 대변인이 부산시장 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_013',
        name: '이강덕',
        party: '무소속',
        district: '경북도지사',
        imageUrl:
            'https://img3.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202602%2F02%2FNEWS1%2F20260202112344565fblk.jpg',
        bio: '포항시장 이강덕이 2026년 경북도지사 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 0,
        achievementsList: [
          '2026 지방선거 경북도지사 출마 선언',
        ],
        actions: [
          '경북도지사 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_023',
            title: '이강덕 포항시장 "\'제2의 박정희\' 되겠다…경북지사 출마 선언"',
            source: '뉴스1',
            url: 'https://v.daum.net/v/yXeGjdEoG4',
            publishDate: DateTime(2026, 2, 2),
            summary: '이강덕 포항시장이 경북도지사 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_014',
        name: '김재원',
        party: '국민의힘',
        district: '경북도지사',
        imageUrl:
            'https://img2.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202602%2F02%2FNEWS1%2F20260202114307309adas.jpg',
        bio: '국민의힘 김재원 전 최고위원이 2026년 경북도지사 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 22,
        achievementsList: [
          '2026 지방선거 경북도지사 출마 선언',
        ],
        actions: [
          '경북도지사 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_024',
            title: '김재원 "이철우 대안 되겠다"...경북지사 출마 선언',
            source: '뉴스1',
            url: 'https://v.daum.net/v/20260202114307229',
            publishDate: DateTime(2026, 2, 2),
            summary: '김재원 전 최고위원이 경북도지사 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_015',
        name: '주호영',
        party: '국민의힘',
        district: '대구광역시장',
        imageUrl:
            'https://img1.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202601%2F25%2Fnewsis%2F20260125161505394xpah.jpg',
        bio: '국민의힘 주호영 의원이 2026년 대구시장 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 22,
        achievementsList: [
          '2026 지방선거 대구시장 출마 선언',
        ],
        actions: [
          '대구시장 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_025',
            title: '주호영 "내년 대구시장 출마, 분열된 보수 통합"',
            source: '뉴시스',
            url: 'https://v.daum.net/v/20260125161504424',
            publishDate: DateTime(2026, 1, 25),
            summary: '주호영 의원이 대구시장 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_016',
        name: '윤재옥',
        party: '국민의힘',
        district: '대구광역시장',
        imageUrl:
            'https://img4.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202601%2F30%2Fnocut%2F20260130120602101cqxs.jpg',
        bio: '국민의힘 윤재옥 의원이 2026년 대구시장 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 22,
        achievementsList: [
          '2026 지방선거 대구시장 출마 선언',
        ],
        actions: [
          '대구시장 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_026',
            title: '윤재옥, 대구시장 출마 선언..."미래 담은 청사진 제시"',
            source: '노컷뉴스',
            url: 'https://v.daum.net/v/20260130120600016',
            publishDate: DateTime(2026, 1, 30),
            summary: '윤재옥 의원이 대구시장 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_017',
        name: '추경호',
        party: '국민의힘',
        district: '대구광역시장',
        imageUrl:
            'https://img1.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202512%2F29%2Ffnnewsi%2F20251229110227873ppuj.jpg',
        bio: '국민의힘 추경호 의원이 2026년 대구시장 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 22,
        achievementsList: [
          '2026 지방선거 대구시장 출마 선언',
        ],
        actions: [
          '대구시장 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_027',
            title: '추경호 "내년 대구시장 출마"',
            source: '파이낸셜뉴스',
            url: 'https://v.daum.net/v/20251229110227127',
            publishDate: DateTime(2025, 12, 29),
            summary: '추경호 의원이 대구시장 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_018',
        name: '이현규',
        party: '무소속',
        district: '경남 창원시장',
        imageUrl:
            'https://img4.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202601%2F07%2FchoSunbiz%2F20260107142005635baal.jpg',
        bio: '이현규 전 창원시 부시장이 2026년 창원시장 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 0,
        achievementsList: [
          '2026 지방선거 창원시장 출마 선언',
        ],
        actions: [
          '창원시장 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_028',
            title: '이현규 전 창원시 부시장, 내년 창원시장 출마 선언',
            source: '조선비즈',
            url: 'https://v.daum.net/v/14P59M715J',
            publishDate: DateTime(2026, 1, 7),
            summary: '이현규 전 부시장이 창원시장 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_019',
        name: '김수우',
        party: '무소속',
        district: '경기 평택시장',
        imageUrl:
            'https://img1.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202601%2F08%2Fkyeonggi%2F20260108171921488cmxl.jpg',
        bio: '평택시의원 출신 김수우가 2026년 평택시장 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 0,
        achievementsList: [
          '2026 지방선거 평택시장 출마 선언',
        ],
        actions: [
          '평택시장 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_029',
            title: '평택시의원 출신 김수우, 내년 평택시장 출마 선언',
            source: '경기일보',
            url: 'https://v.daum.net/v/20260108171920700',
            publishDate: DateTime(2026, 1, 8),
            summary: '김수우 전 시의원이 평택시장 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
      Member(
        id: 'member_020',
        name: '이춘희',
        party: '더불어민주당',
        district: '세종특별자치시장',
        imageUrl:
            'https://img3.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202601%2F12%2Fdaejonilbo%2F20260112145836024fymz.jpg',
        bio: '이춘희 전 세종시장이 2026년 세종시장 출마를 선언했다.',
        electionDate: DateTime(2026, 6, 3),
        term: 0,
        achievementsList: [
          '2026 지방선거 세종시장 출마 선언',
        ],
        actions: [
          '세종시장 출마 선언 기자회견',
        ],
        policies: [],
        pressReports: [
          PressReport(
            id: 'press_030',
            title: '이춘희 전 세종시장, 내년 지방선거 출마 선언',
            source: '대전일보',
            url: 'https://v.daum.net/v/20260112145834456',
            publishDate: DateTime(2026, 1, 12),
            summary: '이춘희 전 세종시장이 세종시장 출마를 선언했다.',
            sentiment: 'neutral',
          ),
        ],
        polls: [],
        electionPossibility: 0.50,
        lastAnalysisDate: DateTime(2026, 2, 5),
        improvementPoints: [
          '정책 및 공약 정보 수집 중',
        ],
      ),
    ];

  @override
  Future<void> addMember(Member member) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _dummyMembers.add(member);
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _dummyMembers.removeWhere((m) => m.id == memberId);
  }

  @override
  Future<List<Member>> getAllMembers() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _dummyMembers;
  }

  @override
  Future<List<Member>> getCachedMembers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _dummyMembers;
  }

  @override
  Future<Member> getMemberById(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _dummyMembers.firstWhere((m) => m.id == memberId);
    } catch (e) {
      throw Exception('Member not found');
    }
  }

  @override
  Future<List<Member>> searchMembers(String query) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final lowerQuery = query.toLowerCase();
    return _dummyMembers
        .where((m) =>
            m.name.toLowerCase().contains(lowerQuery) ||
            m.party.toLowerCase().contains(lowerQuery) ||
            m.district.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Future<void> updateMember(Member member) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _dummyMembers.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _dummyMembers[index] = member;
    }
  }

  @override
  Future<void> refreshMembers() async {
    if (_refreshInProgress) {
      return;
    }
    _refreshInProgress = true;
    final now = DateTime.now();
    try {
      final entries = await _nesdcPollDataSource.fetchLatest();
      if (!kReleaseMode) {
        debugPrint('[NESDC] fetched list entries: ${entries.length}');
      }
      for (var i = 0; i < _dummyMembers.length; i++) {
        final member = _dummyMembers[i];
        final regionKey = _mapDistrictToRegion(member.district);
        final matchedEntries = entries
            .where((e) => _matchesRegion(e.region, regionKey))
            .toList()
          ..sort((a, b) => b.registeredDate.compareTo(a.registeredDate));
        final limitedEntries = matchedEntries.take(5).toList();

        final newPolls = <Poll>[];
        var extractedCount = 0;
        var partyExtractedCount = 0;
        final candidateNames = _candidateNameVariants(member);
        final partyNames = _partyAliases(member.party);
        for (final entry in limitedEntries) {
          NesdcPollDetail? detail;
          try {
            detail = await _nesdcPollDataSource.fetchDetail(entry.sourceUrl);
          } catch (_) {
            detail = null;
          }
          double? supportRate = detail?.findSupportRate(candidateNames);
          var supportSource = '후보';
          if (supportRate == null) {
            supportRate = detail?.findSupportRate(partyNames);
            if (supportRate != null) {
              supportSource = '정당';
              partyExtractedCount++;
            }
          }
          if (supportRate != null) {
            extractedCount++;
          }
          final sampleSize = detail?.sampleSize;
          final marginOfError = detail?.marginOfError;
          final surveyDate = detail?.surveyDate ?? entry.registeredDate;
          final resultUrl = detail?.resultFileUrl;

          final noteParts = <String>[
            entry.client,
            entry.method,
            entry.sampleFrame,
            entry.pollName,
          ];
          if (entry.status != null && entry.status!.isNotEmpty) {
            noteParts.add('결과등록: ${entry.status}');
          }
          if (supportRate == null) {
            noteParts.add('결과 미공개');
          } else {
            noteParts.add('$supportSource 지지율 추출됨');
          }
          if (resultUrl != null) {
            noteParts.add('결과 링크: $resultUrl');
          }

          newPolls.add(
            Poll(
              id: 'nesdc_${entry.registrationNo}',
              pollAgency: entry.agency,
              surveyDate: surveyDate,
              supportRate: supportRate,
              partyName: member.party,
              sampleSize: sampleSize,
              marginOfError: marginOfError,
              source: entry.sourceUrl,
              notes: noteParts.join(' | '),
            ),
          );
        }

        final mergedPolls = _mergePolls(member.polls, newPolls);
        _dummyMembers[i] = member.copyWith(
          polls: mergedPolls,
          lastAnalysisDate: now,
        );
        if (!kReleaseMode) {
          debugPrint('[NESDC] ${member.name} matched=${limitedEntries.length} extracted=$extractedCount party=$partyExtractedCount');
        }
      }
    } catch (_) {
      for (var i = 0; i < _dummyMembers.length; i++) {
        _dummyMembers[i] = _dummyMembers[i].copyWith(lastAnalysisDate: now);
      }
    } finally {
      _refreshInProgress = false;
    }
  }

  @override
  Stream<List<Member>> watchAllMembers({Duration interval = const Duration(hours: 1)}) async* {
    await refreshMembers();
    yield await getAllMembers();
    yield* Stream.periodic(interval).asyncMap((_) async {
      await refreshMembers();
      return await getAllMembers();
    });
  }

  @override
  Stream<Member> watchMemberById(String memberId, {Duration interval = const Duration(hours: 1)}) async* {
    await refreshMembers();
    yield await getMemberById(memberId);
    yield* Stream.periodic(interval).asyncMap((_) async {
      await refreshMembers();
      return await getMemberById(memberId);
    });
  }

  List<Poll> _mergePolls(List<Poll> existing, List<Poll> incoming) {
    final byId = <String, Poll>{};
    for (final poll in existing) {
      byId[poll.id] = poll;
    }
    for (final poll in incoming) {
      byId[poll.id] = poll;
    }
    final merged = byId.values.toList();
    merged.sort((a, b) => b.surveyDate.compareTo(a.surveyDate));
    return merged;
  }

  List<String> _candidateNameVariants(Member member) {
    final name = member.name.trim();
    final variants = <String>{};
    if (name.isEmpty) {
      return [];
    }

    variants.add(name);
    variants.add(name.replaceAll(' ', ''));

    if (name.length >= 2) {
      variants.add('${name[0]} ${name.substring(1)}');
    }

    final suffixes = ['후보', '후보자', '의원', '시장', '지사', '군수', '구청장', '위원장'];
    for (final suffix in suffixes) {
      variants.add('$name $suffix');
      variants.add('${name.replaceAll(' ', '')}$suffix');
    }

    final partyAliases = _partyAliases(member.party);
    for (final alias in partyAliases) {
      variants.add('$alias $name');
      variants.add('$alias $name 후보');
    }

    return variants.toList();
  }

  List<String> _partyAliases(String party) {
    const aliasMap = {
      '더불어민주당': ['더불어민주당', '민주당', '더불어 민주당', '민주'],
      '국민의힘': ['국민의힘', '국힘'],
      '정의당': ['정의당'],
      '국민의당': ['국민의당'],
      '기본소득당': ['기본소득당'],
      '진보당': ['진보당'],
    };
    return aliasMap[party] ?? [party];
  }

  String _mapDistrictToRegion(String district) {
    final normalized = district.replaceAll(' ', '');
    const regionMap = {
      '서울': '서울특별시',
      '부산': '부산광역시',
      '대구': '대구광역시',
      '인천': '인천광역시',
      '광주': '광주광역시',
      '대전': '대전광역시',
      '울산': '울산광역시',
      '세종': '세종특별자치시',
      '경기': '경기도',
      '강원': '강원도',
      '충북': '충청북도',
      '충남': '충청남도',
      '전북': '전북특별자치도',
      '전남': '전라남도',
      '경북': '경상북도',
      '경남': '경상남도',
      '제주': '제주특별자치도',
    };

    for (final entry in regionMap.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return '전국';
  }

  bool _matchesRegion(String pollRegion, String targetRegion) {
    if (pollRegion.isEmpty) {
      return false;
    }
    if (pollRegion.contains('전국')) {
      return true;
    }
    if (pollRegion.contains(targetRegion)) {
      return true;
    }
    // 약식 표기 대응
    if (targetRegion == '전북특별자치도' && pollRegion.contains('전라북도')) {
      return true;
    }
    return false;
  }

  @override
  Future<void> updateMembers(List<Member> members) async {
    // 여러 멤버를 일괄 업데이트
    for (final member in members) {
      await updateMember(member);
    }
  }
}
