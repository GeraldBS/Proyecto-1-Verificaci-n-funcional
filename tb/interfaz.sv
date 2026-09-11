//////////////////////////////////////////////////////////////////////////////
// interfaz.sv
//----------------------------------------------------------------------------
// Interfaz entre el ambiente de pruebas y el DUT (bs_gnrtr_n_rbtr).
//
// Las señales tienen EXACTAMENTE la misma forma que los puertos del DUT
// (arreglos desempacados [bits-1:0][drvrs-1:0]) para poder conectarlas
// directamente en el test_bench.
//
// Dirección de las señales (vista desde el AMBIENTE):
//   El DUT se comporta como si en cada terminal hubiera dos FIFOs que el
//   ambiente debe emular:
//     - FIFO de entrada  (ambiente -> DUT): el ambiente pone pndng=1 y el
//       dato en D_pop; el DUT lo saca con pop.
//     - FIFO de salida   (DUT -> ambiente): el DUT pone el dato en D_push y
//       lo indica con push; el ambiente lo captura.
//
//   señal   | la maneja  | la lee
//   --------+------------+-----------
//   reset   | ambiente   | DUT
//   pndng   | ambiente   | DUT
//   D_pop   | ambiente   | DUT
//   pop     | DUT        | ambiente (driver)
//   push    | DUT        | ambiente (monitor)
//   D_push  | DUT        | ambiente (monitor)
//
// IMPORTANTE sobre el reset: el contador de turnos del DUT (Counter_arb)
// tiene reset asíncrono por FLANCO (posedge rst) y su reloj es trn_chng, que
// arranca en X. Si reset arranca en 1 desde el tiempo 0 no hay flanco y el
// árbitro queda en X para siempre. El driver debe generar el reset como un
// pulso 0 -> 1 -> 0 (verificado en simulación).
//////////////////////////////////////////////////////////////////////////////
`include "parametros.svh"

interface bus_if #(
  parameter bits    = `BITS,
  parameter drvrs   = `DRVRS,
  parameter pckg_sz = `PCKG_SZ
) (
  input bit clk
);

  // Señales que maneja el ambiente (variables: se asignan desde las clases).
  logic               reset;
  logic               pndng  [bits-1:0][drvrs-1:0]; // hay dato disponible en la FIFO emulada
  logic [pckg_sz-1:0] D_pop  [bits-1:0][drvrs-1:0]; // dato que el DUT tomará con pop

  // Señales que maneja el DUT (wire: las maneja un puerto de salida del DUT;
  // el ambiente solo las lee).
  wire                push   [bits-1:0][drvrs-1:0]; // dato válido en D_push
  wire                pop    [bits-1:0][drvrs-1:0]; // el DUT tomó el dato de D_pop
  wire  [pckg_sz-1:0] D_push [bits-1:0][drvrs-1:0]; // dato recibido por el terminal

endinterface : bus_if
