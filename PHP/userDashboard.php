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
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 20px;
            margin-top: 15px;
        }
        
        .stat-item {
            text-align: center;
            padding: 15px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 8px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .stat-number {
            font-size: 24px;
            font-weight: bold;
            color: var(--primary-blue);
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .item-actions {
            display: flex;
            gap: 5px;
        }
        
        .action-btn-small {
            background: var(--primary-blue);
            color: white;
            padding: 6px 10px;
            border: none;
            border-radius: 4px;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            cursor: pointer;
            transition: all 0.3s ease;
            font-size: 12px;
        }
        
        .action-btn-small:hover {
            background: var(--primary-blue-hover);
            transform: translateY(-1px);
        }
        
        .status-abierto { color: #dc3545; font-weight: bold; }
        .status-en-progreso { color: #fd7e14; font-weight: bold; }
        .status-resuelto { color: #28a745; font-weight: bold; }
        .status-cerrado { color: #6c757d; font-weight: bold; }
        
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .empty-state i {
            font-size: 48px;
            color: #ccc;
            margin-bottom: 15px;
        }
        
        .empty-state p {
            margin-bottom: 15px;
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
            <!-- Estadísticas Rápidas -->
            <div class="glass-card">
                <h3><i class="fas fa-chart-line"></i> Mis Estadísticas</h3>
                <div class="stats-grid">
                    <?php
                    // Contar funcionalidades del usuario
                    $stmt_func = $conn->prepare("SELECT COUNT(*) as total, estado_funcion FROM Funcionalidad WHERE user_rut = ? GROUP BY estado_funcion");
                    $stmt_func->bind_param("s", $rut);
                    $stmt_func->execute();
                    $result_func = $stmt_func->get_result();
                    $func_stats = $result_func ? $result_func->fetch_all(MYSQLI_ASSOC) : [];
                    
                    $func_totals = ['Abierto' => 0, 'En Progreso' => 0, 'Resuelto' => 0, 'Cerrado' => 0];
                    foreach ($func_stats as $stat) {
                        $func_totals[$stat['estado_funcion']] = $stat['total'];
                    }
                    
                    // Contar errores del usuario
                    $stmt_error = $conn->prepare("SELECT COUNT(*) as total, estado_error FROM ErrorBug WHERE user_rut = ? GROUP BY estado_error");
                    $stmt_error->bind_param("s", $rut);
                    $stmt_error->execute();
                    $result_error = $stmt_error->get_result();
                    $error_stats = $result_error ? $result_error->fetch_all(MYSQLI_ASSOC) : [];
                    
                    $error_totals = ['Abierto' => 0, 'En Progreso' => 0, 'Resuelto' => 0, 'Cerrado' => 0];
                    foreach ($error_stats as $stat) {
                        $error_totals[$stat['estado_error']] = $stat['total'];
                    }
                    
                    $total_func = array_sum($func_totals);
                    $total_errors = array_sum($error_totals);
                    ?>
                    <div class="stat-item">
                        <div class="stat-number"><?php echo $total_func; ?></div>
                        <div class="stat-label">Funcionalidades</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number"><?php echo $total_errors; ?></div>
                        <div class="stat-label">Errores Reportados</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number"><?php echo $func_totals['Resuelto'] + $error_totals['Resuelto']; ?></div>
                        <div class="stat-label">Resueltos</div>
                    </div>
                </div>
            </div>

            <!-- Mis Funcionalidades Recientes -->
            <div class="glass-card">
                <h3><i class="fas fa-cogs"></i> Mis Funcionalidades Recientes</h3>
                <?php
                $stmt_recent_func = $conn->prepare("
                    SELECT f.*, t.nombre_topico 
                    FROM Funcionalidad f 
                    JOIN Topico t ON f.id_topico = t.id_topico 
                    WHERE f.user_rut = ? 
                    ORDER BY f.fecha_funcion DESC 
                    LIMIT 5
                ");
                $stmt_recent_func->bind_param("s", $rut);
                $stmt_recent_func->execute();
                $result_recent_func = $stmt_recent_func->get_result();
                $recent_funcs = $result_recent_func ? $result_recent_func->fetch_all(MYSQLI_ASSOC) : [];
                
                if ($recent_funcs): ?>
                    <ul class="item-list">
                        <?php foreach ($recent_funcs as $func): ?>
                        <li>
                            <div class="item-info">
                                <div class="item-title"><?php echo htmlspecialchars($func['titulo_funcion']); ?></div>
                                <div class="item-meta">
                                    <?php echo htmlspecialchars($func['nombre_topico']); ?> | 
                                    <span class="status-<?php echo strtolower(str_replace(' ', '-', $func['estado_funcion'])); ?>">
                                        <?php echo $func['estado_funcion']; ?>
                                    </span> | 
                                    <?php echo date('d/m/Y', strtotime($func['fecha_funcion'])); ?>
                                </div>
                            </div>
                            <div class="item-actions">
                                <a href="funcionalidad/editar.php?id=<?php echo $func['id_funcionalidad']; ?>" class="action-btn-small">
                                    <i class="fas fa-edit"></i>
                                </a>
                            </div>
                        </li>
                        <?php endforeach; ?>
                    </ul>
                <?php else: ?>
                    <div class="empty-state">
                        <i class="fas fa-inbox"></i>
                        <p>No tienes funcionalidades registradas aún.</p>
                        <a href="funcionalidad/crear.php" class="action-btn">
                            <i class="fas fa-plus"></i> Crear Primera Funcionalidad
                        </a>
                    </div>
                <?php endif; ?>
            </div>

            <!-- Mis Errores Recientes -->
            <div class="glass-card">
                <h3><i class="fas fa-bug"></i> Mis Errores Recientes</h3>
                <?php
                $stmt_recent_errors = $conn->prepare("
                    SELECT e.*, t.nombre_topico 
                    FROM ErrorBug e 
                    JOIN Topico t ON e.id_topico = t.id_topico 
                    WHERE e.user_rut = ? 
                    ORDER BY e.fecha_error DESC 
                    LIMIT 5
                ");
                $stmt_recent_errors->bind_param("s", $rut);
                $stmt_recent_errors->execute();
                $result_recent_errors = $stmt_recent_errors->get_result();
                $recent_errors = $result_recent_errors ? $result_recent_errors->fetch_all(MYSQLI_ASSOC) : [];
                
                if ($recent_errors): ?>
                    <ul class="item-list">
                        <?php foreach ($recent_errors as $error): ?>
                        <li>
                            <div class="item-info">
                                <div class="item-title"><?php echo htmlspecialchars($error['titulo_error']); ?></div>
                                <div class="item-meta">
                                    <?php echo htmlspecialchars($error['nombre_topico']); ?> | 
                                    <span class="status-<?php echo strtolower(str_replace(' ', '-', $error['estado_error'])); ?>">
                                        <?php echo $error['estado_error']; ?>
                                    </span> | 
                                    <?php echo date('d/m/Y', strtotime($error['fecha_error'])); ?>
                                </div>
                            </div>
                            <div class="item-actions">
                                <a href="error/editar.php?id=<?php echo $error['id_bug']; ?>" class="action-btn-small">
                                    <i class="fas fa-edit"></i>
                                </a>
                            </div>
                        </li>
                        <?php endforeach; ?>
                    </ul>
                <?php else: ?>
                    <div class="empty-state">
                        <i class="fas fa-inbox"></i>
                        <p>No tienes errores reportados aún.</p>
                        <a href="error/crear.php" class="action-btn">
                            <i class="fas fa-plus"></i> Reportar Primer Error
                        </a>
                    </div>
                <?php endif; ?>
            </div>
        </div>
        
        <!-- Acciones Rápidas -->
        <div class="quick-actions">
            <a href="funcionalidad/crear.php" class="action-btn">
                <i class="fas fa-plus"></i> Nueva Funcionalidad
            </a>
            <a href="error/crear.php" class="action-btn">
                <i class="fas fa-plus"></i> Reportar Error
            </a>
            <a href="funcionalidad/listar.php" class="action-btn">
                <i class="fas fa-cogs"></i> Ver Todas las Funcionalidades
            </a>
            <a href="error/listar.php" class="action-btn">
                <i class="fas fa-bug"></i> Ver Todos los Errores
            </a>
            <a href="logout.php" class="action-btn secondary">
                <i class="fas fa-sign-out-alt"></i> Cerrar Sesión
            </a>
        </div>
    </div>
</body>
</html>
