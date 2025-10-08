<?php
session_start();
require_once '../includes/auth_guard.php';
require_once '../db.php';

if ($_SESSION['rol'] !== 'ingeniero') {
    header('Location: ingDashboard.php');
    exit;
}

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$conn->set_charset('utf8mb4');

$conn->query(
    "UPDATE ErrorBug
     SET estado_error = 'Cerrado'
     WHERE estado_error = 'Resuelto'
       AND resuelto_en IS NOT NULL
       AND resuelto_en <= DATE_SUB(NOW(), INTERVAL 3 DAY)"
);

$page_title = 'Reseñas de Error';
$css_path = '../';
$nav_path = '../';

$ing_rut = $_SESSION['rut'];
$bug_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;

if ($bug_id <= 0) {
    header('Location: listar.php');
    exit;
}

$stmt = $conn->prepare("SELECT e.id_bug, e.titulo_error, e.estado_error, t.nombre_topico
                         FROM ErrorBug e
                         JOIN Topico t ON e.id_topico = t.id_topico
                         WHERE e.id_bug = ?");
$stmt->bind_param('i', $bug_id);
$stmt->execute();
$bug_data = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$bug_data) {
    $_SESSION['flash_error'] = [
        'type' => 'error',
        'message' => 'Error no encontrado.'
    ];
    header('Location: listar.php');
    exit;
}

$stmt = $conn->prepare('SELECT 1 FROM Asignacion_Error WHERE id_bug = ? AND ing_rut = ?');
$stmt->bind_param('is', $bug_id, $ing_rut);
$stmt->execute();
$assigned = $stmt->get_result()->num_rows > 0;
$stmt->close();

if (!$assigned) {
    $_SESSION['flash_error'] = [
        'type' => 'error',
        'message' => 'Solo puedes gestionar reseñas de errores asignados a ti.'
    ];
    header('Location: listar.php');
    exit;
}

$flash = $_SESSION['flash_resena_error'] ?? null;
unset($_SESSION['flash_resena_error']);

