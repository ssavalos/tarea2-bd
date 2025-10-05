<?php
// register.php
session_start();
include 'db.php';

$errors = [];
$success = "";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username']);
    $password = $_POST['password'];
    $password_confirm = $_POST['password_confirm'];
    $rol = $_POST['rol'];

    // Validaciones básicas
    if (strlen($username) < 3) {
        $errors[] = "El nombre de usuario debe tener al menos 3 caracteres.";
    }

    if (strlen($password) < 6) {
        $errors[] = "La contraseña debe tener al menos 6 caracteres.";
    }

    // Validar que la contraseña no contenga espacios
    if (strpos($password, ' ') !== false) {
        $errors[] = "La contraseña no puede contener espacios.";
    }

    if ($password !== $password_confirm) {
        $errors[] = "Las contraseñas no coinciden.";
    }

    // Revisar si el username ya existe
    $stmt = $conn->prepare("SELECT id FROM Auth_User WHERE username = ?");
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $stmt->store_result();
    if ($stmt->num_rows > 0) {
        $errors[] = "El nombre de usuario ya está en uso.";
    }
    $stmt->close();

    // Insertar en la base si no hay errores
    if (empty($errors)) {
        $password_hash = password_hash($password, PASSWORD_DEFAULT);

        // Nota: user_rut / ing_rut pueden ser NULL por ahora
        $stmt = $conn->prepare("INSERT INTO Auth_User (username, pass_hash, rol) VALUES (?, ?, ?)");
        $stmt->bind_param("sss", $username, $password_hash, $rol);
        if ($stmt->execute()) {
            $success = "Usuario registrado correctamente. Puedes <a href='index.php'>iniciar sesión</a>.";
        } else {
            $errors[] = "Error al registrar: " . $stmt->error;
        }
        $stmt->close();
    }
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Registro</title>
<!-- Font Awesome para iconos -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
    body { 
        font-family: Arial, sans-serif; 
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        display: flex; 
        justify-content: center; 
        align-items: center; 
        min-height: 100vh; 
        margin: 0;
        padding: 20px 0;
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
    .register-container { 
        background: rgba(255, 255, 255, 0.95); 
        backdrop-filter: blur(10px);
        padding: 35px; 
        border-radius: 15px; 
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3); 
        width: 350px; 
        max-width: 90%;
        border: 1px solid rgba(255, 255, 255, 0.2);
        position: relative;
        z-index: 1;
    }
    input[type="text"], input[type="password"], select { 
        width: calc(100%); 
        padding: 10px 8px; 
        margin: 8px 0; 
        border: 1px solid #ddd;
        border-radius: 4px;
        box-sizing: border-box;
        font-size: 14px;
    }
    .password-container {
        position: relative;
        display: block;
        margin: 8px 0;
    }
    .password-container input[type="password"], 
    .password-container input[type="text"] {
        width: calc(100%);
        padding: 10px 35px 10px 8px;
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
        color: #0059ffff;;
    }
    .password-toggle i {
        pointer-events: none;
    }
    button { 
        width: 100%; 
        padding: 12px; 
        background: #0059ffff; 
        color: white; 
        border: none; 
        cursor: pointer; 
        border-radius: 4px;
        font-size: 16px;
        margin: 15px 0 10px 0;
        font-weight: bold;
    }
    button:hover { 
        background: #2a00b3b8; 
    }
    .error-list {
        color: red;
        margin: 15px 0;
        padding: 0;
        list-style-type: none;
    }
    .error-list li {
        background: #ffe6e6;
        padding: 10px;
        margin: 5px 0;
        border-radius: 4px;
        border-left: 4px solid red;
        font-size: 14px;
    }
    .success-message {
        color: #2a00b3b8;
        background: #e6ffe6;
        padding: 10px;
        margin: 15px 0;
        border-radius: 4px;
        border-left: 4px solid #0059ffff;;
        font-size: 14px;
    }
    h2 {
        text-align: center;
        color: #333;
        margin-bottom: 25px;
        font-size: 24px;
    }
    p {
        text-align: center;
        margin-top: 20px;
        font-size: 14px;
    }
    a {
        color: #0059ffff;;
        text-decoration: none;
        font-weight: bold;
    }
    a:hover {
        color: #2a00b3b8;
        text-decoration: underline;
    }
    label {
        display: block;
        margin-bottom: 15px;
        font-weight: bold;
        color: #555;
        font-size: 14px;
    }
    select {
        padding: 10px 8px;
    }
    body {
        background: url('assets/images/fondo.png') center/cover no-repeat;
        background-attachment: fixed;
    }
</style>
</head>
<body>
    <div class="register-container">
        <h2>Crear cuenta</h2>
        
        <?php
        if (!empty($errors)) {
            echo "<ul class='error-list'>";
            foreach ($errors as $err) {
                echo "<li>$err</li>";
            }
            echo "</ul>";
        }

        if ($success !== "") {
            echo "<div class='success-message'>$success</div>";
        }
        ?>
        
        <form method="POST">
            <label>
                Usuario:
                <input type="text" name="username" placeholder="Ingresa tu nombre de usuario" required value="<?php echo isset($_POST['username']) ? htmlspecialchars($_POST['username']) : ''; ?>">
            </label>
            
            <label>
                Contraseña:
                <div class="password-container">
                    <input type="password" name="password" id="password" placeholder="Mínimo 6 caracteres" required>
                    <span class="password-toggle" onclick="togglePassword('password')">
                        <i class="fas fa-eye"></i>
                    </span>
                </div>
            </label>
            
            <label>
                Confirmar Contraseña:
                <div class="password-container">
                    <input type="password" name="password_confirm" id="password_confirm" placeholder="Repite tu contraseña" required>
                    <span class="password-toggle" onclick="togglePassword('password_confirm')">
                        <i class="fas fa-eye"></i>
                    </span>
                </div>
            </label>
            
            <label>
                Tipo de cuenta:
                <select name="rol">
                    <option value="usuario" <?php echo (isset($_POST['rol']) && $_POST['rol'] === 'usuario') ? 'selected' : ''; ?>>Usuario</option>
                    <option value="ingeniero" <?php echo (isset($_POST['rol']) && $_POST['rol'] === 'ingeniero') ? 'selected' : ''; ?>>Ingeniero</option>
                </select>
            </label>
            
            <button type="submit">Crear cuenta</button>
        </form>

        <p>¿Ya tienes cuenta? <a href="index.php">Inicia sesión aquí</a></p>
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
});
</script>
</body>
</html>
