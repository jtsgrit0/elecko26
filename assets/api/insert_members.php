<?php
// 에러 리포팅 활성화 (개발 중에만 사용)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// 에러 핸들러 설정
function exception_handler($exception) {
    http_response_code(500);
    echo json_encode([
        'error' => 'PHP Exception',
        'message' => $exception->getMessage(),
        'file' => $exception->getFile(),
        'line' => $exception->getLine()
    ]);
    exit();
}
set_exception_handler('exception_handler');

function error_handler($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
}
set_error_handler("error_handler");


header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Migration-Secret, X-Migration-Action');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

try {
    $expected_secret = 'elecko26-migration-secret-key';
    $provided_secret = $_SERVER['HTTP_X_MIGRATION_SECRET'] ?? '';
    if ($provided_secret !== $expected_secret) {
        http_response_code(403);
        echo json_encode(['error' => 'Forbidden: Invalid or missing secret key.']);
        exit();
    }

    $servername = "localhost";
    $username = "jtsgrit0";
    $password = "Ggdrecon3534@!";
    $dbname = "jtsgrit0";
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['error' => 'Database connection failed: ' . $conn->connect_error]);
        exit();
    }
    $conn->set_charset("utf8mb4");

    $migration_action = $_SERVER['HTTP_X_MIGRATION_ACTION'] ?? '';
    if ($migration_action === 'start') {
        $conn->query("TRUNCATE TABLE members");
    }

    $json_data = file_get_contents('php://input');
    $members = json_decode($json_data, true);

    if (empty($members) || !is_array($members)) {
        $conn->close();
        http_response_code(200);
        echo json_encode(['status' => 'No data received, but connection was OK.']);
        exit();
    }

    $stmt = $conn->prepare(
        "INSERT INTO members (id, name, party, district, description, imageUrl, polls, electionPossibility, isFavorite, pressReports, historical2018PartyRates, lastAnalysisDate, achievementsList, policies, improvementPoints, socialContributions) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    );

    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['error' => 'Statement preparation failed: ' . $conn->error]);
        $conn->close();
        exit();
    }

    $inserted_count = 0;
    $error_count = 0;
    $errors = [];

    foreach ($members as $member) {
        $polls = json_encode($member['polls'] ?? [], JSON_UNESCAPED_UNICODE);
        $pressReports = json_encode($member['pressReports'] ?? [], JSON_UNESCAPED_UNICODE);
        $historical2018PartyRates = json_encode($member['historical2018PartyRates'] ?? [], JSON_UNESCAPED_UNICODE);
        $achievementsList = json_encode($member['achievementsList'] ?? [], JSON_UNESCAPED_UNICODE);
        $policies = json_encode($member['policies'] ?? [], JSON_UNESCAPED_UNICODE);
        $improvementPoints = json_encode($member['improvementPoints'] ?? [], JSON_UNESCAPED_UNICODE);
        $socialContributions = json_encode($member['socialContributions'] ?? [], JSON_UNESCAPED_UNICODE);
        $isFavoriteInt = isset($member['isFavorite']) && $member['isFavorite'] ? 1 : 0;
        $lastAnalysisDate = $member['lastAnalysisDate'] ?? null;

        $stmt->bind_param(
            "ssssssdissssssss",
            $member['id'],
            $member['name'],
            $member['party'],
            $member['district'],
            $member['description'],
            $member['imageUrl'],
            $polls,
            $member['electionPossibility'],
            $isFavoriteInt,
            $pressReports,
            $historical2018PartyRates,
            $lastAnalysisDate,
            $achievementsList,
            $policies,
            $improvementPoints,
            $socialContributions
        );

        if ($stmt->execute()) {
            $inserted_count++;
        } else {
            $error_count++;
            $errors[] = ['id' => $member['id'], 'error' => $stmt->error];
        }
    }

    $stmt->close();
    $conn->close();

    http_response_code(200);
    echo json_encode([
        'inserted_count' => $inserted_count,
        'error_count' => $error_count,
        'errors' => $errors
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'PHP Exception',
        'message' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}
?>