import json
from datetime import datetime, timedelta
import requests
from bs4 import BeautifulSoup
import time
import urllib.parse
import uuid
import random
import re
from collections import Counter

def scrape_bing_news(query):
    """
    주어진 쿼리로 Bing News에서 기사를 검색하고 스크래핑합니다.
    """
    print(f"  - Bing News Scraping started for: {query}")
    articles = []
    
    try:
        encoded_query = urllib.parse.quote_plus(query)
        search_url = f"https://www.bing.com/news/search?q={encoded_query}"
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}

        response = requests.get(search_url, headers=headers, timeout=20)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        
        news_items = soup.select(".news-card")
        
        print(f"    > Found {len(news_items)} news items on Bing News.")

        for item in news_items[:5]: # 상위 5개만 가져옵니다.
            title_anchor = item.select_one("a.title")
            summary_el = item.select_one(".snippet")
            source_el = item.select_one(".source a")

            if not title_anchor or not summary_el:
                continue

            title = title_anchor.get_text(strip=True)
            url = title_anchor.get('href')
            summary = summary_el.get_text(strip=True)
            source = source_el.get_text(strip=True) if source_el else "Unknown Source"
            
            if url and not url.startswith("http"):
                url = "https://www.bing.com" + url

            content = summary 

            articles.append({
                "id": str(uuid.uuid4()),
                "title": title,
                "source": source,
                "url": url,
                "publishDate": datetime.now().isoformat(),
                "summary": summary,
                "content": content,
                "sentiment": "neutral"
            })
            time.sleep(0.5)

    except requests.exceptions.RequestException as e:
        print(f"  -> Bing News request failed: {e}")
    
    print(f"  - Bing News Scraping finished. Collected {len(articles)} articles.")
    return articles

def analyze_text_for_keywords(press_reports, candidate_name):
    """
    수집된 뉴스 기사의 제목과 요약에서 한글 명사형 단어를 추출하여 키워드를 반환합니다.
    konlpy 의존성을 제거한 버전입니다.
    """
    print("  - Analyzing text for keywords (regex-based)...")
    
    # 모든 제목과 요약을 하나로 합칩니다.
    full_text = ' '.join(
        f"{report.get('title', '')} {report.get('summary', '')}" 
        for report in press_reports
    )
    
    if not full_text.strip():
        print("    > No content to analyze.")
        return [], {}

    # 정규식을 사용하여 2~5글자의 한글 단어 추출
    korean_words = re.findall(r'\b[가-힣]{2,5}\b', full_text)
    
    # 불용어 및 후보자 이름 제거
    stopwords = ['기자', '뉴스', '사진', '제공', '무단', '전재', '배포', '금지', '앵커', '영상']
    candidate_firstname = candidate_name[1:]
    stopwords.extend([candidate_name, candidate_firstname])
    
    meaningful_words = [word for word in korean_words if word not in stopwords and len(word) > 1]
    
    # 가장 많이 등장하는 단어 10개 추출
    count = Counter(meaningful_words)
    top_10_keywords = [item[0] for item in count.most_common(10)]
    
    print(f"    > Top keywords found: {top_10_keywords}")

    # 임시로 정책, 강점/약점 등을 키워드 기반으로 생성
    analysis_result = {
        "policies": [f"'{kw}' 관련 정책 강화" for kw in top_10_keywords[:3]],
        "achievementsList": [f"'{kw}' 분야 성과" for kw in top_10_keywords[3:6]],
        "improvementPoints": [f"'{kw}' 관련 논의 필요" for kw in top_10_keywords[6:8]],
        "socialContributions": [f"'{kw}' 캠페인 참여" for kw in top_10_keywords[8:]]
    }
    
    return top_10_keywords, analysis_result

