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

$page_title = 'Editar funcionalidad';
$css_path = '../';
$nav_path = '../';

$rut = $_SESSION['rut'];
$func_id = isset($_GET['id']) ? (int)$_GET['id'] : (isset($_POST['id']) ? (int)$_POST['id'] : 0);

if ($func_id <= 0) {
    header('Location: listar.php');
    exit;
}

$estados_func = ['Abierto', 'En Progreso', 'Resuelto', 'Cerrado'];
$ambientes_validos = ['Web', 'Móvil'];

$topics = [];
if ($result = $conn->query('SELECT id_topico, nombre_topico FROM Topico ORDER BY nombre_topico')) {
    while ($row = $result->fetch_assoc()) {
        $topics[] = $row;
    }
    $result->free();
}

$stmt = $conn->prepare('SELECT f.titulo_funcion, f.ambiente_funcion, f.resumen_funcion, f.estado_funcion, f.id_topico, f.user_rut FROM Funcionalidad f WHERE f.id_funcionalidad = ?');
$stmt->bind_param('i', $func_id);
$stmt->execute();
$result = $stmt->get_result();
$funcionalidad = $result ? $result->fetch_assoc() : null;
$stmt->close();

if (!$funcionalidad || $funcionalidad['user_rut'] !== $rut) {
    $_SESSION['flash_func'] = [
        'type' => 'error',
        'message' => 'No tienes permiso para editar esta funcionalidad.'
    ];
    header('Location: listar.php');
    exit;
}

if ($funcionalidad['estado_funcion'] !== 'Abierto') {
    $_SESSION['flash_func'] = [
        'type' => 'error',
        'message' => 'Solo puedes editar funcionalidades en estado Abierto.'
    ];
    header('Location: listar.php');
    exit;
}

$stmt = $conn->prepare('SELECT id_criterio, descripcion_criterio FROM Criterio_Aceptacion WHERE id_funcionalidad = ? ORDER BY id_criterio');
$stmt->bind_param('i', $func_id);
$stmt->execute();
$result = $stmt->get_result();
$criterios_existentes = $result ? $result->fetch_all(MYSQLI_ASSOC) : [];
$stmt->close();

$titulo = trim($_POST['titulo'] ?? $funcionalidad['titulo_funcion']);
$ambiente = $_POST['ambiente'] ?? ($funcionalidad['ambiente_funcion'] ?? '');
$resumen = trim($_POST['resumen'] ?? $funcionalidad['resumen_funcion']);
$estado = $funcionalidad['estado_funcion'];
$topico = $_POST['topico'] ?? $funcionalidad['id_topico'];
$criterios_input = $_POST['criterios'] ?? array_column($criterios_existentes, 'descripcion_criterio');

