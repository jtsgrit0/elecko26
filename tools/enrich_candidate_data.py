import json
from datetime import datetime
import requests
from bs4 import BeautifulSoup
import time
import urllib.parse
import uuid
from konlpy.tag import Okt
from collections import Counter
import nltk

def search_news_api(query):
    """
    주어진 쿼리로 Saurav.tech의 News API를 호출하여 뉴스 기사를 가져옵니다.
    """
    print(f"  - News API Search started for: {query}")
    articles = []
    try:
        encoded_query = urllib.parse.quote(query)
        search_url = f"https://saurav.tech/NewsAPI/everything/cnn.json?q={encoded_query}&language=ko"
        headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36'}
        response = requests.get(search_url, headers=headers, timeout=20)
        response.raise_for_status()
        data = response.json()
        
        if data.get('status') == 'ok':
            found_articles = data.get('articles', [])
            print(f"    > Found {len(found_articles)} articles from the API.")
            
            for article in found_articles:
                article_url = article.get('url')
                content = ""
                if article_url:
                    try:
                        page_response = requests.get(article_url, headers=headers, timeout=10)
                        page_response.raise_for_status()
                        soup = BeautifulSoup(page_response.content, 'html.parser')
                        # 본문 내용을 포함할 가능성이 높은 태그들을 중심으로 텍스트 추출
                        body_texts = soup.find_all(['p', 'div'])
                        content = ' '.join(p.get_text(strip=True) for p in body_texts)
                    except Exception as e:
                        print(f"    -> Failed to scrape content from {article_url}: {e}")

                # PressReport 모델 형식에 맞게 데이터 변환
                articles.append({
                    "id": str(uuid.uuid4()), # 고유 ID 생성
                    "title": str(article.get('title', '')),
                    "source": str(article.get('source', {}).get('name', '')),
                    "url": str(article.get('url', '')),
                    "publishDate": str(article.get('publishedAt', datetime.now().isoformat())),
                    "summary": str(article.get('description', '')),
                    "content": content, # 스크래핑한 본문 추가
                    "sentiment": "neutral" # 기본값으로 neutral 설정
                })
        else:
            print(f"    > API returned status: {data.get('status')}")

    except requests.exceptions.RequestException as e:
        print(f"  -> News API request failed: {e}")
    except json.JSONDecodeError:
        print("  -> Failed to decode JSON response from the API.")
    
    print(f"  - News API Search finished. Collected {len(articles)} articles.")
    return articles

def analyze_text_for_keywords(press_reports):
    """
    수집된 뉴스 기사 본문에서 명사를 추출하여 빈도수 높은 키워드를 반환합니다.
    """
    print("  - Analyzing text for keywords...")
    okt = Okt()
    
    # 모든 기사 본문을 하나로 합칩니다.
    full_text = ' '.join(report.get('content', '') for report in press_reports)
    
    if not full_text.strip():
        print("    > No content to analyze.")
        return [], {}

    # 명사 추출
    nouns = okt.nouns(full_text)
    
    # 한 글자 단어 및 불용어 제거
    stopwords = ['기자', '뉴스', '사진', '제공', '무단', '전재', '배포', '금지']
    meaningful_nouns = [n for n in nouns if len(n) > 1 and n not in stopwords]
    
    # 가장 많이 등장하는 명사 10개 추출
    count = Counter(meaningful_nouns)
    top_10_keywords = [item[0] for item in count.most_common(10)]
    
    print(f"    > Top keywords found: {top_10_keywords}")

    # 임시로 정책, 강점/약점 등을 키워드 기반으로 생성
    # TODO: 이 부분은 더 정교한 분석 로직으로 교체해야 합니다.
    analysis_result = {
        "policies": [f"'{kw}' 관련 정책 강화" for kw in top_10_keywords[:3]],
        "achievementsList": [f"'{kw}' 분야 성과" for kw in top_10_keywords[3:6]],
        "improvementPoints": [f"'{kw}' 관련 논의 필요" for kw in top_10_keywords[6:8]],
        "socialContributions": [f"'{kw}' 캠페인 참여" for kw in top_10_keywords[8:]]
    }
    
    return top_10_keywords, analysis_result

def enrich_candidate_data():
    """
    전체 후보자 목록을 순차적으로 읽어와서 News API로 데이터를 보강합니다.
    Flutter의 Member/PressReport 모델에 정확히 맞춰 데이터를 생성합니다.
    """
    input_file = 'api/members.json'
    output_file = 'api/members_enriched.json'

    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            members = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file not found at {input_file}")
        return

    print(f"Starting data enrichment for {len(members)} members using News API.")
    
    updated_members = []
    for i, member in enumerate(members):
        print(f"\n--- Processing candidate {i+1}/{len(members)}: {member['name']} ---")
        
        # --- Start Conforming Step ---
        # Ensure all required fields exist with default values
        default_member = {
            'id': '', 'name': '', 'party': '', 'district': '',
            'description': '', 'imageUrl': '', 'electionPossibility': 0.0,
            'isFavorite': False, 'lastAnalysisDate': None, 'polls': [],
            'pressReports': [], 'achievementsList': [], 'policies': [],
            'improvementPoints': [], 'socialContributions': [],
            'historical2018PartyRates': {}
        }
        
        # Create a new, complete member object
        conformed_member = default_member.copy()
        conformed_member.update(member)
        # --- End Conforming Step ---

        query = f"\"{conformed_member['name']}\" AND \"{conformed_member.get('party', '')}\""
        press_reports = search_news_api(query)
        
        # 키워드 및 상세 내용 분석
        keywords, analysis_data = analyze_text_for_keywords(press_reports)
        
        # Now, update the conformed member object
        conformed_member['id'] = str(conformed_member['id'])
        conformed_member['pressReports'] = press_reports
        conformed_member['lastAnalysisDate'] = datetime.now().strftime('%Y-%m-%d')
        
        # 분석된 데이터로 필드 업데이트
        conformed_member['policies'] = analysis_data.get('policies', [])
        conformed_member['achievementsList'] = analysis_data.get('achievementsList', [])
        conformed_member['improvementPoints'] = analysis_data.get('improvementPoints', [])
        conformed_member['socialContributions'] = analysis_data.get('socialContributions', [])
        
        # SNS 분석 키워드 필드 (가칭 'snsKeywords')가 있다면 여기에 추가
        # conformed_member['snsKeywords'] = keywords

        if 'electionPossibility' not in conformed_member or not isinstance(conformed_member['electionPossibility'], (int, float)):
            conformed_member['electionPossibility'] = 0.0

        updated_members.append(conformed_member)
        print(f"  -> Finished for {member['name']}. Found {len(press_reports)} articles.")
        
        time.sleep(1)

    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(updated_members, f, ensure_ascii=False, indent=2)
        print(f"\nSuccessfully enriched {len(updated_members)} members and saved to {output_file}")
    except Exception as e:
        print(f"\nError saving data to {output_file}: {e}")

if __name__ == "__main__":
    enrich_candidate_data()