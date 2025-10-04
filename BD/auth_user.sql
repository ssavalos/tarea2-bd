CREATE TABLE IF NOT EXISTS Auth_User (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(80) UNIQUE NOT NULL,
  pass_hash VARCHAR(255) NOT NULL,
  rol ENUM('usuario','ingeniero') NOT NULL,
  user_rut VARCHAR(12) NULL,
  ing_rut  VARCHAR(12) NULL,
  CONSTRAINT fk_auth_user FOREIGN KEY (user_rut) REFERENCES Usuario(user_rut),
  CONSTRAINT fk_auth_ing  FOREIGN KEY (ing_rut)  REFERENCES Ingeniero(ing_rut)
);
