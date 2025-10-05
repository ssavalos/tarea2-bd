<?php
// db.php → conexión a MySQL con mysqli (versión para MAMP)

$host = "localhost";
$user = "root";
$pass = "root";      // ✅ MAMP usa 'root' como contraseña
$db   = "tarea2";
$port = 8889;        // ✅ puerto por defecto de MySQL en MAMP

$conn = new mysqli($host, $user, $pass, $db, $port);

// Verificar conexión
if ($conn->connect_error) {
    die("Error de conexión: " . $conn->connect_error);
}
// echo "✅ Conectado a MySQL correctamente";
?>
