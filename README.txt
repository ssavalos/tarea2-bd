================================================================================
                      TAREA 2 - BASES DE DATOS
================================================================================

INTEGRANTES:
------------
- Néstor López Opazo       ROL: 202304074-6
- Sofía Ávalos             ROL: 202373011-4


================================================================================
                        ESTRUCTURA DEL PROYECTO
================================================================================

tarea2-bd/
├── BD/                         # Scripts de Base de Datos
│   ├── create_mysql.sql        # Definición de tablas y estructura
│   ├── auth_user.sql          # Tabla de autenticación
│   ├── triggers.sql           # Triggers de validación e integridad
│   ├── procedimientos.sql     # Procedimientos almacenados
│   ├── funciones.sql          # Funciones definidas por el usuario
│   ├── vistas.sql             # Vistas para consultas complejas
│   ├── tarea2sof.sql          # Script completo de importación (opción 1)
│   ├── tarea2nes.sql          # Script completo alternativo (opción 2)
│   ├── poblar_BD.py           # Script Python para poblar con datos
│   └── despoblar_BD.py        # Script para limpiar la base de datos
│
├── PHP/                        # Aplicación Web
│   ├── index.php              # Página principal
│   ├── login.php              # Sistema de autenticación
│   ├── register.php           # Registro de usuarios
│   ├── userDashboard.php      # Dashboard para usuarios
│   ├── ingDashboard.php       # Dashboard para ingenieros
│   ├── db.php                 # Configuración de conexión a BD
│   │
│   ├── funcionalidad/         # Módulo de funcionalidades
│   │   ├── crear.php          # Crear funcionalidad
│   │   ├── editar.php         # Editar funcionalidad
│   │   ├── eliminar.php       # Eliminar funcionalidad
│   │   ├── listar.php         # Listar con filtros avanzados
│   │   └── reviews.php        # Sistema de reseñas
│   │
│   ├── error/                 # Módulo de errores
│   │   ├── crear.php          # Reportar error
│   │   ├── editar.php         # Editar error
│   │   ├── eliminar.php       # Eliminar error
│   │   ├── listar.php         # Listar con filtros avanzados
│   │   └── reviews.php        # Sistema de reseñas
│   │
│   └── includes/              # Archivos compartidos
│       ├── header.php         # Header HTML común
│       └── auth_guard.php     # Protección de rutas
│
├── PDF/                        # Documentación
│   └── Normalizacion Tarea2.pdf
│
└── .env                        # Configuración de base de datos


================================================================================
                        REQUISITOS DEL SISTEMA
================================================================================

SOFTWARE NECESARIO:
-------------------
1. MAMP (Mac) o XAMPP/WAMP (Windows/Linux)
   - Apache 2.4+
   - PHP 8.0+
   - MySQL 5.7+ o MariaDB 10.3+

2. Python 3.8+ (solo para script de poblamiento)
   - Librerías: faker, mysql-connector-python, python-dotenv

3. Navegador web (Chrome, Firefox, Safari, Edge)


================================================================================
                     INSTRUCCIONES DE INSTALACIÓN
================================================================================

PASO 1: CONFIGURAR EL SERVIDOR
-------------------------------
1. Instalar MAMP/XAMPP según tu sistema operativo
2. Iniciar los servicios Apache y MySQL
3. Verificar que los servicios estén corriendo correctamente


PASO 2: CREAR LA BASE DE DATOS
-------------------------------
Tienes 3 opciones para importar la base de datos:

OPCIÓN A - Importación completa (Recomendado y pobladas):
   1. Abrir phpMyAdmin (http://localhost:8888/phpMyAdmin o similar)
   2. Importar el archivo: BD/tarea2sof.sql o BD/tarea2nes.sql

OPCIÓN B - Importación modular (Más confiable):
   1. Abrir phpMyAdmin
   2. Importar los archivos en este ORDEN:
      a) BD/create_mysql.sql       (tablas y estructura)
      b) BD/auth_user.sql          (tabla de autenticación)
      c) BD/triggers.sql           (triggers de validación)
      d) BD/procedimientos.sql     (procedimientos almacenados)
      e) BD/funciones.sql          (funciones personalizadas)
      f) BD/vistas.sql             (vistas)

OPCIÓN C - Usando consola MySQL:
   $ mysql -u root -p < BD/tarea2.sql

IMPORTANTE: Si usas la OPCIÓN B, la base de datos estará vacía. 
            Continúa con el PASO 3 para poblarla con datos de prueba.


PASO 3: POBLAR CON DATOS DE PRUEBA, (solo usar este script si se usó la opción B más arriba.)
---------------------------------------------------------------
1. Navegar a la carpeta BD:
   $ cd BD

2. Instalar dependencias Python:
   $ pip install faker mysql-connector-python python-dotenv

3. Configurar el archivo .env en la raíz del proyecto:
   DB_NAME=tarea2
   DB_USER=root
   DB_PASS=root        # "" si usas XAMPP
   DB_HOST=localhost
   DB_PORT=8889        # Cambiar a 3306 si usas XAMPP

4. Ejecutar el script de poblamiento:
   $ python poblar_BD.py
   
   Esto creará:
   - 50 usuarios con credenciales
   - 80 ingenieros con especialidades
   - 300 errores reportados
   - 200 funcionalidades con criterios
   - 10 tópicos diferentes
   - Asignaciones automáticas
   - Reseñas de ejemplo

5. Credenciales de acceso generadas:
   contraseña: password (para todos los usuarios generados)


PASO 4: CONFIGURAR LA APLICACIÓN WEB
-------------------------------------
1. Copiar la carpeta del proyecto a la carpeta htdocs de MAMP/XAMPP:
   MAMP:  /Applications/MAMP/htdocs/tarea2-bd
   XAMPP: C:\xampp\htdocs\tarea2-bd  (Windows)
          /opt/lampp/htdocs/tarea2-bd  (Linux)

2. Editar el archivo PHP/db.php con tus credenciales:
   $host = 'localhost';
   $port = '8889';      // Cambiar a 3306 si usas XAMPP
   $dbname = 'tarea2';
   $username = 'root';
   $password = 'root';


PASO 5: ACCEDER A LA APLICACIÓN
--------------------------------
1. Abrir el navegador web
2. Navegar a: http://localhost:8888/tarea2-bd/PHP/
   (o http://localhost/tarea2-bd/PHP/ si usas XAMPP)
3. Iniciar sesión con las credenciales de prueba
4. usar la página xd. 
