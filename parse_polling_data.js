const fs = require('fs');

function parsePollingData() {
    const rawData = fs.readFileSync('polling_data_page_12.txt', 'utf-8');
    const lines = rawData.split(/\r?\n/);

    const regionData = {};
    // 정당 목록을 하드코딩하여 안정성 확보
    const parties = ['더불어민주당', '국민의힘', '조국혁신당', '개혁신당', '진보당', '기본소득당', '사회민주당', '이외정당', '무당층'];
    const regions = ['서울', '인천/경기', '대전/세종/충청', '광주/전라', '대구/경북', '부산/울산/경남', '강원', '제주'];
    
    let inRegionSection = false;

    for (const line of lines) {
        if (line.includes('지역별')) {
            inRegionSection = true;
        }

        if (line.includes('성별')) {
            inRegionSection = false;
            break; 
        }

        if (inRegionSection) {
            const trimmedLine = line.trim();
            const foundRegion = regions.find(r => trimmedLine.includes(r));
            if (foundRegion) {
                const regionIndex = trimmedLine.indexOf(foundRegion);
                const dataLine = trimmedLine.substring(regionIndex);

                const numbers = dataLine.match(/(\d+(\.\d+)?)%/g);
                if (numbers) {
                    const partyData = {};
                    for (let i = 0; i < parties.length; i++) {
                        if (i < numbers.length) {
                            partyData[parties[i]] = parseFloat(numbers[i]);
                        } else {
                            partyData[parties[i]] = 0;
                        }
                    }
                    regionData[foundRegion] = partyData;
                } else if (dataLine.includes('- - -')) {
                    const partyData = {};
                    parties.forEach(p => partyData[p] = 0);
                    regionData[foundRegion] = partyData;
                }
            }
        }
    }

    fs.writeFileSync('polling_data.json', JSON.stringify(regionData, null, 2));
    console.log('polling_data.json 파일이 생성되었습니다.');
    console.log(JSON.stringify(regionData, null, 2));
}

parsePollingData();