$editing_review = null;
if (isset($_GET['edit'])) {
    $edit_id = (int)$_GET['edit'];
    if ($edit_id > 0) {
        $stmt = $conn->prepare('SELECT id_resena, comentario, ing_rut FROM Resena_Error WHERE id_resena = ? AND id_bug = ?');
        $stmt->bind_param('ii', $edit_id, $bug_id);
        $stmt->execute();
        $editing_review = $stmt->get_result()->fetch_assoc();
        $stmt->close();
        if (!$editing_review || $editing_review['ing_rut'] !== $ing_rut) {
            $editing_review = null;
        }
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    try {
        switch ($action) {
            case 'add':
                $comentario = trim($_POST['comentario'] ?? '');
                if ($comentario === '') {
                    throw new Exception('El comentario no puede estar vacío.');
                }
                $stmt = $conn->prepare('INSERT INTO Resena_Error (id_bug, ing_rut, comentario) VALUES (?, ?, ?)');
                $stmt->bind_param('iss', $bug_id, $ing_rut, $comentario);
                $stmt->execute();
                $stmt->close();
                $_SESSION['flash_resena_error'] = ['type' => 'success', 'message' => 'Reseña registrada correctamente.'];
                break;
            case 'update':
                $resena_id = (int)($_POST['resena_id'] ?? 0);
                $comentario = trim($_POST['comentario'] ?? '');
                if ($comentario === '') {
                    throw new Exception('El comentario no puede estar vacío.');
                }
                $stmt = $conn->prepare('SELECT ing_rut FROM Resena_Error WHERE id_resena = ? AND id_bug = ?');
                $stmt->bind_param('ii', $resena_id, $bug_id);
                $stmt->execute();
                $owner = $stmt->get_result()->fetch_assoc();
                $stmt->close();
                if (!$owner || $owner['ing_rut'] !== $ing_rut) {
                    throw new Exception('No puedes editar esta reseña.');
                }
                $stmt = $conn->prepare('UPDATE Resena_Error SET comentario = ? WHERE id_resena = ?');
                $stmt->bind_param('si', $comentario, $resena_id);
                $stmt->execute();
                $stmt->close();
                $_SESSION['flash_resena_error'] = ['type' => 'success', 'message' => 'Reseña actualizada.'];
                break;
            case 'delete':
                $resena_id = (int)($_POST['resena_id'] ?? 0);
                $stmt = $conn->prepare('DELETE FROM Resena_Error WHERE id_resena = ? AND ing_rut = ?');
                $stmt->bind_param('is', $resena_id, $ing_rut);
                $stmt->execute();
                if ($stmt->affected_rows === 0) {
                    throw new Exception('No se pudo eliminar la reseña.');
                }
                $stmt->close();
                $_SESSION['flash_resena_error'] = ['type' => 'success', 'message' => 'Reseña eliminada.'];
                break;
        }
    } catch (Exception $e) {
        $_SESSION['flash_resena_error'] = ['type' => 'error', 'message' => $e->getMessage()];
    }

    header('Location: reviews.php?id=' . $bug_id);
    exit;
}

$stmt = $conn->prepare('SELECT re.id_resena, re.comentario, re.ing_rut, re.created_at, re.updated_at, i.nombre_ing
                         FROM Resena_Error re
                         JOIN Ingeniero i ON re.ing_rut = i.ing_rut
                         WHERE re.id_bug = ?
                         ORDER BY re.created_at DESC');
$stmt->bind_param('i', $bug_id);
$stmt->execute();
$reviews = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();

include '../includes/header.php';
?>

<div class="main-container">
    <div class="glass-card header-card">
        <h2><i class="fas fa-comments"></i> Reseñas de «<?php echo htmlspecialchars($bug_data['titulo_error']); ?>»</h2>
        <p><strong>Tópico:</strong> <?php echo htmlspecialchars($bug_data['nombre_topico']); ?> | <strong>Estado:</strong> <?php echo htmlspecialchars($bug_data['estado_error']); ?></p>
        <a href="listar.php" class="action-link"><i class="fas fa-arrow-left"></i> Volver al listado</a>
    </div>

    <?php if ($flash): ?>
        <div class="glass-card flash-<?php echo htmlspecialchars($flash['type']); ?>">
            <?php echo htmlspecialchars($flash['message']); ?>
        </div>
    <?php endif; ?>

    <?php if ($editing_review): ?>
        <div class="glass-card">
            <h3><i class="fas fa-pen"></i> Editar reseña</h3>
            <form method="post" class="review-form">
                <input type="hidden" name="action" value="update">
                <input type="hidden" name="resena_id" value="<?php echo $editing_review['id_resena']; ?>">
                <textarea name="comentario" rows="4" required><?php echo htmlspecialchars($editing_review['comentario']); ?></textarea>
                <div class="form-actions">
                    <button type="submit" class="action-btn"><i class="fas fa-save"></i> Guardar cambios</button>
                    <a href="reviews.php?id=<?php echo $bug_id; ?>" class="action-btn secondary"><i class="fas fa-undo"></i> Cancelar</a>
                </div>
            </form>
        </div>
    <?php else: ?>
        <div class="glass-card">
            <h3><i class="fas fa-plus"></i> Agregar reseña</h3>
            <form method="post" class="review-form">
                <input type="hidden" name="action" value="add">
                <textarea name="comentario" rows="4" placeholder="Escribe tus observaciones" required></textarea>
                <div class="form-actions">
                    <button type="submit" class="action-btn"><i class="fas fa-paper-plane"></i> Publicar</button>
                </div>
            </form>
        </div>
    <?php endif; ?>

    <div class="glass-card">
        <h3><i class="fas fa-list"></i> Historial de reseñas</h3>
        <?php if (empty($reviews)): ?>
            <p class="empty-state">Aún no se registran reseñas para este error.</p>
        <?php else: ?>
            <div class="reviews-grid">
                <?php foreach ($reviews as $review): ?>
                    <div class="review-card">
                        <div class="review-meta">
                            <span><i class="fas fa-user"></i> <?php echo htmlspecialchars($review['nombre_ing']); ?></span>
                            <span><i class="fas fa-clock"></i> <?php echo htmlspecialchars($review['created_at']); ?></span>
                        </div>
                        <div class="review-body">
                            <?php echo nl2br(htmlspecialchars($review['comentario'])); ?>
                        </div>
                        <?php if ($review['ing_rut'] === $ing_rut): ?>
                            <div class="review-actions">
                                <a href="reviews.php?id=<?php echo $bug_id; ?>&edit=<?php echo $review['id_resena']; ?>" class="action-link"><i class="fas fa-edit"></i> Editar</a>
                                <form method="post" onsubmit="return confirm('¿Eliminar esta reseña?');">
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="resena_id" value="<?php echo $review['id_resena']; ?>">
                                    <button type="submit" class="link-button danger"><i class="fas fa-trash"></i> Eliminar</button>
                                </form>
                            </div>
                        <?php endif; ?>
                    </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>
</div>

<style>
.main-container {
    max-width: 900px;
    margin: 0 auto;
    display: flex;
    flex-direction: column;
    gap: 20px;
}

.header-card {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.review-form textarea {
    width: 100%;
    padding: 12px;
    border-radius: 10px;
    border: 1px solid rgba(0,0,0,0.12);
    font-size: 14px;
}

.form-actions {
    margin-top: 10px;
    display: flex;
    gap: 10px;
}

.reviews-grid {
    display: grid;
    gap: 16px;
}

.review-card {
    background: rgba(255,255,255,0.95);
    border: 1px solid rgba(0,0,0,0.08);
    border-radius: 12px;
    padding: 16px;
    box-shadow: 0 4px 18px rgba(0,0,0,0.08);
}

.review-meta {
    display: flex;
    justify-content: space-between;
    font-size: 13px;
    color: var(--text-secondary);
    margin-bottom: 10px;
}

.review-body {
    font-size: 14px;
    color: var(--text-color);
    margin-bottom: 12px;
}

.review-actions {
    display: flex;
    gap: 12px;
    align-items: center;
}

.link-button {
    background: none;
    border: none;
    padding: 0;
    font-size: 13px;
    font-weight: bold;
    color: var(--primary-blue);
    cursor: pointer;
}

.link-button.danger {
    color: #c0392b;
}

.link-button:hover {
    text-decoration: underline;
}

.empty-state {
    text-align: center;
    font-style: italic;
    color: var(--text-secondary);
}

.flash-success {
    border-left: 4px solid #2ecc71;
    color: #155724;
    padding: 12px;
}

.flash-error {
    border-left: 4px solid #c0392b;
    color: #721c24;
    padding: 12px;
}

.action-btn {
    background: var(--primary-blue);
    color: #fff;
    border: none;
    padding: 10px 18px;
    border-radius: 8px;
    cursor: pointer;
    font-weight: bold;
    display: inline-flex;
    align-items: center;
    gap: 6px;
}

.action-btn.secondary {
    background: #6c757d;
}

.action-btn:hover {
    filter: brightness(1.05);
}
</style>

<?php include '../includes/footer.php'; ?>
