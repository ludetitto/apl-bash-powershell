# Actividad Práctica de Laboratorio
## Scripting en Bash y Powershell
Como parte de la cursada de _Virtualización de Hardware_, se propuso la realización de una serie de ejercicios prácticos obligatorios relacionados a prácticas de scripting.

Son cinco ejercicios en total, cada uno de ellos abarcando una herramienta en particular. **Para la aprobación de la práctica la resolución de todos los ejercicios debe ser tanto en Bash como en Powershell.**

### Ejercicio 1
`//TODO: Completar documentación a medida que se resuelva.`
### Ejercicio 2
`//TODO: Completar documentación a medida que se resuelva.`
### Ejercicio 3
Script que, dado un directorio que es pasado por parámetro, busca archivos duplicados en él y sus subdirectorios correspondiente. Se comprende por archivos duplicados a todos aquellos cuyo nombre y tamaño sean equivalentes.
El uso de un array asociativo es determinante para la resolución, donde:
+ La clave es nombre:tamaño.
+ El valor acumula los directorios donde aparece.

Ejemplo:
* Primera vez que aparece test.txt:5 (desde sub1):
```bash
tabla["test.txt:5"] = "/tmp/prueba/sub1"
```
* Segunda vez que aparece test.txt:5 (desde sub2):
```bash
tabla["test.txt:5"] = "/tmp/prueba/sub1|/tmp/prueba/sub2"
```
**Funcionamiento básico:** 

**Bash:**

I. Posicionese en el directorio que se encuentran los archivos con:
```bash
cd [Directorio correspondiente] 
```
II. Ver ayuda:
```bash
./ejercicio3.sh -h
# o en cambio
./ejercicio3.sh --help
```
III. Ejecute el lote de prueba, necesitamos que los directorios y archivos destinados a las pruebas existan:
```bash
./lote_prueba.sh
```
IV. Ejecute el script principal con los casos que se sugieren en el script anterior:
```bash
./ejercicio3.sh -d "/ruta/inventada"
# o en cambio
./ejercicio3.sh --directorio "/ruta/inventada"
```

**PowerShell:**

I. Posicionese en el directorio que se encuentran los archivos con:
```powershell
cd [Directorio correspondiente] 
```
II. Ver ayuda:
```powershell
Get-Help ./ejercicio3.ps1
```
III. Ejecute el lote de prueba, se esperará que presione enter para limpiar los directorios y archivos temporales 
```powershell
./lote_prueba.ps1
```
IV. **Sugerencia:** Habra una nueva terminal PowerShell y ejecute el script principal con los casos que se sugieren en el script anterior:
```powershell
./ejercicio3.ps1 -directorio "/ruta/inventada"
```

**IMPORTANTE!** Para evitar resultados inconsistentes cuando introduzca directorios con espacios por parámetros, procure que dicho parámetro sea un *string*. Es decir, haga uso de las comillas ("" o '').
### Ejercicio 4
`//TODO: Completar documentación a medida que se resuelva.`
### Ejercicio 5
`//TODO: Completar documentación a medida que se resuelva.`

## Conclusiones
`//TODO: Completar documentación a medida que se resuelva.`

## Participantes
