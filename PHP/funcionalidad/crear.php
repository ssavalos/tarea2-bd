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

function autoAsignarFuncionalidad(mysqli $conn, int $func_id, int $topico_id): void
{
    $stmt = $conn->prepare(
        "SELECT ie.ing_rut
         FROM Ingeniero_Especialidad ie
         LEFT JOIN (
             SELECT ing_rut, COUNT(*) AS total
             FROM Asignacion_Funcionalidad
             GROUP BY ing_rut
         ) asign ON ie.ing_rut = asign.ing_rut
         WHERE ie.id_topico = ?
         ORDER BY COALESCE(asign.total, 0), ie.ing_rut
         LIMIT 3"
    );
    $stmt->bind_param('i', $topico_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $ingenieros = $result ? $result->fetch_all(MYSQLI_ASSOC) : [];
    $stmt->close();

    if (empty($ingenieros)) {
        return;
    }

    $stmtInsert = $conn->prepare('INSERT IGNORE INTO Asignacion_Funcionalidad (id_funcionalidad, ing_rut) VALUES (?, ?)');
    $funcParam = $func_id;
    $ingParam = null;
    $stmtInsert->bind_param('is', $funcParam, $ingParam);
    foreach ($ingenieros as $row) {
        $ingParam = $row['ing_rut'];
        $stmtInsert->execute();
    }
    $stmtInsert->close();
}

$page_title = 'Registrar funcionalidad';
$css_path = '../';
$nav_path = '../';

$rut = $_SESSION['rut'];

$errors = [];

$titulo = '';
$ambiente = '';
$resumen = '';
$topico = '';
$criterios_input = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $titulo = trim($_POST['titulo'] ?? '');
    $ambiente = $_POST['ambiente'] ?? '';
    $resumen = trim($_POST['resumen'] ?? '');
    $topico = $_POST['topico'] ?? '';
    $criterios_input = $_POST['criterios'] ?? [];
} else {
    $criterios_input = ['', '', ''];
}

$ambientes_validos = ['Web', 'Móvil'];

$topics = [];
if ($result = $conn->query('SELECT id_topico, nombre_topico FROM Topico ORDER BY nombre_topico')) {
    while ($row = $result->fetch_assoc()) {
        $topics[] = $row;
    }
    $result->free();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (strlen($titulo) < 20) {
        $errors[] = 'El título debe tener al menos 20 caracteres.';
    } elseif (strlen($titulo) > 100) {
        $errors[] = 'El título no puede exceder 100 caracteres.';
    }

    if ($ambiente !== '' && !in_array($ambiente, $ambientes_validos, true)) {
        $errors[] = 'Ambiente inválido seleccionado.';
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
        $errors[] = 'Debes ingresar al menos 3 criterios de aceptación.';
    }

    $fecha_hoy = date('Y-m-d');

    if (empty($errors)) {
        $stmt = $conn->prepare('SELECT COUNT(*) FROM Funcionalidad WHERE user_rut = ? AND fecha_funcion = ?');
        $stmt->bind_param('ss', $rut, $fecha_hoy);
        $stmt->execute();
        $stmt->bind_result($cantidad_hoy);
        $stmt->fetch();
        $stmt->close();

        if ($cantidad_hoy >= 25) {
            $errors[] = 'Has alcanzado el máximo de 25 funcionalidades registradas para hoy.';
        }
    }

    if (empty($errors)) {
        try {
            $conn->begin_transaction();

            $estado = 'Abierto';
            $stmt = $conn->prepare('INSERT INTO Funcionalidad (titulo_funcion, ambiente_funcion, resumen_funcion, estado_funcion, fecha_funcion, id_topico, user_rut) VALUES (?, ?, ?, ?, ?, ?, ?)');
            $ambienteParam = $ambiente !== '' ? $ambiente : null;
            $topicoId = (int)$topico;
            $stmt->bind_param('sssssis', $titulo, $ambienteParam, $resumen, $estado, $fecha_hoy, $topicoId, $rut);
            $stmt->execute();
            $func_id = $stmt->insert_id;
            $stmt->close();

            $stmtCrit = $conn->prepare('INSERT INTO Criterio_Aceptacion (descripcion_criterio, id_funcionalidad) VALUES (?, ?)');
            foreach ($criterios_limpios as $criterio) {
                $stmtCrit->bind_param('si', $criterio, $func_id);
                $stmtCrit->execute();
            }
            $stmtCrit->close();

            autoAsignarFuncionalidad($conn, $func_id, $topicoId);

            $conn->commit();

            $_SESSION['flash_func'] = [
                'type' => 'success',
                'message' => 'Funcionalidad creada correctamente.'
            ];
            header('Location: listar.php');
            exit;
        } catch (mysqli_sql_exception $e) {
            $conn->rollback();
            if ($e->getCode() === 1062) {
                $errors[] = 'Ya existe una funcionalidad con ese título.';
            } else {
                $errors[] = 'Error al guardar la funcionalidad: ' . $e->getMessage();
            }
        }
    }
}

include '../includes/header.php';
?>

<div class="main-container form-page">
    <div class="glass-card">
        <h2><i class="fas fa-plus"></i> Registrar funcionalidad</h2>

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
                <small>Debe tener entre 20 y 100 caracteres.</small>
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
                <label for="topico">Tópico</label>
                <select id="topico" name="topico" required>
                    <option value="">-- Selecciona un tópico --</option>
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
                <label>Criterios de aceptación (mínimo 3)</label>
                <div class="criterios-wrapper">
                    <?php
                    $maxCampos = max(3, count($criterios_input));
                    for ($i = 0; $i < $maxCampos; $i++):
                        $value = $criterios_input[$i] ?? '';
                    ?>
                        <textarea name="criterios[]" rows="2" placeholder="Criterio #<?php echo $i + 1; ?>" maxlength="255" required><?php echo htmlspecialchars($value); ?></textarea>
                    <?php endfor; ?>
                </div>
                <small>Si dejas una fila vacía, no se guardará. Debes ingresar al menos tres criterios.</small>
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

.form-field small {
    color: var(--text-secondary);
    margin-top: 4px;
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
