CREATE TABLE IF NOT EXISTS Auth_User (
  id INT AUTO_INCREMENT PRIMARY KEY,
  rut VARCHAR(12) UNIQUE NOT NULL,
  pass_hash VARCHAR(255) NOT NULL,
  rol ENUM('usuario','ingeniero') NOT NULL,
  CONSTRAINT chk_auth_rut_format CHECK (rut REGEXP '^[0-9]{7,8}-[0-9Kk]$'),
  CONSTRAINT fk_auth_user_rut FOREIGN KEY (rut) REFERENCES Usuario(user_rut) ON DELETE CASCADE,
  CONSTRAINT fk_auth_ing_rut  FOREIGN KEY (rut) REFERENCES Ingeniero(ing_rut) ON DELETE CASCADE
);
