-- Crear BD y usarla
CREATE DATABASE IF NOT EXISTS tarea2
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
USE tarea2;

-- Para reimportar sin errores de FK
SET FOREIGN_KEY_CHECKS = 0;

-- ====== Drop en orden de dependencias ======
DROP TABLE IF EXISTS Resena_Error;
DROP TABLE IF EXISTS Resena_Funcionalidad;
DROP TABLE IF EXISTS Asignacion_Error;
DROP TABLE IF EXISTS Asignacion_Funcionalidad;
DROP TABLE IF EXISTS Criterio_Aceptacion;
DROP TABLE IF EXISTS ErrorBug;
DROP TABLE IF EXISTS Funcionalidad;
DROP TABLE IF EXISTS Ingeniero_Especialidad;
DROP TABLE IF EXISTS Ingeniero;
DROP TABLE IF EXISTS Topico;
DROP TABLE IF EXISTS Usuario;

-- ====== Tablas base ======
CREATE TABLE Usuario (
  user_rut VARCHAR(12) PRIMARY KEY,
  user_nombre VARCHAR(100) NOT NULL,
  user_email  VARCHAR(100) NOT NULL,
  CONSTRAINT chk_user_rut_format CHECK (user_rut REGEXP '^[0-9]{7,8}-[0-9Kk]$')
) ENGINE=InnoDB;

CREATE TABLE Topico (
  id_topico INT PRIMARY KEY AUTO_INCREMENT,
  nombre_topico VARCHAR(100) NOT NULL,
  UNIQUE KEY uq_topico_nombre (nombre_topico)
) ENGINE=InnoDB;

CREATE TABLE Ingeniero (
  ing_rut VARCHAR(12) PRIMARY KEY,
  nombre_ing VARCHAR(100) NOT NULL,
  email_ing  VARCHAR(100) NOT NULL,
  CONSTRAINT chk_ing_rut_format CHECK (ing_rut REGEXP '^[0-9]{7,8}-[0-9Kk]$')
) ENGINE=InnoDB;

CREATE TABLE Ingeniero_Especialidad (
  id_topico INT NOT NULL,
  ing_rut   VARCHAR(12) NOT NULL,
  PRIMARY KEY (id_topico, ing_rut),
  CONSTRAINT fk_ie_topico    FOREIGN KEY (id_topico) REFERENCES Topico(id_topico)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ie_ingeniero FOREIGN KEY (ing_rut)   REFERENCES Ingeniero(ing_rut)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Funcionalidad (
  id_funcionalidad INT PRIMARY KEY AUTO_INCREMENT,
  titulo_funcion     VARCHAR(100) NOT NULL,
  ambiente_funcion   ENUM('Web','Móvil') NULL,
  resumen_funcion    VARCHAR(150) NOT NULL,
  estado_funcion     ENUM('Abierto','En Progreso','Resuelto','Cerrado') NOT NULL,
  fecha_funcion      DATE NOT NULL,
  id_topico          INT NOT NULL,
  user_rut           VARCHAR(12) NOT NULL,
  CONSTRAINT fk_func_topico  FOREIGN KEY (id_topico) REFERENCES Topico(id_topico)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_func_usuario FOREIGN KEY (user_rut)  REFERENCES Usuario(user_rut)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_titulo_func_len CHECK (CHAR_LENGTH(titulo_funcion) >= 20),
  CONSTRAINT uq_titulo_func UNIQUE (titulo_funcion)
) ENGINE=InnoDB;

CREATE TABLE Criterio_Aceptacion (
  id_criterio INT PRIMARY KEY AUTO_INCREMENT,
  descripcion_criterio TEXT NOT NULL,
  id_funcionalidad INT NOT NULL,
  CONSTRAINT fk_crit_func FOREIGN KEY (id_funcionalidad) REFERENCES Funcionalidad(id_funcionalidad)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Resena_Funcionalidad (
  id_resena INT PRIMARY KEY AUTO_INCREMENT,
  id_funcionalidad INT NOT NULL,
  ing_rut VARCHAR(12) NOT NULL,
  comentario TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_rf_func FOREIGN KEY (id_funcionalidad) REFERENCES Funcionalidad(id_funcionalidad)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_rf_ing FOREIGN KEY (ing_rut) REFERENCES Ingeniero(ing_rut)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ErrorBug (
  id_bug        INT PRIMARY KEY AUTO_INCREMENT,
  titulo_error  VARCHAR(100) NOT NULL,
  descripcion_error VARCHAR(200) NOT NULL,
  fecha_error   DATE NOT NULL,
  estado_error  ENUM('Abierto','En Progreso','Resuelto','Cerrado') NOT NULL,
  id_topico     INT NOT NULL,
  user_rut      VARCHAR(12) NOT NULL,
  CONSTRAINT fk_bug_topico  FOREIGN KEY (id_topico) REFERENCES Topico(id_topico)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_bug_usuario FOREIGN KEY (user_rut)  REFERENCES Usuario(user_rut)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT uq_titulo_error UNIQUE (titulo_error)
) ENGINE=InnoDB;

CREATE TABLE Resena_Error (
  id_resena INT PRIMARY KEY AUTO_INCREMENT,
  id_bug INT NOT NULL,
  ing_rut VARCHAR(12) NOT NULL,
  comentario TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_re_error FOREIGN KEY (id_bug) REFERENCES ErrorBug(id_bug)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_re_ing FOREIGN KEY (ing_rut) REFERENCES Ingeniero(ing_rut)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Asignacion_Funcionalidad (
  id_funcionalidad INT NOT NULL,
  ing_rut          VARCHAR(12) NOT NULL,
  PRIMARY KEY (id_funcionalidad, ing_rut),
  CONSTRAINT fk_af_func FOREIGN KEY (id_funcionalidad) REFERENCES Funcionalidad(id_funcionalidad)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_af_ing  FOREIGN KEY (ing_rut)          REFERENCES Ingeniero(ing_rut)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Asignacion_Error (
  id_bug  INT NOT NULL,
  ing_rut VARCHAR(12) NOT NULL,
  PRIMARY KEY (id_bug, ing_rut),
  CONSTRAINT fk_ae_bug FOREIGN KEY (id_bug)  REFERENCES ErrorBug(id_bug)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ae_ing FOREIGN KEY (ing_rut) REFERENCES Ingeniero(ing_rut)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;
