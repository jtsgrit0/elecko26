# Firebase Admin SDK 설정 방법

## 1. 서비스 계정 키 생성

### Firebase 콘솔에서:
1. https://console.firebase.google.com/project/elecko26-536e0/settings/serviceaccounts/adminsdk
2. **"새 비공개 키 생성"** 클릭
3. JSON 파일이 다운로드됩니다
4. 파일을 `firebase-admin-key.json`으로 이름 변경
5. 프로젝트 루트에 저장

## 2. Node.js 패키지 설치
```bash
npm init -y
npm install firebase-admin
```

## 3. 데이터 업로드 실행
```bash
node upload_to_firebase.js
```

## 4. 대안: Firebase CLI 사용
```bash
# Firebase CLI 설치
npm install -g firebase-tools

# 로그인
firebase login

# 프로젝트 선택
firebase use elecko26-536e0

# Firestore 데이터 가져오기 (개별 파일)
firebase firestore:delete --all-collections  # 기존 데이터 삭제 (선택사항)
```

## 5. 수동 업로드 방법 (권장)
```bash
# members 컬렉션만 먼저 테스트
node -e "
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const data = require('./firebase_collections/members.json');

// 첫 5개만 테스트
const first5 = Object.fromEntries(Object.entries(data).slice(0, 5));

Promise.all(
  Object.entries(first5).map(([id, doc]) => 
    db.collection('members').doc(id).set(doc)
  )
).then(() => {
  console.log('✅ 테스트 업로드 완료!');
  process.exit();
});
"
```