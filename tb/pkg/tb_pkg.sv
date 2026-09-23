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
`include "transaction/pckg_mon.sv"
`include "transaction/trans_sb.sv"

// mailboxes con tipo
typedef mailbox #(packet)    packet_mbx;     // generator -> agente -> driver
typedef mailbox #(cfg)       cfg_mbx;        // test -> generator
typedef mailbox #(escenario) escenario_mbx;  // test -> agente
typedef mailbox #(pckg_mon)  pckg_mon_mbx;   // monitor -> agente -> checker

// las clases del ambiente van despues de los mailboxes porque los usan
`include "driver/driver.sv"
`include "driver/agent_drv.sv"
`include "generator/generator.sv"
`include "monitor/monitor.sv"
`include "monitor/agent_mon.sv"
`include "scoreboard/scoreboard.sv"
`include "checker/checker.sv"
`include "env/environment.sv"

`endif
