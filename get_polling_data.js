const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
puppeteer.use(StealthPlugin());
const axios = require('axios');
const fs = require('fs');
const PDFParser = require("pdf2json");
const path = require('path');

async function getPollingData() {
    const url = 'https://www.gallup.co.kr/gallupdb/reportContent.asp?seqNo=1557';
    let browser = null;
    try {
        console.log('브라우저를 실행합니다...');
        browser = await puppeteer.launch({ headless: true });
        const page = await browser.newPage();
        
        console.log(`페이지로 이동합니다: ${url}`);
        await page.goto(url, { waitUntil: 'networkidle2' });

        const pdfUrl = await page.evaluate(() => {
            const links = Array.from(document.querySelectorAll('a'));
            const pdfRegex = /.*\.pdf$/;
            const downloadLink = links.find(link => pdfRegex.test(link.href) && (link.textContent.includes('교차집계표') || link.textContent.includes('다운로드')));
            return downloadLink ? downloadLink.href : null;
        });

        if (pdfUrl) {
            console.log('PDF 링크를 찾았습니다:', pdfUrl);
            const tempPdfPath = path.join(__dirname, 'temp_poll.pdf');
            
            console.log('PDF 파일을 다운로드합니다...');
            const response = await axios.get(pdfUrl, { responseType: 'arraybuffer' });
            fs.writeFileSync(tempPdfPath, response.data);
            console.log(`PDF 다운로드 완료: ${tempPdfPath}`);

            const pdfParser = new PDFParser(this, 1);

            pdfParser.on("pdfParser_dataError", errData => {
                console.error("PDF 파싱 오류:", errData.parserError);
                fs.unlinkSync(tempPdfPath); // 오류 발생 시 임시 파일 삭제
            });

            pdfParser.on("pdfParser_dataReady", pdfData => {
                console.log('PDF 파싱 완료. 페이지별로 텍스트를 파일에 저장합니다...');
            pdfData.Pages.forEach((page, index) => {
                const pageNumber = index + 1;
                
                const lines = {}; // Y좌표를 키로 사용하여 라인별 텍스트 그룹화
                page.Texts.forEach(text => {
                    const y = text.y;
                    const textContent = text.R.map(r => r.T).join('');
                    
                    if (!lines[y]) {
                        lines[y] = [];
                    }
                    
                    try {
                        lines[y].push(decodeURIComponent(textContent));
                    } catch (e) {
                        lines[y].push(textContent); // 디코딩 실패 시 원본 텍스트 사용
                    }
                });

                // Y좌표를 기준으로 정렬하고, 각 라인을 공백으로 합친 후, 전체를 줄바꿈으로 합침
                const pageText = Object.keys(lines).sort((a, b) => a - b).map(y => lines[y].join(' ')).join('\n');

                const outputFileName = `polling_data_page_${pageNumber}.txt`;
                fs.writeFileSync(outputFileName, pageText);
                console.log(`${outputFileName} 파일이 생성되었습니다.`);
            });
                
                fs.unlinkSync(tempPdfPath);
                console.log('임시 PDF 파일을 삭제했습니다.');
            });

            console.log('PDF 파일 파싱을 시작합니다...');
            pdfParser.loadPDF(tempPdfPath);

        } else {
            console.log('PDF 링크를 찾지 못했습니다.');
        }

    } catch (error) {
        console.error('페이지 분석 중 오류 발생:', error);
    } finally {
        if (browser) {
            await browser.close();
            console.log('브라우저를 종료했습니다.');
        }
    }
}

getPollingData();