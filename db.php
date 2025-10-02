<?php
// db.php → conexión a MySQL con mysqli

$host = "localhost";   // Servidor de MySQL (en XAMPP es siempre localhost)
$user = "root";        // Usuario por defecto en XAMPP
$pass = "";            // Contraseña (en XAMPP normalmente está en blanco)
$db   = "tarea2";      // Nombre de la base de datos que crearás en phpMyAdmin

$conn = new mysqli($host, $user, $pass, $db);

// Verificar conexión
if ($conn->connect_error) {
    die("Error de conexión: " . $conn->connect_error);
}
//echo "✅ Conectado a MySQL correctamente"; // úsalo para probar
?>
