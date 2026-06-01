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
  <?php
include_once "db_connect.php";

$method = $_SERVER["REQUEST_METHOD"];

switch ($me  incl
$method = $_SERVER["REQUEST
  
switch ($method) {
    case "GET":
        case "GET":
k;        if (isseT\            // 특정 회원 ?     \            $id = $conn->real_esnt            $sql = "SELECT id, name, region, party, image_upe            $result = $conn->query($sql);
            if ($result->num_rows > 0) {
                echo json_encode($result->fet              if ($result->num_rows > 0) {
 nn                echo json_encode($resul:             } else {
                http_response_code(4?                 htt_s                echo json_encode(array(              }
        } else {
            // 모든 회원 조회
          ng        } eesc            // ul            $sql = "SELECT id, nme            $result = $conn->query($sql);
  <?php
include_once "db_connect.php";

$method = $_SERVER["REQUEST_METHOD"];

sw    <?php
include_once "db_connect.php";

\  includht
$method = $_SERVER["REQUEST   
switch ($me  incl
$method = $_SERVMe$method = $_SERVEid
