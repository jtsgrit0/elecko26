const axios = require('axios');
const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');

require('events').EventEmitter.defaultMaxListeners = 20;

const BASE_URL = 'https://cpmadang.org';
const LIST_PATH = '/people/list_of_candidates_2026?page=';

const STRUCTURED_FILE = path.join(__dirname, 'assets', 'data', 'candidates_2026.json');
const LEGACY_FILE = path.join(__dirname, 'data', 'election_candidates.json');
const LEGACY_ASSET_FILE = path.join(__dirname, 'assets', 'data', 'election_candidates.json');

const SYNC_LEGACY_ASSET = process.env.SYNC_LEGACY_ASSET === '1';
const PAGE_TIMEOUT_MS = Number(process.env.CRAWL_PAGE_TIMEOUT_MS || 15000);
const PAGE_DELAY_MS = Number(process.env.CRAWL_PAGE_DELAY_MS || 300);
const MAX_CONSECUTIVE_EMPTY_PAGES = Number(process.env.CRAWL_EMPTY_LIMIT || 5);
const DEFAULT_END_PAGE = Number(process.env.CRAWL_END_PAGE || 272);

const PARTY_NAMES = [
  '국민의힘',
  '더불어민주당',
  '정의당',
  '무소속',
  '자유와혁신당',
  '조국혁신당',
  '개혁신당',
  '진보당',
  '노동당',
  '국민의당',
  '기본소득당',
  '한국국민당',
  '신자유민주당',
  '통일한국당',
];

const REGION_PREFIXES = [
  ['서울', '서울특별시'],
  ['부산', '부산광역시'],
  ['대구', '대구광역시'],
  ['인천', '인천광역시'],
  ['광주', '광주광역시'],
  ['대전', '대전광역시'],
  ['울산', '울산광역시'],
  ['세종', '세종특별자치시'],
  ['경기', '경기도'],
  ['강원', '강원특별자치도'],
  ['충북', '충청북도'],
  ['충남', '충청남도'],
  ['전북', '전북특별자치도'],
  ['전남', '전라남도'],
  ['경북', '경상북도'],
  ['경남', '경상남도'],
  ['제주', '제주특별자치도'],
];

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function normalizeText(value) {
  return String(value ?? '').replace(/\s+/g, ' ').trim();
}

function resolveUrl(url, baseUrl = BASE_URL) {
  const normalized = normalizeText(url);
  if (!normalized) return '';

  try {
    return new URL(normalized, baseUrl).href;
  } catch (_) {
    if (normalized.startsWith('http')) return normalized;
    return `${baseUrl}${normalized.startsWith('/') ? '' : '/'}${normalized}`;
  }
}

function ensureDirForFile(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function safeReadJson(filePath) {
  try {
    if (!fs.existsSync(filePath)) {
      return null;
    }

    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (error) {
    console.warn(`⚠️  ${filePath} 읽기 실패: ${error.message}`);
    return null;
  }
}

function extractHanja(rawName) {
  const normalized = normalizeText(rawName);
  if (!normalized) return '';

  const match = normalized.match(/\(([^)]+)\)/) || normalized.match(/（([^）]+)）/);
  return match ? normalizeText(match[1]) : '';
}

function normalizeName(rawName) {
  const stripped = normalizeText(rawName)
    .replace(/\([^)]*\)/g, '')
    .replace(/（[^）]*）/g, '');

  const match = stripped.match(/[가-힣]{2,4}/);
  return normalizeText(match ? match[0] : stripped);
}

function extractParty(text) {
  for (const party of PARTY_NAMES) {
    if (text.includes(party)) return party;
  }

  if (text.includes('국민의')) return '국민의힘';
  if (text.includes('더불어')) return '더불어민주당';
  if (text.includes('정의')) return '정의당';
  if (text.includes('혁신')) {
    if (text.includes('자유')) return '자유와혁신당';
    if (text.includes('조국')) return '조국혁신당';
    if (text.includes('개혁')) return '개혁신당';
  }

  return '무소속';
}

