# Gecko — SPEC v0

> La mitad que le falta a ponytail: ponytail **previene** en la escritura, gecko
> **recolecta** al cerrar.

Un artefacto portable (skill + script, cero dependencias) que hace que borrar
código sea un output obligatorio de cada cambio, usando **git como memoria** y un
**ratchet** como red dura.

---

## 1. Problema

El modelo escribe bien y borra mal. No es incapacidad: son dos causas.

1. **Incentivo.** El output de cada turno es "algo cambió". Agregar se lee como
   progreso; borrar, como retroceso. Borrar nunca es el resultado *requerido* de
   ningún paso.
2. **Memoria.** Nadie lleva la cuenta de "agregué X en el turno 3, ¿sigue
   haciendo falta?". La compactación destruye esa procedencia.

Una skill sola no alcanza: es texto advisory, se aplica al escribir y no
recuerda nada. Un plugin de harness resuelve la memoria y el veto, pero no es
portable. La salida es no inventar el ledger: **usar git**, que ya es universal,
durable y no se olvida.

## 2. No-goals (v0)

Excluido a propósito, con criterio de entrada para después:

- **Call-graph / análisis estático propio.** Es específico de lenguaje y no es
  portable. Se delega a detectores enchufables (ver §6.3).
- **Plugins de harness** (opencode V2, hooks de Claude, etc.). Viven detrás de
  una API que cambia. v0 no depende de ninguno.
- **Publicación en npm / paquete.** v0 se copia.
- **Provenance por intención ligada a tareas/specs.** Nivel 3.
- **Finetunear un modelo.** Descartado: no se puede tocar un modelo hosteado, y
  el reward que habría que definir es la misma especificación que todavía no
  escribimos. La herramienta es el harness, no el modelo.

## 3. Principios

1. **Ratchet, no gate.** No se exige llegar a cero; se impide *crecer*. Un gate
   que pide cero nunca se activa porque la deuda preexistente lo bloquea; un
   ratchet congela la deuda y prohíbe sumarle.
2. **Git es la memoria.** La procedencia no depende de que el modelo recuerde.
   Sobrevive compactación, restart y cambio de harness.
3. **Barato.** POSIX sh + git. Sin red, sin frameworks, sin daemons.
4. **Portable.** El mismo `SKILL.md` funciona sin cambios en cualquier harness.
5. **Honesto sobre sus límites.** Detecta formas, no todas. El límite se declara
   en la herramienta, no se descubre en producción.

## 4. Decisiones (entendimiento compartido)

| # | Decisión | Elegido |
|---|---|---|
| Q1 | Objetivo | Cambio de conducta in-session (pase de borrado al cerrar), con el ratchet como red dura. Métrica: agregadas vs borradas. |
| Q2 | Distribución | Portable, harness-agnostic. **Complementa** a gentle-ai (su ratchet estático sigue en CI); no lo reemplaza. |
| Q3 | Detección | Procedencia, no call-graph. El call-graph se delega si el usuario lo enchufa. |
| Q4 | Sustrato | Git + un archivo de baseline en el repo (`.gecko/baseline`), commiteado. |
| Q5 | Superficie de enforcement | Skill (convence) + script (mide) + **ratchet en git pre-commit / CI** (impide). |
| Q6 | Memoria | Git (`diff` / `blame` / `log`). |
| Q7 | Qué mide | `diff` como **disparador**, anotación como **detección**, detector externo como **enchufe opcional**. |
| Q8 | Alcance del spec | v0 ejecutable; niveles 2–3 como backlog. |
| Q9 | Idioma | `SPEC.md` en español (doc del dueño); `SKILL.md` en inglés (paridad con ponytail, portabilidad). |

## 5. Artefactos

```
gecko/
├── SPEC.md                    # este documento
├── README.md                  # instalación y uso
├── LICENSE
├── install.sh                 # instalador (curl-able)
├── skills/gecko/
│   ├── SKILL.md               # la disciplina (política) — en inglés
│   └── scripts/gecko          # el CLI, POSIX sh, cero deps (mecanismo)
└── examples/.gecko/config     # detector de ejemplo
```

El núcleo son dos archivos: `SKILL.md` (política) y `scripts/gecko`
(mecanismo). El resto es envoltorio.

## 6. Contrato del CLI

```
gecko review [--base REF] [--json]   # input para el paso de recolección
gecko check                          # el ratchet (exit 1 si hay hallazgos nuevos)
gecko baseline [--update]            # regenera el baseline
gecko hook install|uninstall         # hook de pre-commit (opcional)
gecko version                        # versión
```

### 6.1 `gecko review`

Mide el diff actual y lo ordena para que el pase de borrado tenga un blanco
concreto. No decide: muestra.

Comportamiento:

- Base por defecto: `HEAD` (cambios en el working tree). `--base REF` para un
  rango.
- Usa `git diff --numstat` para archivos trackeados.
- Lista archivos untracked aparte (con `wc -l`), porque `--numstat` no los ve.
- **Candidato** = archivo con líneas agregadas y **cero borradas**. Son las
  adiciones puras, la mayor sospecha.
- Ordena candidatos por neto descendente.
- Cierra con el resumen del changeset: total agregado, total borrado, ratio.

Salida (legible por agente, terse):

```
gecko review (base: HEAD)

CANDIDATES (added, nothing removed)
  src/foo.ts        +142  -0   net +142
  src/bar.ts         +18  -0   net  +18

TOUCHED
  src/baz.ts         +30 -12   net  +18
  src/qux.ts          +2 -40   net  -38   shrunk

untracked (not in --numstat)
  src/new.ts         +60

summary: +252 -52  ratio 4.8:1  (candidates: 2)
```

