#!/usr/bin/env python3
"""
cpmadang.org 2026년 제9회 지방선거 후보자 명단 크롤링 스크립트
페이지 0~272를 순차적으로 크롤링하여 JSON으로 저장합니다.
"""

import re
import json
import time
import ssl
import urllib.request
import urllib.error
import datetime
from collections import Counter

# SSL 인증서 검증 비활성화 (Mac 환경 대응)
_SSL_CTX = ssl.create_default_context()
_SSL_CTX.check_hostname = False
_SSL_CTX.verify_mode = ssl.CERT_NONE

BASE_URL = "https://cpmadang.org/people/list_of_candidates_2026?page={}"
OUTPUT_FILE = "/Users/jtsgrit0/Documents/flutter/elecko26_new/assets/data/candidates_2026.json"
TOTAL_PAGES = 273  # 0 ~ 272


def fetch_page(url, retries=3):
    """페이지 HTML 다운로드"""
    headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "ko-KR,ko;q=0.9,en;q=0.8",
    }
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=30, context=_SSL_CTX) as resp:
                return resp.read().decode("utf-8", errors="replace")
        except Exception as e:
            print(f"  ⚠️  시도 {attempt+1}/{retries} 실패: {e}")
            if attempt < retries - 1:
                time.sleep(2)
    return None