$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (strlen($titulo) < 20) {
        $errors[] = 'El título debe tener al menos 20 caracteres.';
    } elseif (strlen($titulo) > 100) {
        $errors[] = 'El título no puede exceder 100 caracteres.';
    }

    if ($ambiente !== '' && !in_array($ambiente, $ambientes_validos, true)) {
        $errors[] = 'Ambiente inválido.';
    }

    if ($resumen === '') {
        $errors[] = 'El resumen es obligatorio.';
    } elseif (strlen($resumen) > 150) {
        $errors[] = 'El resumen no puede exceder 150 caracteres.';
    }

    if (!ctype_digit((string)$topico)) {
        $errors[] = 'Debes seleccionar un tópico válido.';
    }

    $criterios_limpios = array_values(array_filter(array_map('trim', $criterios_input), fn($c) => $c !== ''));
    if (count($criterios_limpios) < 3) {
        $errors[] = 'Debes ingresar al menos 3 criterios.';
    }

    if (empty($errors)) {
        try {
            $conn->begin_transaction();

            $stmt = $conn->prepare('UPDATE Funcionalidad SET titulo_funcion = ?, ambiente_funcion = ?, resumen_funcion = ?, estado_funcion = ?, id_topico = ? WHERE id_funcionalidad = ?');
            $ambienteParam = $ambiente !== '' ? $ambiente : null;
            $topicoId = (int)$topico;
            $stmt->bind_param('ssssii', $titulo, $ambienteParam, $resumen, $estado, $topicoId, $func_id);
            $stmt->execute();
            $stmt->close();

            $existingCount = count($criterios_existentes);
            $newCount = count($criterios_limpios);

            if ($existingCount > 0) {
                $stmtUpd = $conn->prepare('UPDATE Criterio_Aceptacion SET descripcion_criterio = ? WHERE id_criterio = ?');
                $criterioDescUpd = '';
                $criterioIdUpd = 0;
                $stmtUpd->bind_param('si', $criterioDescUpd, $criterioIdUpd);
            }

            if ($newCount > $existingCount) {
                $stmtIns = $conn->prepare('INSERT INTO Criterio_Aceptacion (descripcion_criterio, id_funcionalidad) VALUES (?, ?)');
                $criterioDescIns = '';
                $funcIdForInsert = $func_id;
                $stmtIns->bind_param('si', $criterioDescIns, $funcIdForInsert);
            }

            if ($existingCount > $newCount) {
                $stmtDel = $conn->prepare('DELETE FROM Criterio_Aceptacion WHERE id_criterio = ?');
                $criterioIdDel = 0;
                $stmtDel->bind_param('i', $criterioIdDel);
            }

            $minCount = min($existingCount, $newCount);
            for ($i = 0; $i < $minCount; $i++) {
                $criterioDescUpd = $criterios_limpios[$i];
                $criterioIdUpd = (int)$criterios_existentes[$i]['id_criterio'];
                $stmtUpd->execute();
            }

            if ($newCount > $existingCount) {
                for ($i = $existingCount; $i < $newCount; $i++) {
                    $criterioDescIns = $criterios_limpios[$i];
                    $stmtIns->execute();
                }
            }

            if ($existingCount > $newCount) {
                for ($i = $newCount; $i < $existingCount; $i++) {
                    $criterioIdDel = (int)$criterios_existentes[$i]['id_criterio'];
                    $stmtDel->execute();
                }
            }

            if (isset($stmtUpd)) {
                $stmtUpd->close();
            }
            if (isset($stmtIns)) {
                $stmtIns->close();
            }
            if (isset($stmtDel)) {
                $stmtDel->close();
            }

            $conn->commit();

            $_SESSION['flash_func'] = [
                'type' => 'success',
                'message' => 'Funcionalidad actualizada correctamente.'
            ];
            header('Location: listar.php');
            exit;
        } catch (mysqli_sql_exception $e) {
            $conn->rollback();
            if ($e->getCode() === 1062) {
                $errors[] = 'Ya existe una funcionalidad con ese título.';
            } else {
                $errors[] = 'Error al actualizar la funcionalidad: ' . $e->getMessage();
            }
        }
    }
}

include '../includes/header.php';
?>

<div class="main-container form-page">
    <div class="glass-card">
        <h2><i class="fas fa-edit"></i> Editar funcionalidad #<?php echo $func_id; ?></h2>

        <?php if (!empty($errors)): ?>
            <ul class="error-list">
                <?php foreach ($errors as $err): ?>
                    <li><?php echo htmlspecialchars($err); ?></li>
                <?php endforeach; ?>
            </ul>
        <?php endif; ?>

        <form method="post" class="form-grid">
            <input type="hidden" name="id" value="<?php echo $func_id; ?>">

            <div class="form-field">
                <label for="titulo">Título</label>
                <input type="text" id="titulo" name="titulo" maxlength="100" required value="<?php echo htmlspecialchars($titulo); ?>">
            </div>

            <div class="form-field">
                <label for="ambiente">Ambiente</label>
                <select id="ambiente" name="ambiente">
                    <option value="">-- Selecciona --</option>
                    <?php foreach ($ambientes_validos as $amb): ?>
                        <option value="<?php echo $amb; ?>" <?php echo $ambiente === $amb ? 'selected' : ''; ?>><?php echo $amb; ?></option>
                    <?php endforeach; ?>
                </select>
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
                <label for="resumen">Resumen</label>
                <textarea id="resumen" name="resumen" maxlength="150" rows="3" required><?php echo htmlspecialchars($resumen); ?></textarea>
            </div>

            <div class="form-field full">
                <label>Criterios de aceptación</label>
                <div class="criterios-wrapper">
                    <?php
                    $maxCampos = max(count($criterios_input), 3);
                    for ($i = 0; $i < $maxCampos; $i++):
                        $value = $criterios_input[$i] ?? '';
                    ?>
                        <textarea name="criterios[]" rows="2" placeholder="Criterio #<?php echo $i + 1; ?>" maxlength="255" required><?php echo htmlspecialchars($value); ?></textarea>
                    <?php endfor; ?>
                </div>
                <small>No puedes dejar menos de tres criterios al guardar.</small>
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

.criterios-wrapper {
    display: grid;
    gap: 10px;
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
