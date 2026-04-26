const axios = require('axios');
const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');

// EventEmitter 메모리 누수 방지
require('events').EventEmitter.defaultMaxListeners = 20;

// 기존 후보자 ID 집합 (중복 방지)
let existingCandidateIds = new Set();

// 한글 이름 추출 함수 (개선됨)
function extractKoreanName(text, context = '') {
    // 한글+한자 이름 패턴 (이름 뒤에 괄호와 한자가 오는 경우)
    const namePattern = /([가-힣]{2,4})\([\u4E00-\u9FFF]{2,4}\)/g;
    const matches = text.match(namePattern);
    
    if (matches && matches.length > 0) {
        // 첫 번째 매칭에서 한글 이름만 추출
        const koreanName = matches[0].match(/([가-힣]{2,4})/)[1];
        return koreanName;
    }
    
    // 일반 한글 이름 패턴
    const simpleNamePattern = /[가-힣]{2,4}/g;
    const simpleMatches = text.match(simpleNamePattern);
    
    if (!simpleMatches || simpleMatches.length === 0) return null;
    
    // 메뉴 항목 및 일반 단어 필터링
    const commonMenuWords = ['진행', '전체', '오늘', '태그', '대선', '지방', '댓글', '인물', '단체', '리스트', '추천', '로그인', '가입', '비밀번호', '했습니다', '페이지', '시민정치', '후원내역', '취소', '사이트', '이용약관', '사업자', '판단', '마지막'];
    const locationWords = ['서울', '부산', '대구', '인천', '광주', '대전', '울산', '세종', '경기', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주'];
    
    const potentialNames = simpleMatches.filter(name => {
        if (name.length < 2 || name.length > 4) return false;
        if (commonMenuWords.some(word => name.includes(word))) return false;
        if (locationWords.includes(name)) return false;
        
        // 후보자 관련 문맥에서만 이름으로 간주
        if (context.includes('후보') || context.includes('예비후보') || context.includes('출마') || context.includes('선거')) {
            return true;
        }
        
        return true; // 일단 모든 한글 이름 수집
    });
    
    if (potentialNames.length > 0) {
        return potentialNames[0]; // 첫 번째 이름 반환
    }
    
    return null;
}

// 정당명 추출 함수
function extractParty(text) {
    const parties = [
        '국민의힘', '더불어민주당', '정의당', '무소속', '자유와혁신당', 
        '조국혁신당', '개혁신당', '진보당', '노동당', '국민의당',
        '기본소득당', '한국국민당', '신자유민주당', '통일한국당'
    ];
    
    for (const party of parties) {
        if (text.includes(party)) {
            return party;
        }
    }
    
    // 정당 키워드로 검색
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

// 지역구 추출 함수
function extractDistrict(text) {
    const districts = [
        '서울특별시', '부산광역시', '대구광역시', '인천광역시', '광주광역시', 
        '대전광역시', '울산광역시', '세종특별자치시', '경기도', '강원특별자치도',
        '충청북도', '충청남도', '전라북도', '전라남도', '경상북도', '경상남도', '제주특별자치도'
    ];
    
    for (const district of districts) {
        if (text.includes(district)) {
            return district;
        }
    }
    
    // 축약어로도 검색
    if (text.includes('서울')) return '서울특별시';
    if (text.includes('부산')) return '부산광역시';
    if (text.includes('대구')) return '대구광역시';
    if (text.includes('인천')) return '인천광역시';
    if (text.includes('광주')) return '광주광역시';
    if (text.includes('대전')) return '대전광역시';
    if (text.includes('울산')) return '울산광역시';
    if (text.includes('세종')) return '세종특별자치시';
    if (text.includes('경기')) return '경기도';
    if (text.includes('강원')) return '강원특별자치도';
    if (text.includes('충북')) return '충청북도';
    if (text.includes('충남')) return '충청남도';
    if (text.includes('전북')) return '전라북도';
    if (text.includes('전남')) return '전라남도';
    if (text.includes('경북')) return '경상북도';
    if (text.includes('경남')) return '경상남도';
    if (text.includes('제주')) return '제주특별자치도';
    
    return '정보없음';
}

// 후보자 정보 추출 함수 (개선됨)
function extractCandidateInfo($, url) {
    const candidates = [];
    const candidateSelectors = [
        '.candidate-card',
        'div[class*="candidate"]',
        'div[class*="people"]',
        '.card',
        '.item'
    ];
    
    // 각 선택자로 시도
    let totalCandidateCount = 0;
    let foundAnyCandidates = false;
    
    for (const selector of candidateSelectors) {
        const elements = $(selector);
        if (elements.length > 0) {
            console.log(`🔍 선택자 "${selector}"로 ${elements.length}개 요소 발견`);
            
            let foundCandidates = false;
            let candidateCount = 0;
            
            elements.each((index, element) => {
                const $element = $(element);
                
                // 제목 요소에서 이름 찾기 (h1-h6, .title, .name 등)
                let name = null;
                const titleSelectors = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', '.title', '.name', '.candidate-name'];
                
                for (const titleSelector of titleSelectors) {
                    const titleElement = $element.find(titleSelector).first();
                    if (titleElement.length > 0) {
                        const titleText = titleElement.text().trim();
                        name = extractKoreanName(titleText, titleText);
                        if (name) break;
                    }
                }
                
                // 제목 요소에서 못 찾으면 전체 텍스트에서 검색
                if (!name) {
                    const elementText = $element.text().trim();
                    name = extractKoreanName(elementText, elementText);
                }
                
                if (name && name.length >= 2 && name.length <= 4) {
                    // 전체 텍스트에서 정당과 지역구 추출
                    const elementText = $element.text().trim();
                    const party = extractParty(elementText);
                    const district = extractDistrict(elementText);
                    
                    // 이미지 URL 찾기
                    let imageUrl = '';
                    const imgSelectors = [
                        'img', 
                        'img[src*="candidate"]', 
                        'img[src*="people"]', 
                        'img[src*="profile"]',
                        'img[src*="thumbnail"]'
                    ];
                    
                    for (const imgSelector of imgSelectors) {
                        const img = $element.find(imgSelector).first();
                        if (img.length > 0) {
                            imageUrl = img.attr('src') || img.attr('data-src') || '';
                            if (imageUrl) {
                                imageUrl = imageUrl.startsWith('http') ? imageUrl : `https://cpmadang.org${imageUrl}`;
                                break;
                            }
                        }
                    }
                    
                    // 프로필 URL 찾기
                    let profileUrl = '';
                    const linkSelectors = [
                        'a[href*="candidate"]', 
                        'a[href*="people"]', 
                        'a[href*="profile"]', 
                        'a[href*="/후보/"]',
                        'a'
                    ];
                    
                    for (const linkSelector of linkSelectors) {
                        const link = $element.find(linkSelector).first();
                        if (link.length > 0) {
                            profileUrl = link.attr('href') || '';
                            if (profileUrl) {
                                profileUrl = profileUrl.startsWith('http') ? profileUrl : `https://cpmadang.org${profileUrl}`;
                                break;
                            }
                        }
                    }
                    
                    const candidateId = `member_${name.replace(/\s+/g, '_').toLowerCase()}`;
                    
                    // 중복 확인
                    if (!existingCandidateIds.has(candidateId)) {
                        candidates.push({
                            id: candidateId,
                            name: name,
                            party: party,
                            district: district,
                            imageUrl: imageUrl,
                            bio: '',
                            electionDate: '2026-06-03T00:00:00.000',
                            term: 1,
                            achievementsList: [],
                            actions: [],
                            policies: [],
                            pressReports: [],
                            sourceUrl: profileUrl || url,
                            crawledDate: new Date().toISOString(),
                            confidence: 0.9,
                            rawText: elementText.substring(0, 200) // 디버깅용
                        });
                        
                        existingCandidateIds.add(candidateId);
                        candidateCount++;
                        console.log(`  ✅ ${name} (${party}) - ${district}`);
                        foundCandidates = true;
                    }
                }
            });
            
            if (foundCandidates) {
                foundAnyCandidates = true;
                totalCandidateCount += candidateCount;
                break;
            }
        }
    }
    
    if (candidates.length === 0) {
        console.log('  ℹ️  후보자 정보를 찾을 수 없습니다. 페이지 구조를 확인하세요.');
        
        // 페이지의 주요 텍스트 내용을 파일로 저장하여 분석
        const pageContent = {
            url: url,
            title: $('title').text().trim(),
            bodyText: $('body').text().trim().substring(0, 1000),
            selectors: candidateSelectors.map(sel => ({
                selector: sel,
                count: $(sel).length,
                sample: $(sel).first().text().trim().substring(0, 100)
            }))
        };
        
        const debugFile = `./debug_page_${Date.now()}.json`;
        fs.writeFileSync(debugFile, JSON.stringify(pageContent, null, 2));
        console.log(`  🔍 디버그 정보 저장됨: ${debugFile}`);
    } else {
        console.log(`  📊 ${totalCandidateCount}명의 후보자 발견`);
    }
    
    return candidates;
}

// 후보자 상세 정보 수집 함수 (향후 확장)
async function enrichCandidateData(candidate) {
    if (!candidate.sourceUrl || candidate.sourceUrl === candidate.crawledUrl) {
        return candidate;
    }
    
    try {
        console.log(`  🔍 ${candidate.name}의 상세 정보 수집 중...`);
        
        const response = await axios.get(candidate.sourceUrl, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8'
            },
            timeout: 10000
        });
        
        const $ = cheerio.load(response.data);
        
        // 프로필 이미지 업데이트
        if (!candidate.imageUrl) {
            const profileImg = $('img.profile-image, img.candidate-photo, .profile img').first();
            if (profileImg.length > 0) {
                candidate.imageUrl = profileImg.attr('src') || profileImg.attr('data-src') || '';
                if (candidate.imageUrl && !candidate.imageUrl.startsWith('http')) {
                    candidate.imageUrl = `https://cpmadang.org${candidate.imageUrl}`;
                }
            }
        }
        
        // SNS 정보 수집
        const snsLinks = [];
        $('a[href*="facebook.com"], a[href*="instagram.com"], a[href*="twitter.com"], a[href*="youtube.com"], a[href*="blog.naver.com"]').each((i, elem) => {
            const href = $(elem).attr('href');
            if (href && !snsLinks.includes(href)) {
                snsLinks.push(href);
            }
        });
        
        if (snsLinks.length > 0) {
            candidate.snsLinks = snsLinks;
        }
        
        // 약력 정보 수집
        const bioElements = $('.bio, .profile-bio, .candidate-bio, .about, .introduction').first();
        if (bioElements.length > 0) {
            candidate.bio = bioElements.text().trim().substring(0, 500);
        }
        
        candidate.confidence = 0.95;
        
    } catch (error) {
        console.log(`  ⚠️  상세 정보 수집 실패: ${error.message}`);
    }
    
    return candidate;
}

