const admin = require('firebase-admin');
const fs = require('fs');

// 서비스 계정 키 파일 경로
const serviceAccountPath = './firebase-admin-key.json';

// 서비스 계정 키 파일 확인
if (!fs.existsSync(serviceAccountPath)) {
    console.error('❌ firebase-admin-key.json 파일이 없습니다.');
    console.log('📋 Firebase 콘솔에서 다운로드하세요:');
    console.log('1. https://console.firebase.google.com/project/elecko26-536e0/settings/serviceaccounts/adminsdk');
    console.log('2. "새 비공개 키 생성" 클릭');
    console.log('3. 다운로드된 파일을 firebase-admin-key.json으로 이름 변경');
    console.log('4. 현재 디렉토리에 저장');
    process.exit(1);
}

// Firebase Admin SDK 초기화
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

// Firestore 인스턴스
const db = admin.firestore();

// 토큰 생성 함수
async function generateCustomToken() {
    try {
        console.log('🔥 Firebase Admin SDK 초기화 완료');
        console.log('📋 프로젝트 ID:', serviceAccount.project_id);
        
        // Firestore 연결 테스트
        console.log('🔗 Firestore 연결 테스트 중...');
        await db.collection('test').doc('connection').set({ 
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            message: 'Connection test'
        });
        
        console.log('✅ Firestore 연결 성공!');
        
        // 커스텀 토큰 생성 (1시간 유효)
        const customToken = await admin.auth().createCustomToken('admin-user');
        
        console.log('');
        console.log('🎯 생성된 토큰:');
        console.log(customToken);
        console.log('');
        
        // 토큰을 파일로 저장
        fs.writeFileSync('firebase-token.txt', customToken);
        console.log('✅ 토큰이 firebase-token.txt 파일에 저장되었습니다.');
        
        // 업로드 스크립트 실행 권장
        console.log('');
        console.log('🚀 이제 다음 명령어로 데이터를 업로드하세요:');
        console.log('./upload_firestore_restapi.sh $(cat firebase-token.txt)');
        
    } catch (error) {
        console.error('❌ 토큰 생성 중 오류:', error.message);
        process.exit(1);
    } finally {
        process.exit(0);
    }
}

// 메인 실행
generateCustomToken();