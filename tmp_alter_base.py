import mysql.connector

conn = mysql.connector.connect(host='127.0.0.1', user='root', password='', database='tarea2', port=3306, autocommit=True)
cur = conn.cursor()

alter_stmts = [
    "ALTER TABLE Funcionalidad ADD COLUMN IF NOT EXISTS resuelto_en DATETIME NULL",
    "ALTER TABLE ErrorBug ADD COLUMN IF NOT EXISTS resuelto_en DATETIME NULL",
    "UPDATE Funcionalidad SET resuelto_en = NOW() WHERE resuelto_en IS NULL AND estado_funcion IN ('Resuelto','Cerrado')",
    "UPDATE ErrorBug SET resuelto_en = NOW() WHERE resuelto_en IS NULL AND estado_error IN ('Resuelto','Cerrado')"
]
for stmt in alter_stmts:
    cur.execute(stmt)

cur.close()
conn.close()