function extractElectionType(text) {
  const electionTypes = [
    '시·도지사선거',
    '구·시·군의 장선거',
    '시·도의회의원선거',
    '구·시·군의회의원선거',
    '광역의원비례대표선거',
    '기초의원비례대표선거',
    '교육감선거',
    '국회의원선거',
    '대통령선거',
  ];

  for (const type of electionTypes) {
    if (text.includes(type)) return type;
  }

  return '기타 선거';
}

function resolveRegion(regionRaw = '', district = '') {
  const haystack = `${normalizeText(regionRaw)} ${normalizeText(district)}`;

  for (const [needle, value] of REGION_PREFIXES) {
    if (haystack.includes(needle)) {
      return value;
    }
  }

  return normalizeText(regionRaw) || '전국';
}

function extractCandidateFromCard($, card, pageTitle) {
  const nameNode = card.find('.info-name a').first();
  const rawName = normalizeText(nameNode.text() || card.find('.info-name').first().text());
  const name = normalizeName(rawName);

  if (!name || name.length < 2 || name.length > 4) {
    return null;
  }

  const party = normalizeText(card.find('.info-party a').first().text()) || extractParty(card.text());
  const badgeRegion = normalizeText(card.find('.card-badge.badge-right a').first().text());
  const metaLinks = card.find('.info-meta-line .meta-item a');

  const district = normalizeText(metaLinks.eq(0).text()) || badgeRegion;
  const electionType = normalizeText(metaLinks.eq(1).text()) || extractElectionType(pageTitle || card.text());
  const status = normalizeText(metaLinks.eq(2).text()) || '예비후보';
  const job = normalizeText(card.find('.occupation-text a').first().text());
  const education = normalizeText(card.find('.flow-part.school').first().text());
  const careerParts = card
    .find('.flow-part')
    .map((_, el) => normalizeText($(el).text()))
    .get()
    .filter(Boolean);
  const career = careerParts.join(' | ');
  const tags = card
    .find('.footer-tags a')
    .map((_, el) => normalizeText($(el).text()))
    .get()
    .filter(Boolean);

  const imageUrl = resolveUrl(
    card.find('.candidate-face img').first().attr('src') ||
      card.find('.candidate-face img').first().attr('data-src') ||
      '',
  );
  const sourceUrl = resolveUrl(
    card.find('.candidate-face a').first().attr('href') ||
      nameNode.attr('href') ||
      '',
  );

  return {
    party,
    nameRaw: rawName,
    name,
    sourceUrl,
    imageUrl,
    region: badgeRegion,
    district,
    electionType,
    status,
    job,
    education,
    career,
    tags,
  };
}

function extractCandidatesFromHtml(html, pageUrl) {
  const $ = cheerio.load(html);
  const pageTitle = normalizeText($('title').text());
  const cards = $('.candidate-card');
  const candidates = [];

  if (!cards.length) {
    return { candidates, pageTitle, $ };
  }

  cards.each((_, element) => {
    const candidate = extractCandidateFromCard($, $(element), pageTitle);
    if (candidate) {
      candidates.push(candidate);
    }
  });

  return { candidates, pageTitle, $ };
}

function buildCandidateKey(candidate) {
  if (candidate.sourceUrl) {
    return `url:${candidate.sourceUrl}`.toLowerCase();
  }

  return [
    `name:${candidate.name || ''}`,
    `party:${candidate.party || ''}`,
    `district:${candidate.district || ''}`,
    `type:${candidate.electionType || ''}`,
  ]
    .map((value) => value.toLowerCase())
    .join('|');
}

function parseCandidateIndex(id) {
  const match = String(id || '').match(/^cpm_(\d+)$/);
  return match ? Number(match[1]) : null;
}

