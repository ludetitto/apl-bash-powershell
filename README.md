# Actividad Práctica de Laboratorio
## Scripting en Bash y Powershell
Como parte de la cursada de _Virtualización de Hardware_, se propuso la realización de una serie de ejercicios prácticos obligatorios relacionados a prácticas de scripting.

Son cinco ejercicios en total, cada uno de ellos abarcando una herramienta en particular. **Para la aprobación de la práctica la resolución de todos los ejercicios debe ser tanto en Bash como en Powershell.**

### Ejercicio 1
Script genérico en Bash que permite procesar archivos CSV realizando operaciones de filtrado, conteo y suma sobre sus registros.

El programa toma como referencia la primera fila del archivo para identificar los nombres de las columnas, permitiendo trabajar con ellas de forma dinámica mediante parámetros.

### Funcionalidades

- Filtrar registros por un campo y un patrón de texto (case-insensitive)
- Contar la cantidad de registros resultantes
- Sumar valores de una columna numérica
- Validar parámetros de entrada y tipos de datos
- Manejo de errores con mensajes claro

**Uso básico:**
```bash
./procesarCSV.sh -a clientes.csv -f Apellido -b "Perez" -s Saldo
```

### Ejercicio 2
`//TODO: Completar documentación a medida que se resuelva.`
### Ejercicio 3
`//TODO: Completar documentación a medida que se resuelva.`
### Ejercicio 4
Script demonio que monitorea un directorio en segundo plano y registra en un log cada vez que se crea o modifica un archivo que contenga alguna de las palabras clave indicadas.

*BASH*
**Cómo funciona paso a paso:**
1. El usuario ejecuta el script con `-d`, `-p` y `-l` → se validan los argumentos
2. Se verifica que `inotifywait` esté instalado (`inotify-tools`)
3. Se verifica que no haya ya un daemon corriendo para ese directorio
4. Se crea el archivo log vacío
5. El script se relanza a sí mismo en segundo plano con `nohup ... &` → ese proceso hijo es el daemon
6. El PID del hijo se guarda en `/tmp/demonio_<hash>.pid` → permite matarlo después con `-k`
7. El daemon escanea los archivos que ya existen en el directorio al iniciar
8. `inotifywait -m` queda escuchando eventos del sistema operativo (creación/modificación de archivos)
9. Cuando `inotifywait` detecta un evento, le pasa la línea al daemon que la procesa
10. Por cada evento, busca las palabras clave dentro del archivo con `grep`
11. Si encuentra una coincidencia, la registra en el log con timestamp, operación, ruta y tamaño
12. Al usar `-k`, se envía `SIGTERM` al proceso; si no muere en 1 segundo, se fuerza con `SIGKILL`

**Comandos útiles:**
```bash
./demonio.sh -d ./carpeta -p password,token -l log.txt    # iniciar
./demonio.sh -d ./carpeta -k                              # detener
cat log.txt                                               # ver detecciones
ps aux | grep demonio                                     # ver si está corriendo
```

*POWERSHELL*
**Cómo funciona paso a paso:**
1. El usuario ejecuta el script con `-Directorio`, `-Palabras` y `-Log` → se validan los argumentos en el bloque `param`
2. Se verifica que no haya ya un daemon corriendo para ese directorio
3. Se crea el archivo log vacío
4. El script se relanza a sí mismo en segundo plano con `Start-Process` → ese proceso hijo es el daemon
5. El PID del hijo se guarda en un archivo `.pid` en el directorio temporal → permite matarlo después con `-Kill`
6. El daemon escanea los archivos que ya existen en el directorio al iniciar
7. `FileSystemWatcher` queda escuchando eventos del sistema operativo (creación/modificación de archivos)
8. Cuando `FileSystemWatcher` detecta un evento, el daemon lo procesa
9. Por cada evento, busca las palabras clave dentro del archivo con `-match`
10. Si encuentra una coincidencia, la registra en el log con timestamp, operación, ruta y tamaño
11. Al usar `-Kill`, se llama a `Stop-Process -Force` para detener el daemon y se elimina el archivo PID

**Comandos útiles:**
```powershell
.\demonio.ps1 -Directorio carpeta -Palabras "password,token" -Log log.txt     # iniciar
.\demonio.ps1 -Directorio carpeta -Kill                                       # detener
Get-Content log.txt                                                           # ver detecciones
Get-Help .\demonio.ps1 -Examples                                              # ver ejemplos de uso
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
