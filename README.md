# Actividad Práctica de Laboratorio
## Scripting en Bash y Powershell
Como parte de la cursada de _Virtualización de Hardware_, se propuso la realización de una serie de ejercicios prácticos obligatorios relacionados a prácticas de scripting.

Son cinco ejercicios en total, cada uno de ellos abarcando una herramienta en particular. **Para la aprobación de la práctica la resolución de todos los ejercicios debe ser tanto en Bash como en Powershell.**

### Ejercicio 1
`//TODO: Completar documentación a medida que se resuelva.`
### Ejercicio 2
`//TODO: Completar documentación a medida que se resuelva.`
### Ejercicio 3
`//TODO: Completar documentación a medida que se resuelva.`
### Ejercicio 4
Script demonio que monitorea un directorio en segundo plano y registra en un log cada vez que se crea o modifica un archivo que contenga alguna de las palabras clave indicadas.

**Conceptos clave:**
- **Proceso demonio:** un programa que corre "de fondo", sin ocupar la terminal. El usuario lo inicia y sigue funcionando aunque cierre la consola.
- **inotifywait:** en vez de revisar el directorio cada X segundos (lo cual es ineficiente), el sistema operativo avisa directamente cuando un archivo cambia. `inotifywait` escucha esos avisos.
- **Archivo PID:** para poder detener el demonio más tarde, el script guarda el número de proceso (PID) en un archivo. Así sabe a quién enviarle la señal de "pará".
- **Process substitution (`< <(...)`):** detalle técnico de Bash para que el bucle principal y `inotifywait` corran en el mismo proceso, evitando comportamientos inesperados al detener el demonio.

**Uso básico:**
```bash
# Iniciar
./demonio.sh -d ./carpeta --palabras usuario,contraseña -l log.txt

# Detener
./demonio.sh -d ./carpeta -k
```
### Ejercicio 5
`//TODO: Completar documentación a medida que se resuelva.`

## Conclusiones
`//TODO: Completar documentación a medida que se resuelva.`

## Participantes
