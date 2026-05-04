<?php
// 최상단에 에러 리포팅을 추가하여 모든 오류를 표시합니다.
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS 및 JSON 헤더를 설정합니다. charset=utf-8을 명시적으로 추가합니다.
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *'); // 모든 도메인에서의 요청을 허용합니다.
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

// 브라우저가 보내는 preflight(사전 확인) 요청에 대한 처리입니다.
// OPTIONS 메소드로 요청이 오면, 헤더만 보내고 즉시 종료합니다.
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// DB 연결 정보
$servername = "localhost";
$username = "jtsgrit0";
$password = "Ggdrecon3534@!";
$dbname = "jtsgrit0";

// DB 연결
$conn = new mysqli($servername, $username, $password, $dbname);

// 연결 오류 확인
if ($conn->connect_error) {
    http_response_code(500);
    // 에러 메시지를 JSON 형식으로 출력합니다.
    echo json_encode(["error" => "Database connection failed: " . $conn->connect_error]);
    exit();
}

// 데이터베이스와의 통신에 사용할 문자 인코딩을 utf8mb4로 설정합니다.
$conn->set_charset("utf8mb4");

// 데이터 조회 SQL
$sql = "SELECT * FROM members";
$result = $conn->query($sql);

// 쿼리 실행 오류 확인
if (!$result) {
    http_response_code(500);
    echo json_encode(["error" => "Query failed: " . $conn->error]);
    $conn->close();
    exit();
}

$members = [];

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // JSON으로 저장된 필드들을 PHP 배열로 디코딩합니다.
        $json_fields = ['polls', 'pressReports', 'historical2018PartyRates', 'achievementsList', 'policies', 'improvementPoints', 'socialContributions'];
        foreach ($json_fields as $field) {
            if (isset($row[$field]) && is_string($row[$field])) {
                $decoded = json_decode($row[$field], true);
                // 디코딩에 실패하면 빈 배열을, 성공하면 디코딩된 배열을 할당합니다.
                $row[$field] = (json_last_error() === JSON_ERROR_NONE) ? $decoded : [];
            }
        }

        // isFavorite 필드를 boolean 값으로 변환합니다.
        if (isset($row['isFavorite'])) {
            $row['isFavorite'] = (bool)$row['isFavorite'];
        }
        
        $members[] = $row;
    }
}

// DB 연결 종료
$conn->close();

// 최종 결과를 JSON으로 출력합니다. 한글이 깨지지 않도록 합니다.
echo json_encode($members, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
?>