const puppeteer = require('puppeteer');
const fs = require('fs');

const idsFile = 'polling_ids.json';
const outputFile = 'polling_details.json';
const baseUrl = 'https://www.nesdc.go.kr/portal/bbs/B0000005/view.do';

async function scrapeAllPollingDetails() {
  console.log('여론조사 상세 정보 수집을 시작합니다...');
  
  // 1. 수집 대상 ID 목록 읽기
  if (!fs.existsSync(idsFile)) {
    console.error(`${idsFile} 파일이 없습니다. 먼저 ID를 추출해주세요.`);
    return;
  }
  const nttIds = JSON.parse(fs.readFileSync(idsFile, 'utf-8'));
  console.log(`총 ${nttIds.length}개의 상세 정보를 수집합니다.`);

  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  let allPollingDetails = [];

  try {
    for (let i = 0; i < nttIds.length; i++) {
      const nttId = nttIds[i];
      const url = `${baseUrl}?nttId=${nttId}`;
      console.log(`(${i + 1}/${nttIds.length}) ${url} 페이지에서 정보 수집 중...`);

      await page.goto(url, { waitUntil: 'networkidle2' });

      // 2. 상세 페이지에서 데이터 추출
      const details = await page.evaluate(() => {
        const data = {};
        const keyMap = {
            '선거명': '선거명',
            '조사의뢰자': '조사의뢰자',
            '조사기관': '조사기관명',
            '조사기관명': '조사기관명',
            '조사지역': '조사지역',
            '조사일시': '조사일시',
            '조사대상': '조사대상',
            '조사방법': '조사방법',
            '표본크기': '표본크기',
            '표본추출방법': '표본추출방법',
            '피조사자 선정방법': '표본추출방법',
            '응답률': '응답률',
            '가중값 산출 및 적용방법': '가중값 산출 및 적용방법',
            '표본오차': '표본오차',
            '질문내용': '질문내용'
        };

        // 모든 tr 요소를 순회하며 데이터 추출
        document.querySelectorAll('tr').forEach(tr => {
            const th = tr.querySelector('th');
            const td = tr.querySelector('td');

            if (th && td) {
                const header = th.innerText.trim();
                const mappedKey = keyMap[header];
                if (mappedKey) {
                    // 이미 키가 존재하면, 값을 추가 (여러 테이블에 정보가 나뉘어 있는 경우)
                    if (data[mappedKey]) {
                        data[mappedKey] += `\n${td.innerText.trim()}`;
                    } else {
                        data[mappedKey] = td.innerText.trim();
                    }
                }
            }
        });

        // 질문내용을 별도로 한번 더 시도 (더 견고하게)
        if (!data['질문내용']) {
            const questionHeader = Array.from(document.querySelectorAll('th, strong')).find(el => el.innerText.includes('질문내용'));
            if (questionHeader) {
                let content = '';
                let currentElement = questionHeader.closest('tr');
                while (currentElement && (currentElement = currentElement.nextElementSibling)) {
                    if (currentElement.querySelector('th')) break; // 다음 헤더를 만나면 중단
                    content += currentElement.innerText.trim() + '\n';
                }
                data['질문내용'] = content.trim();
            }
        }
        return data;

        return data;
      });

      allPollingDetails.push({ nttId, ...details });
      
      // 3. 중간 저장 (예: 100개마다)
      if ((i + 1) % 100 === 0) {
        fs.writeFileSync(outputFile, JSON.stringify(allPollingDetails, null, 2), 'utf-8');
        console.log(`> 현재까지 ${allPollingDetails.length}개의 정보를 ${outputFile}에 저장했습니다.`);
      }
    }

    // 4. 최종 저장
    fs.writeFileSync(outputFile, JSON.stringify(allPollingDetails, null, 2), 'utf-8');
    console.log(`총 ${allPollingDetails.length}개의 상세 정보를 ${outputFile} 파일에 최종 저장했습니다.`);

  } catch (error) {
    console.error('상세 정보 수집 중 오류 발생:', error);
  } finally {
    await browser.close();
  }
}

scrapeAllPollingDetails();