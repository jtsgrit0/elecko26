const admin = require('firebase-admin');
const serviceAccount = require('../firebase-admin-key.json');

// Firebase Admin SDK 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fetchNewsForKeyword(keyword) {
  // 이 함수는 실제 뉴스 크롤링 로직을 대체하는 예시입니다.
  // 실제 구현에서는 이 부분에 Puppeteer, Cheerio 또는 외부 뉴스 API를 사용하여
  // 해당 키워드로 뉴스를 검색하고 결과를 반환해야 합니다.
  console.log(`  - "${keyword}" 키워드로 뉴스 검색 중... (시뮬레이션)`);
  // 예시 뉴스 데이터 반환
  return [
    {
      title: `${keyword} 관련 뉴스 1`,
      link: `https://example.com/news/${encodeURIComponent(keyword)}/1`,
      press: '예시 언론사',
      timestamp: new Date()
    },
    {
      title: `${keyword} 관련 뉴스 2`,
      link: `https://example.com/news/${encodeURIComponent(keyword)}/2`,
      press: '다른 언론사',
      timestamp: new Date()
    }
  ];
}

async function updateAllNews() {
  console.log('🔥 뉴스 데이터 업데이트 스크립트 시작...');

  try {
    const membersSnapshot = await db.collection('members').get();
    if (membersSnapshot.empty) {
      console.log('후보자 정보가 없습니다. 스크립트를 종료합니다.');
      return;
    }

    console.log(`총 ${membersSnapshot.size}명의 후보자에 대한 뉴스 업데이트를 시작합니다.`);

    for (const doc of membersSnapshot.docs) {
      const member = doc.data();
      const memberId = doc.id;
      const searchKeywords = member.newsSearchKeyword;

      if (!searchKeywords || searchKeywords.length === 0) {
        console.log(`- ${member.name}(${memberId}) 후보의 검색 키워드가 없습니다. 건너뜁니다.`);
        continue;
      }

      console.log(`- ${member.name}(${memberId}) 후보 뉴스 업데이트 중...`);
      
      let allNewsItems = [];
      for (const keyword of searchKeywords) {
        const newsItems = await fetchNewsForKeyword(keyword);
        allNewsItems = allNewsItems.concat(newsItems);
      }

      // Firestore 문서 업데이트
      await db.collection('members').doc(memberId).update({
        newsItems: allNewsItems,
        newsUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      console.log(`  ✅ ${member.name}(${memberId}) 후보 뉴스 업데이트 완료.`);
      
      // API 제한 및 서버 부하 방지를 위한 지연
      await new Promise(resolve => setTimeout(resolve, 200));
    }

    console.log('\n🎉 모든 후보자의 뉴스 데이터 업데이트가 완료되었습니다.');

  } catch (error) {
    console.error('❌ 뉴스 업데이트 중 오류 발생:', error);
  } finally {
    // 스크립트가 정상적으로 종료되도록 프로세스를 명시적으로 종료합니다.
    process.exit(0);
  }
}

// 메인 함수 실행
updateAllNews();