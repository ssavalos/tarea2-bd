<?php
// logout.php
session_start();

// Limpiar todas las variables de sesión
$_SESSION = [];

// Destruir la sesión
session_destroy();

// Redirigir al index con mensaje de logout
header("Location: index.php?logout=success");
exit;
?>
