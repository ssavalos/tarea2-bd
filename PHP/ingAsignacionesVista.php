<?php
session_start();
require_once 'includes/auth_guard.php';
require_once 'db.php';

if ($_SESSION['rol'] !== 'ingeniero') {
    header('Location: userDashboard.php');
    exit;
}

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$conn->set_charset('utf8mb4');

$rut = $_SESSION['rut'];
$page_title = 'Vista de Asignaciones';
$css_path = './';
$nav_path = './';

$conn->query("
    UPDATE Funcionalidad
    SET estado_funcion = 'Cerrado'
    WHERE estado_funcion = 'Resuelto'
      AND resuelto_en IS NOT NULL
      AND resuelto_en <= DATE_SUB(NOW(), INTERVAL 3 DAY)
");
$conn->query("
    UPDATE ErrorBug
    SET estado_error = 'Cerrado'
    WHERE estado_error = 'Resuelto'
      AND resuelto_en IS NOT NULL
      AND resuelto_en <= DATE_SUB(NOW(), INTERVAL 3 DAY)
");

$registros = [];
if ($stmt = $conn->prepare("SELECT tipo, id_solicitud, titulo, topico, estado, fecha, resumen_funcion, ambiente_funcion, solicitante FROM v_asignado_a_ingeniero WHERE ing_rut = ? ORDER BY fecha DESC")) {
    $stmt->bind_param("s", $rut);
    if ($stmt->execute()) {
        $result = $stmt->get_result();
        $registros = $result ? $result->fetch_all(MYSQLI_ASSOC) : [];
    }
    $stmt->close();
}

include 'includes/header.php';
?>

<div class="main-container">
    <div class="glass-card">
        <h2><i class="fas fa-eye"></i> Asignaciones desde la vista SQL</h2>

        <?php if (empty($registros)): ?>
            <div class="empty-state">
                <i class="fas fa-inbox"></i>
                <p>No hay asignaciones registradas.</p>
            </div>
        <?php else: ?>
            <div class="table-wrapper">
                <table class="styled-table">
                    <thead>
                        <tr>
                            <th>Tipo</th>
                            <th>ID</th>
                            <th>Título</th>
                            <th>Tópico</th>
                            <th>Estado</th>
                            <th>Fecha</th>
                            <th>Solicitante</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($registros as $row): ?>
                        <tr>
                            <td><span class="tipo-tag tipo-<?php echo htmlspecialchars($row['tipo']); ?>"><?php echo strtoupper($row['tipo']); ?></span></td>
                            <td><?php echo htmlspecialchars($row['id_solicitud']); ?></td>
                            <td><?php echo htmlspecialchars($row['titulo']); ?></td>
                            <td><?php echo htmlspecialchars($row['topico']); ?></td>
                            <td><span class="badge estado-<?php echo strtolower(str_replace(' ', '', $row['estado'])); ?>"><?php echo htmlspecialchars($row['estado']); ?></span></td>
                            <td><?php echo date('d/m/Y', strtotime($row['fecha'])); ?></td>
                            <td><?php echo htmlspecialchars($row['solicitante']); ?></td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </div>
</div>

<style>
.tipo-tag {
    display: inline-block;
    padding: 4px 8px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: bold;
    background: rgba(0, 89, 255, 0.15);
    color: var(--primary-blue);
    text-transform: uppercase;
}
.tipo-error {
    background: rgba(220, 53, 69, 0.15);
    color: #dc3545;
}
</style>

<?php include 'includes/footer.php'; ?>
