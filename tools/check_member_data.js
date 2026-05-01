const admin = require('firebase-admin');
const serviceAccount = require('../firebase-admin-key.json');

// Firebase Admin SDK 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkMemberData(memberId) {
  console.log(`🔍 '${memberId}' 후보의 데이터를 Firestore에서 조회합니다...`);
  try {
    const docRef = db.collection('members').doc(memberId);
    const doc = await docRef.get();

    if (!doc.exists) {
      console.log('해당 후보자 문서를 찾을 수 없습니다.');
    } else {
      console.log('✅ 데이터 조회 성공:');
      console.log(JSON.stringify(doc.data(), null, 2));
    }
  } catch (error) {
    console.error('❌ 데이터 조회 중 오류 발생:', error);
  } finally {
    process.exit(0);
  }
}

// 이전 로그에서 확인된 후보자 ID 중 하나를 사용합니다.
const targetMemberId = 'member_황우일';
checkMemberData(targetMemberId);