
const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, 'data');
const CANDIDATES_FILE = path.join(DATA_DIR, 'election_candidates.json');
const CLEANED_BACKUP_FILE = path.join(DATA_DIR, `election_candidates_cleaned_backup_${Date.now()}.json`);

// 사람 이름이 아닌 것으로 판단되는 단어 목록
const INVALID_NAME_KEYWORDS = [
    '전국', '지방', '비례', '대표', '선거', '위원회', 
    '후보', '등록', '명부', '서울', '부산', '대구', 
    '인천', '광주', '대전', '울산', '세종', '경기', 
    '강원', '충북', '충남', '전북', '전남', '경북', 
    '경남', '제주', '총선', '구시군', '시도의원'
];

function cleanCandidateData() {
    try {
        // 1. 데이터 파일 읽기
        if (!fs.existsSync(CANDIDATES_FILE)) {
            console.error(`오류: 데이터 파일(${CANDIDATES_FILE})을 찾을 수 없습니다.`);
            return;
        }
        const fileContent = fs.readFileSync(CANDIDATES_FILE, 'utf-8');
        const candidates = JSON.parse(fileContent);
        const originalCount = candidates.length;

        // 2. 백업 파일 생성
        fs.copyFileSync(CANDIDATES_FILE, CLEANED_BACKUP_FILE);
        console.log(`데이터 정제 전 백업 완료: ${CLEANED_BACKUP_FILE}`);

        // 3. 데이터 클리닝
        const cleanedCandidates = candidates.filter(candidate => {
            if (!candidate.name || candidate.name.length < 2 || candidate.name.length > 5) {
                console.log(`- 이름이 유효하지 않아 제외: ${candidate.name || '이름 없음'}`);
                return false;
            }
            // 이름에 포함된 키워드인지 확인 (예: '전국지방' -> '전국', '지방' 둘 다 걸림)
            const isInvalid = INVALID_NAME_KEYWORDS.some(keyword => candidate.name.includes(keyword));
            if (isInvalid) {
                console.log(`- 유효하지 않은 이름으로 판단되어 제외: ${candidate.name}`);
            }
            return !isInvalid;
        });

        const cleanedCount = cleanedCandidates.length;
        const removedCount = originalCount - cleanedCount;

        if (removedCount > 0) {
            // 4. 정제된 데이터 저장
            fs.writeFileSync(CANDIDATES_FILE, JSON.stringify(cleanedCandidates, null, 2), 'utf-8');
            console.log(`\n✅ 데이터 정제 완료!`);
            console.log(`- 총 ${originalCount}명의 후보자 중 ${removedCount}명을 제거했습니다.`);
            console.log(`- 현재 ${cleanedCount}명의 후보자 데이터가 저장되었습니다.`);
        } else {
            console.log(`\n✅ 데이터 확인 완료! 제거할 데이터가 없습니다.`);
        }

    } catch (error) {
        console.error('데이터 정제 중 오류 발생:', error);
    }
}

// 스크립트 실행
cleanCandidateData();