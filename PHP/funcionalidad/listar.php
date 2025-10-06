<?php
session_start();
require_once '../includes/auth_guard.php';
require_once '../db.php';

$page_title = 'Funcionalidades';
$css_path = '../';
$nav_path = '../';

$rol = $_SESSION['rol'];
$rut = $_SESSION['rut'];

$search = isset($_GET['q']) ? trim($_GET['q']) : '';
$estado = isset($_GET['estado']) ? trim($_GET['estado']) : '';
$topico = isset($_GET['topico']) ? trim($_GET['topico']) : '';
$ambiente = isset($_GET['ambiente']) ? trim($_GET['ambiente']) : '';

$estados_validos = ['Abierto', 'En Progreso', 'Resuelto', 'Cerrado'];
$ambientes_validos = ['Web', 'Móvil'];

$topics = [];
if ($result = $conn->query('SELECT id_topico, nombre_topico FROM Topico ORDER BY nombre_topico')) {
    while ($row = $result->fetch_assoc()) {
        $topics[] = $row;
    }
    $result->free();
}

function buildFuncionalidadQuery(mysqli $conn, array $options): array {
    $base = "SELECT f.id_funcionalidad, f.titulo_funcion, f.ambiente_funcion, f.resumen_funcion, f.estado_funcion, f.fecha_funcion,\n                     t.nombre_topico, u.user_nombre, u.user_rut,\n                     GROUP_CONCAT(DISTINCT i.nombre_ing ORDER BY i.nombre_ing SEPARATOR ', ') AS ingenieros,\n                     (SELECT GROUP_CONCAT(descripcion_criterio ORDER BY id_criterio SEPARATOR '\n')\n                        FROM Criterio_Aceptacion ca\n                        WHERE ca.id_funcionalidad = f.id_funcionalidad) AS criterios\n              FROM Funcionalidad f\n              INNER JOIN Topico t ON f.id_topico = t.id_topico\n              INNER JOIN Usuario u ON f.user_rut = u.user_rut\n              LEFT JOIN Asignacion_Funcionalidad af ON f.id_funcionalidad = af.id_funcionalidad\n              LEFT JOIN Ingeniero i ON af.ing_rut = i.ing_rut";

    $where = [];
    $types = '';
    $params = [];

    if (!empty($options['buscar'])) {
        $where[] = 'f.titulo_funcion LIKE ?';
        $types .= 's';
        $params[] = '%' . $options['buscar'] . '%';
    }

    if (!empty($options['estado'])) {
        $where[] = 'f.estado_funcion = ?';
        $types .= 's';
        $params[] = $options['estado'];
    }

    if (!empty($options['topico'])) {
        $where[] = 'f.id_topico = ?';
        $types .= 'i';
        $params[] = (int)$options['topico'];
    }

    if (!empty($options['ambiente'])) {
        $where[] = 'f.ambiente_funcion = ?';
        $types .= 's';
        $params[] = $options['ambiente'];
    }

    if (!empty($options['solo_usuario'])) {
        $where[] = 'f.user_rut = ?';
        $types .= 's';
        $params[] = $options['solo_usuario'];
    }

    if (!empty($options['solo_ingeniero'])) {
        $where[] = 'af.ing_rut = ?';
        $types .= 's';
        $params[] = $options['solo_ingeniero'];
    }

    $sql = $base;
    if ($where) {
        $sql .= ' WHERE ' . implode(' AND ', $where);
    }

    $sql .= ' GROUP BY f.id_funcionalidad, f.titulo_funcion, f.ambiente_funcion, f.resumen_funcion, f.estado_funcion, f.fecha_funcion, t.nombre_topico, u.user_nombre, u.user_rut';
    $sql .= ' ORDER BY f.fecha_funcion DESC LIMIT 100';

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        return []; // En producción deberíamos manejar el error
    }

    if ($types !== '') {
        $stmt->bind_param($types, ...$params);
    }

    $stmt->execute();
    $result = $stmt->get_result();
    $rows = $result ? $result->fetch_all(MYSQLI_ASSOC) : [];
    $stmt->close();

    return $rows;
}

$flash = $_SESSION['flash_func'] ?? null;
if (isset($_SESSION['flash_func'])) {
    unset($_SESSION['flash_func']);
}

$comunes = [
    'buscar' => $search,
    'estado' => in_array($estado, $estados_validos, true) ? $estado : '',
    'topico' => ctype_digit($topico) ? $topico : '',
    'ambiente' => in_array($ambiente, $ambientes_validos, true) ? $ambiente : ''
];

$datos_usuario = [];
if ($rol === 'usuario') {
    $datos_usuario = buildFuncionalidadQuery($conn, $comunes + ['solo_usuario' => $rut]);
}

