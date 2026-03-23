# NESDC Backend (Optional)

브라우저 CORS 문제와 PDF 파싱 부하를 줄이기 위한 간단한 백엔드입니다.

## 실행

```bash
cd tools/nesdc_backend
npm install
npm run start
```

기본 포트는 `8787`입니다.

## 환경변수

- `PORT`: 서버 포트 (기본 8787)
- `NESDC_BASE_URL`: NESDC 기본 주소 (기본 `https://www.nesdc.go.kr`)
- `NESDC_PAGES`: 기본 페이지 수 (기본 2)
- `NESDC_LIMIT`: 최대 반환 건수 (기본 20)

## 앱 연동

```bash
flutter run -d chrome --dart-define=NESDC_BACKEND_URL=http://localhost:8787
```

## 응답 예시

`/polls?pages=2&limit=20` → `entries` 배열을 반환합니다.
각 entry는 목록 정보와 `detail`(조사기간, 표본, 오차한계, 결과 파일 링크 등)를 포함합니다.