function normalizeStoredCandidate(candidate) {
  if (!candidate || typeof candidate !== 'object') {
    return null;
  }

  const nameRaw = normalizeText(candidate.nameRaw || candidate.name || '');
  const name = normalizeName(nameRaw);
  if (!name) {
    return null;
  }

  return {
    ...candidate,
    nameRaw,
    name,
    party: normalizeText(candidate.party || '무소속') || '무소속',
    sourceUrl: normalizeText(candidate.sourceUrl || ''),
    imageUrl: normalizeText(candidate.imageUrl || ''),
    region: normalizeText(candidate.region || ''),
    district: normalizeText(candidate.district || ''),
    electionType: normalizeText(candidate.electionType || '기타 선거') || '기타 선거',
    status: normalizeText(candidate.status || '예비후보') || '예비후보',
    job: normalizeText(candidate.job || ''),
    education: normalizeText(candidate.education || ''),
    career: normalizeText(candidate.career || ''),
    tags: Array.isArray(candidate.tags)
      ? candidate.tags.map((tag) => normalizeText(tag)).filter(Boolean)
      : [],
  };
}

function loadStructuredDataset() {
  const defaultMetadata = {
    source: `${BASE_URL}${LIST_PATH}0`,
    election: '2026년 제9회 전국동시지방선거',
    totalCount: 0,
    scrapedAt: '',
  };

  const raw = safeReadJson(STRUCTURED_FILE);
  if (!raw) {
    console.log(`⚠️  기존 구조화 데이터가 없습니다. 새로 시작합니다: ${STRUCTURED_FILE}`);
    return { metadata: defaultMetadata, candidates: [] };
  }

  const metadata = {
    ...defaultMetadata,
    ...(raw.metadata || {}),
  };

  const rawCandidates = Array.isArray(raw) ? raw : Array.isArray(raw.candidates) ? raw.candidates : [];
  const candidates = [];
  const seenKeys = new Set();

  for (const item of rawCandidates) {
    const candidate = normalizeStoredCandidate(item);
    if (!candidate) {
      continue;
    }

    const key = buildCandidateKey(candidate);
    if (seenKeys.has(key)) {
      continue;
    }

    seenKeys.add(key);
    candidates.push(candidate);
  }

  console.log(`✅ 기존 구조화 후보자 ${candidates.length}명 로드 완료`);
  return { metadata, candidates };
}

function writeJsonWithBackup(filePath, payload) {
  ensureDirForFile(filePath);

  if (fs.existsSync(filePath)) {
    const backupPath = path.join(
      path.dirname(filePath),
      `${path.basename(filePath, path.extname(filePath))}_backup_${Date.now()}${path.extname(filePath)}`,
    );
    fs.copyFileSync(filePath, backupPath);
    console.log(`💾 백업 생성: ${backupPath}`);
  }

  fs.writeFileSync(filePath, JSON.stringify(payload, null, 2), 'utf8');
  console.log(`💾 저장 완료: ${filePath}`);
}

function sortCandidatesForStructuredOutput(a, b) {
  const districtCmp = normalizeText(a.district).localeCompare(normalizeText(b.district), 'ko');
  if (districtCmp !== 0) return districtCmp;

  const partyCmp = normalizeText(a.party).localeCompare(normalizeText(b.party), 'ko');
  if (partyCmp !== 0) return partyCmp;

  return normalizeText(a.name).localeCompare(normalizeText(b.name), 'ko');
}

function sortMembersForLegacyOutput(a, b) {
  const regionCmp = normalizeText(a.region).localeCompare(normalizeText(b.region), 'ko');
  if (regionCmp !== 0) return regionCmp;

  const partyCmp = normalizeText(a.party).localeCompare(normalizeText(b.party), 'ko');
  if (partyCmp !== 0) return partyCmp;

  return normalizeText(a.name).localeCompare(normalizeText(b.name), 'ko');
}

