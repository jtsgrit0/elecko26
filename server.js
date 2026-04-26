const http = require('http');
const fs = require('fs');

const PORT = 8080;

let cachedCandidates = []; // 마지막으로 성공한 데이터를 캐싱할 변수
let lastUpdateStatus = "데이터를 성공적으로 불러왔습니다.";

function updateCandidates() {
    fs.readFile('election_candidates.json', 'utf8', (err, data) => {
        if (err) {
            // 파일을 읽는 데 실패하면, 마지막 성공 상태를 '업데이트 중'으로 변경
            lastUpdateStatus = "데이터 파일이 업데이트 중입니다. 잠시 후 최신 정보가 표시됩니다.";
            return;
        }

        try {
            cachedCandidates = JSON.parse(data);
            lastUpdateStatus = "데이터를 성공적으로 불러왔습니다.";
        } catch (parseError) {
            // 파싱에 실패하면, 마지막 성공 상태를 '업데이트 중'으로 변경
            lastUpdateStatus = "데이터 파일이 업데이트 중입니다. 잠시 후 최신 정보가 표시됩니다.";
        }
    });
}

// 1초마다 파일의 최신 내용을 읽어 캐시를 업데이트
setInterval(updateCandidates, 1000);

const server = http.createServer((req, res) => {
    if (req.url === '/') {
        let html = `
            <!DOCTYPE html>
            <html lang="ko">
            <head>
                <meta charset="UTF-8">
                <title>후보자 목록</title>
                <style>
                    body { font-family: sans-serif; margin: 2em; }
                    table { width: 100%; border-collapse: collapse; }
                    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                    th { background-color: #f2f2f2; }
                    tr:nth-child(even) { background-color: #f9f9f9; }
                    h1 { border-bottom: 2px solid #eee; padding-bottom: 10px; }
                    .status { padding: 10px; background-color: #eee; border-radius: 5px; margin-bottom: 1em; }
                </style>
            </head>
            <body>
                <h1>후보자 목록 (총 ${cachedCandidates.length}명)</h1>
                <div class="status">${lastUpdateStatus}</div>
                <table>
                    <tr>
                        <th>이름</th>
                        <th>정당</th>
                        <th>선거구</th>
                        <th>수집된 뉴스 기사 수</th>
                    </tr>
        `;

        cachedCandidates.forEach(candidate => {
            html += `
                <tr>
                    <td>${candidate.name}</td>
                    <td>${candidate.party}</td>
                    <td>${candidate.electoral_district}</td>
                    <td>${candidate.news.length}</td>
                </tr>
            `;
        });

        html += `
                </table>
            </body>
            </html>
        `;

        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(html);

    } else {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('페이지를 찾을 수 없습니다.');
    }
});

server.listen(PORT, () => {
    console.log(`개선된 서버가 http://localhost:${PORT} 에서 실행 중입니다.`);
    console.log('뉴스 기사 수집 작업은 계속 백그라운드에서 실행됩니다.');
    updateCandidates(); // 서버 시작 시 첫 데이터 로드
});