//////////////////////////////////////////////////////////////////////
// Parametros que cambian el hardware, se fijan al compilar.        //
// ej: vcs ... +define+PCKG_SZ=32 +define+DRVRS=8                   //
// Si no se pasan se usan los valores de aqui.                      //
//////////////////////////////////////////////////////////////////////
`ifndef PARAMETROS_SVH
`define PARAMETROS_SVH

// tamano del paquete (16, 32 o 64)
`ifndef PCKG_SZ
  `define PCKG_SZ 16
`endif

// cantidad de dispositivos en el bus
// maximo 254 para poder mandar a destinos que no existen
// (las direcciones son de 8 bits y 0xFF es broadcast)
`ifndef DRVRS
  `define DRVRS 4
`endif

// numero de buses, el enunciado lo deja en 1
`ifndef BITS
  `define BITS 1
`endif

// direccion de broadcast
// no cambiar: el DUT compara internamente contra {8{1'b1}}
`ifndef BROADCAST
  `define BROADCAST 8'hFF
`endif

// bits de direccion dentro del paquete (el DUT usa los 8 mas altos)
`ifndef ANCHO_DIR
  `define ANCHO_DIR 8
`endif

// periodo del reloj en ns
`ifndef PERIODO_CLK
  `define PERIODO_CLK 10
`endif

`endif
