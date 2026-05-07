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

def scrape_bing_news(query, max_results=5):
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

        for item in news_items[:max_results]:
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

def analyze_public_opinion(candidate_name, party):
    """
    Bing 검색을 사용하여 후보자에 대한 SNS 언급량과 여론 동향을 분석합니다.
    """
    print("  - Analyzing public opinion (SNS Trends)...")
    opinion_data = {"snsMentions": 0, "trend": "보합"}
    
    try:
        # 1. SNS 언급량 (검색 결과 수로 추정)
        query = f'"{candidate_name}" OR "{party} {candidate_name}"'
        encoded_query = urllib.parse.quote_plus(query)
        search_url = f"https://www.bing.com/search?q={encoded_query}"
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
        
        response = requests.get(search_url, headers=headers, timeout=15)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        
        result_stats = soup.select_one(".sb_count")
        if result_stats:
            count_text = result_stats.get_text(strip=True).replace("결과", "").replace("개", "").replace(",", "").strip()
            if count_text.isdigit():
                opinion_data["snsMentions"] = int(count_text)

        # 2. 여론 동향 (최근 뉴스의 제목으로 분석)
        news_query = f'"{candidate_name}" 지지율'
        news_articles = scrape_bing_news(news_query, max_results=10)
        
        trend_keywords = {'상승': 0, '하락': 0, '보합': 0}
        for article in news_articles:
            title = article.get('title', '')
            if "상승" in title or "급등" in title or "증가" in title:
                trend_keywords['상승'] += 1
            elif "하락" in title or "급락" in title or "감소" in title:
                trend_keywords['하락'] += 1
            else:
                trend_keywords['보합'] += 1
        
        if trend_keywords['상승'] > trend_keywords['하락']:
            opinion_data["trend"] = "상승"
        elif trend_keywords['하락'] > trend_keywords['상승']:
            opinion_data["trend"] = "하락"
        
        print(f"    > SNS Mentions (estimated): {opinion_data['snsMentions']} Trend: {opinion_data['trend']}")

    except Exception as e:
        print(f"  -> Public opinion analysis failed: {e}")
        
    return opinion_data

def analyze_text_for_keywords(press_reports, candidate_name, trend_analysis_text=""):
    """
    수집된 뉴스 기사와 트렌드 분석 텍스트에서 키워드를 추출합니다.
    """
    print("  - Analyzing text for keywords (regex-based)...")
    
    full_text = ' '.join(
        f"{report.get('title', '')} {report.get('summary', '')}" 
        for report in press_reports
    )
    full_text += " " + trend_analysis_text
    
    if not full_text.strip():
        print("    > No content to analyze.")
        return [], {}

    korean_words = re.findall(r'\b[가-힣]{2,5}\b', full_text)
    
    stopwords = ['기자', '뉴스', '사진', '제공', '무단', '전재', '배포', '금지', '앵커', '영상']
    candidate_firstname = candidate_name[1:]
    stopwords.extend([candidate_name, candidate_firstname])
    
    meaningful_words = [word for word in korean_words if word not in stopwords and len(word) > 1]
    
    count = Counter(meaningful_words)
    top_10_keywords = [item[0] for item in count.most_common(10)]
    
    print(f"    > Top keywords found: {top_10_keywords}")

    analysis_result = {
        "policies": [f"'{kw}' 관련 정책 강화" for kw in top_10_keywords[:3]],
        "achievementsList": [f"'{kw}' 분야 성과" for kw in top_10_keywords[3:6]],
        "improvementPoints": [f"'{kw}' 관련 논의 필요" for kw in top_10_keywords[6:8]],
        "socialContributions": [f"'{kw}' 캠페인 참여" for kw in top_10_keywords[8:]]
    }
    
    return top_10_keywords, analysis_result