def clean_text(s):
    """HTML 태그 및 공백 제거"""
    s = re.sub(r'<[^>]+>', '', s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s


def decode_url_region(url_part):
    """URL 인코딩된 지역명 디코드"""
    from urllib.parse import unquote
    try:
        return unquote(url_part)
    except Exception:
        return url_part


def extract_candidates_from_html(html):
    """
    HTML에서 후보자 카드(.candidate-card) 블록을 추출하여 구조화된 데이터 반환
    """
    candidates = []

    # candidate-card 블록 분리 (각 후보 카드)
    card_pattern = re.compile(
        r'<div class="candidate-card">(.*?)</div>\s*</div>\s*<div class="card-footer"',
        re.DOTALL
    )

    # 더 넓은 패턴으로 각 views-row 블록 추출
    row_pattern = re.compile(
        r'<div class="views-row">\s*<div class="candidate-card">(.*?)</div>\s*</div>',
        re.DOTALL
    )

    # card-badge와 candidate-info 기반 추출
    # 각 후보 카드를 찾는 패턴
    # 패턴: class="candidate-card" 로 시작해서 card-footer 직전까지
    full_card_pattern = re.compile(
        r'class="candidate-card">(.*?)(?=class="candidate-card"|</body>)',
        re.DOTALL
    )

    for m in full_card_pattern.finditer(html):
        block = m.group(1)
        candidate = {}

        # 지역 추출 (badge-right)
        region_m = re.search(
            r'class="card-badge badge-right">\s*<a[^>]*>([^<]+)</a>',
            block
        )
        if region_m:
            candidate["region"] = clean_text(region_m.group(1))

        # 정당 추출 (info-party)
        party_m = re.search(
            r'class="info-party">\s*<a[^>]*>([^<]+)</a>',
            block
        )
        if party_m:
            candidate["party"] = clean_text(party_m.group(1))

        # 이름 추출 (h2 info-name)
        name_m = re.search(
            r'class="info-name"[^>]*>.*?<a[^>]*>([^<]+)</a>',
            block, re.DOTALL
        )
        if name_m:
            name_raw = clean_text(name_m.group(1))
            # 한자 괄호 포함 원본 저장
            candidate["nameRaw"] = name_raw
            # 한자 제거: 괄호(吳鉉) 부분 제거
            name_clean = re.sub(r'\([^\)]*\)', '', name_raw).strip()
            candidate["name"] = name_clean

        # 상세 페이지 URL 추출
        url_m = re.search(
            r'<a href="(/%ED%9B%84%EB%B3%B4/[^"]+)"',
            block
        )
        if url_m:
            candidate["sourceUrl"] = "https://cpmadang.org" + url_m.group(1)

        # 사진 URL 추출
        img_m = re.search(r'<img[^>]+src="([^"]+)"', block)
        if img_m:
            img_src = img_m.group(1)
            if img_src.startswith("/"):
                img_src = "https://cpmadang.org" + img_src
            candidate["imageUrl"] = img_src

        # 선거구 추출 (info-meta-line 첫 번째 span)
        meta_m = re.search(
            r'class="info-meta-line">(.*?)</div>',
            block, re.DOTALL
        )
        if meta_m:
            meta_text = meta_m.group(1)
            # 첫 번째 meta-item = 선거구
            items = re.findall(r'class="meta-item[^"]*">\s*<a[^>]*>([^<]+)</a>', meta_text)
            if len(items) >= 1:
                candidate["district"] = clean_text(items[0])
            if len(items) >= 2:
                candidate["electionType"] = clean_text(items[1])
            if len(items) >= 3:
                candidate["status"] = clean_text(items[2])

        # 직업/소개 추출 (occupation-text)
        job_m = re.search(
            r'class="occupation-text">\s*<a[^>]*>([^<]+)</a>',
            block
        )
        if job_m:
            candidate["job"] = clean_text(job_m.group(1))

        # 태그 추출 (footer-tags)
        tags_section = re.search(r'class="footer-tags">(.*?)</div>', block, re.DOTALL)
        tags = []
        if tags_section:
            tag_links = re.findall(r'<a[^>]+>([^<]+)</a>', tags_section.group(1))
            tags = [clean_text(t) for t in tag_links if t.strip()]
        candidate["tags"] = tags

        # 경력/학력 추출
        career_parts = re.findall(r'class="flow-part[^"]*">([^<]+)', block)
        if career_parts:
            candidate["career"] = " | ".join([c.strip().replace('\n', ' ') for c in career_parts if c.strip()])

        # 이름이 있는 경우만 추가
        if candidate.get("name"):
            candidates.append(candidate)

    return candidates


def main():
    import os

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    all_candidates = []
    seen_urls = set()

    print(f"🚀 cpmadang.org 후보자 명단 크롤링 시작 (총 {TOTAL_PAGES}페이지)")
    print(f"📁 출력 파일: {OUTPUT_FILE}\n")

    for page in range(TOTAL_PAGES):
        url = BASE_URL.format(page)
        print(f"📥 페이지 {page:3d}/{TOTAL_PAGES-1} 다운로드 중...", end=" ", flush=True)

        html = fetch_page(url)
        if not html:
            print(f"❌ 실패 (스킵)")
            continue

        candidates = extract_candidates_from_html(html)

        new_count = 0
        for c in candidates:
            key = c.get("sourceUrl") or (c.get("name", "") + "|" + c.get("district", ""))
            if key and key not in seen_urls:
                seen_urls.add(key)
                all_candidates.append(c)
                new_count += 1

        print(f"✅ {new_count:2d}명 추출 (누적: {len(all_candidates):5d}명)")

        # 서버 부하 방지 (0.3초 간격)
        time.sleep(0.3)

    # 지역 > 정당 > 이름 순 정렬
    all_candidates.sort(key=lambda x: (
        x.get("region", ""),
        x.get("party", ""),
        x.get("name", "")
    ))

    # ID 부여
    for i, c in enumerate(all_candidates):
        c["id"] = f"cpm_{i:05d}"
        # electionPossibility 기본값 (추후 업데이트)
        c["electionPossibility"] = 0.5

    # JSON 저장
    output = {
        "metadata": {
            "source": "https://cpmadang.org/people/list_of_candidates_2026",
            "election": "2026년 제9회 전국동시지방선거",
            "totalCount": len(all_candidates),
            "scrapedAt": datetime.datetime.now().isoformat(),
        },
        "candidates": all_candidates,
    }

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"\n✅ 완료! 총 {len(all_candidates)}명의 후보자 데이터가 저장되었습니다.")
    print(f"📁 {OUTPUT_FILE}")

    # 정당별 통계
    party_counts = Counter(c.get("party", "미상") for c in all_candidates)
    print("\n📊 정당별 후보자 수:")
    for party, count in party_counts.most_common(10):
        print(f"  {party}: {count}명")

    # 선거 종류별 통계
    type_counts = Counter(c.get("electionType", "미상") for c in all_candidates)
    print("\n📊 선거 종류별 후보자 수:")
    for etype, count in type_counts.most_common():
        print(f"  {etype}: {count}명")


if __name__ == "__main__":
    main()
