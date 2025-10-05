<?php
session_start();
include 'includes/auth_guard.php';
include 'db.php';

// Verificar que sea ingeniero
if ($_SESSION['rol'] !== 'ingeniero') {
    header("Location: userDashboard.php");
    exit;
}

$rut = $_SESSION['rut'];
$nombre = $_SESSION['nombre'];

// Obtener información del ingeniero y sus especialidades
$stmt = $conn->prepare("
    SELECT i.nombre_ing, i.email_ing
    FROM Ingeniero i 
    WHERE i.ing_rut = ?
");
$stmt->bind_param("s", $rut);
$stmt->execute();
$ingeniero_info = $stmt->get_result()->fetch_assoc();

// Obtener especialidades del ingeniero
$stmt = $conn->prepare("
    SELECT t.nombre_topico
    FROM Ingeniero_Especialidad ie
    JOIN Topico t ON ie.id_topico = t.id_topico
    WHERE ie.ing_rut = ?
");
$stmt->bind_param("s", $rut);
$stmt->execute();
$especialidades = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

// Obtener estadísticas de asignaciones de funcionalidades
$stmt = $conn->prepare("
    SELECT 
        COUNT(af.id_funcionalidad) as total_asignadas,
        COUNT(CASE WHEN f.estado_funcion = 'Abierto' THEN 1 END) as funcionalidades_abiertas,
        COUNT(CASE WHEN f.estado_funcion = 'En Progreso' THEN 1 END) as funcionalidades_progreso,
        COUNT(CASE WHEN f.estado_funcion = 'Resuelto' THEN 1 END) as funcionalidades_resueltas,
        COUNT(CASE WHEN f.estado_funcion = 'Cerrado' THEN 1 END) as funcionalidades_cerradas
    FROM Asignacion_Funcionalidad af
    JOIN Funcionalidad f ON af.id_funcionalidad = f.id_funcionalidad
    WHERE af.ing_rut = ?
");
$stmt->bind_param("s", $rut);
$stmt->execute();
$stats_func = $stmt->get_result()->fetch_assoc();

// Obtener estadísticas de asignaciones de errores
$stmt = $conn->prepare("
    SELECT 
        COUNT(ae.id_bug) as total_asignados,
        COUNT(CASE WHEN e.estado_error = 'Abierto' THEN 1 END) as errores_abiertos,
        COUNT(CASE WHEN e.estado_error = 'En Progreso' THEN 1 END) as errores_progreso,
        COUNT(CASE WHEN e.estado_error = 'Resuelto' THEN 1 END) as errores_resueltos,
        COUNT(CASE WHEN e.estado_error = 'Cerrado' THEN 1 END) as errores_cerrados
    FROM Asignacion_Error ae
    JOIN ErrorBug e ON ae.id_bug = e.id_bug
    WHERE ae.ing_rut = ?
");
$stmt->bind_param("s", $rut);
$stmt->execute();
$stats_error = $stmt->get_result()->fetch_assoc();

// Obtener funcionalidades asignadas recientes
$stmt = $conn->prepare("
    SELECT f.id_funcionalidad, f.titulo_funcion, f.estado_funcion, f.fecha_funcion, 
           t.nombre_topico, u.user_nombre
    FROM Asignacion_Funcionalidad af
    JOIN Funcionalidad f ON af.id_funcionalidad = f.id_funcionalidad
    JOIN Topico t ON f.id_topico = t.id_topico
    JOIN Usuario u ON f.user_rut = u.user_rut
    WHERE af.ing_rut = ?
    ORDER BY f.fecha_funcion DESC
    LIMIT 5
");
$stmt->bind_param("s", $rut);
$stmt->execute();
$funcionalidades_asignadas = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

// Obtener errores asignados recientes
$stmt = $conn->prepare("
    SELECT e.id_bug, e.titulo_error, e.estado_error, e.fecha_error, 
           t.nombre_topico, u.user_nombre
    FROM Asignacion_Error ae
    JOIN ErrorBug e ON ae.id_bug = e.id_bug
    JOIN Topico t ON e.id_topico = t.id_topico
    JOIN Usuario u ON e.user_rut = u.user_rut
    WHERE ae.ing_rut = ?
    ORDER BY e.fecha_error DESC
    LIMIT 5
");
$stmt->bind_param("s", $rut);
$stmt->execute();
$errores_asignados = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

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
        .estado-enprogreso { background: #cce5ff; color: #004085; }
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
        
        .especialidades {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-top: 10px;
        }
        
        .especialidad-badge {
            background: var(--primary-blue);
            color: white;
            padding: 4px 12px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: bold;
        }
        
        .engineer-info {
            background: rgba(255, 255, 255, 0.9);
            backdrop-filter: blur(10px);
            padding: 20px;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="main-container">
        
        <div class="engineer-info">
            <div class="item-info">
                <div class="item-title">¡Bienvenido, <?php echo htmlspecialchars($nombre); ?>!</div>
                <div class="item-meta">
                    RUT: <?php echo htmlspecialchars($rut); ?> | Rol: Ingeniero
                    <?php if ($ingeniero_info): ?>
                        | Email: <?php echo htmlspecialchars($ingeniero_info['email_ing']); ?>
                    <?php endif; ?>
                </div>
                <?php if (!empty($especialidades)): ?>
                    <div class="especialidades">
                        <strong>Especialidades:</strong>
                        <?php foreach ($especialidades as $esp): ?>
                            <span class="especialidad-badge">
                                <?php echo htmlspecialchars($esp['nombre_topico']); ?>
                            </span>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
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