// Firebase Admin SDK 초기화
let db = null;
try {
    const admin = require('firebase-admin');
    const serviceAccount = require('./firebase-admin-key.json');
    
    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    }
    db = admin.firestore();
} catch (error) {
    console.log('⚠️  Firebase Admin SDK 초기화 실패:', error.message);
}

// 데이터 저장 함수
async function saveCandidates(candidates) {
    if (candidates.length === 0) return;
    
    try {
        // 기존 데이터 읽기
        const existingDataPath = './data/election_candidates.json';
        let existingCandidates = [];
        
        if (fs.existsSync(existingDataPath)) {
            existingCandidates = JSON.parse(fs.readFileSync(existingDataPath, 'utf8'));
        }
        
        // 백업 생성
        const backupPath = `./data/election_candidates_backup_${Date.now()}.json`;
        fs.writeFileSync(backupPath, JSON.stringify(existingCandidates, null, 2));
        console.log(`  💾 백업 생성: ${backupPath}`);
        
        // 중복 제거 및 병합
        const existingIds = new Set(existingCandidates.map(c => c.id));
        const newCandidates = candidates.filter(c => !existingIds.has(c.id));
        
        const mergedCandidates = [...existingCandidates, ...newCandidates];
        
        // 저장
        fs.writeFileSync(existingDataPath, JSON.stringify(mergedCandidates, null, 2));
        console.log(`  💾 데이터 저장 완료: ${mergedCandidates.length}명의 후보자`);
        
        // Firebase에 업로드
        if (db && newCandidates.length > 0) {
            console.log(`  🔥 Firebase에 ${newCandidates.length}명의 새 후보자 업로드 중...`);
            
            let successCount = 0;
            for (const candidate of newCandidates) {
                try {
                    await db.collection('members').doc(candidate.id).set(candidate);
                    process.stdout.write(`    ✅ ${candidate.name}\r`);
                    successCount++;
                } catch (error) {
                    console.error(`    ❌ ${candidate.name} 업로드 실패:`, error.message);
                }
                
                // API 제한 방지
                await new Promise(resolve => setTimeout(resolve, 100));
            }
            
            console.log(`\n  ✅ Firebase 업로드 완료: ${successCount}/${newCandidates.length}명`);
        }
        
        return newCandidates.length;
        
    } catch (error) {
        console.error('  ❌ 데이터 저장 실패:', error.message);
        return 0;
    }
}

