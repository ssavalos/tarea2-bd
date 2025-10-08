<?php
session_start();
require_once '../includes/auth_guard.php';
require_once '../db.php';

$page_title = 'Errores';
$css_path = '../';
$nav_path = '../';

$rol = $_SESSION['rol'];
$rut = $_SESSION['rut'];

$search = isset($_GET['q']) ? trim($_GET['q']) : '';
$estado = isset($_GET['estado']) ? trim($_GET['estado']) : '';
$topico = isset($_GET['topico']) ? trim($_GET['topico']) : '';

$estados_validos = ['Abierto', 'En Progreso', 'Resuelto', 'Cerrado'];

$topics = [];
if ($result = $conn->query('SELECT id_topico, nombre_topico FROM Topico ORDER BY nombre_topico')) {
    while ($row = $result->fetch_assoc()) {
        $topics[] = $row;
    }
    $result->free();
}

function autocerrarErrores(mysqli $conn): void
{
    $conn->query(
        "UPDATE ErrorBug
         SET estado_error = 'Cerrado'
         WHERE estado_error = 'Resuelto'
           AND resuelto_en IS NOT NULL
           AND resuelto_en <= DATE_SUB(NOW(), INTERVAL 3 DAY)"
    );
}

autocerrarErrores($conn);

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'update_estado' && $rol === 'ingeniero') {
    $bug_id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
    $nuevo_estado = $_POST['estado'] ?? '';

    if ($bug_id > 0 && in_array($nuevo_estado, ['En Progreso', 'Resuelto'], true)) {
        $stmt = $conn->prepare('SELECT estado_error FROM ErrorBug WHERE id_bug = ?');
        $stmt->bind_param('i', $bug_id);
        $stmt->execute();
        $bug_data = $stmt->get_result()->fetch_assoc();
        $stmt->close();

        if ($bug_data) {
            $estado_actual = $bug_data['estado_error'];
            $stmt = $conn->prepare('SELECT 1 FROM Asignacion_Error WHERE id_bug = ? AND ing_rut = ?');
            $stmt->bind_param('is', $bug_id, $rut);
            $stmt->execute();
            $asignado = $stmt->get_result()->num_rows > 0;
            $stmt->close();

            if ($asignado) {
                $transicion_valida = (
                    ($estado_actual === 'Abierto' && $nuevo_estado === 'En Progreso') ||
                    ($estado_actual === 'En Progreso' && $nuevo_estado === 'Resuelto')
                );

                if ($transicion_valida) {
                    if ($nuevo_estado === 'Resuelto') {
                        $stmt = $conn->prepare('UPDATE ErrorBug SET estado_error = ?, resuelto_en = NOW() WHERE id_bug = ?');
                    } else {
                        $stmt = $conn->prepare('UPDATE ErrorBug SET estado_error = ?, resuelto_en = NULL WHERE id_bug = ?');
                    }
                    $stmt->bind_param('si', $nuevo_estado, $bug_id);
                    $stmt->execute();
                    $stmt->close();

                    $_SESSION['flash_error'] = [
                        'type' => 'success',
                        'message' => "Estado actualizado a {$nuevo_estado}."
                    ];
                } else {
                    $_SESSION['flash_error'] = [
                        'type' => 'error',
                        'message' => 'Transición de estado no permitida.'
                    ];
                }
            } else {
                $_SESSION['flash_error'] = [
                    'type' => 'error',
                    'message' => 'No puedes actualizar errores que no están asignados a ti.'
                ];
            }
        }
    }

    header('Location: listar.php');
    exit;
}