`--json` para consumo programático.

### 6.2 `gecko check` (el ratchet)

Corre los detectores, compara contra el baseline y **falla si aparecen hallazgos
nuevos**. Es lo único duro del sistema, y vive donde vive git: pre-commit o CI.

Reglas (idénticas en filosofía al `deadcode-ratchet` de gentle-ai):

- La deuda preexistente está congelada. No se exige limpiarla.
- Un hallazgo nuevo → exit 1 con la lista. O se arregla, o se borra, o se
  actualiza el baseline **diciendo por qué en el commit**.
- Un hallazgo que desapareció → nota informativa, no falla. Invita a apretar el
  baseline con `--update`.
- Comparación con colación fijada (`LC_ALL=C`) para que sea reproducible entre
  máquinas. Sin esto, `comm` produce basura si los inputs no están ordenados
  igual.

### 6.3 Detectores (la parte específica de lenguaje)

`.gecko/config` es un shell que gecko sourcea. Puede definir `gecko_detect()`,
que imprime hallazgos, uno por línea, formato `<path>\t<clave>`.

```sh
# .gecko/config
gecko_detect() {
  npx --yes knip --reporter compact 2>/dev/null | sed -E 's/^([^:]+):.*/\1\tknip/'
}
```

Sin `gecko_detect()` definida, el detector por defecto es el **ratchet de
anotaciones**: cuenta los marcadores `ponytail:` / `gecko:` sin resolver. Cero
configuración, agnóstico de lenguaje, y directamente sobre deuda.

Detectores conocidos que el usuario puede enchufar: `knip` (TS/JS), `vulture`
(Python), `deadcode` (Go), `cargo udeps` (Rust). Gecko no los instala ni los
conoce: solo compara la lista antes y después.

## 7. La skill (`SKILL.md`)

Inglés, misma forma que ponytail (frontmatter + secciones + niveles).

Contenido mínimo:

- **Invariante.** *"Un cambio no está cerrado hasta que cada línea agregada esté
  contabilizada: justificada por escrito, o borrada."*
- **Procedimiento (el pase de recolección):**
  1. Correr `gecko review` antes de declarar terminado.
  2. Por cada candidato: borrar lo que ya no tiene referente, o anotar la razón.
  3. Para adiciones que quedan, confirmar que su razón sigue en pie.
  4. `gecko check` debe pasar.
- **Convención de anotación.** Reutiliza `ponytail:`; agrega `gecko:` para
  adiciones que se mantienen a propósito. Formato: `# gecko: <razón> — borrar
  cuando <condición>`.
- **Niveles.** `lite` / `full` / `ultra`, paridad con ponytail.
- **Límites honestos.** No detecta ramas muertas, campos nunca asignados, ni
  efectos muertos. Eso lo encuentra ejecutar el producto, no analizarlo.

## 8. Distribución e instalación

Dos canales, uno primario:

| Canal | Comando | Para qué | Por qué |
|---|---|---|---|
| **skills.sh** (primario) | `npx skills add lucasvidela94/gecko -g -y` | Instala el skill (con su CLI) en todos los agentes detectados. | Nativo del ecosistema, descubre solo, cero mantenimiento, 75+ agentes. |
| **`install.sh`** (secundario) | `curl -fsSL .../install.sh \| sh` | Pone `gecko` en el PATH y, si hay `npx`, instala el skill. | Para uso manual del CLI o entornos sin Node. |

**No hay instalador propio para el skill.** `npx skills` ya copia el skill a cada
harness; reimplementar eso con un `curl` sería duplicar el ecosistema y perder el
descubrimiento.

El layout sigue la convención del ecosistema — `skills/gecko/SKILL.md` +
`skills/gecko/scripts/gecko` — para que el skill instalado contenga solo lo
necesario (no el SPEC ni el README).

**Versionado.** Semver, tags `vX.Y.Z`, `gecko version`. El instalador resuelve el
último release y permite pinnear con `--version`.

**Descubrimiento.** El repositorio público aparece en skills.sh, que rankea por
telemetría anónima de instalación. Badge en el README. La capa dura sigue siendo
`gecko hook install` (pre-commit) o un paso de CI.

El `SKILL.md` no se toca al cambiar de harness. Esa es la prueba de portabilidad.

## 9. Criterio de éxito

- Corre en POSIX sh + git, sin red y sin instalar nada.
- `gecko review` sobre un diff real marca exactamente los archivos que un humano
  marcaría como adiciones puras.
- `gecko check` falla ante una función muerta recién introducida (con detector
  Go) y pasa en el baseline.
- El mismo `SKILL.md`, sin cambios, se usa en ≥ 2 harnesses.
- Una sesión que siga la skill termina con borrados o con razones escritas —
  nunca con silencio.

## 10. Futuro (niveles 2–3, fuera de v0)

Criterio de entrada: v0 en uso real y su límite conocido.

- **Nivel 2.** Presets de detectores por lenguaje; salida `--json` estable;
  ledger por commit (`gecko log`) que mapea adiciones a commits.
- **Nivel 3.** Provenance por intención: ligar adiciones a una tarea/spec y
  marcar huérfanas cuando la tarea desaparece. Adapters opcionales de harness
  (plugin opencode V2, hooks de Claude) como *acelerador*, nunca como requisito.
