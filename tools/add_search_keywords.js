const admin = require('firebase-admin');
const serviceAccount = require('../firebase-admin-key.json');

// Firebase Admin SDK 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addDefaultSearchKeywords() {
  console.log('🔥 모든 후보자에게 기본 뉴스 검색어 추가를 시작합니다...');

  try {
    const membersSnapshot = await db.collection('members').get();
    if (membersSnapshot.empty) {
      console.log('후보자 정보가 없습니다. 스크립트를 종료합니다.');
      return;
    }

    console.log(`총 ${membersSnapshot.size}명의 후보자 데이터를 확인하고 업데이트합니다.`);

    let updatedCount = 0;
    for (const doc of membersSnapshot.docs) {
      const member = doc.data();
      const memberId = doc.id;

      // `name`과 `party` 필드가 있는지 확인
      if (!member.name || !member.party) {
        console.log(`- ${memberId} 후보는 이름 또는 정당 정보가 없어 건너뜁니다.`);
        continue;
      }

      // `newsSearchKeyword` 필드가 이미 있는지, 비어있지 않은지 확인
      if (member.newsSearchKeyword && member.newsSearchKeyword.length > 0) {
        // console.log(`- ${member.name}(${memberId}) 후보는 이미 검색어가 있습니다. 건너뜁니다.`);
        continue;
      }

      // 기본 검색어로 이름과 정당을 사용
      const defaultKeywords = [member.name, `${member.name} ${member.party}`];
      
      // Firestore 문서 업데이트
      await db.collection('members').doc(memberId).update({
        newsSearchKeyword: defaultKeywords
      });

      process.stdout.write(`  ✅ ${member.name}(${memberId}) 후보 검색어 추가 완료\r`);
      updatedCount++;
      
      // API 제한 및 서버 부하 방지를 위한 지연
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    console.log(`\n\n🎉 총 ${updatedCount}명의 후보자에게 기본 검색어가 추가되었습니다.`);

  } catch (error) {
    console.error('❌ 검색어 추가 중 오류 발생:', error);
  } finally {
    process.exit(0);
  }
}

// 메인 함수 실행
addDefaultSearchKeywords();