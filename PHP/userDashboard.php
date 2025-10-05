<?php
session_start();
include 'includes/auth_guard.php';
include 'db.php';

// Verificar que sea usuario
if ($_SESSION['rol'] !== 'usuario') {
    header("Location: ingDashboard.php");
    exit;
}

$rut = $_SESSION['rut'];
$nombre = $_SESSION['nombre'];

// Obtener estadísticas del usuario
$stmt = $conn->prepare("
    SELECT 
        COUNT(f.id_funcionalidad) as total_funcionalidades,
        COUNT(CASE WHEN f.estado_funcion = 'Abierto' THEN 1 END) as funcionalidades_abiertas,
        COUNT(CASE WHEN f.estado_funcion = 'En Progreso' THEN 1 END) as funcionalidades_progreso,
        COUNT(CASE WHEN f.estado_funcion = 'Resuelto' THEN 1 END) as funcionalidades_resueltas,
        COUNT(CASE WHEN f.estado_funcion = 'Cerrado' THEN 1 END) as funcionalidades_cerradas
    FROM Funcionalidad f 
    WHERE f.user_rut = ?
");
$stmt->bind_param("s", $rut);
$stmt->execute();
$stats_func = $stmt->get_result()->fetch_assoc();

$stmt = $conn->prepare("
    SELECT 
        COUNT(e.id_bug) as total_errores,
        COUNT(CASE WHEN e.estado_error = 'Abierto' THEN 1 END) as errores_abiertos,
        COUNT(CASE WHEN e.estado_error = 'En Progreso' THEN 1 END) as errores_progreso,
        COUNT(CASE WHEN e.estado_error = 'Resuelto' THEN 1 END) as errores_resueltos,
        COUNT(CASE WHEN e.estado_error = 'Cerrado' THEN 1 END) as errores_cerrados
    FROM ErrorBug e 
    WHERE e.user_rut = ?
");
$stmt->bind_param("s", $rut);
$stmt->execute();
$stats_error = $stmt->get_result()->fetch_assoc();

// Obtener funcionalidades recientes
$stmt = $conn->prepare("
    SELECT f.id_funcionalidad, f.titulo_funcion, f.estado_funcion, f.fecha_funcion, t.nombre_topico
    FROM Funcionalidad f
    JOIN Topico t ON f.id_topico = t.id_topico
    WHERE f.user_rut = ?
    ORDER BY f.fecha_funcion DESC
    LIMIT 5
");
$stmt->bind_param("s", $rut);
$stmt->execute();
$funcionalidades_recientes = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

// Obtener errores recientes
$stmt = $conn->prepare("
    SELECT e.id_bug, e.titulo_error, e.estado_error, e.fecha_error, t.nombre_topico
    FROM ErrorBug e
    JOIN Topico t ON e.id_topico = t.id_topico
    WHERE e.user_rut = ?
    ORDER BY e.fecha_error DESC
    LIMIT 5
");
$stmt->bind_param("s", $rut);
$stmt->execute();
$errores_recientes = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$page_title = "ZeroPressure";
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title><?php echo $page_title; ?></title>
    <!-- Font Awesome para iconos -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Estilos comunes -->
    <link rel="stylesheet" href="assets/css/style.css">
    <style>
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stats-card {
            background: rgba(255, 255, 255, 0.9);
            backdrop-filter: blur(10px);
            padding: 20px;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
        }
        
        .stats-card h3 {
            margin: 0 0 15px 0;
            color: var(--primary-blue);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .stat-item {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid rgba(0, 0, 0, 0.1);
        }
        
        .stat-item:last-child {
            border-bottom: none;
        }
        
        .stat-value {
            font-weight: bold;
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 14px;
        }
        
        .estado-abierto { background: #fff3cd; color: #856404; }
        .estado-progreso { background: #cce5ff; color: #004085; }
        .estado-resuelto { background: #d4edda; color: #155724; }
        .estado-cerrado { background: #e2e3e5; color: #495057; }
        
        .recent-items {
            background: rgba(255, 255, 255, 0.9);
            backdrop-filter: blur(10px);
            padding: 20px;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
        }
        
        .recent-items h3 {
            margin: 0 0 15px 0;
            color: var(--primary-blue);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .item-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        
        .item-list li {
            padding: 10px 0;
            border-bottom: 1px solid rgba(0, 0, 0, 0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .item-list li:last-child {
            border-bottom: none;
        }
        
        .item-info {
            flex: 1;
        }
        
        .item-title {
            font-weight: bold;
            color: #333;
            margin-bottom: 4px;
        }
        
        .item-meta {
            font-size: 12px;
            color: #666;
        }
        
        .quick-actions {
            display: flex;
            gap: 15px;
            justify-content: center;
            margin-top: 30px;
            flex-wrap: wrap;
        }
        
        .action-btn {
            background: var(--primary-blue);
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            font-size: 14px;
            font-weight: bold;
        }
        
        .action-btn:hover {
            background: var(--primary-blue-hover);
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 89, 255, 0.3);
        }
        
        .action-btn.secondary {
            background: #6c757d;
        }
        
        .action-btn.secondary:hover {
            background: #545b62;
        }
        
        .empty-state {
            text-align: center;
            color: #666;
            font-style: italic;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="main-container">
        
        <div class="user-info">
            <div class="item-info">
                <div class="item-title">¡Bienvenido, <?php echo htmlspecialchars($nombre); ?>!</div>
                <div class="item-meta">RUT: <?php echo htmlspecialchars($rut); ?> | Rol: Usuario</div>
            </div>
        </div>
        
        <div class="dashboard-grid">
           
            
            
        
        
        <!-- Acciones Rápidas -->
        <div class="quick-actions">
            <a href="logout.php" class="action-btn secondary">
                <i class="fas fa-sign-out-alt"></i> Cerrar Sesión
            </a>
        </div>
    </div>
</body>
</html>
