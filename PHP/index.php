<?php
session_start();
include 'db.php'; // conexión a la BD

$errors = [];
$logout_message = "";

// Verificar si viene del logout
if (isset($_GET['logout']) && $_GET['logout'] === 'success') {
    $logout_message = "Has cerrado sesión correctamente.";
    // Limpiar la URL para evitar que persista el mensaje al recargar
    echo "<script>
        if (window.history.replaceState) {
            window.history.replaceState(null, null, window.location.pathname);
        }
    </script>";
}

// Si ya hay sesión iniciada, redirige a la página principal
if (isset($_SESSION['rol'])) {
    header("Location: main.php");
    exit;
}

// Procesar login si es POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $rut = trim($_POST['rut']);
    $password = $_POST['password'];

    // Verificar que el usuario exista
    $stmt = $conn->prepare("SELECT au.id, au.rut, au.pass_hash, au.rol, 
                                   COALESCE(u.user_nombre, i.nombre_ing) as nombre_completo 
                            FROM Auth_User au 
                            LEFT JOIN Usuario u ON au.rut = u.user_rut 
                            LEFT JOIN Ingeniero i ON au.rut = i.ing_rut 
                            WHERE au.rut = ?");
    $stmt->bind_param("s", $rut);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        $errors[] = "Usuario no encontrado.";
    } else {
        $user = $result->fetch_assoc();
        // Verificar contraseña
        if (password_verify($password, $user['pass_hash'])) {
            // Inicio de sesión exitoso
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['rut'] = $user['rut'];
            $_SESSION['nombre'] = $user['nombre_completo'];
            $_SESSION['rol'] = $user['rol'];

            // Redirigir a la página principal
            header("Location: main.php");
            exit;
        } else {
            $errors[] = "Contraseña incorrecta.";
        }
    }
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Login - Tarea 2</title>
    <!-- Font Awesome para iconos -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Estilos comunes -->
    <link rel="stylesheet" href="assets/css/style.css">
    <!-- Script para formateo de RUT -->
    <script src="assets/js/rut-formatter.js"></script>
    <style>
        /* Estilos específicos solo para login */
        body {
            display: flex; 
            justify-content: center; 
            align-items: center; 
            height: 100vh; 
            padding: 0;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <h2>Inicia sesión</h2>
        
        <?php
        if (!empty($logout_message)) {
            echo "<div class='success-message'>" . htmlspecialchars($logout_message) . "</div>";
        }
        
        if (!empty($errors)) {
            echo "<ul class='error-list'>";
            foreach ($errors as $err) {
                echo "<li>$err</li>";
            }
            echo "</ul>";
        }
        ?>
        
        <form method="POST">
            <div class="rut-input">
                <input type="text" name="rut" placeholder="RUT (Ej: 12345678-9)" required value="<?php echo isset($_POST['rut']) ? htmlspecialchars($_POST['rut']) : ''; ?>" data-rut>
            </div>
            
            <div class="password-container">
                <input type="password" name="password" id="password" placeholder="Contraseña" required>
                <span class="password-toggle" onclick="togglePassword('password')">
                    <i class="fas fa-eye"></i>
                </span>
            </div>
            
            <button type="submit">Entrar</button>
        </form>
        <p>¿No tienes cuenta? <a href="register.php">Regístrate aquí</a></p>
    </div>

    <script>
    function togglePassword(fieldId) {
        const passwordField = document.getElementById(fieldId);
        const toggleIcon = passwordField.nextElementSibling.querySelector('i');
        
        if (passwordField.type === 'password') {
            passwordField.type = 'text';
            toggleIcon.className = 'fas fa-eye-slash';
        } else {
            passwordField.type = 'password';
            toggleIcon.className = 'fas fa-eye';
        }
    }

    // Prevenir espacios en campos de contraseña
    function preventSpaces(event) {
        if (event.key === ' ' || event.keyCode === 32) {
            event.preventDefault();
            return false;
        }
    }

    // Aplicar la función a los campos de contraseña cuando se carga la página
    document.addEventListener('DOMContentLoaded', function() {
        const passwordFields = document.querySelectorAll('input[type="password"]');
        passwordFields.forEach(function(field) {
            field.addEventListener('keydown', preventSpaces);
            field.addEventListener('keypress', preventSpaces);
        });

        // Auto-fade del mensaje de logout después de 4 segundos
        const successMessage = document.querySelector('.success-message');
        if (successMessage) {
            setTimeout(function() {
                successMessage.style.transition = 'opacity 0.5s ease-out';
                successMessage.style.opacity = '0';
                setTimeout(function() {
                    successMessage.style.display = 'none';
                }, 500);
            }, 4000);
        }
    });
    </script>
</body>
</html>
