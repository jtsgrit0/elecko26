const axios = require('axios');
const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, 'data');
const CANDIDATES_FILE = path.join(DATA_DIR, 'election_candidates.json');
const ENRICHED_BACKUP_FILE = path.join(DATA_DIR, `election_candidates_enriched_backup_${Date.now()}.json`);
const ENABLE_GOOGLE = false; // Puppeteer를 사용하는 Google News 검색 활성화
const ENABLE_NAVER_DAUM = true; // Naver/Daum 검색 비활성화
const START_INDEX = Number(process.env.ENRICH_START_INDEX || 0);
const MAX_CANDIDATES = Number(process.env.ENRICH_LIMIT || 0);
const INITIAL_DELAY_MIN_MS = Number(process.env.ENRICH_INITIAL_DELAY_MIN_MS || 2500);
const INITIAL_DELAY_JITTER_MS = Number(process.env.ENRICH_INITIAL_DELAY_JITTER_MS || 3000);
const BETWEEN_ENGINES_MIN_MS = Number(process.env.ENRICH_BETWEEN_ENGINES_MIN_MS || 1500);
const BETWEEN_ENGINES_JITTER_MS = Number(process.env.ENRICH_BETWEEN_ENGINES_JITTER_MS || 1500);
const SAVE_EVERY = Number(process.env.ENRICH_SAVE_EVERY || 10);
const SEARCH_KEYWORDS = ['지지율', '분석', '여론조사', '평가', '전망', '공약', '정책', '비판', '논란', '프로필'];
const POSITIVE_KEYWORDS = ['기부', '후원', '봉사', '선행', '수상', '장학금', '기탁', '나눔'];
const USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
];
const getRandomUserAgent = () => USER_AGENTS[Math.floor(Math.random() * USER_AGENTS.length)];

const REQUEST_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
    'Accept-Language': 'ko-KR,ko;q=0.9'
};


// --- 유틸리티 함수 ---

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function randomDelay(minMs, jitterMs) {
    return minMs + Math.random() * jitterMs;
}

function hasRelevantKeyword(title = '', snippet = '') {
    return SEARCH_KEYWORDS.some(keyword => title.includes(keyword) || snippet.includes(keyword));
}

async function fetchHtml(url, candidateName, source, retryCount = 0) {
    try {
        const { data } = await axios.get(url, {
            headers: REQUEST_HEADERS,
            timeout: 15000
        });
        return data;
    } catch (error) {
        const status = error.response?.status;

        if (status === 429 && retryCount < 3) {
            const waitTime = Math.pow(2, retryCount) * 5000 + Math.random() * 3000;
            console.warn(`[${candidateName}] ⚠️ ${source} 요청 제한(429). ${Math.round(waitTime / 1000)}초 후 재시도합니다. (시도: ${retryCount + 1}/3)`);
            await sleep(waitTime);
            return fetchHtml(url, candidateName, source, retryCount + 1);
        }

        console.error(`[${candidateName}] ❌ ${source} 정보 검색 실패:`, error.message);
        return null;
    }
}

function loadCandidates() {
    try {
        if (fs.existsSync(CANDIDATES_FILE)) {
            const fileContent = fs.readFileSync(CANDIDATES_FILE, 'utf-8');
            fs.copyFileSync(CANDIDATES_FILE, ENRICHED_BACKUP_FILE);
            console.log(`정보 보강 전 데이터 백업 완료: ${ENRICHED_BACKUP_FILE}`);
            return JSON.parse(fileContent);
        }
        console.error(`오류: 후보자 파일(${CANDIDATES_FILE})을 찾을 수 없습니다.`);
        return null;
    } catch (error) {
        console.error('후보자 데이터를 로드하는 중 오류 발생:', error);
        return null;
    }
}

function saveCandidates(candidates) {
    try {
        fs.writeFileSync(CANDIDATES_FILE, JSON.stringify(candidates, null, 2), 'utf-8');
    } catch (error) {
        console.error('후보자 데이터를 저장하는 중 오류 발생:', error);
    }
}

