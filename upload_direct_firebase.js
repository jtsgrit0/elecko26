const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Firebase Admin SDK 초기화
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 데이터 업로드 함수
async function uploadAllData() {
    console.log('🔥 Firebase Admin SDK로 데이터 업로드 시작...');
    console.log('📋 프로젝트 ID:', serviceAccount.project_id);
    
    try {
        // 1. members 컬렉션 업로드
        console.log('\n🎯 members 컬렉션 업로드 중...');
        const membersDir = './firebase_collections/members_documents';
        
        if (fs.existsSync(membersDir)) {
            const files = fs.readdirSync(membersDir).filter(f => f.endsWith('.json'));
            let successCount = 0;
            
            for (const file of files) {
                const memberId = path.basename(file, '.json');
                const filePath = path.join(membersDir, file);
                const memberData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                
                try {
                    await db.collection('members').doc(memberId).set(memberData);
                    process.stdout.write(`  ✅ ${memberId} 업로드 완료\r`);
                    successCount++;
                } catch (error) {
                    console.error(`  ❌ ${memberId} 업로드 실패:`, error.message);
                }
                
                // API 제한 방지
                await new Promise(resolve => setTimeout(resolve, 100));
            }
            
            console.log(`\n✅ members: ${successCount}/${files.length} 명 업로드 완료`);
        }
        
        // 2. elections 컬렉션 업로드
        console.log('\n📊 elections 컬렉션 업로드 중...');
        const electionsFile = './firebase_collections/elections.json';
        
        if (fs.existsSync(electionsFile)) {
            const electionsData = JSON.parse(fs.readFileSync(electionsFile, 'utf8'));
            let electionCount = 0;
            
            for (const [key, value] of Object.entries(electionsData)) {
                try {
                    await db.collection('elections').doc(key).set(value);
                    process.stdout.write(`  ✅ ${key} 업로드 완료\r`);
                    electionCount++;
                } catch (error) {
                    console.error(`  ❌ ${key} 업로드 실패:`, error.message);
                }
                
                await new Promise(resolve => setTimeout(resolve, 100));
            }
            
            console.log(`\n✅ elections: ${electionCount} 개 문서 업로드 완료`);
        }
        
        // 3. polls 컬렉션 업로드
        console.log('\n📈 polls 컬렉션 업로드 중...');
        const pollsFile = './firebase_collections/polls.json';
        
        if (fs.existsSync(pollsFile)) {
            const pollsData = JSON.parse(fs.readFileSync(pollsFile, 'utf8'));
            
            for (const [key, value] of Object.entries(pollsData)) {
                try {
                    await db.collection('polls').doc(key).set(value);
                    process.stdout.write(`  ✅ ${key} 업로드 완료\r`);
                } catch (error) {
                    console.error(`  ❌ ${key} 업로드 실패:`, error.message);
                }
                
                await new Promise(resolve => setTimeout(resolve, 100));
            }
            
            console.log('\n✅ polls 컬렉션 업로드 완료');
        }
        
        // 4. pdf_data 컬렉션 업로드
        console.log('\n📄 pdf_data 컬렉션 업로드 중...');
        const pdfFile = './firebase_collections/pdf_data.json';
        
        if (fs.existsSync(pdfFile)) {
            const pdfData = JSON.parse(fs.readFileSync(pdfFile, 'utf8'));
            
            for (const [key, value] of Object.entries(pdfData)) {
                try {
                    await db.collection('pdf_data').doc(key).set(value);
                    process.stdout.write(`  ✅ ${key} 업로드 완료\r`);
                } catch (error) {
                    console.error(`  ❌ ${key} 업로드 실패:`, error.message);
                }
                
                await new Promise(resolve => setTimeout(resolve, 100));
            }
            
            console.log('\n✅ pdf_data 컬렉션 업로드 완료');
        }
        
        console.log('\n🎉 모든 데이터 업로드 완료!');
        console.log('\n🔗 Firebase 콘솔에서 확인: https://console.firebase.google.com/project/' + serviceAccount.project_id + '/firestore');
        
    } catch (error) {
        console.error('❌ 업로드 중 오류 발생:', error.message);
        process.exit(1);
    } finally {
        process.exit(0);
    }
}

// 메인 실행
uploadAllData();