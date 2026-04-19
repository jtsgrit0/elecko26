const admin = require('firebase-admin');
const fs = require('fs');

// Firebase Admin SDK 초기화
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 데이터 업로드 함수
async function uploadData() {
  try {
    console.log('📊 Firebase 데이터 업로드 시작...');
    
    // 1. members 컬렉션 업로드
    console.log('\n🎯 members 컬렉션 업로드 중...');
    const membersData = JSON.parse(fs.readFileSync('firebase_collections/members.json', 'utf8'));
    let count = 0;
    
    for (const [memberId, memberData] of Object.entries(membersData)) {
      await db.collection('members').doc(memberId).set(memberData);
      count++;
      if (count % 10 === 0) {
        console.log(`  ✅ ${count}/${Object.keys(membersData).length} 완료`);
      }
    }
    console.log(`✅ members: ${count}명 업로드 완료`);
    
    // 2. elections 컬렉션 업로드
    console.log('\n📊 elections 컬렉션 업로드 중...');
    const electionsData = JSON.parse(fs.readFileSync('firebase_collections/elections.json', 'utf8'));
    
    for (const [key, value] of Object.entries(electionsData)) {
      await db.collection('elections').doc(key).set(value);
    }
    console.log(`✅ elections: ${Object.keys(electionsData).length}개 문서 업로드 완료`);
    
    // 3. polls 컬렉션 업로드
    console.log('\n📈 polls 컬렉션 업로드 중...');
    const pollsData = JSON.parse(fs.readFileSync('firebase_collections/polls.json', 'utf8'));
    
    if (pollsData.entries) {
      for (const [key, value] of Object.entries(pollsData.entries)) {
        await db.collection('polls').doc(key).set(value);
      }
      console.log(`✅ polls: ${Object.keys(pollsData.entries).length}개 문서 업로드 완료`);
    }
    
    // 4. pdf_data 컬렉션 업로드
    console.log('\n📄 pdf_data 컬렉션 업로드 중...');
    const pdfData = JSON.parse(fs.readFileSync('firebase_collections/pdf_data.json', 'utf8'));
    
    for (const [key, value] of Object.entries(pdfData)) {
      await db.collection('pdf_data').doc(key).set(value);
    }
    console.log(`✅ pdf_data: ${Object.keys(pdfData).length}개 문서 업로드 완료`);
    
    console.log('\n🎉 모든 데이터 업로드 완료!');
    
  } catch (error) {
    console.error('❌ 업로드 중 오류 발생:', error);
  } finally {
    process.exit();
  }
}

// 서비스 계정 키 파일 확인
if (!fs.existsSync('./firebase-admin-key.json')) {
  console.log('⚠️  firebase-admin-key.json 파일이 필요합니다.');
  console.log('📋 Firebase 콘솔에서 서비스 계정 키를 다운로드하세요:');
  console.log('1. Firebase 콘솔 → 프로젝트 설정 → 서비스 계정');
  console.log('2. 새 비공개 키 생성 → 파일 저장 (firebase-admin-key.json)');
  console.log('3. 이 파일을 현재 디렉토리에 복사');
  process.exit(1);
}

// 업로드 실행
uploadData();