$datos_asignadas = [];
$datos_todas = [];
if ($rol === 'ingeniero') {
    $datos_asignadas = buildFuncionalidadQuery($conn, $comunes + ['solo_ingeniero' => $rut]);
    $datos_todas = buildFuncionalidadQuery($conn, $comunes);
}

include '../includes/header.php';
?>

<div class="main-container">
    <?php if ($flash): ?>
        <div class="glass-card flash-<?php echo htmlspecialchars($flash['type']); ?>">
            <?php echo htmlspecialchars($flash['message']); ?>
        </div>
    <?php endif; ?>

    <div class="glass-card">
        <h2><i class="fas fa-cogs"></i> Funcionalidades</h2>
        <?php if ($rol === 'usuario'): ?>
            <div class="actions-bar">
                <a href="crear.php" class="action-btn">
                    <i class="fas fa-plus"></i> Nueva funcionalidad
                </a>
            </div>
        <?php endif; ?>
        <form method="get" class="filters-form">
            <div class="filters-grid">
                <div>
                    <label for="q">Buscar por título</label>
                    <input type="text" id="q" name="q" value="<?php echo htmlspecialchars($search); ?>" placeholder="Ej: Panel de reportes">
                </div>
                <div>
                    <label for="estado">Estado</label>
                    <select id="estado" name="estado">
                        <option value="">Todos</option>
                        <?php foreach ($estados_validos as $op): ?>
                            <option value="<?php echo $op; ?>" <?php echo ($estado === $op) ? 'selected' : ''; ?>><?php echo $op; ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div>
                    <label for="topico">Tópico</label>
                    <select id="topico" name="topico">
                        <option value="">Todos</option>
                        <?php foreach ($topics as $topic): ?>
                            <option value="<?php echo $topic['id_topico']; ?>" <?php echo ($topico === (string)$topic['id_topico']) ? 'selected' : ''; ?>><?php echo htmlspecialchars($topic['nombre_topico']); ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div>
                    <label for="ambiente">Ambiente</label>
                    <select id="ambiente" name="ambiente">
                        <option value="">Todos</option>
                        <?php foreach ($ambientes_validos as $amb): ?>
                            <option value="<?php echo $amb; ?>" <?php echo ($ambiente === $amb) ? 'selected' : ''; ?>><?php echo $amb; ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="filters-actions">
                <button type="submit" class="action-btn"><i class="fas fa-search"></i> Filtrar</button>
                <a href="listar.php" class="action-btn secondary"><i class="fas fa-undo"></i> Limpiar</a>
            </div>
        </form>
    </div>

    <?php if ($rol === 'usuario'): ?>
        <div class="glass-card">
            <h3><i class="fas fa-user"></i> Mis solicitudes de funcionalidad</h3>
            <?php if (empty($datos_usuario)): ?>
                <p class="empty-state">Aún no has registrado solicitudes de funcionalidad.</p>
            <?php else: ?>
                <div class="table-wrapper">
                    <table class="styled-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Título</th>
                                <th>Ambiente</th>
                                <th>Tópico</th>
                                <th>Estado</th>
                                <th>Fecha</th>
                                <th>Ingenieros asignados</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($datos_usuario as $row): ?>
                                <tr>
                                    <td><?php echo $row['id_funcionalidad']; ?></td>
                                    <td>
                                        <span class="title-cell" title="<?php echo htmlspecialchars($row['resumen_funcion']); ?>">
                                            <?php echo htmlspecialchars($row['titulo_funcion']); ?>
                                        </span>
                                    </td>
                                    <td><?php echo htmlspecialchars($row['ambiente_funcion']); ?></td>
                                    <td><?php echo htmlspecialchars($row['nombre_topico']); ?></td>
                                    <td><span class="badge estado-<?php echo strtolower(str_replace(' ', '', $row['estado_funcion'])); ?>"><?php echo htmlspecialchars($row['estado_funcion']); ?></span></td>
                                    <td><?php echo htmlspecialchars($row['fecha_funcion']); ?></td>
                                    <td><?php echo $row['ingenieros'] ? htmlspecialchars($row['ingenieros']) : 'Sin asignar'; ?></td>
                                    <td class="actions-cell">
                                        <?php if ($row['estado_funcion'] === 'Abierto'): ?>
                                            <a href="editar.php?id=<?php echo $row['id_funcionalidad']; ?>" class="action-link"><i class="fas fa-edit"></i> Editar</a>
                                            <a href="eliminar.php?id=<?php echo $row['id_funcionalidad']; ?>" class="action-link danger"><i class="fas fa-trash"></i> Eliminar</a>
                                        <?php else: ?>
                                            <span class="action-disabled" title="Disponible solo para funcionalidades abiertas">Bloqueado</span>
                                        <?php endif; ?>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </div>
    <?php endif; ?>

    <?php if ($rol === 'ingeniero'): ?>
        <div class="glass-card">
            <h3><i class="fas fa-briefcase"></i> Funcionalidades asignadas a mí</h3>
            <?php if (empty($datos_asignadas)): ?>
                <p class="empty-state">No tienes funcionalidades asignadas bajo los filtros actuales.</p>
            <?php else: ?>
                <div class="table-wrapper">
                    <table class="styled-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Título</th>
                                <th>Tópico</th>
                                <th>Estado</th>
                                <th>Fecha</th>
                                <th>Solicitante</th>
                                <th>Reseñas</th>
                                <th>Detalles</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($datos_asignadas as $row): ?>
                                <tr>
                                    <td><?php echo $row['id_funcionalidad']; ?></td>
                                    <td>
                                        <span class="title-cell" title="<?php echo htmlspecialchars($row['resumen_funcion']); ?>">
                                            <?php echo htmlspecialchars($row['titulo_funcion']); ?>
                                        </span>
                                    </td>
                                    <td><?php echo htmlspecialchars($row['nombre_topico']); ?></td>
                                    <td><span class="badge estado-<?php echo strtolower(str_replace(' ', '', $row['estado_funcion'])); ?>"><?php echo htmlspecialchars($row['estado_funcion']); ?></span></td>
                                    <td><?php echo htmlspecialchars($row['fecha_funcion']); ?></td>
                                    <td><?php echo htmlspecialchars($row['user_nombre']); ?> (<?php echo htmlspecialchars($row['user_rut']); ?>)</td>
                                    <td><a href="reviews.php?id=<?php echo $row['id_funcionalidad']; ?>" class="review-link"><i class="fas fa-comments"></i> Ver reseñas</a></td>
                                    <td class="details-cell">
                                        <span class="info-icon" aria-label="Mostrar detalles"><i class="fas fa-circle-info"></i></span>
                                        <div class="info-popover">
                                            <?php if (!empty($row['ambiente_funcion'])): ?>
                                                <p><strong>Ambiente:</strong> <?php echo htmlspecialchars($row['ambiente_funcion']); ?></p>
                                            <?php endif; ?>
                                            <p><strong>Resumen:</strong><br><?php echo nl2br(htmlspecialchars($row['resumen_funcion'])); ?></p>
                                            <?php $criterios_list = $row['criterios'] ? array_filter(explode("\n", $row['criterios'])) : []; ?>
                                            <?php if (!empty($criterios_list)): ?>
                                                <p><strong>Criterios de aceptación:</strong></p>
                                                <ul>
                                                    <?php foreach ($criterios_list as $criterio): ?>
                                                        <li><?php echo htmlspecialchars($criterio); ?></li>
                                                    <?php endforeach; ?>
                                                </ul>
                                            <?php endif; ?>
                                        </div>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </div>

        <div class="glass-card">
            <h3><i class="fas fa-globe"></i> Todas las funcionalidades recientes</h3>
            <?php if (empty($datos_todas)): ?>
                <p class="empty-state">No hay funcionalidades que coincidan con los filtros seleccionados.</p>
            <?php else: ?>
                <div class="table-wrapper">
                    <table class="styled-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Título</th>
                                <th>Tópico</th>
                                <th>Estado</th>
                                <th>Fecha</th>
                                <th>Solicitante</th>
                                <th>Ingenieros asignados</th>
                                <th>Reseñas</th>
                                <th>Detalles</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($datos_todas as $row): ?>
                                <tr>
                                    <td><?php echo $row['id_funcionalidad']; ?></td>
                                    <td>
                                        <span class="title-cell" title="<?php echo htmlspecialchars($row['resumen_funcion']); ?>">
                                            <?php echo htmlspecialchars($row['titulo_funcion']); ?>
                                        </span>
                                    </td>
                                    <td><?php echo htmlspecialchars($row['nombre_topico']); ?></td>
                                    <td><span class="badge estado-<?php echo strtolower(str_replace(' ', '', $row['estado_funcion'])); ?>"><?php echo htmlspecialchars($row['estado_funcion']); ?></span></td>
                                    <td><?php echo htmlspecialchars($row['fecha_funcion']); ?></td>
                                    <td><?php echo htmlspecialchars($row['user_nombre']); ?> (<?php echo htmlspecialchars($row['user_rut']); ?>)</td>
                                    <td><?php echo $row['ingenieros'] ? htmlspecialchars($row['ingenieros']) : 'Sin asignar'; ?></td>
                                    <td><a href="reviews.php?id=<?php echo $row['id_funcionalidad']; ?>" class="review-link"><i class="fas fa-comments"></i> Ver reseñas</a></td>
                                    <td class="details-cell">
                                        <span class="info-icon" aria-label="Mostrar detalles"><i class="fas fa-circle-info"></i></span>
                                        <div class="info-popover">
                                            <?php if (!empty($row['ambiente_funcion'])): ?>
                                                <p><strong>Ambiente:</strong> <?php echo htmlspecialchars($row['ambiente_funcion']); ?></p>
                                            <?php endif; ?>
                                            <p><strong>Resumen:</strong><br><?php echo nl2br(htmlspecialchars($row['resumen_funcion'])); ?></p>
                                            <?php $criterios_list = $row['criterios'] ? array_filter(explode("\n", $row['criterios'])) : []; ?>
                                            <?php if (!empty($criterios_list)): ?>
                                                <p><strong>Criterios de aceptación:</strong></p>
                                                <ul>
                                                    <?php foreach ($criterios_list as $criterio): ?>
                                                        <li><?php echo htmlspecialchars($criterio); ?></li>
                                                    <?php endforeach; ?>
                                                </ul>
                                            <?php endif; ?>
                                        </div>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </div>
    <?php endif; ?>
