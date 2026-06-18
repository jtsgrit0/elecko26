<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET POST PUT DELETE OPTIONS");
header("Access-Control-Allow-Headers: Content-Type Access-Control-Allow-Headers Authorization X-Requested-With");

// OPTIONS 요청 처리 (CORS preflight)
if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") {
    http_response_code(200);
    exit();
}

$servername = "localhost";
$username = "jtsgrit0";
$password = "Ggdrecon3534@!";
$dbname = "jtsgrit0";

// 데이터베이스 연결 생성
$conn = new mysqli($servername, $username, $password, $dbname);

// 연결 확인
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(array("message" => "Connection failed: " . $conn->connect_error));
    exit();
}

// 문자셋 설정
$conn->set_charset("utf8mb4");
?>