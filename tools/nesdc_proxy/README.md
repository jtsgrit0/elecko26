# NESDC CORS Proxy (Cloudflare Worker)

NESDC 사이트는 브라우저 CORS 정책 때문에 직접 호출이 막힐 수 있습니다.
이 워커는 NESDC 요청을 프록시하고 CORS 헤더를 붙여줍니다.

## 사용 방법

1) Cloudflare Wrangler 설치
```bash
npm i -g wrangler
```

2) 워커 배포
```bash
wrangler init nesdc-proxy
cd nesdc-proxy
```

`src/index.js`에 `tools/nesdc_proxy/worker.js` 내용을 복사합니다.

3) 배포
```bash
wrangler deploy
```

4) 앱에서 사용

배포된 워커 URL이 `https://your-worker.example.workers.dev` 라면,
실행 시 아래처럼 환경변수를 넣어주세요.

```bash
flutter run -d chrome --dart-define=NESDC_BASE_URL=https://your-worker.example.workers.dev
```

데이터 소스는 내부적으로 `?url=<NESDC URL>` 형태로 호출합니다.
