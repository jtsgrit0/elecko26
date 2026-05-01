<?php
include_once "db_connect.php";

$method = $_SERVER["REQUEST_METHOD"];

switch ($method) {
    case "GET":
        if (isset($_GET["id"])) {
            // 특정 회원 조회
            $id = $conn->real_escape_string($_GET["id"]);
            $sql = "SELECT id, name, region, party, image_url, description, created_at, updated_at FROM members WHERE id = '$id'";
            $result = $conn->query($sql);
            if ($result->num_rows > 0) {
                echo json_encode($result->fetch_assoc());
            } else {
                http_response_code(404);
                echo json_encode(array("message" => "Member not found."));
            }
        } else {
            // 모든 회원 조회
            $sql = "SELECT id, name, region, party, image_url, description, created_at, updated_at FROM members ORDER BY id DESC";
            $result = $conn->query($sql);
            $members = array();
            while($row = $result->fetch_assoc()) {
                $members[] = $row;
            }
            echo json_encode($members);
        }
        break;

    case "POST":
        // 회원 생성
        $data = json_decode(file_get_contents("php://input"), true);
        $name = $conn->real_escape_string($data["name"]);
        $region = isset($data["region"]) ? $conn->real_escape_string($data["region"]) : null;
        $party = isset($data["party"]) ? $conn->real_escape_string($data["party"]) : null;
        $image_url = isset($data["image_url"]) ? $conn->real_escape_string($data["image_url"]) : null;
        $description = isset($data["description"]) ? $conn->real_escape_string($data["description"]) : null;

        $sql = "INSERT INTO members (name, region, party, image_url, description) VALUES ('$name', '$region', '$party', '$image_url', '$description')";
        if ($conn->query($sql) === TRUE) {
            http_response_code(201);
            echo json_encode(array("message" => "Member created.", "id" => $conn->insert_id));
        } else {
            http_response_code(500);
            echo json_encode(array("message" => "Error: " . $sql . "<br>" . $conn->error));
        }
        break;

    case "PUT":
        // 회원 정보 업데이트
        $data = json_decode(file_get_contents("php://input"), true);
        $id = $conn->real_escape_string($data["id"]);
        $name = $conn->real_escape_string($data["name"]);
        $region = isset($data["region"]) ? $conn->real_escape_string($data["region"]) : null;
        $party = isset($data["party"]) ? $conn->real_escape_string($data["party"]) : null;
        $image_url = isset($data["image_url"]) ? $conn->real_escape_string($data["image_url"]) : null;
        $description = isset($data["description"]) ? $conn->real_escape_string($data["description"]) : null;

        $sql = "UPDATE members SET name='$name', region='$region', party='$party', image_url='$image_url', description='$description' WHERE id = '$id'";
        if ($conn->query($sql) === TRUE) {
            echo json_encode(array("message" => "Member updated."));
        } else {
            http_response_code(500);
            echo json_encode(array("message" => "Error: " . $sql . "<br>" . $conn->error));
        }
        break;

    case "DELETE":
        // 회원 삭제
        $data = json_decode(file_get_contents("php://input"), true);
        $id = $conn->real_escape_string($data["id"]);

        $sql = "DELETE FROM members WHERE id = '$id'";
        if ($conn->query($sql) === TRUE) {
            echo json_encode(array("message" => "Member deleted."));
        } else {
            http_response_code(500);
            echo json_encode(array("message" => "Error: " . $sql . "<br>" . $conn->error));
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(array("message" => "Method not allowed."));
        break;
}

$conn->close();
?>
