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

// Si ya hay sesión iniciada, redirige al dashboard correspondiente
if (isset($_SESSION['rol'])) {
    if ($_SESSION['rol'] === 'ingeniero') {
        header("Location: ingDashboard.php");
    } else {
        header("Location: userDashboard.php");
    }
    exit;
}

// Procesar login si es POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $rut = trim($_POST['rut']);
    $password = $_POST['password'];
    $user_type = $_POST['user_type'] ?? 'usuario'; // 'usuario' o 'ingeniero'

    // Verificar según el tipo de usuario seleccionado
    if ($user_type === 'ingeniero') {
        // Verificar en tabla Ingeniero y Auth_User
        $stmt = $conn->prepare("SELECT au.id, au.rut, au.pass_hash, au.rol, i.nombre_ing as nombre_completo 
                                FROM Auth_User au 
                                INNER JOIN Ingeniero i ON au.rut = i.ing_rut 
                                WHERE au.rut = ? AND au.rol = 'ingeniero'");
    } else {
        // Verificar en tabla Usuario y Auth_User
        $stmt = $conn->prepare("SELECT au.id, au.rut, au.pass_hash, au.rol, u.user_nombre as nombre_completo 
                                FROM Auth_User au 
                                INNER JOIN Usuario u ON au.rut = u.user_rut 
                                WHERE au.rut = ? AND au.rol = 'usuario'");
    }
    
    $stmt->bind_param("s", $rut);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        if ($user_type === 'ingeniero') {
            $errors[] = "Ingeniero no encontrado o credenciales incorrectas.";
        } else {
            $errors[] = "Usuario no encontrado o credenciales incorrectas.";
        }
    } else {
        $user = $result->fetch_assoc();
        // Verificar contraseña
        if (password_verify($password, $user['pass_hash'])) {
            // Inicio de sesión exitoso
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['rut'] = $user['rut'];
            $_SESSION['nombre'] = $user['nombre_completo'];
            $_SESSION['rol'] = $user['rol'];

            // Redirigir según el rol del usuario
            if ($user['rol'] === 'ingeniero') {
                header("Location: ingDashboard.php");
            } else {
                header("Location: userDashboard.php");
            }
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
        
        .user-type-tabs {
            display: flex;
            margin-bottom: 20px;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }
        
        .tab {
            flex: 1;
            padding: 12px 20px;
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            color: #666;
            cursor: pointer;
            transition: all 0.3s ease;
            font-weight: bold;
            border: 1px solid rgba(255, 255, 255, 0.2);
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        
        .tab:hover {
            background: rgba(255, 255, 255, 0.2);
            color: #333;
        }
        
        .tab.active {
            background: var(--primary-blue);
            color: white;
            box-shadow: 0 2px 8px rgba(0, 89, 255, 0.3);
        }
        
        .tab i {
            font-size: 16px;
        }
        
        #login-btn {
            transition: all 0.3s ease;
        }
        
        .test-credentials {
            margin-top: 20px;
            padding: 15px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 8px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            font-size: 12px;
        }
        
        .test-credentials h4 {
            margin: 0 0 10px 0;
            color: var(--primary-blue);
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
        }
        
        .credential-item {
            margin: 5px 0;
            padding: 5px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 4px;
            font-family: monospace;
        }
        
        .credential-item strong {
            color: var(--primary-blue);
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
            <!-- Pestañas para seleccionar tipo de usuario -->
            <div class="user-type-tabs">
                <div class="tab <?php echo (!isset($_POST['user_type']) || $_POST['user_type'] === 'usuario') ? 'active' : ''; ?>" onclick="switchTab('usuario')">
                    <i class="fas fa-user"></i> Usuario
                </div>
                <div class="tab <?php echo (isset($_POST['user_type']) && $_POST['user_type'] === 'ingeniero') ? 'active' : ''; ?>" onclick="switchTab('ingeniero')">
                    <i class="fas fa-user-cog"></i> Ingeniero
                </div>
            </div>
            
            <input type="hidden" name="user_type" id="user_type" value="<?php echo isset($_POST['user_type']) ? htmlspecialchars($_POST['user_type']) : 'usuario'; ?>">
            
            <div class="rut-input">
                <input type="text" name="rut" placeholder="RUT (Ej: 12345678-9)" required value="<?php echo isset($_POST['rut']) ? htmlspecialchars($_POST['rut']) : ''; ?>" data-rut>
            </div>
            
            <div class="password-container">
                <input type="password" name="password" id="password" placeholder="Contraseña" required>
                <span class="password-toggle" onclick="togglePassword('password')">
                    <i class="fas fa-eye"></i>
                </span>
            </div>
            
            <button type="submit" id="login-btn">
                <i class="fas fa-sign-in-alt"></i> 
                <?php 
                if (isset($_POST['user_type']) && $_POST['user_type'] === 'ingeniero') {
                    echo 'Entrar como Ingeniero';
                } else {
                    echo 'Entrar como Usuario';
                }
                ?>
            </button>
        </form>
        <p>¿No tienes cuenta? <a href="register.php">Regístrate aquí</a></p>
        
        

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

    function switchTab(userType) {
        // Actualizar pestañas visuales
        document.querySelectorAll('.tab').forEach(tab => tab.classList.remove('active'));
        event.target.closest('.tab').classList.add('active');
        
        // Actualizar valor del input hidden
        document.getElementById('user_type').value = userType;
        
        // Actualizar texto del botón
        const loginBtn = document.getElementById('login-btn');
        if (userType === 'ingeniero') {
            loginBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i> Entrar como Ingeniero';
        } else {
            loginBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i> Entrar como Usuario';
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

        // Inicializar el estado correcto del botón según el tipo de usuario
        const userType = document.getElementById('user_type').value;
        const loginBtn = document.getElementById('login-btn');
        if (userType === 'ingeniero') {
            loginBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i> Entrar como Ingeniero';
        } else {
            loginBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i> Entrar como Usuario';
        }

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
