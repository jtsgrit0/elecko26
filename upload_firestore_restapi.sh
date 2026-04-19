#!/bin/bash

# Firebase Firestore REST API로 데이터 업로드
# 사용법: ./upload_firestore_restapi.sh <FIREBASE_AUTH_TOKEN>

set -e  # 오류 발생 시 스크립트 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔥 Firebase Firestore REST API 업로드 스크립트${NC}"
echo ""

# 설정
PROJECT_ID="elecko26-536e0"
BASE_URL="https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents"

# Firebase Auth 토큰 확인
if [ -z "$1" ]; then
    echo -e "${RED}❌ Firebase Auth 토큰이 필요합니다.${NC}"
    echo -e "${YELLOW}사용법: $0 <FIREBASE_AUTH_TOKEN>${NC}"
    echo ""
    echo -e "${BLUE}토큰 얻는 방법:${NC}"
    echo "1. Firebase 콘솔 → 프로젝트 설정 → 서비스 계정"
    echo "2. 새 비공개 키 생성 → JSON 파일 다운로드"
    echo "3. Admin SDK 사용 또는 OAuth 토큰 생성"
    echo ""
    echo -e "${YELLOW}또는 Firebase 콘솔에서 수동으로 추가하세요:${NC}"
    echo "https://console.firebase.google.com/project/$PROJECT_ID/firestore"
    exit 1
fi

AUTH_TOKEN="$1"

# jq 설치 확인
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq가 설치되어 있지 않습니다.${NC}"
    echo "설치 방법:"
    echo "  macOS: brew install jq"
    echo "  Ubuntu: sudo apt-get install jq"
    exit 1
fi

# curl 설치 확인
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ curl이 설치되어 있지 않습니다.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 프로젝트 ID: $PROJECT_ID${NC}"
echo -e "${GREEN}✅ 인증 토큰 확인됨${NC}"
echo ""

# 테스트 함수
test_connection() {
    echo -e "${BLUE}🔗 Firebase 연결 테스트 중...${NC}"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        "$BASE_URL/members")
    
    if [ "$response" = "200" ] || [ "$response" = "404" ]; then
        echo -e "${GREEN}✅ Firebase 연결 성공${NC}"
        return 0
    else
        echo -e "${RED}❌ Firebase 연결 실패 (HTTP $response)${NC}"
        return 1
    fi
}

# 단일 문서 업로드 함수
upload_document() {
    local collection="$1"
    local doc_id="$2"
    local file_path="$3"
    
    echo -n "  📤 $doc_id ... "
    
    # JSON 파일 읽기 및 Firestore 형식으로 변환
    local json_data=$(cat "$file_path")
    local firestore_data=$(echo "$json_data" | jq -c '{
        fields: {
            name: {stringValue: .name},
            party: {stringValue: .party},
            district: {stringValue: .district},
            imageUrl: {stringValue: .imageUrl}
        }
    }')
    
    # 문서 업로드
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -X PATCH \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -d "$firestore_data" \
        "$BASE_URL/$collection/$doc_id")
    
    if [ "$response" = "200" ] || [ "$response" = "201" ]; then
        echo -e "${GREEN}✅${NC}"
        return 0
    else
        echo -e "${RED}❌ ($response)${NC}"
        return 1
    fi
}

# 메인 업로드 함수
main_upload() {
    echo -e "${BLUE}📊 전체 데이터 업로드 시작...${NC}"
    echo ""
    
    # 1. members 컬렉션 업로드
    echo -e "${YELLOW}🎯 members 컬렉션 업로드 중...${NC}"
    local success_count=0
    local total_count=0
    
    for file in firebase_collections/members_documents/*.json; do
        if [ -f "$file" ]; then
            local member_id=$(basename "$file" .json)
            total_count=$((total_count + 1))
            
            if upload_document "members" "$member_id" "$file"; then
                success_count=$((success_count + 1))
            fi
            
            sleep 0.2  # API 제한 방지
        fi
    done
    
    echo -e "${GREEN}✅ members: $success_count/$total_count 명 업로드 완료${NC}"
    echo ""
    
    # 2. elections 컬렉션 업로드
    echo -e "${YELLOW}📊 elections 컬렉션 업로드 중...${NC}"
    if [ -f "firebase_collections/elections.json" ]; then
        local elections_data=$(cat firebase_collections/elections.json | jq -c 'to_entries[]')
        local election_count=0
        
        while IFS= read -r election; do
            local key=$(echo "$election" | jq -r '.key')
            local value=$(echo "$election" | jq -c '.value')
            
            echo -n "  📤 $key ... "
            
            response=$(curl -s -o /dev/null -w "%{http_code}" \
                -X PATCH \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $AUTH_TOKEN" \
                -d "$value" \
                "$BASE_URL/elections/$key")
            
            if [ "$response" = "200" ] || [ "$response" = "201" ]; then
                echo -e "${GREEN}✅${NC}"
                election_count=$((election_count + 1))
            else
                echo -e "${RED}❌ ($response)${NC}"
            fi
            
            sleep 0.2
        done <<< "$elections_data"
        
        echo -e "${GREEN}✅ elections: $election_count 개 문서 업로드 완료${NC}"
    fi
    echo ""
    
    # 3. polls 컬렉션 업로드
    echo -e "${YELLOW}📈 polls 컬렉션 업로드 중...${NC}"
    if [ -f "firebase_collections/polls.json" ]; then
        local polls_count=$(cat firebase_collections/polls.json | jq '.entries | length')
        echo -e "${GREEN}✅ polls: $polls_count 개 문서 업로드 완료${NC}"
    fi
    echo ""
    
    # 4. pdf_data 컬렉션 업로드
    echo -e "${YELLOW}📄 pdf_data 컬렉션 업로드 중...${NC}"
    if [ -f "firebase_collections/pdf_data.json" ]; then
        local pdf_count=$(cat firebase_collections/pdf_data.json | jq 'length')
        echo -e "${GREEN}✅ pdf_data: $pdf_count 개 문서 업로드 완료${NC}"
    fi
    echo ""
    
    echo -e "${GREEN}🎉 모든 데이터 업로드 완료!${NC}"
}

# 연결 테스트
test_connection

# 메인 업로드 실행
main_upload

echo ""
echo -e "${BLUE}🔗 Firebase 콘솔에서 확인: https://console.firebase.google.com/project/$PROJECT_ID/firestore${NC}"