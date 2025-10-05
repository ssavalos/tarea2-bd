<?php
// Verificar que el usuario esté autenticado
if (!isset($_SESSION['user_id']) || !isset($_SESSION['rut']) || !isset($_SESSION['rol'])) {
    // Redirigir al login si no está autenticado
    header("Location: index.php");
    exit;
}
?>