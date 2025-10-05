<?php
// Footer común para todas las páginas
?>

<footer class="main-footer">
    <div class="footer-content">
        <p>&copy; <?php echo date('Y'); ?> Sistema de Gestión BD - Tarea 2</p>
        <p>Usuario: <strong><?php echo isset($_SESSION['nombre']) ? $_SESSION['nombre'] : 'Invitado'; ?></strong> 
        <?php if (isset($_SESSION['rol'])): ?>
            | Rol: <span class="role-badge"><?php echo ucfirst($_SESSION['rol']); ?></span>
        <?php endif; ?>
        </p>
    </div>
</footer>

<style>
.main-footer {
    background: var(--glass-bg);
    backdrop-filter: blur(10px);
    border: 1px solid var(--glass-border);
    border-radius: 10px;
    margin-top: 40px;
    padding: 20px;
    text-align: center;
    position: relative;
    z-index: 2;
}

.footer-content p {
    margin: 5px 0;
    color: var(--text-secondary);
    font-size: 14px;
}

.footer-content .role-badge {
    font-size: 12px;
    padding: 3px 8px;
}
</style>

</body>
</html>