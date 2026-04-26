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
Script que consulta la API de Rick and Morty para obtener información de personajes, cacheándola localmente para futuras consultas.

**Conceptos clave:**
- **APIs REST:** obtener datos de la API de Rick and Morty (https://rickandmortyapi.com/) usando HTTP requests.
- **Caché:** se guarda localmente la información obtenida para no consultar la API innecesariamente.
- **Búsquedas:** por ID o por nombre (puede devolver múltiples resultados ya que es por coincidencia).
- **Validaciones:** manejar IDs inválidos, nombres sin resultados y HTTP responses no exitosas.
- **Registro de consultas:** cada consulta se registra en un log con timestamp y parámetro utilizado.

#### Uso básico:

**Bash:**
```bash
# Búsqueda por ID único
./ejercicio5.sh --id 1

# Búsqueda por múltiples IDs
./ejercicio5.sh --id "1,2,3"

# Búsqueda por nombre
./ejercicio5.sh --nombre "rick"

# Búsqueda combinada
./ejercicio5.sh --id 1,2 --nombre rick,morty
```

**PowerShell:**
```powershell
# Búsqueda por ID único
./ejercicio5.ps1 -id 1

# Búsqueda por múltiples IDs (como array)
./ejercicio5.ps1 -id 1,2,3

# Búsqueda por nombre
./ejercicio5.ps1 -nombre "rick"

# Búsqueda combinada (arrays de IDs y nombres)
./ejercicio5.ps1 -id 1,2 -nombre "rick","morty"
```

#### Archivos generados:
- `characters_cache.json` (o `.txt`): almacena la información de los personajes en caché.
- `api_tracking.log`: registra las consultas realizadas.

## Conclusiones
`//TODO: Completar documentación a medida que se resuelva.`

## Participantes