def generate_mock_polls(base_possibility, trend="보합"):
    """
    기본 당선 가능성과 여론 동향을 바탕으로 가상의 여론조사 데이터를 생성합니다.
    """
    print("  - Generating mock poll data based on trend...")
    polls = []
    if not isinstance(base_possibility, (int, float)) or base_possibility <= 0:
        base_possibility = random.uniform(5, 20)

    # 트렌드에 따른 가중치 적용
    if trend == "상승":
        trend_multiplier = 1.15
    elif trend == "하락":
        trend_multiplier = 0.85
    else: # 보합
        trend_multiplier = 1.0

    latest_support = base_possibility
    for i in range(3):
        poll_date = datetime.now() - timedelta(days=30 * i)
        
        if i > 0: # 첫번째 이후 조사부터 트렌드 적용
            latest_support *= trend_multiplier * random.uniform(0.98, 1.02)
        
        support_rate = max(5.0, min(60.0, latest_support))
        
        polls.append({
            "id": str(uuid.uuid4()),
            "source": f"가상 여론조사 기관 {i+1}",
            "date": poll_date.strftime('%Y-%m-%d'),
            "supportRate": round(support_rate, 2),
            "sampleSize": random.randint(500, 1000),
            "marginOfError": round(random.uniform(2.5, 3.1), 1)
        })
    
    print(f"    > Generated {len(polls)} mock polls. Latest support: {polls[0]['supportRate']}%")
    return polls

def enrich_candidate_data(members):
    """
    후보자 목록을 순회하며 Bing 검색 및 분석을 통해 데이터를 보강합니다.
    """
    print(f"Starting data enrichment for {len(members)} members.")
    
    updated_members = []
    for i, member in enumerate(members):
        print(f"\n--- Processing candidate {i+1}/{len(members)}: {member['name']} ---")
        
        default_member = {
            'id': '', 'name': '', 'party': '', 'district': '',
            'description': '', 'imageUrl': '', 'electionPossibility': 0.0,
            'isFavorite': False, 'lastAnalysisDate': None, 'polls': [],
            'pressReports': [], 'achievementsList': [], 'policies': [],
            'improvementPoints': [], 'socialContributions': [],
            'historical2018PartyRates': {}, 'snsKeywords': [],
            'snsMentions': 0, 'opinionTrend': '보합'
        }
        
        conformed_member = default_member.copy()
        conformed_member.update(member)

        # 뉴스 기사 스크래핑
        query = f"{conformed_member.get('party', '')} {conformed_member['name']} {conformed_member.get('region', '')}"
        press_reports = scrape_bing_news(query)
        
        # SNS 분석
        opinion_data = analyze_public_opinion(conformed_member['name'], conformed_member.get('party', ''))
        conformed_member['snsMentions'] = opinion_data['snsMentions']
        conformed_member['opinionTrend'] = opinion_data['trend']

        # 키워드 분석
        trend_text = f"지지율 {opinion_data['trend']}"
        keywords, analysis_data = analyze_text_for_keywords(press_reports, conformed_member['name'], trend_text)
        
        conformed_member['id'] = str(conformed_member['id'])
        conformed_member['pressReports'] = press_reports
        conformed_member['lastAnalysisDate'] = datetime.now().strftime('%Y-%m-%d')
        
        conformed_member.update(analysis_data)
        conformed_member['snsKeywords'] = keywords

        # 여론조사 데이터 생성
        conformed_member['polls'] = generate_mock_polls(
            conformed_member.get('electionPossibility', 0.0),
            opinion_data['trend']
        )

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

    print(f"--- Starting data enrichment for all {len(members_data)} candidates... ---")

    enriched_members = enrich_candidate_data(members_data)

    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(enriched_members, f, ensure_ascii=False, indent=2)
        print(f"\nSuccessfully enriched {len(enriched_members)} members and saved to {output_file}")
    except Exception as e:
        print(f"\nError saving data to {output_file}: {e}")

if __name__ == "__main__":
    main()