function buildErrorQuery(mysqli $conn, array $options): array {
    $base = "SELECT e.id_bug, e.titulo_error, e.descripcion_error, e.estado_error, e.fecha_error,\n                     t.nombre_topico, u.user_nombre, u.user_rut,\n                     GROUP_CONCAT(DISTINCT i.nombre_ing ORDER BY i.nombre_ing SEPARATOR ', ') AS ingenieros\n              FROM ErrorBug e\n              INNER JOIN Topico t ON e.id_topico = t.id_topico\n              INNER JOIN Usuario u ON e.user_rut = u.user_rut\n              LEFT JOIN Asignacion_Error ae ON e.id_bug = ae.id_bug\n              LEFT JOIN Ingeniero i ON ae.ing_rut = i.ing_rut";

    $where = [];
    $types = '';
    $params = [];

    if (!empty($options['buscar'])) {
        $where[] = 'e.titulo_error LIKE ?';
        $types .= 's';
        $params[] = '%' . $options['buscar'] . '%';
    }

    if (!empty($options['estado'])) {
        $where[] = 'e.estado_error = ?';
        $types .= 's';
        $params[] = $options['estado'];
    }

    if (!empty($options['topico'])) {
        $where[] = 'e.id_topico = ?';
        $types .= 'i';
        $params[] = (int)$options['topico'];
    }

    if (!empty($options['solo_usuario'])) {
        $where[] = 'e.user_rut = ?';
        $types .= 's';
        $params[] = $options['solo_usuario'];
    }

    if (!empty($options['solo_ingeniero'])) {
        $where[] = 'ae.ing_rut = ?';
        $types .= 's';
        $params[] = $options['solo_ingeniero'];
    }

    $sql = $base;
    if ($where) {
        $sql .= ' WHERE ' . implode(' AND ', $where);
    }

    $sql .= ' GROUP BY e.id_bug, e.titulo_error, e.descripcion_error, e.estado_error, e.fecha_error, t.nombre_topico, u.user_nombre, u.user_rut';
    $sql .= ' ORDER BY e.fecha_error DESC LIMIT 100';

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        return [];
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

$flash = $_SESSION['flash_error'] ?? null;
if (isset($_SESSION['flash_error'])) {
    unset($_SESSION['flash_error']);
}

$comunes = [
    'buscar' => $search,
    'estado' => in_array($estado, $estados_validos, true) ? $estado : '',
    'topico' => ctype_digit($topico) ? $topico : ''
];

$datos_usuario = [];
if ($rol === 'usuario') {
    $datos_usuario = buildErrorQuery($conn, $comunes + ['solo_usuario' => $rut]);
}

$datos_asignados = [];
$datos_todos = [];
if ($rol === 'ingeniero') {
    $datos_asignados = buildErrorQuery($conn, $comunes + ['solo_ingeniero' => $rut]);
    $datos_todos = buildErrorQuery($conn, $comunes);
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
        <h2><i class="fas fa-bug"></i> Errores</h2>
        <?php if ($rol === 'usuario'): ?>
            <div class="actions-bar">
                <a href="crear.php" class="action-btn">
                    <i class="fas fa-plus"></i> Reportar error
                </a>
            </div>
        <?php endif; ?>
        <form method="get" class="filters-form">
            <div class="filters-grid">
                <div>
                    <label for="q">Buscar por título</label>
                    <input type="text" id="q" name="q" value="<?php echo htmlspecialchars($search); ?>" placeholder="Ej: Error 404">
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
            </div>
            <div class="filters-actions">
                <button type="submit" class="action-btn"><i class="fas fa-search"></i> Filtrar</button>
                <a href="listar.php" class="action-btn secondary"><i class="fas fa-undo"></i> Limpiar</a>
            </div>
        </form>
    </div>

    <?php if ($rol === 'usuario'): ?>
        <div class="glass-card">
            <h3><i class="fas fa-user"></i> Mis reportes de error</h3>
            <?php if (empty($datos_usuario)): ?>
                <p class="empty-state">Aún no has reportado errores.</p>
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
                                <th>Ingenieros asignados</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($datos_usuario as $row): ?>
                                <tr>
                                    <td><?php echo $row['id_bug']; ?></td>
                                    <td>
                                        <span class="title-cell" title="<?php echo htmlspecialchars($row['descripcion_error']); ?>">
                                            <?php echo htmlspecialchars($row['titulo_error']); ?>
                                        </span>
                                    </td>
                                    <td><?php echo htmlspecialchars($row['nombre_topico']); ?></td>
                                    <td><span class="badge estado-<?php echo strtolower(str_replace(' ', '', $row['estado_error'])); ?>"><?php echo htmlspecialchars($row['estado_error']); ?></span></td>
                                    <td><?php echo htmlspecialchars($row['fecha_error']); ?></td>
                                    <td><?php echo $row['ingenieros'] ? htmlspecialchars($row['ingenieros']) : 'Sin asignar'; ?></td>
                                    <td class="actions-cell">
                                        <?php if ($row['estado_error'] === 'Abierto'): ?>
                                            <a href="editar.php?id=<?php echo $row['id_bug']; ?>" class="action-link"><i class="fas fa-edit"></i> Editar</a>
                                            <a href="eliminar.php?id=<?php echo $row['id_bug']; ?>" class="action-link danger"><i class="fas fa-trash"></i> Eliminar</a>
                                        <?php else: ?>
                                            <span class="action-disabled" title="Disponible solo para errores abiertos">Bloqueado</span>
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
            <h3><i class="fas fa-briefcase"></i> Errores asignados a mí</h3>
            <?php if (empty($datos_asignados)): ?>
                <p class="empty-state">No tienes errores asignados bajo los filtros actuales.</p>
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
                                <th>Reportado por</th>
                                <th>Reseñas</th>
                                <th>Detalles</th>
                                <th>Gestionar</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($datos_asignados as $row): ?>
                                <tr>
                                    <td><?php echo $row['id_bug']; ?></td>
                                    <td>
                                        <span class="title-cell" title="<?php echo htmlspecialchars($row['descripcion_error']); ?>">
                                            <?php echo htmlspecialchars($row['titulo_error']); ?>
                                        </span>
                                    </td>
                                    <td><?php echo htmlspecialchars($row['nombre_topico']); ?></td>
                                    <td><span class="badge estado-<?php echo strtolower(str_replace(' ', '', $row['estado_error'])); ?>"><?php echo htmlspecialchars($row['estado_error']); ?></span></td>
                                    <td><?php echo htmlspecialchars($row['fecha_error']); ?></td>
                                    <td><?php echo htmlspecialchars($row['user_nombre']); ?> (<?php echo htmlspecialchars($row['user_rut']); ?>)</td>
                                    <td><a href="reviews.php?id=<?php echo $row['id_bug']; ?>" class="review-link"><i class="fas fa-comments"></i> Ver reseñas</a></td>
                                    <td class="details-cell">
                                        <span class="info-icon" aria-label="Mostrar detalles"><i class="fas fa-circle-info"></i></span>
                                        <div class="info-popover">
                                            <p><strong>Descripción:</strong><br><?php echo nl2br(htmlspecialchars($row['descripcion_error'])); ?></p>
                                        </div>
                                    </td>
                                    <td>
                                        <?php if ($row['estado_error'] === 'Abierto'): ?>
                                            <form method="post" class="status-form">
                                                <input type="hidden" name="action" value="update_estado">
                                                <input type="hidden" name="id" value="<?php echo $row['id_bug']; ?>">
                                                <input type="hidden" name="estado" value="En Progreso">
                                                <button type="submit" class="status-btn">
                                                    <i class="fas fa-play"></i> Marcar en progreso
                                                </button>
                                            </form>
                                        <?php elseif ($row['estado_error'] === 'En Progreso'): ?>
                                            <form method="post" class="status-form">
                                                <input type="hidden" name="action" value="update_estado">
                                                <input type="hidden" name="id" value="<?php echo $row['id_bug']; ?>">
                                                <input type="hidden" name="estado" value="Resuelto">
                                                <button type="submit" class="status-btn secondary">
                                                    <i class="fas fa-check"></i> Marcar resuelto
                                                </button>
                                            </form>
                                        <?php elseif ($row['estado_error'] === 'Resuelto'): ?>
                                            <span class="status-note">En espera de cierre automático</span>
                                        <?php else: ?>
                                            <span class="status-note">Sin acciones</span>
                                        <?php endif; ?>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </div>

        <div class="glass-card">
            <h3><i class="fas fa-globe"></i> Todos los errores recientes</h3>
            <?php if (empty($datos_todos)): ?>
                <p class="empty-state">No hay errores que coincidan con los filtros seleccionados.</p>
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
                                <th>Reportado por</th>
                                <th>Ingenieros asignados</th>
                                <th>Reseñas</th>
                                <th>Detalles</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($datos_todos as $row): ?>
                                <tr>
                                    <td><?php echo $row['id_bug']; ?></td>
                                    <td>
                                        <span class="title-cell" title="<?php echo htmlspecialchars($row['descripcion_error']); ?>">
                                            <?php echo htmlspecialchars($row['titulo_error']); ?>
                                        </span>
                                    </td>
                                    <td><?php echo htmlspecialchars($row['nombre_topico']); ?></td>
                                    <td><span class="badge estado-<?php echo strtolower(str_replace(' ', '', $row['estado_error'])); ?>"><?php echo htmlspecialchars($row['estado_error']); ?></span></td>
                                    <td><?php echo htmlspecialchars($row['fecha_error']); ?></td>
                                    <td><?php echo htmlspecialchars($row['user_nombre']); ?> (<?php echo htmlspecialchars($row['user_rut']); ?>)</td>
                                    <td><?php echo $row['ingenieros'] ? htmlspecialchars($row['ingenieros']) : 'Sin asignar'; ?></td>
                                    <td><a href="reviews.php?id=<?php echo $row['id_bug']; ?>" class="review-link"><i class="fas fa-comments"></i> Ver reseñas</a></td>
                                    <td class="details-cell">
                                        <span class="info-icon" aria-label="Mostrar detalles"><i class="fas fa-circle-info"></i></span>
                                        <div class="info-popover">
                                            <p><strong>Descripción:</strong><br><?php echo nl2br(htmlspecialchars($row['descripcion_error'])); ?></p>
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

.styled-table {
    width: 100%;
    border-collapse: collapse;
}

.styled-table thead {
    background: rgba(211, 47, 47, 0.1);
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

.status-form {
    display: inline-block;
}

.status-btn {
    background: var(--primary-blue);
    color: #fff;
    border: none;
    border-radius: 6px;
    padding: 6px 12px;
    font-size: 12px;
    font-weight: bold;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 6px;
}

.status-btn.secondary {
    background: #28a745;
}

.status-btn:hover {
    filter: brightness(1.05);
}

.status-note {
    font-size: 12px;
    color: var(--text-secondary);
}
</style>

<?php include '../includes/footer.php'; ?>
