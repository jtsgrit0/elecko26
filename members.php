<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // 모든 도메인 허용 (개발용)
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// DB 연결 정보
$servername = "localhost";
$username = "jtsgrit0";
$password = "Ggdrecon3534@!"; // 제공해주신 비밀번호
$dbname = "jtsgrit0";

// DB 연결
$conn = new mysqli($servername, $username, $password, $dbname);

// 연결 오류 확인
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Database connection failed: " . $conn->connect_error]);
    exit();
}

// 문자 인코딩 설정
$conn->set_charset("utf8mb4");

// 데이터 조회
$sql = "SELECT * FROM members";
$result = $conn->query($sql);

$members = [];

if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // JSON으로 저장된 필드들을 PHP 배열로 디코딩
        $json_fields = ['polls', 'pressReports', 'historical2018PartyRates', 'achievementsList', 'policies', 'improvementPoints', 'socialContributions'];
        foreach ($json_fields as $field) {
            if (isset($row[$field])) {
                $decoded = json_decode($row[$field], true);
                // JSON 디코딩 실패 시 원본 문자열 유지 또는 null 처리
                $row[$field] = ($decoded !== null) ? $decoded : (is_string($row[$field]) ? [] : $row[$field]);
            }
        }

        // isFavorite 필드를 boolean으로 변환
        if (isset($row['isFavorite'])) {
            $row['isFavorite'] = (bool)$row['isFavorite'];
        }

        // lastAnalysisDate 필드를 ISO 8601 형식으로 변환
        if (isset($row['lastAnalysisDate']) && $row['lastAnalysisDate'] !== null) {
            try {
                $row['lastAnalysisDate'] = (new DateTime($row['lastAnalysisDate']))->format(DateTime::ATOM);
            } catch (Exception $e) {
                // 날짜 형식이 잘못된 경우 null 처리
                $row['lastAnalysisDate'] = null;
            }
        }
        
        $members[] = $row;
    }
}

// DB 연결 종료
$conn->close();

// JSON으로 출력
echo json_encode($members, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
?>