async function getArticleContent(url) {
    try {
        // 일부 언론사는 euc-kr 인코딩을 사용하므로, arraybuffer로 받은 후 인코딩 감지
        const response = await axios.get(url, {
            headers: { 'User-Agent': getRandomUserAgent() },
            timeout: 10000,
            responseType: 'arraybuffer',
        });
        
        // iconv-lite 또는 유사 라이브러리가 필요하지만, 일단 utf-8로 시도
        const html = response.data.toString('utf-8');
        const $ = cheerio.load(html);

        let content = '';
        if (url.includes('news.naver.com')) {
            content = $('#dic_area, #articeBody').text();
        } else if (url.includes('v.daum.net')) {
            content = $('.article_view').text();
        } else {
            // 일반적인 경우, 여러 선택자를 시도
            content = $('article').text() || $('#article').text() || $('#content').text() || $('.content').text() || $('#main_content').text();
        }

        if (!content) {
            // 선택자를 찾지 못한 경우, body 전체에서 텍스트를 가져와 불필요한 부분을 필터링 (최후의 수단)
            content = $('body').text();
            // 스크립트 및 스타일 태그 내용 제거
            content = content.replace(/<script[^>]*>([\s\S]*?)<\/script>/g, '');
            content = content.replace(/<style[^>]*>([\s\S]*?)<\/style>/g, '');
        }

        // 불필요한 공백, 줄바꿈 정리
        return content.replace(/\s\s+/g, ' ').trim();
    } catch (error) {
        // console.error(`  - 기사 본문 수집 실패: ${url}`, error.message);
        return null;
    }
}

// --- 핵심 로직 ---



async function searchBing(candidate) {
    if (!candidate || !candidate.name) return null;
    const query = `${candidate.name} ${candidate.district || ''} ${candidate.party || ''}`;
    const url = `https://www.bing.com/news/search?q=${encodeURIComponent(query)}`;
    console.log(`[${candidate.name}]  Bing 검색 중...`);

    try {
        const response = await axios.get(url, {
            headers: { 'User-Agent': getRandomUserAgent() }
        });
        const $ = cheerio.load(response.data);
        const newsItems = [];
        $('a.title').each((i, elem) => {
            const title = $(elem).text().trim();
            const link = $(elem).attr('href');
            if (title && link) {
                newsItems.push({ title, link, source: 'Bing' });
            }
        });

        if (newsItems.length > 0) {
            console.log(`[${candidate.name}] ✔️ Bing에서 ${newsItems.length}개의 관련 뉴스 링크를 찾았습니다.`);
            return newsItems;
        }
        return null;
    } catch (error) {
        console.error(`[${candidate.name}] ❌ Bing 정보 검색 중 오류 발생:`, error);
        return null;
    }
}

async function searchDaum(candidate) {
    if (!candidate || !candidate.name) return null;
    const query = `${candidate.name} ${candidate.district || ''} ${candidate.party || ''}`;
    const url = `https://search.daum.net/search?w=news&q=${encodeURIComponent(query)}`;
    console.log(`[${candidate.name}]  Daum 검색 중...`);

    try {
        const response = await axios.get(url, {
            headers: { 'User-Agent': getRandomUserAgent() }
        });
        const $ = cheerio.load(response.data);
        const newsItems = [];
        $('a.tit_main').each((i, elem) => {
            const title = $(elem).text().trim();
            const link = $(elem).attr('href');
            if (title && link) {
                newsItems.push({ title, link, source: 'Daum' });
            }
        });

        if (newsItems.length > 0) {
            console.log(`[${candidate.name}] ✔️ Daum에서 ${newsItems.length}개의 관련 뉴스 링크를 찾았습니다.`);
            return newsItems;
        }
        return null;
    } catch (error) {
        console.error(`[${candidate.name}] ❌ Daum 정보 검색 중 오류 발생:`, error);
        return null;
    }
}

async function searchNaver(candidate) {
    if (!candidate || !candidate.name) return null;
    const query = `${candidate.name} ${candidate.district || ''} ${candidate.party || ''}`;
    const url = `https://search.naver.com/search.naver?where=news&query=${encodeURIComponent(query)}`;
    console.log(`[${candidate.name}]  Naver 검색 중...`);

    try {
        const response = await axios.get(url, {
            headers: { 'User-Agent': getRandomUserAgent() }
        });
        const $ = cheerio.load(response.data);
        const newsItems = [];
        $('.news_tit').each((i, elem) => {
            const title = $(elem).text().trim();
            const link = $(elem).attr('href');
            if (title && link) {
                newsItems.push({ title, link, source: 'Naver' });
            }
        });

        if (newsItems.length > 0) {
            console.log(`[${candidate.name}] ✔️ Naver에서 ${newsItems.length}개의 관련 뉴스 링크를 찾았습니다.`);
            return newsItems;
        }
        return null;
    } catch (error) {
        console.error(`[${candidate.name}] ❌ Naver 정보 검색 중 오류 발생:`, error);
        return null;
    }
}

