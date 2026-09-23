//////////////////////////////////////////////////////////////////////
// Interfaz entre el ambiente y el DUT (bs_gnrtr_n_rbtr)            //
//////////////////////////////////////////////////////////////////////
// Las senales tienen la misma forma que los puertos del DUT para
// poder conectarlas directo.
//
// El ambiente hace de FIFO de entrada y de salida de cada dispositivo:
//  - entrada: ponemos pndng=1 y el dato en D_pop, el DUT lo saca con pop
//  - salida: el DUT pone el dato en D_push y levanta push
//////////////////////////////////////////////////////////////////////
`include "parametros.svh"

interface bus_if #(
  parameter bits    = `BITS,
  parameter drvrs   = `DRVRS,
  parameter pckg_sz = `PCKG_SZ
) (
  input bit clk
);

  // las maneja el ambiente
  logic               reset;
  logic               pndng  [bits-1:0][drvrs-1:0]; // hay dato en la fifo
  logic [pckg_sz-1:0] D_pop  [bits-1:0][drvrs-1:0]; // dato que va a sacar el DUT

  // las maneja el DUT (wire porque vienen de puertos de salida)
  wire                push   [bits-1:0][drvrs-1:0]; // hay dato valido en D_push
  wire                pop    [bits-1:0][drvrs-1:0]; // el DUT saco el dato
  wire  [pckg_sz-1:0] D_push [bits-1:0][drvrs-1:0]; // dato que llego

endinterface
