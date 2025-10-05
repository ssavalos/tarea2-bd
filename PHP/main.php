<?php
session_start();

// Verificar que el usuario esté logueado
if (!isset($_SESSION['user_id'])) {
    header("Location: index.php");
    exit;
}

$username = $_SESSION['username'];
$rol = $_SESSION['rol'];
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Página Principal - Tarea 2</title>
    <!-- Font Awesome para iconos -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background: #f0f0f0; 
            margin: 0;
            padding: 20px;
        }
        .main-container { 
            background: white; 
            padding: 40px; 
            border-radius: 8px; 
            box-shadow: 0 0 10px rgba(0,0,0,0.2); 
            max-width: 800px;
            margin: 0 auto;
        }
        h1 {
            text-align: center;
            color: #333;
            margin-bottom: 30px;
            font-size: 36px;
        }
        .welcome-message {
            text-align: center;
            font-size: 18px;
            color: #666;
            margin-bottom: 40px;
        }
        .user-info {
            background: #e6ffe6;
            padding: 20px;
            border-radius: 6px;
            border-left: 4px solid #00ff59ff;
            margin-bottom: 30px;
        }
        .user-info h3 {
            margin: 0 0 10px 0;
            color: #00b383b8;
        }
        .user-info p {
            margin: 5px 0;
            color: #555;
        }
        .role-badge {
            display: inline-block;
            background: #00ff59ff;
            color: white;
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 14px;
            font-weight: bold;
            text-transform: capitalize;
        }
        .navigation {
            display: flex;
            gap: 15px;
            justify-content: center;
            margin-top: 30px;
        }
        .nav-button {
            background: #00ff59ff;
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 5px;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            transition: background 0.3s ease;
            font-size: 16px;
        }
        .nav-button:hover {
            background: #00b383b8;
        }
        .logout-button {
            background: #dc3545;
        }
        .logout-button:hover {
            background: #c82333;
        }
        .provisional-note {
            text-align: center;
            color: #999;
            font-style: italic;
            margin-top: 40px;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 5px;
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
            <p><strong>Usuario:</strong> <?php echo htmlspecialchars($username); ?></p>
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