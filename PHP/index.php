// aqui va el home + buscador simple

<?php
include 'db.php';

// Hacer una consulta simple
$sql = "SHOW TABLES";
$result = $conn->query($sql);
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Inicio Tarea 2</title>
</head>
<body>
    <h1>Bienvenido a Tarea 2</h1>
    <p>Conexión con MySQL lista ✅</p>

    <h2>Tablas en la BD:</h2>
    <ul>
        <?php
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_array()) {
                echo "<li>" . $row[0] . "</li>";
            }
        } else {
            echo "<li>No hay tablas aún</li>";
        }
        ?>
    </ul>
</body>
</html>
