<?php
session_start();

// Verificar que el usuario esté logueado
if (!isset($_SESSION['user_id'])) {
    header("Location: index.php");
    exit;
}

$rut = $_SESSION['rut'];
$nombre = $_SESSION['nombre'];
$rol = $_SESSION['rol'];
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Página Principal - Tarea 2</title>
    <!-- Font Awesome para iconos -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Estilos comunes -->
    <link rel="stylesheet" href="assets/css/style.css">
    <style>
        /* Estilos específicos para main */
        .provisional-note {
            text-align: center;
            color: #999;
            font-style: italic;
            margin-top: 40px;
            padding: 20px;
            background: rgba(248, 249, 250, 0.8);
            border-radius: 5px;
            backdrop-filter: blur(5px);
        }
    </style>
</head>
<body>
    <div class="main-container">
        <h1><i class="fas fa-home"></i> Bienvenido</h1>
        
        <div class="welcome-message">
            <p>Esta es la página principal</p>
        </div>
        
        <div class="user-info">
            <h3><i class="fas fa-user"></i> Información de la sesión</h3>
            <p><strong>RUT:</strong> <?php echo htmlspecialchars($rut); ?></p>
            <p><strong>Nombre:</strong> <?php echo htmlspecialchars($nombre); ?></p>
            <p><strong>Rol:</strong> <span class="role-badge"><?php echo htmlspecialchars($rol); ?></span></p>
        </div>
        
        <div class="navigation">
            <?php if ($rol === 'ingeniero'): ?>
                <a href="ingDashboard.php" class="nav-button">
                    <i class="fas fa-cog"></i> Dashboard Ingeniero
                </a>
            <?php else: ?>
                <a href="userDashboard.php" class="nav-button">
                    <i class="fas fa-user-circle"></i> Dashboard Usuario
                </a>
            <?php endif; ?>
            
            <a href="logout.php" class="nav-button logout-button">
                <i class="fas fa-sign-out-alt"></i> Cerrar Sesión
            </a>
        </div>
        
        <div class="provisional-note">
            <p><i class="fas fa-info-circle"></i> Nota: Esta es una página principal provisional.</p>
            <p>Aquí se puede agregar más contenido según las necesidades del proyecto.</p>
        </div>
    </div>
</body>
</html>