const { getJson } = require("serpapi");

async function searchGoogle(candidate, retryCount = 0) {
    if (!candidate || !candidate.name) return null;

    const searchQuery = `"${candidate.name}" 지방선거 출마자`;
    
    try {
        const response = await getJson({
            engine: "google",
            q: searchQuery,
            api_key: process.env.SERPAPI_KEY, // 환경 변수에서 API 키를 가져옵니다.
            hl: "ko",
        });

        const organicResults = response.organic_results || [];
        const newsItems = [];

        // 1단계: 키워드로 정밀 검색
        const relevantResults = organicResults.filter(result => 
            hasRelevantKeyword(result.title, result.snippet)
        );

        const resultsToProcess = relevantResults.length > 0 ? relevantResults : organicResults.slice(0, 5);
        
        for (const r of resultsToProcess) {
            if (r.title && r.link) {
                newsItems.push({
                    title: r.title,
                    link: r.link,
                    source: 'Google (SerpApi)',
                    snippet: r.snippet
                });
            }
        }

        if (newsItems.length > 0) {
            console.log(`[${candidate.name}] ✔️ Google (SerpApi)에서 ${newsItems.length}개의 관련 결과를 찾았습니다.`);
            return newsItems;
        }

        return null;

    } catch (error) {
        // SerpApi 에러 처리
        const errorMessage = error.message?.toLowerCase() || '';
        if (errorMessage.includes('invalid api key') || errorMessage.includes('missing api key')) {
            console.error(`[${candidate.name}] ❌ Google (SerpApi) API 키가 유효하지 않거나 설정되지 않았습니다. SERPAPI_KEY 환경 변수를 확인하세요.`);
            // API 키 문제의 경우 재시도하지 않고 즉시 중단
            throw new Error("SerpApi 키 문제로 작업을 중단합니다.");
        }

        if (retryCount < 2) {
            const waitTime = Math.pow(2, retryCount) * 5000 + Math.random() * 3000;
            console.warn(`[${candidate.name}] ⚠️ Google (SerpApi) 요청 실패. ${Math.round(waitTime / 1000)}초 후 재시도합니다. (시도: ${retryCount + 1}/2)`);
            await sleep(waitTime);
            return searchGoogle(candidate, retryCount + 1);
        }
        console.error(`[${candidate.name}] ❌ Google (SerpApi) 정보 검색 실패:`, error.message);
        return null;
    }
}

// 기존 searchAndExtractAnalysis 함수는 이제 사용되지 않습니다.




// --- 메인 실행 함수 ---

