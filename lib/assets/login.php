<?php

header('Content-Type: application/json');

$host = "localhost";
$username = "root";
$password = "";
$dbname = "hkbppond_db2";

$conn = mysqli_connect($host, $username, $password, $dbname);

if (!$conn) {
    echo json_encode(["success" => false, "message" => "Database connection failed"]);
    exit;
}

$userid = $_POST['userid'];
$pass = $_POST['pass'];

// ENKRIPSI MD5 sesuai permintaan Anda
$encrypted_pass = md5($pass);

$sql = "SELECT * FROM tbl_login WHERE userid = '$userid' AND pass = '$encrypted_pass'";
$result = mysqli_query($conn, $sql);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["success" => true, "message" => "Login Berhasil"]);
} else {
    echo json_encode(["success" => false, "message" => "User ID atau Password salah"]);
}

mysqli_close($conn);
?>