function buildLegacyMemberRecord(candidate) {
  const nameHanja = extractHanja(candidate.nameRaw || candidate.name);
  const tags = Array.isArray(candidate.tags) ? candidate.tags : [];
  const electionPossibility =
    typeof candidate.electionPossibility === 'number' ? candidate.electionPossibility : 0.5;

  return {
    id: candidate.id,
    name: candidate.name,
    nameHanja,
    party: candidate.party || '무소속',
    constituency: candidate.district || '',
    district: candidate.district || '',
    districtName: candidate.district || '',
    region: resolveRegion(candidate.region || '', candidate.district || ''),
    description: `[${candidate.status || '예비후보'}] ${candidate.electionType || '기타 선거'}${
      candidate.district ? ` | ${candidate.district}` : ''
    }`,
    imageUrl: candidate.imageUrl || '',
    gender: tags.includes('여성') ? '여성' : '',
    birthdate: '',
    address: '',
    occupation: candidate.job || '',
    education: candidate.education || '',
    career: candidate.career || '',
    criminalRecord: '',
    electionType: candidate.electionType || '',
    candidateStatus: candidate.status || '',
    tags,
    sourceUrl: candidate.sourceUrl || '',
    achievementsList: [],
    policies: [],
    pressReports: [],
    polls: [],
    electionPossibility,
    lastAnalysisDate: candidate.lastAnalysisDate || null,
    improvementPoints: [],
    socialContributions: [],
    isFavorite: Boolean(candidate.isFavorite),
    historical2018PartyRates: candidate.historical2018PartyRates || {},
  };
}

function saveDebugSnapshot(url, pageTitle, $) {
  const selectors = [
    '.candidate-card',
    '.info-name',
    '.info-party',
    '.info-meta-line',
    '.card-badge',
    '.occupation-text',
    '.flow-part',
  ];

  const snapshot = {
    url,
    title: pageTitle,
    bodyText: normalizeText($('body').text()).slice(0, 2000),
    selectors: selectors.map((selector) => ({
      selector,
      count: $(selector).length,
      sample: normalizeText($(selector).first().text()).slice(0, 150),
    })),
  };

  const debugFile = `./debug_page_${Date.now()}.json`;
  fs.writeFileSync(debugFile, JSON.stringify(snapshot, null, 2), 'utf8');
  console.log(`  🔍 디버그 정보 저장됨: ${debugFile}`);
}

async function fetchPage(url, retries = 3) {
  for (let attempt = 0; attempt < retries; attempt++) {
    try {
      const response = await axios.get(url, {
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
        },
        timeout: PAGE_TIMEOUT_MS,
        maxRedirects: 5,
      });

      return response.data;
    } catch (error) {
      const status = error.response?.status;
      const suffix = status ? ` (HTTP ${status})` : '';
      console.warn(`⚠️  페이지 요청 실패${suffix}: ${error.message}`);

      if (attempt < retries - 1) {
        await sleep(1500 * (attempt + 1));
      }
    }
  }

  return null;
}

