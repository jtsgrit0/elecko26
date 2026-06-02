<?php
header('Content-Type: application/json');

// Dothome DB 연결 정보 (db_connect.php 또는 직접 설정)
// 일반적으로 Dothome 내부에서는 'localhost'를 사용합니다.
$servername = "localhost";
$username = "jtsgrit0"; // 사용자님의 DB 사용자 이름
$password = "Ggdrecon3534@!"; // 사용자님의 DB 비밀번호
$dbname = "jtsgrit0"; // 사용자님의 DB 이름

// DB 연결
$conn = new mysqli($servername, $username, $password, $dbname);

// 연결 확인
if ($conn->connect_error) {
    die(json_encode(["error" => "Connection failed: " . $conn->connect_error]));
}

$sql = "SELECT id, name, imageUrl FROM members";
$result = $conn->query($sql);

$members = array();
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $members[] = $row;
    }
}

echo json_encode($members, JSON_UNESCAPED_UNICODE);

$conn->close();
?>