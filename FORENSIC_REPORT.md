# FORENSIC REPORT – Taller Docker Semana 13

**Estudiantes:** Carlos Andrés Taquez Maya - ID: 844173 - Juan Manuel Ordoñez - 909950
**Fecha:** 2026-10-21

## Tabla de Identidad

| Item | Comando | Salida |
|---|---|---|
| Hash de la imagen (prueba final) | `docker inspect --format='{{.Id}}' eco-air-backend:1.0.0` | `sha256:6434c167313a168e08de9a24b4deb930f67fac421ff07aa8044a79c69d1f28fe` |
| Variable inyectada | `docker exec eco_air_active env \| grep OPERATOR_ID` | `OPERATOR_ID=844173` |

## Reto 2

### 2.1 docker history

```text
La salida completa de docker history no aparece en el registro de terminal disponible.
```

**Explicación:** La imagen utiliza una construcción multi-stage con Maven para construir la aplicación y una imagen runtime basada en Java JRE. Las capas de la etapa builder no forman parte de la imagen final; esta incluye los archivos y las capas necesarios para ejecutar la aplicación.

### 2.2 docker top

```text
PID   USER       COMMAND
1     sensor_u   java
102   sensor_u   ps
```

**Explicación:** El proceso Java se ejecuta como `sensor_user`, UID 10001, y no como root.

Evidencia adicional:

```text
uid=10001(sensor_user) gid=10001(sensorgroup) groups=10001(sensorgroup)
```

### 2.3 Inmutabilidad

```text
docker exec eco_air_active touch /etc/crontab_fake
touch: /etc/crontab_fake: Permission denied
```

**Explicación:** El intento de escritura en `/etc` fue denegado, lo que demuestra que el usuario del proceso no tiene permisos para realizar esa operación.

### 2.4 Artefactos de desarrollo

```bash
docker exec eco_air_active which mvn
docker exec eco_air_active find / -name "*.java" 2>/dev/null
```

La salida exacta de estos dos comandos no aparece en el registro disponible.

**Explicación:** La imagen se construyó utilizando etapas separadas para la compilación y la ejecución. Sin embargo, no se puede confirmar mediante el registro disponible que ambos comandos hayan producido una salida vacía.

## Reto 3

### 3.1 OOMKilled (48 MB)

```text
Comando:
docker run -d --name eco_air_crash -m 48m eco-air-backend:1.0.0

Salida de docker inspect:
Status: exited | ExitCode: 137 | OOMKilled: true
```

**Explicación:** Con el límite de 48 MB, el contenedor terminó con código 137 y Docker registró `OOMKilled: true`, indicando que fue terminado por falta de memoria.

La prueba con 64 MB también falló:

```text
Status: exited | ExitCode: 137 | OOMKilled: true
```

### 3.2 Calibración

| Límite probado | ¿Arrancó? | Tiempo de arranque | Resultado |
|---|---|---|---|
| 256m | Sí | 3.513 s; prueba final: 3.791 s | running; ExitCode 0; OOMKilled false |
| 384m | Sí | 3.203 s | running; ExitCode 0; OOMKilled false |
| 512m | Sí | 3.553 s | running; ExitCode 0; OOMKilled false |

**Umbral mínimo exitoso dentro de esta tabla:** 256m.

**Nota:** En las pruebas adicionales también permanecieron en ejecución los límites de 96m, 128m, 160m y 192m. Por tanto, 256m es el límite menor exitoso de los tres valores incluidos en esta tabla, no el mínimo de todas las pruebas realizadas.

Registro de inicio de la prueba final con 256m:

```text
2026-10-21T16:19:25.514853768Z 2026-10-21T16:19:25.514Z INFO 1 --- [eco-air-backend] [main] com.ecoair.backend.EcoAirApplication : Started EcoAirApplication in 3.791 seconds (process running for 4.381)
```

Salida de `docker stats --no-stream eco_air_active`:

```text
CONTAINER ID   NAME           CPU %   MEM USAGE / LIMIT   MEM %   NET I/O       BLOCK I/O       PIDS
366250e4d6c8   eco_air_active 10.57%  210.5MiB / 256MiB   82.24%  1.77kB / 657B 129MB / 32.8kB 31
```

Verificación del endpoint `/health`:

```json
{"alerts":0,"status":"UP"}
```

Estado final del contenedor:

```text
Status: running | ExitCode: 0 | OOMKilled: false
```