async function crawlCandidates(startPage = 0, endPage = DEFAULT_END_PAGE) {
  console.log(`🚀 CPMadang.org 후보자 크롤링 시작 (${startPage} ~ ${endPage} 페이지)`);

  const dataset = loadStructuredDataset();
  const allCandidates = dataset.candidates;
  const existingKeys = new Set();
  let nextCandidateIndex = 0;

  for (const candidate of allCandidates) {
    existingKeys.add(buildCandidateKey(candidate));
    const idx = parseCandidateIndex(candidate.id);
    if (idx !== null && idx >= nextCandidateIndex) {
      nextCandidateIndex = idx + 1;
    }
  }

  let totalNewCandidates = 0;
  let consecutiveEmptyPages = 0;

  for (let page = startPage; page <= endPage; page++) {
    const url = `${BASE_URL}${LIST_PATH}${page}`;
    console.log(`\n📄 페이지 ${page}/${endPage} 처리 중...`);

    const html = await fetchPage(url);
    if (!html) {
      consecutiveEmptyPages++;
      console.log('  ℹ️  페이지를 가져오지 못했습니다.');
      if (consecutiveEmptyPages >= MAX_CONSECUTIVE_EMPTY_PAGES) {
        console.log(`\n⚠️  연속 ${MAX_CONSECUTIVE_EMPTY_PAGES}페이지 실패로 크롤링을 중단합니다.`);
        break;
      }
      continue;
    }

    const { candidates, pageTitle, $ } = extractCandidatesFromHtml(html, url);
    console.log(`📄 페이지 제목: ${pageTitle}`);
    console.log(`📄 후보 카드: ${candidates.length}개`);

    if (candidates.length === 0) {
      consecutiveEmptyPages++;
      saveDebugSnapshot(url, pageTitle, $);

      if (consecutiveEmptyPages >= MAX_CONSECUTIVE_EMPTY_PAGES) {
        console.log(`\n⚠️  연속 ${MAX_CONSECUTIVE_EMPTY_PAGES}페이지가 비어 있어 크롤링을 중단합니다.`);
        break;
      }

      await sleep(PAGE_DELAY_MS);
      continue;
    }

    consecutiveEmptyPages = 0;

    let pageNewCandidates = 0;
    for (const candidate of candidates) {
      const key = buildCandidateKey(candidate);
      if (existingKeys.has(key)) {
        continue;
      }

      candidate.id = `cpm_${String(nextCandidateIndex).padStart(5, '0')}`;
      candidate.electionPossibility = 0.5;

      allCandidates.push(candidate);
      existingKeys.add(key);
      nextCandidateIndex += 1;
      pageNewCandidates += 1;
      totalNewCandidates += 1;
    }

    console.log(`  ✅ 신규 후보자 ${pageNewCandidates}명 추가 (누적 ${allCandidates.length}명)`);

    await sleep(PAGE_DELAY_MS);
  }

  allCandidates.sort(sortCandidatesForStructuredOutput);

  const structuredOutput = {
    metadata: {
      ...dataset.metadata,
      source: `${BASE_URL}${LIST_PATH}`,
      election: dataset.metadata?.election || '2026년 제9회 전국동시지방선거',
      totalCount: allCandidates.length,
      scrapedAt: new Date().toISOString(),
    },
    candidates: allCandidates,
  };

  writeJsonWithBackup(STRUCTURED_FILE, structuredOutput);

  const legacyMembers = allCandidates
    .map((candidate) => buildLegacyMemberRecord(candidate))
    .sort(sortMembersForLegacyOutput);

  writeJsonWithBackup(LEGACY_FILE, legacyMembers);

  if (SYNC_LEGACY_ASSET) {
    ensureDirForFile(LEGACY_ASSET_FILE);
    fs.writeFileSync(LEGACY_ASSET_FILE, JSON.stringify(legacyMembers, null, 2), 'utf8');
    console.log(`📦 자산 동기화 완료: ${LEGACY_ASSET_FILE}`);
  }

  console.log(`\n✅ 크롤링 완료! 신규 ${totalNewCandidates}명 추가, 전체 ${allCandidates.length}명`);
  return totalNewCandidates;
}

if (require.main === module) {
  const startPage = Number.parseInt(process.argv[2] || '0', 10);
  const endPage = Number.parseInt(process.argv[3] || String(DEFAULT_END_PAGE), 10);

  console.log('🚀 CPMadang.org 후보자 크롤러 시작');
  console.log(`📊 페이지 범위: ${startPage} ~ ${endPage}`);
  console.log(
    `⏰ 예상 소요시간: 페이지당 ${Math.round(PAGE_DELAY_MS / 1000)}초 기준, ` +
      `${Math.ceil(((endPage - startPage + 1) * PAGE_DELAY_MS) / 60000)}분 예상`,
  );

  crawlCandidates(startPage, endPage)
    .then((total) => {
      console.log(`\n🎉 모든 작업 완료! 총 ${total}명의 새로운 후보자를 추가했습니다.`);
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ 크롤링 중 오류 발생:', error);
      process.exit(1);
    });
}

module.exports = {
  crawlCandidates,
  extractCandidatesFromHtml,
  extractCandidateFromCard,
  buildCandidateKey,
};