// 메인 크롤링 함수
async function crawlCandidates(startPage = 0, endPage = 800) {
    console.log('🚀 CPMadang.org 후보자 크롤러 시작');
    console.log(`📊 페이지 범위: ${startPage} ~ ${endPage}`);
    console.log(`⏰ 예상 소요시간: 페이지당 2초 기준 ${Math.ceil((endPage - startPage + 1) * 2 / 60)}분 소요 예상`);
    
    // 기존 후보자 ID 로드
    try {
        const existingData = JSON.parse(fs.readFileSync('./data/election_candidates.json', 'utf8'));
        existingCandidateIds = new Set(existingData.map(c => c.id));
        console.log(`✅ 기존 ${existingData.length}명의 후보자 데이터 로드 완료`);
    } catch (error) {
        console.log('⚠️  기존 데이터 없음, 새로 시작합니다.');
    }
    
    const allCandidates = [];
    let consecutiveEmptyPages = 0;
    const maxConsecutiveEmptyPages = 5;
    
    for (let page = startPage; page <= endPage; page++) {
        console.log(`\n📄 페이지 ${page}/${endPage} 처리 중...`);
        
        try {
            const url = `https://cpmadang.org/people/list_of_candidates_2026?page=${page}`;
            console.log(`🔍 ${url}에서 데이터 추출 중...`);
            
            const response = await axios.get(url, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                    'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
                },
                timeout: 30000
            });
            
            const $ = cheerio.load(response.data);
            
            console.log(`📄 페이지 HTML 크기: ${response.data.length} bytes`);
            console.log(`📄 페이지 제목: ${$('title').text().trim()}`);
            
            // 후보자 정보 추출
            const pageCandidates = extractCandidateInfo($, url);
            
            if (pageCandidates.length > 0) {
                allCandidates.push(...pageCandidates);
                consecutiveEmptyPages = 0;
                
                // 10페이지마다 자동 저장
                if ((page - startPage + 1) % 10 === 0 || allCandidates.length >= 50) {
                    console.log(`\n💾 ${allCandidates.length}명 수집 완료, 중간 저장 중...`);
                    await saveCandidates(allCandidates);
                    allCandidates.length = 0; // 배열 초기화
                }
            } else {
                consecutiveEmptyPages++;
                console.log(`  ℹ️  새로운 후보자 없음`);
                
                if (consecutiveEmptyPages >= maxConsecutiveEmptyPages) {
                    console.log(`⚠️  연속 ${maxConsecutiveEmptyPages}페이지가 비어있어 크롤링을 중단합니다.`);
                    break;
                }
            }
            
            const progress = ((page - startPage + 1) / (endPage - startPage + 1)) * 100;
            const totalCollected = existingCandidateIds.size - (existingCandidateIds.size - allCandidates.length);
            console.log(`📈 전체 진행률: ${progress.toFixed(1)}% (${totalCollected}명 수집됨)`);
            
            // 페이지당 2초 대기 (서버 부하 방지)
            await new Promise(resolve => setTimeout(resolve, 2000));
            
        } catch (error) {
            console.error(`❌ 페이지 ${page} 처리 실패:`, error.message);
            
            // 5초 대기 후 다음 페이지 시도
            await new Promise(resolve => setTimeout(resolve, 5000));
        }
    }
    
    // 남은 데이터 저장
    if (allCandidates.length > 0) {
        console.log(`\n💾 마지막 ${allCandidates.length}명 저장 중...`);
        await saveCandidates(allCandidates);
    }
    
    console.log('\n✅ 크롤링 완료!');
}

// 명령줄 인자 처리
const startPage = parseInt(process.argv[2]) || 0;
const endPage = parseInt(process.argv[3]) || 238;

console.log(`🚀 CPMadang.org 후보자 크롤링 시작 (${startPage} ~ ${endPage} 페이지)`);

crawlCandidates(startPage, endPage)
    .then(() => {
        console.log('\n🎉 모든 작업 완료!');
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ 작업 실패:', error);
        process.exit(1);
    });