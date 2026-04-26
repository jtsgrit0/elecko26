const axios = require('axios');
const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');

// 현재 등록된 후보자 ID 목록 (중복 방지)
const existingCandidateIds = new Set();

// 기존 데이터 로드
function loadExistingCandidates() {
    try {
        const existingData = JSON.parse(fs.readFileSync('./data/election_candidates.json', 'utf8'));
        existingData.forEach(candidate => {
            if (candidate.id) {
                existingCandidateIds.add(candidate.id);
            }
        });
        console.log(`✅ 기존 ${existingCandidateIds.size}명의 후보자 데이터 로드 완료`);
    } catch (error) {
        console.log('⚠️  기존 데이터가 없습니다. 새로 시작합니다.');
    }
}

// 웹 페이지에서 후보자 정보 추출
async function extractCandidateInfo(url) {
    try {
        console.log(`🔍 ${url} 에서 데이터 추출 중...`);
        
        const response = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            },
            timeout: 10000
        });
        
        const $ = cheerio.load(response.data);
        const candidates = [];
        
        // 후보자 카드 선택자 (실제 HTML 구조에 따라 조정 필요)
        $('.candidate-card, .people-item, .candidate-item').each((index, element) => {
            const $element = $(element);
            
            // 기본 정보 추출
            const name = $element.find('.name, .candidate-name, h3, h4').first().text().trim();
            const party = $element.find('.party, .party-name').text().trim();
            const district = $element.find('.district, .area').text().trim();
            const imageUrl = $element.find('img').attr('src');
            const profileUrl = $element.find('a').attr('href');
            
            if (name) {
                const candidateId = `member_${name.replace(/\s+/g, '_').toLowerCase()}`;
                
                // 중복 확인
                if (!existingCandidateIds.has(candidateId)) {
                    candidates.push({
                        id: candidateId,
                        name: name,
                        party: party || '무소속',
                        district: district || '미정',
                        imageUrl: imageUrl ? (imageUrl.startsWith('http') ? imageUrl : `https://cpmadang.org${imageUrl}`) : '',
                        bio: '',
                        electionDate: '2026-06-03T00:00:00.000',
                        term: 1,
                        achievementsList: [],
                        actions: [],
                        policies: [],
                        pressReports: [],
                        sourceUrl: profileUrl ? (profileUrl.startsWith('http') ? profileUrl : `https://cpmadang.org${profileUrl}`) : url,
                        crawledDate: new Date().toISOString()
                    });
                    
                    existingCandidateIds.add(candidateId);
                    console.log(`  ✅ ${name} (${party}) - ${district}`);
                } else {
                    console.log(`  ⏭️  중복: ${name}`);
                }
            }
        });
        
        return candidates;
        
    } catch (error) {
        console.error(`❌ ${url} 크롤링 실패:`, error.message);
        return [];
    }
}

// SNS 및 추가 정보 수집 (간단한 버전)
async function enrichCandidateData(candidate) {
    try {
        console.log(`🔍 ${candidate.name}의 추가 정보 수집 중...`);
        
        // 기본 바이오 정보 생성
        candidate.bio = `${candidate.party} 소속 ${candidate.district} 지역 후보자입니다.`;
        
        // 여기서 더 상세한 웹 검색이나 SNS 정보 수집 가능
        // 예: Google 검색 API, 네이버 검색 API 등 활용
        
        return candidate;
    } catch (error) {
        console.error(`❌ ${candidate.name} 정보 보강 실패:`, error.message);
        return candidate;
    }
}

// 메인 크롤링 함수
async function crawlCandidates(startPage = 0, endPage = 238) {
    console.log(`🚀 CPMadang.org 후보자 크롤링 시작 (${startPage} ~ ${endPage} 페이지)`);
    
    loadExistingCandidates();
    
    const allCandidates = [];
    let totalNewCandidates = 0;
    
    for (let page = startPage; page <= endPage; page++) {
        const url = `https://cpmadang.org/people/list_of_candidates_2026?page=${page}`;
        
        console.log(`\n📄 페이지 ${page}/${endPage} 처리 중...`);
        
        const pageCandidates = await extractCandidateInfo(url);
        
        if (pageCandidates.length > 0) {
            // 추가 정보 보강
            for (const candidate of pageCandidates) {
                const enrichedCandidate = await enrichCandidateData(candidate);
                allCandidates.push(enrichedCandidate);
                totalNewCandidates++;
            }
            
            console.log(`  📊 ${pageCandidates.length}명의 새로운 후보자 발견`);
        } else {
            console.log('  ℹ️  새로운 후보자 없음');
        }
        
        // Rate limiting - 페이지당 2초 대기
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        // 진행률 표시
        const progress = ((page - startPage + 1) / (endPage - startPage + 1) * 100).toFixed(1);
        console.log(`\n📈 전체 진행률: ${progress}% (${totalNewCandidates}명 수집됨)`);
        
        // 중간 저장 (매 10페이지마다)
        if ((page - startPage + 1) % 10 === 0 && allCandidates.length > 0) {
            await saveProgress(allCandidates);
        }
    }
    
    // 최종 저장
    if (allCandidates.length > 0) {
        await saveProgress(allCandidates);
        console.log(`\n✅ 크롤링 완료! 총 ${totalNewCandidates}명의 새로운 후보자 수집`);
    } else {
        console.log('\nℹ️  수집된 새로운 후보자가 없습니다.');
    }
    
    return allCandidates;
}

// 중간 진행 상황 저장
async function saveProgress(candidates) {
    try {
        // 기존 데이터와 병합
        let existingData = [];
        try {
            existingData = JSON.parse(fs.readFileSync('./data/election_candidates.json', 'utf8'));
        } catch (error) {
            // 기존 파일이 없으면 새로 시작
        }
        
        // 새로운 후보만 추가
        const newCandidates = candidates.filter(candidate => 
            !existingData.some(existing => existing.id === candidate.id)
        );
        
        const mergedData = [...existingData, ...newCandidates];
        
        // 백업 생성
        const backupFile = `./data/election_candidates_backup_${Date.now()}.json`;
        if (fs.existsSync('./data/election_candidates.json')) {
            fs.copyFileSync('./data/election_candidates.json', backupFile);
            console.log(`  💾 백업 생성: ${backupFile}`);
        }
        
        // 저장
        fs.writeFileSync('./data/election_candidates.json', JSON.stringify(mergedData, null, 2));
        console.log(`  💾 데이터 저장 완료: ${mergedData.length}명의 후보자`);
        
    } catch (error) {
        console.error('❌ 데이터 저장 실패:', error.message);
    }
}

// 프로그램 시작
if (require.main === module) {
    const startPage = parseInt(process.argv[2]) || 0;
    const endPage = parseInt(process.argv[3]) || 238;
    
    console.log('🚀 CPMadang.org 후보자 크롤러 시작');
    console.log(`📊 페이지 범위: ${startPage} ~ ${endPage}`);
    console.log('⏰ 예상 소요시간: 페이지당 2초 기준, ' + 
                `${Math.ceil((endPage - startPage + 1) * 2 / 60)}분 소요 예상`);
    
    crawlCandidates(startPage, endPage).catch(error => {
        console.error('❌ 크롤링 중 오류 발생:', error);
        process.exit(1);
    });
}

module.exports = { crawlCandidates, extractCandidateInfo };