const puppeteer = require('puppeteer');
const fs = require('fs');

const url = 'https://www.nesdc.go.kr/portal/bbs/B0000005/list.do';
const outputFile = 'polling_list_page_full.html';

async function getPageStructure() {
  console.log('Puppeteer를 사용하여 페이지 구조를 가져옵니다...');
  let browser;
  try {
    browser = await puppeteer.launch();
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'networkidle2' });
    const content = await page.content();
    fs.writeFileSync(outputFile, content, 'utf-8');
    console.log(`페이지 구조를 ${outputFile} 파일에 저장했습니다.`);
  } catch (error) {
    console.error('페이지 구조를 가져오는 중 오류 발생:', error);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}

getPageStructure();