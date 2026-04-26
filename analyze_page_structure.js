const axios = require('axios');
const cheerio = require('cheerio');

// 페이지 구조 분석을 위한 디버그 스크립트
async function analyzePageStructure(page) {
    const url = `https://cpmadang.org/people/list_of_candidates_2026?page=${page}`;
    
    try {
        console.log(`\n🔍 페이지 ${page} 구조 분석 중...`);
        
        const response = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
            },
            timeout: 30000
        });
        
        const $ = cheerio.load(response.data);
        
        console.log(`📄 페이지 제목: ${$('title').text().trim()}`);
        console.log(`📄 전체 텍스트 길이: ${$('body').text().length} characters`);
        
        // 다양한 선택자로 요소 찾기
        const selectors = [
            '.candidate-card',
            '.candidate-card *',
            '.card',
            '.card *',
            '.people',
            '.people *',
            '.list',
            '.list *',
            '.item',
            '.item *',
            'div[class*="candidate"]',
            'div[class*="people"]',
            'div[class*="card"]',
            'div[class*="list"]'
        ];
        
        console.log('\n📊 선택자별 요소 수:');
        selectors.forEach(selector => {
            const count = $(selector).length;
            if (count > 0) {
                console.log(`  ${selector}: ${count}개`);
                
                // 첫 3개 요소의 텍스트 내용 보기
                $(selector).slice(0, 3).each((i, elem) => {
                    const text = $(elem).text().trim();
                    if (text.length > 0 && text.length < 200) {
                        console.log(`    [${i+1}] ${text.replace(/\s+/g, ' ')}`);
                    }
                });
            }
        });
        
        // candidate-card 내부 구조 자세히 보기
        console.log('\n🔍 .candidate-card 내부 구조:');
        $('.candidate-card').each((i, card) => {
            if (i >= 3) return; // 처음 3개만
            
            console.log(`\n  카드 ${i+1}:`);
            const $card = $(card);
            
            // 제목 요소 찾기
            const headings = $card.find('h1, h2, h3, h4, h5, h6, .title, .name, .candidate-name');
            if (headings.length > 0) {
                console.log('    제목 요소:');
                headings.each((j, heading) => {
                    console.log(`      ${$(heading).text().trim()}`);
                });
            }
            
            // 이미지 찾기
            const images = $card.find('img');
            if (images.length > 0) {
                console.log('    이미지:');
                images.each((j, img) => {
                    const src = $(img).attr('src') || $(img).attr('data-src');
                    const alt = $(img).attr('alt') || '';
                    console.log(`      ${src} (${alt})`);
                });
            }
            
            // 링크 찾기
            const links = $card.find('a');
            if (links.length > 0) {
                console.log('    링크:');
                links.each((j, link) => {
                    const href = $(link).attr('href');
                    const text = $(link).text().trim();
                    if (text.length > 0) {
                        console.log(`      ${text} -> ${href}`);
                    }
                });
            }
            
            // 전체 텍스트
            const fullText = $card.text().trim();
            if (fullText.length > 0) {
                console.log(`    전체 텍스트: ${fullText.replace(/\s+/g, ' ').substring(0, 150)}...`);
            }
        });
        
    } catch (error) {
        console.error(`❌ 페이지 ${page} 분석 실패:`, error.message);
    }
}

// 실행
async function main() {
    console.log('🔍 CPMadang.org 페이지 구조 분석 시작');
    
    // 처음 몇 페이지만 분석
    for (let page = 0; page <= 3; page++) {
        await analyzePageStructure(page);
        await new Promise(resolve => setTimeout(resolve, 2000)); // 2초 대기
    }
    
    console.log('\n✅ 분석 완료');
}

main().catch(console.error);