</div>

<style>
.main-container {
    max-width: 1200px;
    margin: 0 auto;
    display: flex;
    flex-direction: column;
    gap: 20px;
}

.glass-card {
    background: var(--glass-bg);
    border: 1px solid var(--glass-border);
    border-radius: 12px;
    padding: 20px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
}

.filters-form label {
    font-size: 13px;
    font-weight: bold;
    color: var(--text-secondary);
}

.filters-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 15px;
}

.filters-form input,
.filters-form select {
    width: 100%;
    padding: 8px 10px;
    border-radius: 8px;
    border: 1px solid rgba(0,0,0,0.1);
    font-size: 14px;
}

.filters-actions {
    margin-top: 15px;
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
}

.table-wrapper {
    position: relative;
    overflow-x: auto;
    overflow-y: visible;
}

.table-wrapper::after {
    content: '';
    position: absolute;
    inset: 0;
    pointer-events: none;
    box-shadow: 0 0 0 0 rgba(0,0,0,0);
}

.styled-table {
    width: 100%;
    border-collapse: collapse;
}

.styled-table thead {
    background: rgba(0, 89, 255, 0.1);
}

.styled-table th,
.styled-table td {
    padding: 10px;
    text-align: left;
    border-bottom: 1px solid rgba(0,0,0,0.1);
}

