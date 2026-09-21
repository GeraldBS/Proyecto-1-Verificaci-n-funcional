//////////////////////////////////////////////////////////////////////
// scoreboard: modelo de referencia y reporte                       //
//////////////////////////////////////////////////////////////////////
// Recibe del driver cada paquete que salio y anota a quien deberia
// llegarle. El checker le pregunta por cada recepcion que ve el
// monitor, y aqui se busca el registro que le calza.
//
// Quien deberia recibir se calcula del campo destino, no del enum
// tipo, para no revisar el DUT contra nuestra propia etiqueta.
//////////////////////////////////////////////////////////////////////

class scoreboard;

  packet_mbx drv_sb_mbx;   // del driver: lo que el DUT ya tomo

  trans_sb esperando_q[$]; // todavia no llegan
  trans_sb cerrados_q[$];  // entregados o descartados

  int enviados    = 0;
  int entregados  = 0;
  int descartados = 0;
  int ambiguos    = 0;     // cuando dos registros calzan con la misma recepcion

  string archivo = "reporte.csv";

  task run();
    packet p;
    forever begin
      drv_sb_mbx.get(p);
      anotar(p);
    end
  endtask

  // un paquete solo llega si el destino existe y no es el mismo origen
  function bit deberia_recibir(packet p, int i);
    if (p.destino == `BROADCAST)             return (i != p.origen);
    if (p.destino < `DRVRS && p.destino != p.origen) return (i == p.destino);
    return 0;
  endfunction

  function void anotar(packet p);
    trans_sb r;
    int cuantos = 0;

    enviados++;

    for (int i = 0; i < `DRVRS; i++) begin
      if (deberia_recibir(p, i)) begin
        r = new();
        r.id       = p.id;
        r.origen   = p.origen;
        r.destino  = p.destino;
        r.terminal = i;
        r.payload  = p.payload;
        r.t_envio  = p.t_envio / 1ns;
        r.estado   = esperando;
        esperando_q.push_back(r);
        cuantos++;
      end
    end

    if (cuantos == 0) begin   // destino inexistente o a si mismo
      r = new();
      r.id       = p.id;
      r.origen   = p.origen;
      r.destino  = p.destino;
      r.terminal = -1;
      r.payload  = p.payload;
      r.t_envio  = p.t_envio / 1ns;
      r.estado   = descartado;
      cerrados_q.push_back(r);
      descartados++;
    end
  endfunction

  // el checker pregunta por cada recepcion; se toma el mas viejo que calce
  function bit emparejar(pckg_mon m);
    int idx    = -1;
    int calzan = 0;

    foreach (esperando_q[k]) begin
      if (esperando_q[k].terminal == m.terminal &&
          esperando_q[k].destino  == m.destino  &&
          esperando_q[k].payload  == m.payload) begin
        calzan++;
        if (idx < 0) idx = k;
      end
    end

    if (idx < 0) return 0;

    // dos envios iguales en vuelo a la vez: no se puede saber cual es cual
    if (calzan > 1) ambiguos++;

    esperando_q[idx].t_recibido = m.t_recibido / 1ns;
    esperando_q[idx].calc_retraso();
    esperando_q[idx].estado = entregado;
    cerrados_q.push_back(esperando_q[idx]);
    esperando_q.delete(idx);
    entregados++;
    return 1;
  endfunction

  // lo que quedo esperando al final es que nunca llego
  function int perdidos();
    return esperando_q.size();
  endfunction

  function void escribir_csv();
    int fd;
    fd = $fopen(this.archivo, "w");
    if (fd == 0) begin
      $display("scoreboard: no se pudo abrir %s", this.archivo);
      return;
    end
    $fdisplay(fd, "%s", trans_sb::encabezado_csv());
    foreach (cerrados_q[k])  $fdisplay(fd, "%s", cerrados_q[k].linea_csv());
    foreach (esperando_q[k]) begin
      esperando_q[k].estado = perdido;
      $fdisplay(fd, "%s", esperando_q[k].linea_csv());
    end
    $fclose(fd);
    $display("scoreboard: reporte escrito en %s", this.archivo);
  endfunction

  function void reporte();
    longint suma = 0;
    longint mn = -1;
    longint mx = 0;

    foreach (cerrados_q[k]) begin
      if (cerrados_q[k].estado == entregado) begin
        suma += cerrados_q[k].retraso;
        if (mn < 0 || cerrados_q[k].retraso < mn) mn = cerrados_q[k].retraso;
        if (cerrados_q[k].retraso > mx)           mx = cerrados_q[k].retraso;
      end
    end

    $display("---- scoreboard ----");
    $display("paquetes enviados        : %0d", enviados);
    $display("entregas esperadas       : %0d", entregados + perdidos());
    $display("entregas confirmadas     : %0d", entregados);
    $display("descartados a proposito  : %0d", descartados);
    $display("perdidos (no llegaron)   : %0d", perdidos());
    $display("emparejamientos ambiguos : %0d", ambiguos);
    if (entregados > 0)
      $display("retraso min/prom/max     : %0d / %0d / %0d ns",
               mn, suma/entregados, mx);

    foreach (esperando_q[k])
      esperando_q[k].print("scoreboard: ERROR nunca llego");
  endfunction

endclass
