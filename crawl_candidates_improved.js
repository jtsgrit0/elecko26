const axios = require('axios');
const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');

// EventListener 제한 증가 (메모리 누수 방지)
require('events').EventEmitter.defaultMaxListeners = 20;

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
        return existingData;
    } catch (error) {
        console.log('⚠️  기존 데이터가 없습니다. 새로 시작합니다.');
        return [];
    }
}

// 한글 이름 추출 함수 (개선된 버전)
function extractKoreanName(text, context = '') {
    // 한글 이름 패턴 (2-4글자) + 문맥 필터링
    const namePattern = /[가-힣]{2,4}/g;
    const matches = text.match(namePattern);
    
    if (!matches || matches.length === 0) return null;
    
    // 문맥에 따라 필터링
    const commonMenuWords = ['진행', '전체', '오늘', '태그', '대선', '지방', '댓글', '인물', '단체', '리스트', '추천', '로그인', '가입', '비밀번호', '했습니다', '페이지', '시민정치', '후원내역', '취소', '사이트', '이용약관', '사업자', '판단', '마지막'];
    const locationWords = ['서울', '부산', '대구', '인천', '광주', '대전', '울산', '세종', '경기', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주'];
    
    // 후보자 이름으로 추정되는 단어 찾기
    const potentialNames = matches.filter(name => {
        // 2-4글자인지 확인
        if (name.length < 2 || name.length > 4) return false;
        
        // 흔한 메뉴 단어 제외
        if (commonMenuWords.some(word => name.includes(word))) return false;
        
        // 지역명 제외
        if (locationWords.includes(name)) return false;
        
        // 문맥에서 후보자로 보이는 경우
        if (context.includes('후보') || context.includes('예비후보') || context.includes('출마')) {
            return true;
        }
        
        return true;
    });
    
    if (potentialNames.length > 0) {
        // 가장 긴 이름 선택 (보통 3글자 이름이 많음)
        return potentialNames.sort((a, b) => b.length - a.length)[0];
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
    const shortDistricts = {
        '서울': '서울특별시',
        '부산': '부산광역시', 
        '대구': '대구광역시',
        '인천': '인천광역시',
        '광주': '광주광역시',
        '대전': '대전광역시', 
        '울산': '울산광역시',
        '세종': '세종특별자치시',
        '경기': '경기도',
        '강원': '강원특별자치도',
        '충북': '충청북도',
        '충남': '충청남도',
        '전북': '전라북도',
        '전남': '전라남도',
        '경북': '경상북도',
        '경남': '경상남도',
        '제주': '제주특별자치도'
    };
    
    for (const [short, full] of Object.entries(shortDistricts)) {
        if (text.includes(short)) {
            return full;
        }
    }
    
    return '미정';
}

// 웹 페이지에서 후보자 정보 추출 (개선된 버전)
async function extractCandidateInfo(url) {
    try {
        console.log(`🔍 ${url} 에서 데이터 추출 중...`);
        
        const response = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
                'Accept-Encoding': 'gzip, deflate, br',
                'Connection': 'keep-alive',
                'Upgrade-Insecure-Requests': '1'
            },
            timeout: 15000,
            maxRedirects: 5
        });
        
        const $ = cheerio.load(response.data);
        const candidates = [];
        
        console.log(`📄 페이지 HTML 크기: ${response.data.length} bytes`);
        console.log(`📄 페이지 제목: ${$('title').text().trim()}`);
        
        // 후보자 목록을 찾기 위한 다양한 선택자
        const candidateSelectors = [
            '.candidate-card',
            '.people-item', 
            '.candidate-item',
            '.member-item',
            '.profile-card',
            '.list-item',
            '.item',
            'article',
            '.card',
            '.box',
            'div[class*="candidate"]',
            'div[class*="people"]',
            'div[class*="member"]',
            'div[class*="profile"]'
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
                    const elementText = $element.text().trim();
                    
                    // 이름 추출 (문맥 정보 포함)
                    const name = extractKoreanName(elementText, elementText);
                    
                    if (name && name.length >= 2 && name.length <= 4) {
                        // 정당 추출
                        const party = extractParty(elementText);
                        
                        // 지역구 추출
                        const district = extractDistrict(elementText);
                        
                        // 이미지 URL 찾기
                        let imageUrl = '';
                        const imgSelectors = [
                            'img', 
                            'img[src*="candidate"]', 
                            'img[src*="people"]', 
                            'img[src*="profile"]', 
                            'img[src*="photo"]'
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
                            'a[href*="detail"]',
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
                                confidence: 0.8,
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
        
    } catch (error) {
        console.error(`❌ ${url} 크롤링 실패:`, error.message);
        if (error.response) {
            console.error(`  📊 상태 코드: ${error.response.status}`);
        }
        return [];
    }
}

// SNS 및 추가 정보 수집 (개선된 버전)
async function enrichCandidateData(candidate) {
    try {
        console.log(`🔍 ${candidate.name}의 추가 정보 수집 중...`);
        
        // 기본 바이오 정보 생성
        candidate.bio = `${candidate.party} 소속 ${candidate.district} 지역 후보자입니다.`;
        
        // 프로필 URL이 있다면 상세 정보 수집
        if (candidate.sourceUrl && candidate.sourceUrl.includes('cpmadang.org')) {
            try {
                const profileResponse = await axios.get(candidate.sourceUrl, {
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                    },
                    timeout: 10000
                });
                
                const $ = cheerio.load(profileResponse.data);
                
                // 상세 정보 추출
                const bioSelectors = ['.bio', '.profile-text', '.description', '.intro', '.summary', '.content'];
                for (const bioSelector of bioSelectors) {
                    const bioText = $(bioSelector).text().trim();
                    if (bioText && bioText.length > 10) {
                        candidate.bio = bioText.substring(0, 500);
                        break;
                    }
                }
                
                // 추가 이미지 찾기
                if (!candidate.imageUrl) {
                    const imgSelectors = ['.profile-img', '.candidate-img', '.main-img', '.photo'];
                    for (const imgSelector of imgSelectors) {
                        const img = $(imgSelector).first();
                        if (img.length > 0) {
                            const imgUrl = img.attr('src') || img.attr('data-src');
                            if (imgUrl) {
                                candidate.imageUrl = imgUrl.startsWith('http') ? imgUrl : `https://cpmadang.org${imgUrl}`;
                                break;
                            }
                        }
                    }
                }
                
                // SNS 링크 찾기
                const socialSelectors = ['a[href*="facebook"]', 'a[href*="twitter"]', 'a[href*="instagram"]', 'a[href*="youtube"]'];
                const socialLinks = [];
                
                socialSelectors.forEach(selector => {
                    const link = $(selector).attr('href');
                    if (link) {
                        socialLinks.push(link);
                    }
                });
                
                if (socialLinks.length > 0) {
                    candidate.socialLinks = socialLinks;
                }
                
            } catch (profileError) {
                console.log(`  ⚠️  프로필 페이지 접근 실패: ${profileError.message}`);
            }
        }
        
        return candidate;
    } catch (error) {
        console.error(`❌ ${candidate.name} 정보 보강 실패:`, error.message);
        return candidate;
    }
}

// 메인 크롤링 함수
async function crawlCandidates(startPage = 0, endPage = 238) {
    console.log(`🚀 CPMadang.org 후보자 크롤링 시작 (${startPage} ~ ${endPage} 페이지)`);
    
    const existingData = loadExistingCandidates();
    
    const allCandidates = [];
    let totalNewCandidates = 0;
    let consecutiveEmptyPages = 0;
    const maxConsecutiveEmpty = 5; // 연속 5페이지가 비어있으면 중지
    
    for (let page = startPage; page <= endPage; page++) {
        const url = `https://cpmadang.org/people/list_of_candidates_2026?page=${page}`;
        
        console.log(`\n📄 페이지 ${page}/${endPage} 처리 중...`);
        
        const pageCandidates = await extractCandidateInfo(url);
        
        if (pageCandidates.length > 0) {
            consecutiveEmptyPages = 0; // 연속 빈 페이지 카운트 리셋
            
            // 추가 정보 보강
            for (const candidate of pageCandidates) {
                const enrichedCandidate = await enrichCandidateData(candidate);
                allCandidates.push(enrichedCandidate);
                totalNewCandidates++;
            }
            
            console.log(`  📊 ${pageCandidates.length}명의 새로운 후보자 발견`);
        } else {
            consecutiveEmptyPages++;
            console.log('  ℹ️  새로운 후보자 없음');
            
            // 연속으로 빈 페이지가 나오면 중지
            if (consecutiveEmptyPages >= maxConsecutiveEmpty) {
                console.log(`\n⚠️  연속 ${maxConsecutiveEmpty}페이지가 비어있어 크롤링을 중단합니다.`);
                break;
            }
        }
        
        // Rate limiting - 페이지당 2초 대기
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        // 진행률 표시
        const progress = ((page - startPage + 1) / (endPage - startPage + 1) * 100).toFixed(1);
        console.log(`\n📈 전체 진행률: ${progress}% (${totalNewCandidates}명 수집됨)`);
        
        // 중간 저장 (매 10페이지마다 또는 50명 수집시)
        if ((page - startPage + 1) % 10 === 0 || allCandidates.length >= 50) {
            await saveProgress(allCandidates);
            allCandidates.length = 0; // 배열 비우기
        }
    }
    
    // 최종 저장
    if (allCandidates.length > 0) {
        await saveProgress(allCandidates);
    }
    
    console.log(`\n✅ 크롤링 완료! 총 ${totalNewCandidates}명의 새로운 후보자 수집`);
    
    return totalNewCandidates;
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
        console.log(`  💾 데이터 저장 완료: ${mergedData.length}명의 후보자 (신규: ${newCandidates.length}명)`);
        
        // Firebase에도 업데이트
        await updateFirebaseWithNewCandidates(newCandidates);
        
    } catch (error) {
        console.error('❌ 데이터 저장 실패:', error.message);
    }
}

