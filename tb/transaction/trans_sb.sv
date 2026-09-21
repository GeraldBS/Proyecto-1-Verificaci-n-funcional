//////////////////////////////////////////////////////////////////////
// trans_sb: registro de un envio y su recepcion                    //
//////////////////////////////////////////////////////////////////////
// Junta lo que sabe el driver (origen, t_envio) con lo que ve el
// monitor (t_recibido) y produce la linea del csv.
//
// Un broadcast genera varios registros, uno por terminal que
// deberia recibirlo. Un mensaje a un destino que no existe genera
// uno solo, marcado como descartado.
//
// Los tiempos se guardan en ns. La division entre 1ns convierte
// desde las unidades del simulador sin tener que suponer cuales son.
//////////////////////////////////////////////////////////////////////
`include "parametros.svh"

typedef enum {esperando, entregado, descartado, perdido} estado_sb;

class trans_sb;

  localparam int DIR     = `ANCHO_DIR;
  localparam int PAYLOAD = `PCKG_SZ - `ANCHO_DIR;

  int               id;
  bit [DIR-1:0]     origen;
  bit [DIR-1:0]     destino;   // lo que iba en el paquete (0xFF si broadcast)
  int               terminal;  // terminal que deberia recibirlo, -1 si ninguna
  bit [PAYLOAD-1:0] payload;
  estado_sb         estado;

  longint t_envio;     // ns
  longint t_recibido;  // ns
  longint retraso;     // ns

  function new();
    this.id         = 0;
    this.origen     = '0;
    this.destino    = '0;
    this.terminal   = -1;
    this.payload    = '0;
    this.estado     = esperando;
    this.t_envio    = 0;
    this.t_recibido = 0;
    this.retraso    = 0;
  endfunction

  function void calc_retraso();
    this.retraso = this.t_recibido - this.t_envio;
  endfunction

  static function string encabezado_csv();
    return "id_transaccion,t_envio,d_origen,d_destino,terminal,t_recibido,retraso";
  endfunction

  // los descartados y los perdidos van sin t_recibido ni retraso
  function string linea_csv();
    if (this.estado == entregado)
      return $sformatf("%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                       this.id, this.t_envio, this.origen, this.destino,
                       this.terminal, this.t_recibido, this.retraso);
    else
      return $sformatf("%0d,%0d,%0d,%0d,%0d,,",
                       this.id, this.t_envio, this.origen, this.destino,
                       this.terminal);
  endfunction

  function void print(string tag = "");
    $display("[%0t] %s id=%0d %s origen=%0d destino=0x%0h terminal=%0d retraso=%0d ns",
             $time, tag, this.id, this.estado.name(), this.origen,
             this.destino, this.terminal, this.retraso);
  endfunction

endclass