.actions-bar {
    margin-bottom: 15px;
}

.actions-cell {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
}

.action-link {
    font-size: 13px;
    font-weight: bold;
    color: var(--primary-blue);
    text-decoration: none;
}

.action-link:hover {
    text-decoration: underline;
}

.action-link.danger {
    color: #c0392b;
}

.action-disabled {
    font-size: 13px;
    color: var(--text-secondary);
    opacity: 0.7;
    cursor: not-allowed;
}

.review-link {
    font-size: 13px;
    font-weight: bold;
    color: var(--primary-blue);
    text-decoration: none;
}

.review-link:hover {
    text-decoration: underline;
}

.flash-success {
    border-left: 4px solid #2ecc71;
    color: #155724;
}

.flash-error {
    border-left: 4px solid #c0392b;
    color: #721c24;
}

.title-cell {
    font-weight: bold;
    color: var(--text-color);
}

.badge {
    display: inline-block;
    padding: 4px 10px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: bold;
}

.estado-abierto { background: #fff3cd; color: #856404; }
.estado-enprogreso { background: #cce5ff; color: #004085; }
.estado-resuelto { background: #d4edda; color: #155724; }
.estado-cerrado { background: #e2e3e5; color: #495057; }

.empty-state {
    text-align: center;
    color: var(--text-secondary);
    font-style: italic;
}

.details-cell {
    position: relative;
    text-align: center;
    z-index: 1;
}

.info-icon {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 28px;
    height: 28px;
    border-radius: 50%;
    background: rgba(0, 89, 255, 0.1);
    color: var(--primary-blue);
    cursor: pointer;
    transition: background 0.2s ease;
}

.info-icon:hover {
    background: rgba(0, 89, 255, 0.25);
}

.info-popover {
    display: none;
    position: absolute;
    top: 50%;
    right: calc(100% + 14px);
    transform: translateY(-50%);
    z-index: 999;
    width: 260px;
    background: rgba(255, 255, 255, 0.98);
    border: 1px solid rgba(0,0,0,0.12);
    border-radius: 10px;
    box-shadow: 0 10px 20px rgba(0,0,0,0.15);
    padding: 12px;
    text-align: left;
    pointer-events: none;
}

.details-cell:hover .info-popover {
    display: block;
}

.info-popover p {
    margin: 6px 0;
    font-size: 13px;
    color: var(--text-secondary);
}

.info-popover ul {
    margin: 6px 0 0 18px;
    padding: 0;
    font-size: 13px;
    color: var(--text-secondary);
}
</style>

<?php include '../includes/footer.php'; ?>
