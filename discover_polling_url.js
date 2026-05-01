const axios = require('axios');
const fs = require('fs');

async function discoverViewUrl() {
  const searchUrl = 'https://www.nesdc.go.kr/portal/bbs/B0000005/list.do';
  const params = new URLSearchParams();
  params.append('menuNo', '200467');
  params.append('pageIndex', '1');
  params.append('pollGubuncd', 'VT025'); // 제22대 국회의원선거

  try {
    console.log('여론조사 목록 첫 페이지를 요청하여 HTML 구조를 파일에 저장합니다...');
    const response = await axios.post(searchUrl, params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36'
      }
    });

    fs.writeFileSync('polling_list_page.html', response.data, 'utf-8');
    console.log('성공! 응답 내용을 polling_list_page.html 파일에 저장했습니다.');
    console.log('이제 이 파일을 분석하여 정확한 링크 구조를 파악할 수 있습니다.');

  } catch (error) {
    console.error('페이지 내용을 가져오는 중 오류 발생:', error.message);
  }
}

discoverViewUrl();