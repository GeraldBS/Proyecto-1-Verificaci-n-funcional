//////////////////////////////////////////////////////////////////////
// tb_pkg: junta las clases del ambiente y define los mailboxes     //
//////////////////////////////////////////////////////////////////////
// El orden de los include importa: los mailboxes necesitan que las
// clases ya esten definidas.
// El top solo tiene que incluir este archivo.
//////////////////////////////////////////////////////////////////////
`ifndef TB_PKG_SV
`define TB_PKG_SV

`include "parametros.svh"
`include "transaction/packet.sv"
`include "transaction/cfg.sv"

// mailboxes con tipo
typedef mailbox #(packet)    packet_mbx;     // generator -> agente -> driver
typedef mailbox #(cfg)       cfg_mbx;        // test -> generator
typedef mailbox #(escenario) escenario_mbx;  // test -> agente

// las clases del ambiente van despues de los mailboxes porque los usan
`include "driver/driver.sv"
`include "driver/agent_drv.sv"
`include "generator/generator.sv"
`include "env/environment.sv"

`endif
