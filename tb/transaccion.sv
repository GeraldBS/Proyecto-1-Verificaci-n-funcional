class transaccion;
  // 1. Entradas que vamos a aleatorizar (rand)
  rand bit [31:0] P_in;       // Dato paralelo de entrada
  rand bit        S_in;       // Dato serial de entrada
  rand bit        rst;        // Señal de reset
  
  // 2. Entradas de control (basado en el diagrama del controlador)
  rand bit        Push;       // Señal para meter datos
  rand bit        Pop;        // Señal para sacar datos
  
  // 3. Salidas que vamos a observar (no son rand porque el DUT las genera)
  bit [31:0]      P_out;      // Salida en paralelo
  bit             S_out;      // Salida serial
  bit             bs_grnt;    // Permiso del árbitro
  bit             bs_bsy;     // Indicador de bus ocupado
  bit             Pndng;      // Indicador de datos pendientes

  // 4. Restricciones (Constraints) para que la aleatoriedad tenga sentido
  // Ejemplo: No podemos hacer Push y Pop al mismo tiempo si el diseño no lo permite
  constraint ctrl_valido {
    !(Push == 1 && Pop == 1); 
  }

  // Función para imprimir el paquete y ver qué se generó (muy útil para depurar)
  function void print();
    $display("Datos -> P_in: %0h, S_in: %0b | Control -> Push: %0b, Pop: %0b", P_in, S_in, Push, Pop);
  endfunction

endclass
