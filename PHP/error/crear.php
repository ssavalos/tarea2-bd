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

$page_title = 'Reportar error';
$css_path = '../';
$nav_path = '../';

$rut = $_SESSION['rut'];

$titulo = '';
$descripcion = '';
$topico = '';
$errors = [];

$topics = [];
if ($result = $conn->query('SELECT id_topico, nombre_topico FROM Topico ORDER BY nombre_topico')) {
    while ($row = $result->fetch_assoc()) {
        $topics[] = $row;
    }
    $result->free();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $titulo = trim($_POST['titulo'] ?? '');
    $descripcion = trim($_POST['descripcion'] ?? '');
    $topico = $_POST['topico'] ?? '';

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

    $fecha_hoy = date('Y-m-d');

    if (empty($errors)) {
        $stmt = $conn->prepare('SELECT COUNT(*) FROM ErrorBug WHERE user_rut = ? AND fecha_error = ?');
        $stmt->bind_param('ss', $rut, $fecha_hoy);
        $stmt->execute();
        $stmt->bind_result($cantidad_hoy);
        $stmt->fetch();
        $stmt->close();

        if ($cantidad_hoy >= 25) {
            $errors[] = 'Has alcanzado el máximo de 25 errores reportados para hoy.';
        }
    }

    if (empty($errors)) {
        try {
            $conn->begin_transaction();

            $estado = 'Abierto';
            $stmt = $conn->prepare('INSERT INTO ErrorBug (titulo_error, descripcion_error, fecha_error, estado_error, id_topico, user_rut) VALUES (?, ?, ?, ?, ?, ?)');
            $topicoId = (int)$topico;
            $stmt->bind_param('ssssss', $titulo, $descripcion, $fecha_hoy, $estado, $topicoId, $rut);
            $stmt->execute();
            $bug_id = $stmt->insert_id;
            $stmt->close();

            $stmtProc = $conn->prepare('CALL sp_asignar_error(?, ?)');
            $stmtProc->bind_param('ii', $bug_id, $topicoId);
            $stmtProc->execute();
            $stmtProc->close();
            while ($conn->more_results() && $conn->next_result()) {}

            $conn->commit();

            $_SESSION['flash_error'] = [
                'type' => 'success',
                'message' => 'Error reportado correctamente.'
            ];
            header('Location: listar.php');
            exit;
        } catch (mysqli_sql_exception $e) {
            $conn->rollback();
            if ($e->getCode() === 1062) {
                $errors[] = 'Ya existe un error con ese título.';
            } else {
                $errors[] = 'Error al registrar el error: ' . $e->getMessage();
            }
        }
    }
}

include '../includes/header.php';
?>

<div class="main-container form-page">
    <div class="glass-card">
        <h2><i class="fas fa-plus"></i> Reportar nuevo error</h2>

        <?php if (!empty($errors)): ?>
            <ul class="error-list">
                <?php foreach ($errors as $err): ?>
                    <li><?php echo htmlspecialchars($err); ?></li>
                <?php endforeach; ?>
            </ul>
        <?php endif; ?>

        <form method="post" class="form-grid">
            <div class="form-field">
                <label for="titulo">Título</label>
                <input type="text" id="titulo" name="titulo" maxlength="100" required value="<?php echo htmlspecialchars($titulo); ?>">
            </div>

            <div class="form-field">
                <label for="topico">Tópico</label>
                <select id="topico" name="topico" required>
                    <option value="">-- Selecciona un tópico --</option>
                    <?php foreach ($topics as $topic): ?>
                        <option value="<?php echo $topic['id_topico']; ?>" <?php echo ((string)$topico === (string)$topic['id_topico']) ? 'selected' : ''; ?>><?php echo htmlspecialchars($topic['nombre_topico']); ?></option>
                    <?php endforeach; ?>
                </select>
            </div>

            <div class="form-field full">
                <label for="descripcion">Descripción</label>
                <textarea id="descripcion" name="descripcion" maxlength=200 rows="4" required><?php echo htmlspecialchars($descripcion); ?></textarea>
            </div>

            <div class="form-actions">
                <button type="submit" class="action-btn"><i class="fas fa-save"></i> Guardar</button>
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
