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
    $username = trim($_POST['username']);
    $password = $_POST['password'];

    // Verificar que el usuario exista
    $stmt = $conn->prepare("SELECT id, username, pass_hash, rol FROM Auth_User WHERE username = ?");
    $stmt->bind_param("s", $username);
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
            $_SESSION['username'] = $user['username'];
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
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex; 
            justify-content: center; 
            align-items: center; 
            height: 100vh; 
            margin: 0;
            position: relative;
        }
        
        /* Efecto de partículas/patrón opcional */
        body::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-image: 
                radial-gradient(circle at 20% 80%, rgba(120, 119, 198, 0.3) 0%, transparent 50%),
                radial-gradient(circle at 80% 20%, rgba(255, 255, 255, 0.1) 0%, transparent 50%),
                radial-gradient(circle at 40% 40%, rgba(120, 119, 198, 0.2) 0%, transparent 50%);
            pointer-events: none;
        }
        .login-container { 
            background: rgba(255, 255, 255, 0.95); 
            backdrop-filter: blur(10px);
            padding: 30px; 
            border-radius: 15px; 
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3); 
            width: 300px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            position: relative;
            z-index: 1;
        }
        input[type="text"], input[type="password"] { 
            width: calc(100%); 
            padding: 8px; 
            margin: 8px 0; 
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
        }
        .password-container {
            position: relative;
            display: block;
            margin: 8px 0;
        }
        .password-container input[type="password"], 
        .password-container input[type="text"] {
            width: calc(100%);
            padding: 8px 35px 8px 8px;
            margin: 0;
        }
        .password-toggle {
            position: absolute;
            right: 15px;
            top: 50%;
            transform: translateY(-50%);
            cursor: pointer;
            user-select: none;
            color: #666;
            font-size: 16px;
            transition: color 0.3s ease;
        }
        .password-toggle:hover {
            color: #0059ffff;
        }
        .password-toggle i {
            pointer-events: none;
        }
        button { 
            width: 100%; 
            padding: 10px; 
            background: #0059ffff;; 
            color: white; 
            border: none; 
            cursor: pointer; 
            border-radius: 4px;
            font-size: 16px;
            margin: 8px 0;
        }
        button:hover { 
            background: #2a00b3b8; 
        }
        .error-list {
            color: red;
            margin: 10px 0;
            padding: 0;
            list-style-type: none;
        }
        .error-list li {
            background: #ffe6e6;
            padding: 8px;
            margin: 4px 0;
            border-radius: 4px;
            border-left: 4px solid red;
        }
        .success-message {
            background: #e6ffe6;
            color: #2a00b3b8;
            padding: 12px;
            margin: 10px 0;
            border-radius: 4px;
            border-left: 4px solid #0059ffff;
            font-size: 14px;
            text-align: center;
            font-weight: bold;
        }
        h2 {
            text-align: center;
            color: #333;
            margin-bottom: 20px;
        }
        p {
            text-align: center;
            margin-top: 15px;
        }
        a {
            color: #0059ffff;;
            text-decoration: none;
        }
        a:hover {
            color: #2a00b3b8;
            text-decoration: underline;
        }
        body {
        background: url('assets/images/fondo.png') center/cover no-repeat;
        background-attachment: fixed;
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
            <input type="text" name="username" placeholder="Usuario" required value="<?php echo isset($_POST['username']) ? htmlspecialchars($_POST['username']) : ''; ?>">
            
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
