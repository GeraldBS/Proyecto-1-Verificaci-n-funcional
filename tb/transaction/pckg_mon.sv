//////////////////////////////////////////////////////////////////////
// pckg_mon: lo que el monitor observa y le manda al checker         //
//////////////////////////////////////////////////////////////////////
// No es un packet. El bus solo lleva {destino, payload} en D_push
// (ver packet::palabra()); el origen no viaja por ahi, asi que el
// monitor no lo puede conocer. Por eso esto es una clase aparte con
// solo lo que de verdad se ve desde afuera del DUT:
//
//   terminal   -> terminal que lo recibio (donde se vio push=1)
//   destino    -> lo que traian los bits altos de D_push
//                 (coincide con terminal en unicast; en broadcast
//                  queda en 0xFF aunque terminal sea otro numero)
//   payload    -> el resto del dato
//   t_recibido -> momento en que se vio el push
//
// Le toca al checker (contra lo que puso el scoreboard) emparejar
// esto con el packet original que salio del generator.
//////////////////////////////////////////////////////////////////////
`include "parametros.svh"

class pckg_mon;

  // igual que en packet.sv: los tamanos salen de parametros.svh
  localparam int PCKG    = `PCKG_SZ;
  localparam int DIR     = `ANCHO_DIR;
  localparam int PAYLOAD = `PCKG_SZ - `ANCHO_DIR;

  int               terminal;
  bit [DIR-1:0]     destino;
  bit [PAYLOAD-1:0] payload;
  time              t_recibido;

  function new();
    this.terminal   = -1;
    this.destino    = '0;
    this.payload    = '0;
    this.t_recibido = 0;
  endfunction

  function void print(string tag = "");
    $display("[%0t] %s terminal=%0d destino=0x%0h payload=0x%0h t_recibido=%0t",
             $time, tag, this.terminal, this.destino, this.payload, this.t_recibido);
  endfunction

endclass
