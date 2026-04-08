---
description: 작업 완료 후 git commit & push
---

// turbo-all

작업이 끝나면 항상 아래 단계를 순서대로 진행한다.

1. 변경된 파일 확인
```
git status
```

2. 변경 파일 전체 스테이징
```
git add -A
```

3. 작업 내용을 한국어로 요약한 커밋 메시지로 커밋 (conventional commits 형식: fix/feat/refactor/chore 등)
```
git commit -m "<type>: <한국어 요약>\n\n<상세 설명 (선택)>"
```

4. main 브랜치에 푸시
```
git push origin main
```

5. 완료 메시지 출력
