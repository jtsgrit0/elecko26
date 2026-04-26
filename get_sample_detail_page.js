const puppeteer = require('puppeteer');
const fs = require('fs');

const url = 'https://www.nesdc.go.kr/portal/bbs/B0000005/view.do?nttId=18360';
const outputFile = 'sample_detail_page.html';

async function getPage() {
  console.log(`샘플 상세 페이지 HTML을 가져옵니다: ${url}`);
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto(url, { waitUntil: 'networkidle2' });
  const content = await page.content();
  fs.writeFileSync(outputFile, content, 'utf-8');
  console.log(`페이지 HTML을 ${outputFile} 파일에 저장했습니다.`);
  await browser.close();
}

getPage();