async function main() {
    const allCandidates = loadCandidates();
    if (!allCandidates) return;

    const pendingCandidates = allCandidates
        .slice(START_INDEX)
        .filter(c => !c.news || c.news.length === 0);
    const candidatesToProcess = MAX_CANDIDATES > 0
        ? pendingCandidates.slice(0, MAX_CANDIDATES)
        : pendingCandidates;

    if (candidatesToProcess.length === 0) {
        console.log("✅ 새로 추가된 모든 후보자의 정보가 이미 최신 상태입니다.");
        return;
    }

    console.log(`총 ${allCandidates.length}명 중, 인덱스 ${START_INDEX} 이후 미보강 후보 ${pendingCandidates.length}명을 찾았습니다.`);
    console.log(`이번 실행 대상은 ${candidatesToProcess.length}명이며 검색 순서는 Google -> Naver -> Daum -> Bing입니다.`);

    try {
        let processedCount = 0;
        for (const candidate of candidatesToProcess) {
            // 각 후보자 처리 전, 사람처럼 보이도록 더 길고 불규칙적인 딜레이 적용
            const delay = processedCount < 5 ?
                (8000 + Math.random() * 5000) : // 초반 5명은 더 긴 딜레이
                (5000 + Math.random() * 5000);   // 이후에는 일반 딜레이
            await new Promise(resolve => setTimeout(resolve, delay));

            console.log(`\n[${processedCount + 1}/${candidatesToProcess.length}] "${candidate.name}" 후보자 정보 검색 중...`);

            let newsItems = null;

            if (ENABLE_GOOGLE) {
                newsItems = await searchGoogle(candidate);
            }

            if (!newsItems && ENABLE_NAVER_DAUM) {
                await sleep(randomDelay(BETWEEN_ENGINES_MIN_MS, BETWEEN_ENGINES_JITTER_MS));
                newsItems = await searchNaver(candidate);
            }

            if (!newsItems && ENABLE_NAVER_DAUM) {
                await sleep(randomDelay(BETWEEN_ENGINES_MIN_MS, BETWEEN_ENGINES_JITTER_MS));
                newsItems = await searchDaum(candidate);
            }

            if (!newsItems) {
                await sleep(randomDelay(BETWEEN_ENGINES_MIN_MS, BETWEEN_ENGINES_JITTER_MS));
                newsItems = await searchBing(candidate);
            }

            if (newsItems && newsItems.length > 0) {
                console.log(`[${candidate.name}] ➡️ ${newsItems.length}개의 뉴스 링크에서 본문 수집을 시작합니다...`);
                
                // 기존 news 배열과 합치고 중복 제거
                const allNewsItems = [...(candidate.news || []), ...newsItems];
                const uniqueNewsItems = Array.from(new Map(allNewsItems.map(item => [item.link, item])).values());
        
                let contentAddedCount = 0;
                // 상위 5개 기사에 대해서만 본문 수집 시도
                for (const item of uniqueNewsItems.slice(0, 5)) {
                    // 이미 content가 있는 경우는 건너뜀
                    if (item.content) continue;
        
                    await sleep(randomDelay(1000, 1000)); // 기사 간 요청 딜레이
                    const content = await getArticleContent(item.link);
                    if (content) {
                        item.content = content.substring(0, 5000); // 5000자 제한
                        contentAddedCount++;

                        // 긍정 키워드 탐색
                        for (const keyword of POSITIVE_KEYWORDS) {
                            if (content.includes(keyword)) {
                                if (!candidate.positiveActivities) {
                                    candidate.positiveActivities = [];
                                }
                                // 키워드 주변 50자씩 잘라서 문맥(snippet)으로 저장
                                const index = content.indexOf(keyword);
                                const snippet = content.substring(Math.max(0, index - 50), Math.min(content.length, index + 50));

                                // 이미 동일한 키워드와 링크가 저장되었는지 확인
                                const isDuplicate = candidate.positiveActivities.some(
                                    act => act.keyword === keyword && act.source === item.link
                                );

                                if (!isDuplicate) {
                                    candidate.positiveActivities.push({
                                        keyword,
                                        source: item.link,
                                        snippet: `...${snippet}...`
                                    });
                                    console.log(`[${candidate.name}] ✨ 긍정 키워드 '${keyword}' 발견!`);
                                }
                            }
                        }
                    }
                }
                
                candidate.news = uniqueNewsItems;
                if (contentAddedCount > 0) {
                    console.log(`[${candidate.name}] ✔️ ${contentAddedCount}개의 기사 본문을 수집했습니다.`);
                } else {
                    console.log(`[${candidate.name}] ℹ️ 수집할 새로운 기사 본문이 없습니다.`);
                }
                
            } else {
                if (!candidate.news) {
                    candidate.news = [];
                }
                console.log(`[${candidate.name}] ✖️ 모든 검색 엔진에서 관련 정보를 찾지 못함 | ${candidate.party} | ${candidate.district}`);
            }

            processedCount++;

            if (processedCount % SAVE_EVERY === 0) {
                saveCandidates(allCandidates);
                console.log(`--- ${processedCount} / ${candidatesToProcess.length} 처리 완료. 중간 저장 ---`);
            }
        }

        saveCandidates(allCandidates);
        console.log("--- ✨ 모든 후보자에 대한 정보 보강 작업이 완료되었습니다. ---");
    } catch (error) {
        console.error('전체 작업 중 오류 발생:', error);
        if (allCandidates) {
            saveCandidates(allCandidates);
            console.log('--- ⚠️ 오류 발생 전까지의 작업 내용을 저장했습니다. ---');
        }
    }
}

main();