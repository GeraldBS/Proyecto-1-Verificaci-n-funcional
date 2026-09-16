interface bus_if (input bit clk);
  // Declaramos los cables
  logic        rst;
  logic [31:0] P_in;
  logic        S_in;
  logic [31:0] P_out;
  logic        S_out;
  
  // Señales de control del Bus y FIFOs
  logic        Push;
  logic        Pop;
  logic        Pndng;
  logic        bs_grnt;
  logic        bs_bsy;

  // Modport para el Driver (Él Escribe a las entradas del DUT)
  modport driver (output P_in, S_in, rst, Push, Pop, input clk, bs_grnt, bs_bsy, Pndng);
  
  // Modport para el Monitor (Él solo Lee/Espía, no puede escribir nada)
  modport monitor (input P_in, S_in, rst, Push, Pop, P_out, S_out, bs_grnt, bs_bsy, Pndng, clk);
  
endinterface