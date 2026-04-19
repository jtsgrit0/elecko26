const admin = require('firebase-admin');
const fs = require('fs');

// Firebase Admin SDK 초기화
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// polls 데이터를 올바르게 업로드하는 함수
async function uploadPollsData() {
    console.log('📈 polls 데이터를 올바르게 업로드 중...');
    
    try {
        const pollsFile = './firebase_collections/polls.json';
        
        if (!fs.existsSync(pollsFile)) {
            console.log('❌ polls.json 파일을 찾을 수 없습니다.');
            return;
        }
        
        const pollsData = JSON.parse(fs.readFileSync(pollsFile, 'utf8'));
        
        // entries 배열의 각 항목을 개별 문서로 업로드
        if (pollsData.entries && Array.isArray(pollsData.entries)) {
            console.log(`📊 총 ${pollsData.entries.length}개의 여론조사 항목을 업로드합니다.`);
            
            let successCount = 0;
            let failCount = 0;
            
            for (let i = 0; i < pollsData.entries.length; i++) {
                const entry = pollsData.entries[i];
                const docId = entry.registrationNo || `poll_${i}`;
                
                try {
                    // Firestore에 적합한 데이터로 변환
                    const cleanData = {
                        registrationNo: entry.registrationNo,
                        agency: entry.agency,
                        client: entry.client,
                        method: entry.method,
                        sampleFrame: entry.sampleFrame,
                        pollName: entry.pollName,
                        registeredDate: entry.registeredDate,
                        region: entry.region,
                        sourceUrl: entry.sourceUrl,
                        status: entry.status,
                        detail: {
                            surveyDate: entry.detail?.surveyDate,
                            sampleSize: entry.detail?.sampleSize,
                            marginOfError: entry.detail?.marginOfError,
                            resultFileUrl: entry.detail?.resultFileUrl,
                            resultText: entry.detail?.resultText
                        }
                    };
                    
                    // null이나 undefined 값 제거
                    Object.keys(cleanData).forEach(key => {
                        if (cleanData[key] === null || cleanData[key] === undefined) {
                            delete cleanData[key];
                        }
                        if (typeof cleanData[key] === 'object' && cleanData[key] !== null) {
                            Object.keys(cleanData[key]).forEach(subKey => {
                                if (cleanData[key][subKey] === null || cleanData[key][subKey] === undefined) {
                                    delete cleanData[key][subKey];
                                }
                            });
                        }
                    });
                    
                    await db.collection('polls').doc(docId).set(cleanData);
                    process.stdout.write(`  ✅ ${docId} 업로드 완료 (${i + 1}/${pollsData.entries.length})\r`);
                    successCount++;
                    
                } catch (error) {
                    console.error(`\n  ❌ ${docId} 업로드 실패:`, error.message);
                    failCount++;
                }
                
                // API 제한 방지
                await new Promise(resolve => setTimeout(resolve, 100));
            }
            
            console.log(`\n✅ polls 업로드 완료: 성공 ${successCount}개, 실패 ${failCount}개`);
            
        } else {
            console.log('❌ entries 배열을 찾을 수 없습니다.');
        }
        
    } catch (error) {
        console.error('❌ polls 업로드 중 오류 발생:', error.message);
    }
}

// 함수 실행
uploadPollsData().then(() => {
    console.log('✅ 모든 작업 완료');
    process.exit(0);
}).catch(error => {
    console.error('❌ 작업 실패:', error);
    process.exit(1);
});