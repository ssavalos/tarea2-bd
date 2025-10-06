<?php
session_start();
require_once '../includes/auth_guard.php';
require_once '../db.php';

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$conn->set_charset('utf8mb4');

if ($_SESSION['rol'] !== 'usuario') {
    header('Location: ../ingDashboard.php');
    exit;
}

$page_title = 'Eliminar funcionalidad';
$css_path = '../';
$nav_path = '../';

$rut = $_SESSION['rut'];
$func_id = isset($_GET['id']) ? (int)$_GET['id'] : (isset($_POST['id']) ? (int)$_POST['id'] : 0);

if ($func_id <= 0) {
    header('Location: listar.php');
    exit;
}

$stmt = $conn->prepare('SELECT titulo_funcion, resumen_funcion, estado_funcion, user_rut FROM Funcionalidad WHERE id_funcionalidad = ?');
$stmt->bind_param('i', $func_id);
$stmt->execute();
$result = $stmt->get_result();
$funcionalidad = $result ? $result->fetch_assoc() : null;
$stmt->close();

if (!$funcionalidad || $funcionalidad['user_rut'] !== $rut) {
    $_SESSION['flash_func'] = [
        'type' => 'error',
        'message' => 'No tienes permiso para eliminar esta funcionalidad.'
    ];
    header('Location: listar.php');
    exit;
}

if ($funcionalidad['estado_funcion'] !== 'Abierto') {
    $_SESSION['flash_func'] = [
        'type' => 'error',
        'message' => 'Solo puedes eliminar funcionalidades en estado Abierto.'
    ];
    header('Location: listar.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $stmt = $conn->prepare('DELETE FROM Funcionalidad WHERE id_funcionalidad = ?');
        $stmt->bind_param('i', $func_id);
        $stmt->execute();
        $stmt->close();

        $_SESSION['flash_func'] = [
            'type' => 'success',
            'message' => 'Funcionalidad eliminada correctamente.'
        ];
        header('Location: listar.php');
        exit;
    } catch (mysqli_sql_exception $e) {
        $_SESSION['flash_func'] = [
            'type' => 'error',
            'message' => 'No se pudo eliminar la funcionalidad: ' . $e->getMessage()
        ];
        header('Location: listar.php');
        exit;
    }
}

include '../includes/header.php';
?>

<div class="main-container form-page">
    <div class="glass-card">
        <h2><i class="fas fa-trash"></i> Eliminar funcionalidad</h2>
        <p>¿Estás seguro de que deseas eliminar la funcionalidad <strong><?php echo htmlspecialchars($funcionalidad['titulo_funcion']); ?></strong>?</p>
        <p>Resumen: <?php echo htmlspecialchars($funcionalidad['resumen_funcion']); ?></p>
        <p><strong>Esta acción no se puede deshacer.</strong></p>

        <form method="post" class="form-actions">
            <input type="hidden" name="id" value="<?php echo $func_id; ?>">
            <button type="submit" class="action-btn danger"><i class="fas fa-trash"></i> Eliminar</button>
            <a href="listar.php" class="action-btn secondary"><i class="fas fa-undo"></i> Cancelar</a>
        </form>
    </div>
</div>

<style>
.form-page {
    max-width: 700px;
    margin: 0 auto;
}

.form-actions {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
}

.action-btn.danger {
    background: #c0392b;
}

.action-btn.danger:hover {
    background: #922b21;
}
</style>

<?php include '../includes/footer.php'; ?>
