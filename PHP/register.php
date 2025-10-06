<?php
// register.php
session_start();
include 'db.php';

$errors = array();
$success = "";

$topics = [];
if ($resultTopics = $conn->query('SELECT id_topico, nombre_topico FROM Topico ORDER BY nombre_topico')) {
    while ($row = $resultTopics->fetch_assoc()) {
        $topics[] = $row;
    }
    $resultTopics->free();
}

$especialidades_seleccionadas = isset($_POST['especialidades']) && is_array($_POST['especialidades'])
    ? array_map('strval', $_POST['especialidades'])
    : [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $rut = isset($_POST['rut']) ? trim($_POST['rut']) : '';
    $nombre = isset($_POST['nombre']) ? trim($_POST['nombre']) : '';
    $email = isset($_POST['email']) ? trim($_POST['email']) : '';
    $password = isset($_POST['password']) ? $_POST['password'] : '';
    $password_confirm = isset($_POST['password_confirm']) ? $_POST['password_confirm'] : '';
    $rol = isset($_POST['rol']) ? $_POST['rol'] : '';
    $especialidades = isset($_POST['especialidades']) && is_array($_POST['especialidades'])
        ? array_unique(array_map('intval', $_POST['especialidades']))
        : [];
    $especialidades_seleccionadas = array_map('strval', $especialidades);

    // Validaciones básicas
    // Validar formato de RUT
    if (!preg_match('/^[0-9]{7,8}-[0-9Kk]$/', $rut)) {
        $errors[] = "El RUT debe tener el formato: 12345678-9 o 1234567-K";
    }

    // Validar nombre
    if (strlen($nombre) < 2) {
        $errors[] = "El nombre debe tener al menos 2 caracteres.";
    }

    // Validar email
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $errors[] = "El email no tiene un formato válido.";
    }

    // Validar contraseña
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

    if ($rol === 'ingeniero') {
        if (empty($topics)) {
            $errors[] = 'No hay tópicos configurados para asignar especialidades. Contacta al administrador.';
        }
        if (count($especialidades) < 1 || count($especialidades) > 2) {
            $errors[] = 'Debes seleccionar entre 1 y 2 especialidades.';
        } else {
            $valid_ids = array_map('intval', array_column($topics, 'id_topico'));
            foreach ($especialidades as $esp) {
                if (!in_array($esp, $valid_ids, true)) {
                    $errors[] = 'Una de las especialidades seleccionadas no es válida.';
                    break;
                }
            }
        }
    }

    // Revisar si el RUT ya existe en Auth_User
    $stmt = $conn->prepare("SELECT id FROM Auth_User WHERE rut = ?");
    $stmt->bind_param("s", $rut);
    $stmt->execute();
    $stmt->store_result();
    if ($stmt->num_rows > 0) {
        $errors[] = "Este RUT ya está registrado.";
    }
    $stmt->close();

    // Insertar en la base si no hay errores
    if (empty($errors)) {
        try {
            // Iniciar transacción
            $conn->autocommit(FALSE);
            
            $password_hash = password_hash($password, PASSWORD_DEFAULT);

            // 1. Insertar en la tabla Usuario o Ingeniero según el rol
            if ($rol === 'usuario') {
                $stmt = $conn->prepare("INSERT INTO Usuario (user_rut, user_nombre, user_email) VALUES (?, ?, ?)");
                $stmt->bind_param("sss", $rut, $nombre, $email);
            } else { // ingeniero
                $stmt = $conn->prepare("INSERT INTO Ingeniero (ing_rut, nombre_ing, email_ing) VALUES (?, ?, ?)");
                $stmt->bind_param("sss", $rut, $nombre, $email);
            }
            
            if (!$stmt->execute()) {
                throw new Exception("Error al crear el perfil: " . $stmt->error);
            }
            $stmt->close();

            if ($rol === 'ingeniero') {
                $stmtEsp = $conn->prepare('INSERT INTO Ingeniero_Especialidad (id_topico, ing_rut) VALUES (?, ?)');
                foreach ($especialidades as $esp) {
                    $stmtEsp->bind_param('is', $esp, $rut);
                    if (!$stmtEsp->execute()) {
                        throw new Exception('Error al registrar especialidades: ' . $stmtEsp->error);
                    }
                }
                $stmtEsp->close();
            }

            // 2. Insertar en Auth_User
            $stmt = $conn->prepare("INSERT INTO Auth_User (rut, pass_hash, rol) VALUES (?, ?, ?)");
            $stmt->bind_param("sss", $rut, $password_hash, $rol);
            
            if (!$stmt->execute()) {
                throw new Exception("Error al crear las credenciales: " . $stmt->error);
            }
            $stmt->close();

            // Confirmar transacción
            $conn->commit();
            $conn->autocommit(TRUE);
            
            $success = "Usuario registrado correctamente. Puedes <a href='index.php'>iniciar sesión</a>.";
            
        } catch (Exception $e) {
            // Revertir transacción en caso de error
            $conn->rollback();
            $conn->autocommit(TRUE);
            $errors[] = $e->getMessage();
        }
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
    <!-- Estilos comunes -->
    <link rel="stylesheet" href="assets/css/style.css">
    <!-- Script para formateo de RUT -->
    <script src="assets/js/rut-formatter.js"></script>
<style>
    /* Estilos específicos solo para registro */
    body {
        display: flex; 
        justify-content: center; 
        align-items: center; 
        min-height: 100vh; 
        padding: 20px 0;
    }
    
    /* Labels específicos para el registro */
    label {
        display: block;
        margin-bottom: 15px;
        font-weight: bold;
        color: #555;
        font-size: 14px;
    }

    .label-helper {
        font-weight: bold;
        color: #555;
        margin: 10px 0 8px;
    }

    .especialidades-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
        gap: 10px;
        margin-bottom: 15px;
    }

    .checkbox-inline {
        font-weight: normal;
        color: #444;
    }

    .empty-specialty {
        font-size: 13px;
        color: var(--text-secondary);
        font-style: italic;
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
                RUT:
                <div class="rut-input">
                    <input type="text" name="rut" placeholder="Ej: 12345678-9" required value="<?php echo isset($_POST['rut']) ? htmlspecialchars($_POST['rut']) : ''; ?>" data-rut>
                </div>
            </label>
            
            <label>
                Nombre completo:
                <input type="text" name="nombre" placeholder="Ingresa tu nombre completo" required value="<?php echo isset($_POST['nombre']) ? htmlspecialchars($_POST['nombre']) : ''; ?>">
            </label>
            
            <label>
                Email:
                <input type="email" name="email" placeholder="tu@email.com" required value="<?php echo isset($_POST['email']) ? htmlspecialchars($_POST['email']) : ''; ?>">
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
                <select name="rol" id="rol-select">
                    <option value="usuario" <?php echo (isset($_POST['rol']) && $_POST['rol'] === 'usuario') ? 'selected' : ''; ?>>Usuario</option>
                    <option value="ingeniero" <?php echo (isset($_POST['rol']) && $_POST['rol'] === 'ingeniero') ? 'selected' : ''; ?>>Ingeniero</option>
                </select>
            </label>

            <div id="especialidades-section" class="especialidades-section" style="display: none;">
                <p class="label-helper">Selecciona entre 1 y 2 especialidades:</p>
                <div class="especialidades-grid">
                    <?php foreach ($topics as $topic): ?>
                        <label class="checkbox-inline">
                            <input type="checkbox" name="especialidades[]" value="<?php echo $topic['id_topico']; ?>" <?php echo in_array((string)$topic['id_topico'], $especialidades_seleccionadas, true) ? 'checked' : ''; ?>>
                            <?php echo htmlspecialchars($topic['nombre_topico']); ?>
                        </label>
                    <?php endforeach; ?>
                </div>
                <?php if (empty($topics)): ?>
                    <p class="empty-specialty">No hay tópicos disponibles actualmente. Consulta con el administrador.</p>
                <?php endif; ?>
            </div>
            
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

    const rolSelect = document.getElementById('rol-select');
    const especialidadesSection = document.getElementById('especialidades-section');

    function toggleEspecialidades() {
        if (!rolSelect) return;
        especialidadesSection.style.display = rolSelect.value === 'ingeniero' ? 'block' : 'none';
    }

    if (rolSelect) {
        rolSelect.addEventListener('change', toggleEspecialidades);
        toggleEspecialidades();
    }
});
</script>
</body>
</html>
