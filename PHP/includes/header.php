<?php
// Header común para todas las páginas
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo isset($page_title) ? $page_title : 'Tarea 2 BD'; ?></title>
    <!-- Font Awesome para iconos -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Estilos comunes -->
    <link rel="stylesheet" href="<?php echo (isset($css_path) ? $css_path : '../') . 'assets/css/style.css'; ?>">
    <!-- Script para formateo de RUT -->
    <script src="<?php echo (isset($css_path) ? $css_path : '../') . 'assets/js/rut-formatter.js'; ?>"></script>
</head>
<body>

<?php 
// Navegación según rol si hay sesión activa
if (isset($_SESSION['rol'])): 
?>
<nav class="main-nav">
    <div class="nav-container">
        <div class="nav-brand">
            <h3><i class="fas fa-database"></i> Sistema BD</h3>
        </div>
        <div class="nav-links">
            <a href="<?php echo (isset($nav_path) ? $nav_path : '../') . 'main.php'; ?>" class="nav-button">
                <i class="fas fa-home"></i> Inicio
            </a>
            
            <?php if ($_SESSION['rol'] === 'usuario'): ?>
                <a href="<?php echo (isset($nav_path) ? $nav_path : '../') . 'funcionalidad/listar.php'; ?>" class="nav-button">
                    <i class="fas fa-cogs"></i> Funcionalidades
                </a>
                <a href="<?php echo (isset($nav_path) ? $nav_path : '../') . 'error/listar.php'; ?>" class="nav-button">
                    <i class="fas fa-bug"></i> Errores
                </a>
            <?php endif; ?>
            
            <?php if ($_SESSION['rol'] === 'ingeniero'): ?>
                <a href="<?php echo (isset($nav_path) ? $nav_path : '../') . 'funcionalidad/listar.php'; ?>" class="nav-button">
                    <i class="fas fa-tasks"></i> Asignaciones
                </a>
                <a href="<?php echo (isset($nav_path) ? $nav_path : '../') . 'error/listar.php'; ?>" class="nav-button">
                    <i class="fas fa-wrench"></i> Resolver Bugs
                </a>
            <?php endif; ?>
            
            <a href="<?php echo (isset($nav_path) ? $nav_path : '../') . 'logout.php'; ?>" class="nav-button logout-button">
                <i class="fas fa-sign-out-alt"></i> Cerrar Sesión
            </a>
        </div>
    </div>
</nav>
<?php endif; ?>

<style>
/* Estilos específicos para la navegación */
.main-nav {
    background: var(--glass-bg);
    backdrop-filter: blur(10px);
    border: 1px solid var(--glass-border);
    border-radius: 10px;
    margin-bottom: 20px;
    padding: 10px 20px;
    position: relative;
    z-index: 2;
}

.nav-container {
    display: flex;
    justify-content: space-between;
    align-items: center;
    max-width: 1200px;
    margin: 0 auto;
}

.nav-brand h3 {
    margin: 0;
    color: var(--primary-blue);
    font-size: 20px;
}

.nav-links {
    display: flex;
    gap: 10px;
    align-items: center;
    flex-wrap: wrap;
}

.nav-links .nav-button {
    padding: 8px 16px;
    font-size: 14px;
    margin: 2px;
}

@media (max-width: 768px) {
    .nav-container {
        flex-direction: column;
        gap: 15px;
    }
    
    .nav-links {
        justify-content: center;
    }
}
</style>