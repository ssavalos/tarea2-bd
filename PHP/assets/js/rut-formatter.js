/**
 * Funciones para formateo automático de RUT chileno
 */

// Formatear RUT mientras se escribe
function formatRUT(input) {
    // Obtener solo números y K
    let value = input.value.replace(/[^0-9kK]/g, '');
    
    if (value.length > 0) {
        // Convertir K a mayúscula
        value = value.toUpperCase();
        
        // Separar números del dígito verificador
        if (value.length > 1) {
            let rut = value.slice(0, -1);
            let dv = value.slice(-1);
            
            // Formatear con puntos cada 3 dígitos (opcional) y guión antes del DV
            if (rut.length > 3) {
                // Si quieres puntos: rut = rut.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
                value = rut + '-' + dv;
            } else {
                value = rut + (rut.length > 0 ? '-' + dv : dv);
            }
        }
    }
    
    // Limitar longitud máxima (12 caracteres con guión)
    if (value.length > 12) {
        value = value.substring(0, 12);
    }
    
    input.value = value;
}

// Validar formato de RUT
function validateRUT(rut) {
    // Expresión regular para RUT chileno
    const rutPattern = /^[0-9]{7,8}-[0-9Kk]$/;
    return rutPattern.test(rut);
}

// Limpiar RUT para validación (quitar puntos y guiones)
function cleanRUT(rut) {
    return rut.replace(/[.-]/g, '');
}

// Aplicar formateo automático a campos RUT
function initRUTFormatting() {
    // Buscar todos los campos de RUT
    const rutInputs = document.querySelectorAll('input[name="rut"], .rut-input input, input[data-rut]');
    
    rutInputs.forEach(function(input) {
        // Evento en tiempo real mientras se escribe
        input.addEventListener('input', function(e) {
            formatRUT(e.target);
        });
        
        // Evento cuando se pega contenido
        input.addEventListener('paste', function(e) {
            setTimeout(function() {
                formatRUT(e.target);
            }, 10);
        });
        
        // Validación al salir del campo
        input.addEventListener('blur', function(e) {
            const rutValue = e.target.value;
            if (rutValue) {
                if (validateRUT(rutValue)) {
                    e.target.classList.remove('invalid');
                    e.target.classList.add('valid');
                } else {
                    e.target.classList.remove('valid');
                    e.target.classList.add('invalid');
                }
            } else {
                e.target.classList.remove('valid', 'invalid');
            }
        });
        
        // Limpiar clases de validación al empezar a escribir
        input.addEventListener('focus', function(e) {
            e.target.classList.remove('valid', 'invalid');
        });
        
        // Configurar atributos del input
        input.setAttribute('maxlength', '12');
        input.setAttribute('placeholder', '12345678-9');
        input.style.textTransform = 'uppercase';
    });
}

// Inicializar cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', function() {
    initRUTFormatting();
});

// Función auxiliar para validar dígito verificador (opcional, más completa)
function validateDV(rut) {
    if (!rut || rut.length < 2) return false;
    
    const cleanRut = rut.replace(/[.-]/g, '');
    const rutNumbers = cleanRut.slice(0, -1);
    const dv = cleanRut.slice(-1).toUpperCase();
    
    let sum = 0;
    let multiplier = 2;
    
    // Calcular desde la derecha
    for (let i = rutNumbers.length - 1; i >= 0; i--) {
        sum += parseInt(rutNumbers[i]) * multiplier;
        multiplier = multiplier === 7 ? 2 : multiplier + 1;
    }
    
    const remainder = sum % 11;
    const calculatedDV = remainder === 0 ? '0' : remainder === 1 ? 'K' : (11 - remainder).toString();
    
    return dv === calculatedDV;
}