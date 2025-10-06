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

$page_title = 'Editar error';
$css_path = '../';
$nav_path = '../';

$rut = $_SESSION['rut'];
$error_id = isset($_GET['id']) ? (int)$_GET['id'] : (isset($_POST['id']) ? (int)$_POST['id'] : 0);

if ($error_id <= 0) {
    header('Location: listar.php');
    exit;
}

$estados_error = ['Abierto', 'En Progreso', 'Resuelto', 'Cerrado'];

$topics = [];
if ($result = $conn->query('SELECT id_topico, nombre_topico FROM Topico ORDER BY nombre_topico')) {
    while ($row = $result->fetch_assoc()) {
        $topics[] = $row;
    }
    $result->free();
}

$stmt = $conn->prepare('SELECT titulo_error, descripcion_error, estado_error, id_topico, user_rut FROM ErrorBug WHERE id_bug = ?');
$stmt->bind_param('i', $error_id);
$stmt->execute();
$result = $stmt->get_result();
$registro = $result ? $result->fetch_assoc() : null;
$stmt->close();

if (!$registro || $registro['user_rut'] !== $rut) {
    $_SESSION['flash_error'] = [
        'type' => 'error',
        'message' => 'No tienes permiso para editar este error.'
    ];
    header('Location: listar.php');
    exit;
}

if ($registro['estado_error'] !== 'Abierto') {
    $_SESSION['flash_error'] = [
        'type' => 'error',
        'message' => 'Solo puedes editar errores en estado Abierto.'
    ];
    header('Location: listar.php');
    exit;
}

$titulo = trim($_POST['titulo'] ?? $registro['titulo_error']);
$descripcion = trim($_POST['descripcion'] ?? $registro['descripcion_error']);
$estado = $registro['estado_error'];
$topico = $_POST['topico'] ?? $registro['id_topico'];

$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (strlen($titulo) < 10) {
        $errors[] = 'El título debe tener al menos 10 caracteres.';
    } elseif (strlen($titulo) > 100) {
        $errors[] = 'El título no puede exceder 100 caracteres.';
    }

    if ($descripcion === '') {
        $errors[] = 'La descripción es obligatoria.';
    } elseif (strlen($descripcion) > 200) {
        $errors[] = 'La descripción no puede exceder 200 caracteres.';
    }

    if (!ctype_digit((string)$topico)) {
        $errors[] = 'Debes seleccionar un tópico válido.';
    }

    if (empty($errors)) {
        try {
            $stmt = $conn->prepare('UPDATE ErrorBug SET titulo_error = ?, descripcion_error = ?, estado_error = ?, id_topico = ? WHERE id_bug = ?');
            $topicoId = (int)$topico;
            $stmt->bind_param('sssii', $titulo, $descripcion, $estado, $topicoId, $error_id);
            $stmt->execute();
            $stmt->close();

            $_SESSION['flash_error'] = [
                'type' => 'success',
                'message' => 'Error actualizado correctamente.'
            ];
            header('Location: listar.php');
            exit;
        } catch (mysqli_sql_exception $e) {
            if ($e->getCode() === 1062) {
                $errors[] = 'Ya existe un error con ese título.';
            } else {
                $errors[] = 'Error al actualizar: ' . $e->getMessage();
            }
        }
    }
}

include '../includes/header.php';
?>

<div class="main-container form-page">
    <div class="glass-card">
        <h2><i class="fas fa-edit"></i> Editar error #<?php echo $error_id; ?></h2>

        <?php if (!empty($errors)): ?>
            <ul class="error-list">
                <?php foreach ($errors as $err): ?>
                    <li><?php echo htmlspecialchars($err); ?></li>
                <?php endforeach; ?>
            </ul>
        <?php endif; ?>

        <form method="post" class="form-grid">
            <input type="hidden" name="id" value="<?php echo $error_id; ?>">

            <div class="form-field">
                <label for="titulo">Título</label>
                <input type="text" id="titulo" name="titulo" maxlength="100" required value="<?php echo htmlspecialchars($titulo); ?>">
            </div>

            <div class="form-field">
                <label>Estado actual</label>
                <input type="text" value="<?php echo htmlspecialchars($estado); ?>" readonly>
            </div>

            <div class="form-field">
                <label for="topico">Tópico</label>
                <select id="topico" name="topico" required>
                    <?php foreach ($topics as $topic): ?>
                        <option value="<?php echo $topic['id_topico']; ?>" <?php echo ((string)$topico === (string)$topic['id_topico']) ? 'selected' : ''; ?>><?php echo htmlspecialchars($topic['nombre_topico']); ?></option>
                    <?php endforeach; ?>
                </select>
            </div>

            <div class="form-field full">
                <label for="descripcion">Descripción</label>
                <textarea id="descripcion" name="descripcion" maxlength="200" rows="4" required><?php echo htmlspecialchars($descripcion); ?></textarea>
            </div>

            <div class="form-actions">
                <button type="submit" class="action-btn"><i class="fas fa-save"></i> Guardar cambios</button>
                <a href="listar.php" class="action-btn secondary"><i class="fas fa-undo"></i> Cancelar</a>
            </div>
        </form>
    </div>
</div>

<style>
.form-page {
    max-width: 900px;
    margin: 0 auto;
}

.form-grid {
    display: grid;
    gap: 20px;
}

.form-field {
    display: flex;
    flex-direction: column;
}

.form-field.full {
    grid-column: 1 / -1;
}

.form-field label {
    font-weight: bold;
    margin-bottom: 6px;
    color: var(--text-secondary);
}

.form-field input,
.form-field select,
.form-field textarea {
    padding: 10px;
    border-radius: 8px;
    border: 1px solid rgba(0,0,0,0.1);
    font-size: 14px;
}

.form-actions {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
}

.error-list {
    background: var(--error-bg);
    border-left: 4px solid #c0392b;
    padding: 15px;
    border-radius: 8px;
    color: var(--error-color);
}
</style>

<?php include '../includes/footer.php'; ?>
