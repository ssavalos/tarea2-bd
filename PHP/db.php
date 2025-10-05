<?php

$host = "localhost";
$user = "root";
$pass = "";      // ✅ MAMP usa 'root' como contraseña, xampp usa "" (CAMBIA CUANDO USES)
$db   = "tarea2";
$port = 3306;        // ✅ puerto por defecto de MySQL en MAMP, xampp usa 3306 (CAMBIA CUANDO USES)

$conn = new mysqli($host, $user, $pass, $db, $port);

// Verificar conexión
if ($conn->connect_error) {
    die("Error de conexión: " . $conn->connect_error);
}
// echo "✅ Conectado a MySQL correctamente";
?>