def generate_mock_polls(base_possibility):
    """
    후보자의 기본 당선 가능성을 바탕으로 가상의 여론조사 데이터를 생성합니다.
    """
    print("  - Generating mock poll data...")
    polls = []
    if not isinstance(base_possibility, (int, float)) or base_possibility <= 0:
        print("    > Invalid base possibility. Skipping poll generation.")
        return polls

    # 최근 3개월간의 가상 데이터 생성
    for i in range(3):
        poll_date = datetime.now() - timedelta(days=30 * i)
        # 약간의 변동성을 추가
        support_rate = base_possibility * (1 + (random.uniform(-0.1, 0.1)))
        support_rate = max(5.0, min(95.0, support_rate)) # 5% ~ 95% 범위로 제한
        
        polls.append({
            "id": str(uuid.uuid4()),
            "source": f"가상 여론조사 기관 {i+1}",
            "date": poll_date.strftime('%Y-%m-%d'),
            "supportRate": round(support_rate, 2),
            "sampleSize": random.randint(500, 1000),
            "marginOfError": round(random.uniform(2.5, 3.1), 1)
        })
    print(f"    > Generated {len(polls)} mock polls.")
    return polls

def enrich_candidate_data(members):
    """
    주어진 후보자 목록을 순차적으로 읽어와서 News API로 데이터를 보강합니다.
    Flutter의 Member/PressReport 모델에 정확히 맞춰 데이터를 생성합니다.
    """
    print(f"Starting data enrichment for {len(members)} members using News API.")
    
    updated_members = []
    for i, member in enumerate(members):
        print(f"\n--- Processing candidate {i+1}/{len(members)}: {member['name']} ---")
        
        default_member = {
            'id': '', 'name': '', 'party': '', 'district': '',
            'description': '', 'imageUrl': '', 'electionPossibility': 0.0,
            'isFavorite': False, 'lastAnalysisDate': None, 'polls': [],
            'pressReports': [], 'achievementsList': [], 'policies': [],
            'improvementPoints': [], 'socialContributions': [],
            'historical2018PartyRates': {}, 'snsKeywords': []
        }
        
        conformed_member = default_member.copy()
        conformed_member.update(member)

        # Bing News에서 후보자 관련 기사 스크래핑
        query = f"{conformed_member.get('party', '')} {conformed_member['name']} {conformed_member.get('region', '')}"
        press_reports = scrape_bing_news(query)
        
        keywords, analysis_data = analyze_text_for_keywords(press_reports, conformed_member['name'])
        
        conformed_member['id'] = str(conformed_member['id'])
        conformed_member['pressReports'] = press_reports
        conformed_member['lastAnalysisDate'] = datetime.now().strftime('%Y-%m-%d')
        
        conformed_member['policies'] = analysis_data.get('policies', [])
        conformed_member['achievementsList'] = analysis_data.get('achievementsList', [])
        conformed_member['improvementPoints'] = analysis_data.get('improvementPoints', [])
        conformed_member['socialContributions'] = analysis_data.get('socialContributions', [])
        conformed_member['snsKeywords'] = keywords

        # 가상 여론조사 데이터 생성
        conformed_member['polls'] = generate_mock_polls(conformed_member.get('electionPossibility', 0.0))

        if 'electionPossibility' not in conformed_member or not isinstance(conformed_member['electionPossibility'], (int, float)):
            conformed_member['electionPossibility'] = 0.0

        updated_members.append(conformed_member)
        print(f"  -> Finished for {member['name']}. Found {len(press_reports)} articles.")
        
        time.sleep(1)

    return updated_members

def main():
    """
    후보자 데이터를 로드하고, 데이터 보강을 수행한 후, 결과를 파일에 저장합니다.
    """
    input_file = 'api/members.json'
    output_file = 'api/members_enriched.json'

    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            members_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file not found at {input_file}")
        return

    # 전체 데이터 처리
    print(f"--- Starting data enrichment for all {len(members_data)} candidates... ---")

    # 데이터 보강
    enriched_members = enrich_candidate_data(members_data)

    # 보강된 데이터를 JSON 파일로 저장
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(enriched_members, f, ensure_ascii=False, indent=2)
        print(f"\nSuccessfully enriched {len(enriched_members)} members and saved to {output_file}")
    except Exception as e:
        print(f"\nError saving data to {output_file}: {e}")

if __name__ == "__main__":
    main()