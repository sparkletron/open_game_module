// test bench, very basic and does no validation.

`define DEF_NTSC_MHZ 140

`timescale 1ns/1ps

module tb_open_game_module
  ();

  integer   index = 0;

  reg         clkv = 1'b0;
  reg         cpu_resetn = 1'b0;
  reg [10:0]  addr = 0;
  reg         MREQn = 1'b1;
  reg         IORQn = 1'b1;
  reg         RFSHn = 1'b0;
  reg         WRn   = 1'b1;
  reg         RDn   = 1'b0;

  wire [7:0]  data_bus;
  wire        snd_enable;
  wire        sn_reg_sel;
  wire        ram_select;
  wire        ram_enable;
  wire        disable_memory;

  porta_glue_coleco dut
  (
    .clk(clkv),
    .A(addr),
    .MREQn(MREQn),
    .RFSHn(RFSHn),
    .IORQn(IORQn),
    .WRn(WRn),
    .RESETn(cpu_resetn),
    .RDn(RDn),
    .D(data_bus),
    .RAM_CSn(ram_select),
    .RAM_OEn(ram_enable),
    .AY_CSn(snd_enable),
    .AY_AS(snd_reg_sel),
    .DIS_MEM(disable_memory)
  );

    // fst dump command
  initial
  begin
    $dumpfile ("tb_open_game_module.fst");
    $dumpvars (0, tb_open_game_module);
    #1;
  end

  always
  begin
    // toggle indexed clock
    clkv <= ~clkv;
    #(`DEF_NTSC_MHZ);
  end


  initial
  begin
    //hold in reset, and then release
    #50000;
    cpu_resetn <= 1'b1;
    #10000;
    //should be out of reset, reassert
    cpu_resetn <= 1'b0;
    #10000;
    //take out of reset
    cpu_resetn <= 1'b1;
    #10000;
    //check decoder U5
    //enable
    RFSHn <= 1'b1;
    MREQn <= 1'b0;
    #50000;
    //ROM
    addr[8] <= 1'b0;
    addr[9] <= 1'b0;
    addr[10] <= 1'b0;
    #50000;
    //RAM
    addr[8] <= 1'b1;
    addr[9] <= 1'b1;
    #50000;
    //rom_bank0
    addr[8] <= 1'b0;
    addr[9] <= 1'b0;
    addr[10] <= 1'b1;
    #50000;
    //rom_bank1
    addr[8] <= 1'b1;
    #50000;
    //rom_bank2
    addr[8] <= 1'b0;
    addr[9] <= 1'b1;
    #50000;
    //rom_bank3
    addr[8] <= 1'b1;
    #50000;
    //disable
    RFSHn <= 1'b0;
    MREQn <= 1'b1;
    #50000;
    //deassert address lines
    addr[8] <= 1'b0;
    addr[9] <= 1'b0;
    addr[10] <= 1'b0;
    #50000;
    //check decoder U6
    //enable
    IORQn <= 1'b0;
    addr[7] <= 1'b1;
    #50000;
    //control enable 2 (FIRE)
    WRn <= 1'b0;
    addr[5]  <= 1'b0;
    addr[6]  <= 1'b0;
    #50000;
    //vdp write enable (CSWn)
    addr[5]  <= 1'b1;
    #50000;
    //vdp read enable (CSRn)
    WRn <= 1'b1;
    #50000;
    //control enable 1 (ARM)
    WRn <= 1'b0;
    addr[5]  <= 1'b0;
    addr[6]  <= 1'b1;
    #50000;
    //sound enable
    addr[5]  <= 1'b1;
    #50000;
    //control read enable
    WRn <= 1'b1;
    #50000;
    WRn <= 1'b0;
    #50000;
    addr[1]   <= 1'b0;
    WRn       <= 1'b0;
    IORQn     <= 1'b1;
    addr[7]   <= 1'b0;
    #5000
    //IO TEST ALL PORTS FOR WRITE
    WRn <= 1'b0;
    RDn <= 1'b1;
    IORQn <= 1'b0;
    addr <= 0;
    for(index = 0; index < 256; index = index + 1)
    begin
      addr[7:0]  <= index;
      #5000;
    end
    #5000
    //IO TEST ALL PORTS FOR READ
    WRn <= 1'b1;
    RDn <= 1'b0;
    IORQn <= 1'b0;
    addr <= 0;
    for(index = 0; index < 256; index = index + 1)
    begin
      addr[7:0]  <= index;
      #5000;
    end
    #500000;
    $finish;
  end

endmodule