// Firebase에 새 후보자 업데이트
async function updateFirebaseWithNewCandidates(newCandidates) {
    if (newCandidates.length === 0) return;
    
    try {
        const admin = require('firebase-admin');
        
        // Firebase 초기화 (이미 초기화되어 있지 않은 경우)
        if (!admin.apps.length) {
            const serviceAccount = require('./firebase-admin-key.json');
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
        }
        
        const db = admin.firestore();
        
        console.log(`  🔥 Firebase에 ${newCandidates.length}명의 새 후보자 업로드 중...`);
        
        let successCount = 0;
        for (const candidate of newCandidates) {
            try {
                await db.collection('members').doc(candidate.id).set(candidate);
                successCount++;
                process.stdout.write(`    ✅ ${candidate.name}\r`);
            } catch (error) {
                console.error(`    ❌ ${candidate.name} 업로드 실패:`, error.message);
            }
            
            // API 제한 방지
            await new Promise(resolve => setTimeout(resolve, 100));
        }
        
        console.log(`\n  ✅ Firebase 업로드 완료: ${successCount}/${newCandidates.length}명`);
        
    } catch (error) {
        console.log(`  ⚠️  Firebase 업로드 실패: ${error.message}`);
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
    
    crawlCandidates(startPage, endPage).then(total => {
        console.log(`\n🎉 모든 작업 완료! 총 ${total}명의 새로운 후보자를 수집했습니다.`);
        process.exit(0);
    }).catch(error => {
        console.error('❌ 크롤링 중 오류 발생:', error);
        process.exit(1);
    });
}

module.exports = { crawlCandidates, extractCandidateInfo };