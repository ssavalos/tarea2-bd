<?php
include 'db.php';

// Hacemos una consulta simple
$sql = "SHOW TABLES";
$result = $conn->query($sql);

echo "<h1>Prueba de conexión a MySQL</h1>";

if ($result) {
    echo "<p>✅ Conectado correctamente. Tablas encontradas:</p><ul>";
    while ($row = $result->fetch_array()) {
        echo "<li>" . $row[0] . "</li>";
    }
    echo "</ul>";
} else {
    echo "<p>❌ Error en la consulta: " . $conn->error . "</p>";
}

$conn->close();
?>
