# Proyecto 1 – Verificación funcional de un bus (`bs_gnrtr_n_rbtr`)

## Estructura

| Carpeta | Contenido |
|---|---|
| `rtl/` | DUT (`Library.sv`) y `fifo.sv` (dados por el profesor) |
| `tb/` | Ambiente: `generator`, `driver`, `monitor`, `checker`, `scoreboard`, `env`, interfaz, transacciones y `tb_top` |
| `tests/` | Pruebas: `test_general` (aleatoria), `test_corner` (casos de esquina) y pruebas de humo/driver/monitor |
| `scripts/` | `correr.sh`, `run.sh` y `plot_histograma.gnu` |
| `sim/` | Salida de simulación (compilación, logs, CSV, histograma) |
| `resultados/` | Reportes e histogramas ya generados para `pckg_sz` = 16, 32 y 64 |
| `docs/` | Test plan y diagrama del ambiente |

## Cómo correr

Desde la raíz del repositorio:

```bash
# Corrida completa: prueba general + casos de esquina + histograma
./scripts/run.sh            # pckg_sz al azar (16, 32 o 64), drvrs = 4
./scripts/run.sh 32 8       # pckg_sz = 32, drvrs = 8

# Una sola prueba
./scripts/correr.sh tb_top 64 8        # prueba completa
./scripts/correr.sh prueba_humo        # prueba rápida de humo
```

Argumentos: `./scripts/correr.sh <prueba> [pckg_sz] [drvrs]`.
Pruebas disponibles: `tb_top`, `prueba_humo`, `prueba_driver`, `prueba_monitor`.

## Opciones sin recompilar

Después de compilar, el ejecutable queda en `sim/`:

```bash
cd sim
./salida +prueba=corner                              # casos de esquina
./salida +min_trans=40 +max_trans=110 +p_bdcst=30    # más tráfico y broadcast
./salida +ntb_random_seed=$RANDOM                    # semilla distinta (por defecto es fija)
```

| Plusarg | Defecto | Qué es |
|---|---|---|
| `+prueba=` | general | `general` o `corner` |
| `+min_trans` / `+max_trans` | 1 / 10 | Transacciones por terminal |
| `+min_delay` / `+max_delay` | 0 / 8 | Retardo entre envíos (ciclos) |
| `+p_nrml` / `+p_bdcst` / `+p_err` / `+p_prp` | 80 / 10 / 10 / 0 | Pesos relativos: normal, broadcast, destino inexistente, a sí mismo |
| `+ntb_random_seed=` | fija | Semilla |

Lo que cambia el hardware (`PCKG_SZ` y `DRVRS`) sí requiere recompilar: se pasa como 2.º y 3.er argumento de `correr.sh`. Los demás parámetros están en `tb/parametros.svh`.

## Qué se aleatoriza

Número de transacciones por terminal, largo del paquete (16/32/64), tiempos de envío, destinos, mensajes con error (a dispositivos inexistentes) y broadcast.

## Resultados

- **Ya generados** (16, 32 y 64): `resultados/`
- **Al correr**, en `sim/` quedan:
  - `reporte.csv`, `reporte_general.csv`, `reporte_corner.csv`: columnas `id_transaccion, t_envio, d_origen, d_destino, terminal, t_recibido, retraso`. Los paquetes descartados quedan sin `t_recibido`/`retraso`.
  - `histograma.png`: histograma de retrasos con GNUplot (`gnuplot -e "archivo='sim/reporte.csv'" scripts/plot_histograma.gnu`).
  - `comp_*.log` y `sim_*.log`: logs de compilación y simulación.

## Documentación

- Test plan: `docs/Test_Plan_Proyecto1.pdf`
- Diagrama del ambiente: `docs/diagrama_ambiente.png`
