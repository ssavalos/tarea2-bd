# 🎨 Opciones de Fondos para Login/Register

## ✅ **Opción 1: Gradiente Moderno (YA APLICADA)**
```css
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
```
**Características:**
- ✅ Profesional y moderno
- ✅ No requiere imágenes externas
- ✅ Carga rápido
- ✅ Efecto glassmorphism en los contenedores

---

## **Opción 2: Gradiente Verde (Acorde a tu tema)**
```css
background: linear-gradient(135deg, #00ff59ff 0%, #00b383b8 50%, #667eea 100%);
```

---

## **Opción 3: Gradiente Nocturno**
```css
background: linear-gradient(135deg, #2c3e50 0%, #34495e 50%, #2c3e50 100%);
```

---

## **Opción 4: Imagen de fondo con URL**
```css
body {
    background: url('https://images.unsplash.com/photo-1557683316-973673baf926?w=1920') center/cover;
    background-attachment: fixed;
}

/* Overlay opcional para mejor legibilidad */
body::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.4);
    pointer-events: none;
}
```

---

## **Opción 5: Imagen local (tu propia imagen)**
```css
body {
    background: url('assets/images/background.jpg') center/cover no-repeat;
    background-attachment: fixed;
}
```

**Para usar tu propia imagen:**
1. Guarda tu imagen en: `PHP/assets/images/background.jpg`
2. Cambia el CSS del body por el código de arriba

---

## **Opción 6: Patrón Geométrico**
```css
background: 
    linear-gradient(90deg, rgba(200,0,0,.5) 50%, transparent 50%), 
    linear-gradient(rgba(200,0,0,.5) 50%, transparent 50%);
background-size: 50px 50px;
background-color: #667eea;
```

---

## **Opción 7: Animación de Gradiente**
```css
background: linear-gradient(-45deg, #ee7752, #e73c7e, #23a6d5, #23d5ab);
background-size: 400% 400%;
animation: gradientShift 15s ease infinite;

@keyframes gradientShift {
    0% { background-position: 0% 50%; }
    50% { background-position: 100% 50%; }
    100% { background-position: 0% 50%; }
}
```

---

## **Cómo cambiar el fondo:**

### **Para usar otra opción:**
1. Abre `index.php` y `register.php`
2. Busca la línea: `background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);`
3. Reemplázala con el código CSS de la opción que prefieras

### **Recomendaciones de imágenes:**
- **Tamaño**: Mínimo 1920x1080px
- **Formato**: JPG (más liviano) o PNG (mejor calidad)
- **Peso**: Máximo 500KB para carga rápida
- **Sitios gratuitos**: Unsplash, Pexels, Pixabay

### **Consejos de diseño:**
- ✅ Usa imágenes con colores suaves para no interferir con el texto
- ✅ Aplica overlay semi-transparente para mejor legibilidad
- ✅ Considera el contraste con los formularios blancos
- ✅ Prueba en diferentes tamaños de pantalla