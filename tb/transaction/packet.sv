//////////////////////////////////////////////////////////////////////
// packet: transaccion que viaja por el ambiente                    //
//////////////////////////////////////////////////////////////////////
// Formato del paquete que ve el DUT:
//   [PCKG_SZ-1 : PCKG_SZ-8] -> destino
//   [PCKG_SZ-9 : 0]         -> payload
//
// Medido en simulacion:
//  - unicast: solo lo recibe el destino
//  - broadcast (0xFF): lo reciben todos menos el que lo envia
//  - destino que no existe: nadie lo recibe
//  - destino igual al origen: nadie lo recibe
//////////////////////////////////////////////////////////////////////
`include "parametros.svh"

// tipos de envio
typedef enum {envio_normal, envio_broadcast, envio_error, envio_propio} tipo_pckg;

class packet;

  // los tamanos vienen de parametros.svh, no se parametriza la clase
  // para poder escribir "packet p = new;" sin #()
  localparam int PCKG     = `PCKG_SZ;
  localparam int DRV      = `DRVRS;
  localparam int DIR      = `ANCHO_DIR;
  localparam int PAYLOAD  = `PCKG_SZ - `ANCHO_DIR;

  // drvrs con el mismo ancho que las direcciones, para no mezclar anchos
  localparam bit [`ANCHO_DIR-1:0] DRV_B = `DRVRS;

  rand tipo_pckg          tipo;
  rand bit [DIR-1:0]      origen;   // quien lo envia
  rand bit [DIR-1:0]      destino;  // a quien va
  rand bit [PAYLOAD-1:0]  payload;
  rand int                retardo;  // ciclos antes de enviarlo

  // no son rand, los pone el generator desde la cfg
  int min_retardo = 0;
  int max_retardo = 10;
  int peso_normal = 80;
  int peso_broadcast = 10;
  int peso_error = 10;
  int peso_propio = 0;

  int  id;        // numero de transaccion
  int  longitud;  // PCKG_SZ, para el reporte
  time t_envio;   // lo pone el driver cuando el DUT hace pop

  // el origen tiene que existir
  constraint c_origen {origen < DRV_B;}

  // cuantos paquetes de cada tipo
  constraint c_tipo {
    tipo dist {envio_normal    := peso_normal,
               envio_broadcast := peso_broadcast,
               envio_error     := peso_error,
               envio_propio    := peso_propio};
  }

  // el destino depende del tipo
  constraint c_destino {
    (tipo == envio_normal)    -> (destino <  DRV_B && destino != origen);
    (tipo == envio_broadcast) -> (destino == `BROADCAST);
    (tipo == envio_error)     -> (destino >= DRV_B && destino != `BROADCAST);
    (tipo == envio_propio)    -> (destino == origen);
  }

  constraint c_retardo {retardo inside {[min_retardo:max_retardo]};}

  // primero el tipo y el origen, despues el destino
  // si no, salen casi puros errores porque hay muchos destinos invalidos
  constraint c_orden {solve tipo before destino; solve origen before destino;}

  function new();
    this.longitud = PCKG;
    this.id       = 0;
    this.t_envio  = 0;
  endfunction

  // dato que se pone en D_pop
  function bit [PCKG-1:0] palabra();
    return {this.destino, this.payload};
  endfunction

  function void print(string tag = "");
    $display("[%0t] %s id=%0d tipo=%s origen=%0d destino=0x%0h payload=0x%0h retardo=%0d",
             $time, tag, this.id, this.tipo.name(), this.origen, this.destino,
             this.payload, this.retardo);
  endfunction

endclass
