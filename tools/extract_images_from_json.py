#!/usr/bin/env python3
"""
election_candidates.json에서 base64 imageData를 추출하여
assets/images/candidates/ 폴더에 PNG 파일로 저장하고,
imageUrl 필드를 로컬 경로로 교체한 후 JSON을 소형화합니다.

사용법:
  python3 tools/extract_images_from_json.py

결과:
  - assets/images/candidates/{id}.png : 후보자 사진 파일
  - assets/data/election_candidates.json : imageData 제거, imageUrl 채워진 소형 JSON
  - web/api/members.json : 동일하게 업데이트
"""

import json
import base64
import os
import hashlib
from pathlib import Path

def main():
    root = Path(__file__).parent.parent
    json_path = root / 'assets' / 'data' / 'election_candidates.json'
    api_path  = root / 'web' / 'api' / 'members.json'
    img_dir   = root / 'assets' / 'images' / 'candidates'
    img_dir.mkdir(parents=True, exist_ok=True)

    print(f"📂 JSON 로딩 중... ({json_path.stat().st_size / 1024 / 1024:.1f} MB)")
    with open(json_path, 'r', encoding='utf-8') as f:
        candidates = json.load(f)

    print(f"👥 총 후보자: {len(candidates)}명")

    saved = 0
    skipped = 0
    no_image = 0

    for c in candidates:
        image_data = c.pop('imageData', None)

        # 이미 imageUrl이 있으면 스킵
        if c.get('imageUrl'):
            skipped += 1
            continue

        if not image_data:
            no_image += 1
            continue

        # base64 → bytes
        try:
            if image_data.startswith('data:'):
                # data:image/png;base64,xxxx 형식
                header, b64 = image_data.split(',', 1)
            else:
                b64 = image_data
            img_bytes = base64.b64decode(b64)
        except Exception as e:
            print(f"  ⚠️  {c.get('name')} 이미지 디코드 실패: {e}")
            no_image += 1
            continue

        # 파일명: 후보 ID 기반 (없으면 이름+정당 해시)
        cid = c.get('id') or ''
        if not cid:
            key = f"{c.get('name','')}|{c.get('party','')}|{c.get('constituency','')}"
            cid = 'img_' + hashlib.sha1(key.encode()).hexdigest()[:10]

        # 파일명 안전하게 처리
        safe_id = cid.replace('/', '_').replace('\\', '_')
        img_file = img_dir / f"{safe_id}.png"

        try:
            with open(img_file, 'wb') as f:
                f.write(img_bytes)
            c['imageUrl'] = f"assets/images/candidates/{safe_id}.png"
            saved += 1
        except Exception as e:
            print(f"  ⚠️  {c.get('name')} 이미지 저장 실패: {e}")
            no_image += 1

    print(f"\n✅ 이미지 저장: {saved}명")
    print(f"⏭️  imageUrl 이미 있음: {skipped}명")
    print(f"❌ 이미지 없음: {no_image}명")

    # 정리된 JSON 저장
    print(f"\n💾 JSON 저장 중...")
    for out_path in (json_path, api_path):
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(candidates, f, ensure_ascii=False, indent=2)
        size_mb = out_path.stat().st_size / 1024 / 1024
        print(f"  📄 {out_path.name}: {size_mb:.1f} MB")

    print("\n🎉 완료!")
    print(f"   이미지 폴더: {img_dir}")
    print(f"   이미지 파일 수: {len(list(img_dir.glob('*.png')))}개")

if __name__ == '__main__':
    main()
