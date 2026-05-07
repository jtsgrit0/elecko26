import json
from datetime import datetime
import requests
import time
import urllib.parse
import uuid

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
                # PressReport 모델 형식에 맞게 데이터 변환
                articles.append({
                    "id": str(uuid.uuid4()), # 고유 ID 생성
                    "title": str(article.get('title', '')),
                    "source": str(article.get('source', {}).get('name', '')),
                    "url": str(article.get('url', '')),
                    "publishDate": str(article.get('publishedAt', datetime.now().isoformat())),
                    "summary": str(article.get('description', '')),
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
        
        # Now, update the conformed member object
        conformed_member['id'] = str(conformed_member['id'])
        conformed_member['pressReports'] = press_reports
        conformed_member['lastAnalysisDate'] = datetime.now().strftime('%Y-%m-%d')
        
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