const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, 'data');
const CANDIDATES_FILE = path.join(DATA_DIR, 'election_candidates.json');
const ANALYZED_BACKUP_FILE = path.join(DATA_DIR, `election_candidates_keyword_backup_${Date.now()}.json`);

// 키워드 목록 정의
const POSITIVE_KEYWORDS = ['기부', '후원', '봉사', '선행', '수상', '장학금', '기탁', '나눔', '헌신', '성과'];
const NEGATIVE_KEYWORDS = ['논란', '의혹', '비판', '문제', '지적', '검찰', '경찰', '조사', '재판', '의심'];

/**
 * 후보자 데이터를 불러오고 백업합니다.
 */
function loadCandidates() {
    try {
        if (fs.existsSync(CANDIDATES_FILE)) {
            const fileContent = fs.readFileSync(CANDIDATES_FILE, 'utf-8');
            fs.copyFileSync(CANDIDATES_FILE, ANALYZED_BACKUP_FILE);
            console.log(`키워드 분석 전 데이터 백업 완료: ${ANALYZED_BACKUP_FILE}`);
            return JSON.parse(fileContent);
        }
        console.error(`오류: 후보자 파일(${CANDIDATES_FILE})을 찾을 수 없습니다.`);
        return null;
    } catch (error) {
        console.error('후보자 데이터를 로드하는 중 오류 발생:', error);
        return null;
    }
}

/**
 * 후보자 데이터를 저장합니다.
 */
function saveCandidates(candidates) {
    try {
        fs.writeFileSync(CANDIDATES_FILE, JSON.stringify(candidates, null, 2), 'utf-8');
    } catch (error) {
        console.error('후보자 데이터를 저장하는 중 오류 발생:', error);
    }
}

/**
 * 키워드를 사용하여 후보자 정보를 분석합니다.
 * @param {object} candidate - 분석할 후보자 객체
 */
function analyzeCandidateWithKeywords(candidate) {
    console.log(`[${candidate.name}] 후보자의 기사 본문에서 키워드를 분석합니다...`);

    const articlesText = candidate.news
        ?.map(article => article.content)
        .filter(Boolean)
        .join(' ');

    if (!articlesText) {
        console.log(`[${candidate.name}] ℹ️ 분석할 기사 본문이 없습니다.`);
        return null;
    }

    // 문장 단위로 텍스트 분리 (마침표, 물음표, 느낌표 기준)
    const sentences = articlesText.match(/[^.!?]+[.!?]+/g) || [];
    const keywordAnalysis = {
        positive: [],
        negative: []
    };

    const MAX_SNIPPETS_PER_CATEGORY = 10; // 카테고리별 최대 10개 문장만 저장

    for (const sentence of sentences) {
        const trimmedSentence = sentence.trim();
        if (!trimmedSentence) continue;

        // 긍정 키워드 확인
        if (keywordAnalysis.positive.length < MAX_SNIPPETS_PER_CATEGORY) {
            for (const keyword of POSITIVE_KEYWORDS) {
                if (trimmedSentence.includes(keyword)) {
                    // 중복 문장 방지
                    if (!keywordAnalysis.positive.some(item => item.sentence === trimmedSentence)) {
                        keywordAnalysis.positive.push({ keyword, sentence: trimmedSentence });
                        break; // 한 문장에 여러 긍정 키워드가 있어도 한 번만 추가
                    }
                }
            }
        }

        // 부정 키워드 확인
        if (keywordAnalysis.negative.length < MAX_SNIPPETS_PER_CATEGORY) {
            for (const keyword of NEGATIVE_KEYWORDS) {
                if (trimmedSentence.includes(keyword)) {
                     // 중복 문장 방지
                    if (!keywordAnalysis.negative.some(item => item.sentence === trimmedSentence)) {
                        keywordAnalysis.negative.push({ keyword, sentence: trimmedSentence });
                        break; // 한 문장에 여러 부정 키워드가 있어도 한 번만 추가
                    }
                }
            }
        }
        
        // 양쪽 카테고리가 꽉 차면 분석 종료
        if (keywordAnalysis.positive.length >= MAX_SNIPPETS_PER_CATEGORY && keywordAnalysis.negative.length >= MAX_SNIPPETS_PER_CATEGORY) {
            break;
        }
    }

    if (keywordAnalysis.positive.length > 0 || keywordAnalysis.negative.length > 0) {
        return keywordAnalysis;
    }

    return null;
}


/**
 * 메인 실행 함수
 */
async function main() {
    const allCandidates = loadCandidates();
    if (!allCandidates) return;

    // 'keyword_analysis'가 없거나, 있더라도 비어있는 경우를 대상으로 함
    const candidatesToAnalyze = allCandidates.filter(c => c.news && c.news.length > 0 && (!c.keyword_analysis || (c.keyword_analysis.positive.length === 0 && c.keyword_analysis.negative.length === 0)));

    if (candidatesToAnalyze.length === 0) {
        console.log("✅ 모든 후보자에 대한 키워드 분석이 이미 완료되었습니다.");
        return;
    }

    console.log(`총 ${candidatesToAnalyze.length}명의 후보자에 대한 키워드 분석을 시작합니다.`);

    let processedCount = 0;
    for (const candidate of candidatesToAnalyze) {
        const analysis = analyzeCandidateWithKeywords(candidate);
        
        if (analysis) {
            candidate.keyword_analysis = analysis;
            console.log(`[${candidate.name}] ✔️ 키워드 분석 완료 (${analysis.positive.length} positive, ${analysis.negative.length} negative)`);
        } else {
            // 분석 결과가 없는 경우에도 빈 객체를 할당하여 다시 시도하지 않도록 함
            candidate.keyword_analysis = { positive: [], negative: [] };
            console.log(`[${candidate.name}] ℹ️ 관련 키워드를 찾지 못했습니다.`);
        }

        processedCount++;
        if (processedCount % 20 === 0) { // 저장 주기를 20명으로 늘림
            saveCandidates(allCandidates);
            console.log(`--- ${processedCount} / ${candidatesToAnalyze.length} 처리 완료. 중간 저장 ---`);
        }
    }

    saveCandidates(allCandidates);
    console.log("--- ✨ 모든 후보자에 대한 키워드 분석 작업이 완료되었습니다. ---");
}

main();