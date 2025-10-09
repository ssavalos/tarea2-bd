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


$ingeniero_info = null;
$especialidades = [];

$stmt = $conn->prepare("SELECT nombre_ing, email_ing FROM Ingeniero WHERE ing_rut = ?");
if ($stmt) {
    $stmt->bind_param("s", $rut);
    if ($stmt->execute()) {
        $result = $stmt->get_result();
        $ingeniero_info = $result ? $result->fetch_assoc() : null;
    }
    $stmt->close();
}

$stmt = $conn->prepare("\n    SELECT t.nombre_topico\n    FROM Ingeniero_Especialidad ie\n    INNER JOIN Topico t ON ie.id_topico = t.id_topico\n    WHERE ie.ing_rut = ?\n");
if ($stmt) {
    $stmt->bind_param("s", $rut);
    if ($stmt->execute()) {
        $result = $stmt->get_result();
        $especialidades = $result ? $result->fetch_all(MYSQLI_ASSOC) : [];
    }
    $stmt->close();
}


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
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
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
            font-size: 11px;
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
        
        <div class="engineer-info">
            <div class="item-info">
                <div class="item-title">¡Bienvenido, <?php echo htmlspecialchars($ingeniero_info ? $ingeniero_info['nombre_ing'] : $nombre); ?>!</div>
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
            <!-- Estadísticas del Ingeniero -->
            <div class="recent-items">
                <h3><i class="fas fa-chart-line"></i> Mis Asignaciones</h3>
                <div class="stats-grid">
                    <?php
                    // Contar funcionalidades asignadas al ingeniero
                    $stmt_func = $conn->prepare("
                        SELECT COUNT(*) as total, f.estado_funcion 
                        FROM Asignacion_Funcionalidad af 
                        JOIN Funcionalidad f ON af.id_funcionalidad = f.id_funcionalidad 
                        WHERE af.ing_rut = ? 
                        GROUP BY f.estado_funcion
                    ");
                    $func_stats = [];
                    if ($stmt_func) {
                        $stmt_func->bind_param("s", $rut);
                        if ($stmt_func->execute()) {
                            $result = $stmt_func->get_result();
                            $func_stats = $result ? $result->fetch_all(MYSQLI_ASSOC) : [];
                        }
                        $stmt_func->close();
                    }
                    
                    $func_totals = ['Abierto' => 0, 'En Progreso' => 0, 'Resuelto' => 0, 'Cerrado' => 0];
                    foreach ($func_stats as $stat) {
                        $func_totals[$stat['estado_funcion']] = $stat['total'];
                    }
                    
                    // Contar errores asignados al ingeniero
                    $stmt_error = $conn->prepare("
                        SELECT COUNT(*) as total, e.estado_error 
                        FROM Asignacion_Error ae 
                        JOIN ErrorBug e ON ae.id_bug = e.id_bug 
                        WHERE ae.ing_rut = ? 
                        GROUP BY e.estado_error
                    ");
                    $error_stats = [];
                    if ($stmt_error) {
                        $stmt_error->bind_param("s", $rut);
                        if ($stmt_error->execute()) {
                            $result = $stmt_error->get_result();
                            $error_stats = $result ? $result->fetch_all(MYSQLI_ASSOC) : [];
                        }
                        $stmt_error->close();
                    }
                    
                    $error_totals = ['Abierto' => 0, 'En Progreso' => 0, 'Resuelto' => 0, 'Cerrado' => 0];
                    foreach ($error_stats as $stat) {
                        $error_totals[$stat['estado_error']] = $stat['total'];
                    }
                    
                    $total_func = array_sum($func_totals);
                    $total_errors = array_sum($error_totals);
                    ?>
                    <div class="stat-item">
                        <div class="stat-number"><?php echo $total_func; ?></div>
                        <div class="stat-label">Funcionalidades Asignadas</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number"><?php echo $total_errors; ?></div>
                        <div class="stat-label">Errores Asignados</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number"><?php echo $func_totals['En Progreso'] + $error_totals['En Progreso']; ?></div>
                        <div class="stat-label">En Progreso</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number"><?php echo $func_totals['Resuelto'] + $error_totals['Resuelto']; ?></div>
                        <div class="stat-label">Completadas</div>
                    </div>
                </div>
            </div>

            <!-- Funcionalidades Asignadas -->
            <div class="recent-items">
                <h3><i class="fas fa-tasks"></i> Funcionalidades Asignadas</h3>
                <?php
                $stmt_assigned_func = $conn->prepare("
                    SELECT f.*, t.nombre_topico, u.user_nombre 
                    FROM Asignacion_Funcionalidad af 
                    JOIN Funcionalidad f ON af.id_funcionalidad = f.id_funcionalidad 
                    JOIN Topico t ON f.id_topico = t.id_topico 
                    JOIN Usuario u ON f.user_rut = u.user_rut 
                    WHERE af.ing_rut = ? 
                    ORDER BY 
                        CASE f.estado_funcion 
                            WHEN 'En Progreso' THEN 1 
                            WHEN 'Abierto' THEN 2 
                            WHEN 'Resuelto' THEN 3 
                            WHEN 'Cerrado' THEN 4 
                        END, f.fecha_funcion DESC 
                    LIMIT 5
                ");
                $assigned_funcs = [];
                if ($stmt_assigned_func) {
                    $stmt_assigned_func->bind_param("s", $rut);
                    if ($stmt_assigned_func->execute()) {
                        $result = $stmt_assigned_func->get_result();
                        $assigned_funcs = $result ? $result->fetch_all(MYSQLI_ASSOC) : [];
                    }
                    $stmt_assigned_func->close();
                }
                
                if ($assigned_funcs): ?>
                    <ul class="item-list">
                        <?php foreach ($assigned_funcs as $func): ?>
                        <li>
                            <div class="item-info">
                                <div class="item-title"><?php echo htmlspecialchars($func['titulo_funcion']); ?></div>
                                <div class="item-meta">
                                    Solicitado por: <?php echo htmlspecialchars($func['user_nombre']); ?> | 
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
                        <p>No tienes funcionalidades asignadas actualmente.</p>
                    </div>
                <?php endif; ?>
            </div>

            <!-- Errores Asignados -->
            <div class="recent-items">
                <h3><i class="fas fa-exclamation-triangle"></i> Errores Asignados</h3>
                <?php
                $stmt_assigned_errors = $conn->prepare("
                    SELECT e.*, t.nombre_topico, u.user_nombre 
                    FROM Asignacion_Error ae 
                    JOIN ErrorBug e ON ae.id_bug = e.id_bug 
                    JOIN Topico t ON e.id_topico = t.id_topico 
                    JOIN Usuario u ON e.user_rut = u.user_rut 
                    WHERE ae.ing_rut = ? 
                    ORDER BY 
                        CASE e.estado_error 
                            WHEN 'En Progreso' THEN 1 
                            WHEN 'Abierto' THEN 2 
                            WHEN 'Resuelto' THEN 3 
                            WHEN 'Cerrado' THEN 4 
                        END, e.fecha_error DESC 
                    LIMIT 5
                ");
                $assigned_errors = [];
                if ($stmt_assigned_errors) {
                    $stmt_assigned_errors->bind_param("s", $rut);
                    if ($stmt_assigned_errors->execute()) {
                        $result = $stmt_assigned_errors->get_result();
                        $assigned_errors = $result ? $result->fetch_all(MYSQLI_ASSOC) : [];
                    }
                    $stmt_assigned_errors->close();
                }
                
                if ($assigned_errors): ?>
                    <ul class="item-list">
                        <?php foreach ($assigned_errors as $error): ?>
                        <li>
                            <div class="item-info">
                                <div class="item-title"><?php echo htmlspecialchars($error['titulo_error']); ?></div>
                                <div class="item-meta">
                                    Reportado por: <?php echo htmlspecialchars($error['user_nombre']); ?> | 
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
                        <p>No tienes errores asignados actualmente.</p>
                    </div>
                <?php endif; ?>
            </div>
        </div>
        
        <!-- Acciones Rápidas -->
        <div class="quick-actions">
            <a href="funcionalidad/listar.php" class="action-btn">
                <i class="fas fa-tasks"></i> Mis Funcionalidades
            </a>
            <a href="error/listar.php" class="action-btn">
                <i class="fas fa-exclamation-triangle"></i> Mis Errores
            </a>
            <a href="funcionalidad/listar.php" class="action-btn">
                <i class="fas fa-cogs"></i> Todas las Funcionalidades
            </a>
            <a href="error/listar.php" class="action-btn">
                <i class="fas fa-bug"></i> Todos los Errores
            </a>
            <a href="logout.php" class="action-btn secondary">
                <i class="fas fa-sign-out-alt"></i> Cerrar Sesión
            </a>
        </div>
    </div>
</body>
</html>
