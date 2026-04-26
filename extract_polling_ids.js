const puppeteer = require('puppeteer');
const fs = require('fs');

const baseUrl = 'https://www.nesdc.go.kr/portal/bbs/B0000005/list.do';
const outputFile = 'polling_ids.json';

async function extractAllPollingIds() {
  console.log('모든 여론조사 ID 추출을 시작합니다...');
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  let allNttIds = [];
  
  try {
    // 1. 첫 페이지로 이동하여 마지막 페이지 번호 확인
    await page.goto(`${baseUrl}?pageIndex=1`, { waitUntil: 'networkidle2' });
    const lastPageHref = await page.$eval('.page.last', el => el.getAttribute('onclick'));
    const lastPageIndex = parseInt(lastPageHref.match(/pageIndex=(\d+)/)[1], 10);
    console.log(`총 ${lastPageIndex} 페이지의 여론조사 목록이 있습니다.`);

    // 2. 모든 페이지를 순회하며 nttId 추출
    for (let i = 1; i <= lastPageIndex; i++) {
      console.log(`${i} 페이지에서 ID를 추출합니다...`);
      await page.goto(`${baseUrl}?pageIndex=${i}`, { waitUntil: 'networkidle2' });
      
      const nttIdsOnPage = await page.$$eval('a.row.tr', links => 
        links.map(link => {
          const url = new URL(link.href);
          return url.searchParams.get('nttId');
        })
      );
      
      allNttIds = allNttIds.concat(nttIdsOnPage);
      console.log(`> ${nttIdsOnPage.length}개의 ID를 찾았습니다. (총 ${allNttIds.length}개)`);
    }

    // 3. 추출된 ID를 JSON 파일로 저장
    fs.writeFileSync(outputFile, JSON.stringify(allNttIds, null, 2), 'utf-8');
    console.log(`총 ${allNttIds.length}개의 ID를 ${outputFile} 파일에 저장했습니다.`);

  } catch (error) {
    console.error('ID 추출 중 오류 발생:', error);
  } finally {
    await browser.close();
  }
}

extractAllPollingIds();