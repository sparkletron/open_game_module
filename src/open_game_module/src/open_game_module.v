//******************************************************************************
// file:    open_game_module.v
//
// author:  JAY CONVERTINO
//
// date:    2025/04/19
//
// about:   Brief
// Colecovision Emulation of the Super Game Module using a YMZ284 for audio.
//
// license: License MIT
// Copyright 2025 Jay Convertino
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
//******************************************************************************

/*
 * Module: open_game_module
 *
 * Colecovision Super Game Module Glue Logic
 *
 * Ports:
 *
 *   clk            - Clock for all devices in the core
 *   A              - Address input bus from Z80
 *   MREQn          - Z80 memory request input, active low
 *   RFSHn          - Refresh request, active low
 *   IORQn          - Z80 IO request input, active low
 *   WRn            - Z80 Write to bus, active low
 *   RESETn         - Input for reset, active low
 *   RDn            - Z80 Read from bus, active low
 *   D              - Z80 8 bit data bus, tristate IN/OUT
 *   RAM_CSn        - RAM chip select, active low
 *   RAM_OEn        - RAM Ouput enable, active low
 *   RAM_WEn        - RAM write enable, active low
 *   AY_CSn         - AY sound chip chip select
 *   AY_AS          - AY data or register select
 */
module open_game_module
  (
    input         clk,
    input [10:0]  A,
    input         MREQn,
    input         RFSHn,
    input         IORQn,
    input         WRn,
    input         RESETn,
    input         RDn,
    inout [7:0]   D,
    output        RAM_CSn,
    output        RAM_OEn,
    output        AY_CSn,
    output        AY_AS
  );

  integer i;

  //****************************************************************************
  // Group: Register Information
  // Core has 3 registers at the IO addresses that follow.
  //
  //  <SOUND_ADDR_CACHE>  - h50
  //  <SOUND_CACHE>       - h51
  //  <RAM_24K_ENABLE>    - h53
  //  <SWAP_BIOS_TO_RAM>  - h7F
  //****************************************************************************

  // Register Address: SOUND_ADDR_CACHE
  // Defines the address of r_snd_addr_cache
  // (see diagrams/reg_sound_addr_cache.png)
  // Setup an address for cache the sound address so each write will be to a proper address (opcode games need to write multiple and read multiple addresses)
  // The resister is only 4 bits since there are only 16 registers max.
  localparam SOUND_ADDR_CACHE = 8'h50;
  // Register Address: SOUND_CACHE
  // Defines the address of r_snd_cache
  // (see diagrams/reg_sound_cache.png)
  // Cache Sound Chip as the SGM games read from it (Yamaha chip does not have a read like a GI does).
  localparam SOUND_CACHE = 8'h51;
  // Register Address: RAM_24K_ENABLE
  // Defines the address of r_24k_ena
  // (see diagrams/reg_24k_ram_enable.png)
  // Super Game Module 24K RAM enable using bit 0 (Active High)
  localparam RAM_24K_ENABLE = 8'h53;
  // Register Address: SWAP_BIOS_TO_RAM
  // Defines the address of r_swap_ena
  // (see diagrams/reg_swap_bios_enable.png)
  // Super Game Module BIOS to RAM swap on bit 1 (Active Low)
  localparam SWAP_BIOS_TO_RAM = 8'h7F;

  //internal wires
  wire s_enable;
  wire s_ram_csn;
  wire s_ram0_csn;
  wire s_ram1_csn;
  wire s_ram2_csn;
  wire s_y0_seln;

  // var: r_snd_addr_cache
  // register for SOUND_ADDR_CACHE
  // See Also: <SOUND_ADDR_CACHE>
  reg [ 1:0]  r_snd_addr_cache  = 0;
  // var: r_24k_ena
  // register for RAM_24K_ENABLE
  // See Also: <RAM_24K_ENABLE>
  reg [ 7:0]  r_24k_ena         = 0;
  // var: r_swap_ena
  // register for 8K RAM/ROM swap
  // See Also: <SWAP_BIOS_TO_RAM>
  reg [ 7:0]  r_swap_ena        = 8'h0F;
  // var: r_snd_cache
  // register for SOUND_CACHE
  // See Also: <SOUND_CACHE>
  reg [ 7:0]  r_snd_cache[3:0];


  //****************************************************************************
  // Group: Assignment Information
  // How signals are created
  //****************************************************************************

  /* assign: s_enable
   * Decided to keep the same method used internally as the coleco. This emualtes the original ttl chip logic.
   *
   */
  assign s_enable = (RFSHn & ~MREQn);

  /* assign: s_y0_seln
   * Address h0000, ROM/RAM
   *
   * s_enable  - Enable decoder
   * A[10:8]   - Address lines used for select lines (actually lines A[15:13]).
   */
  assign s_y0_seln      = ~(s_enable & ~A[10] & ~A[9] & ~A[8]); //Y0

  /* assign: s_ram2_csn
   * Address h2000, RAM
   *
   * s_enable  - Enable decoder
   * A[10:8]   - Address lines used for select lines (actually lines A[15:13]).
   */
  assign s_ram2_csn     = ~(s_enable & ~A[10] & ~A[9] &  A[8]); //Y1

  /* assign: s_ram1_csn
   * Address h4000, RAM
   *
   * s_enable  - Enable decoder
   * A[10:8]   - Address lines used for select lines (actually lines A[15:13]).
   */
  assign s_ram1_csn     = ~(s_enable & ~A[10] &  A[9] & ~A[8]); //Y2

  /* assign: s_ram0_csn
   * Address h6000, RAM
   *
   * s_enable  - Enable decoder
   * A[10:8]   - Address lines used for select lines (actually lines A[15:13]).
   */
  assign s_ram0_csn     = ~(s_enable & ~A[10] &  A[9] &  A[8]); //Y3

  /* assign: s_ram_csn
   * RAM Chip select when address is requested (active low). When the 24k is not enabled, use internal memory.
   *
   * (s_y0_seln   | r_swap_ena[1]) - address range starting at h0000, swap bios/rom bit is enabled (1 is disabled).
   * (s_ram1_csn  | ~r_24k_ena[0]) - address range starting at h4000, 24k enable bit from register.
   * (s_ram2_csn  | ~r_24k_ena[0]) - address range starting at h2000, 24k enable bit from register.
   * (s_ram0_csn  | ~r_24k_ena[0]) - address range starting at h6000, 24k enable bit from register.
   */
  assign s_ram_csn = ((s_y0_seln | r_swap_ena[1]) & (s_ram2_csn  | ~r_24k_ena[0]) & (s_ram1_csn | ~r_24k_ena[0]) & (s_ram0_csn | ~r_24k_ena[0]));

  /* assign: RAM_OEn
   * RAM Output enable when read is requested (active low).
   *
   * RDn        - Z80 read request, active low.
   * s_ram_csn  - See Also: <s_ram_csn>
   */
  assign RAM_OEn = RDn | s_ram_csn;

  /* assign: RAM_CSn
   * RAM Chip Select output assignment.
   *
   * s_ram_csn  - See Also: <s_ram_csn>
   */
  assign RAM_CSn = s_ram_csn;

  //****************************************************************************
  // Group: Decoder Information for Super Game Module
  // How address decoder is created for Super Game Module, using a YMZ284.
  //
  // SGM IO REG - Clocked IO decoder for Super Game Module.
  //****************************************************************************

  /* assign: AY_AS
   * h50 is the address select, when selected its in data mode
   *
   * A[7:0] - If address matches h50, enable
   * IORQn  - Active IO request, enable
   * WRn    - Z80 write is active, enable
   */
  assign AY_AS          = (A[7:0] == 8'h50 & ~IORQn & ~WRn      ? 1'b0 : 1'b1);

  /* assign: s_ay_sound_csn
   * match both h50 and h51 by ignoring bit 0. Enable AY sound chip.
   *
   * A[7:0] - If address matches h50 or h51, enable
   * IORQn  - Active IO request, enable
   * WRn    - Z80 write is active, enable
   */
  assign AY_CSn         = (A[7:1] == 7'b0101000 & ~IORQn & ~WRn ? 1'b0 : 1'b1);

  /* assign: D
   * read cached register from previous write (AY emulation), at set address location.
   *
   * A[7:0] - If address matches h52, enable
   * IORQn  - Active IO request, enable
   * RDn    - Z80 read is active, enable
   */
  assign D              = (A[7:0] == 8'h52 & ~IORQn & ~RDn      ? r_snd_cache[{2'b00, r_snd_addr_cache}]   : 8'bzzzzzzzz);

  //IO registers
  //This logic is registered

  //****************************************************************************
  /// SGM IO REG
  /// Decoder logic for writes to the SGM address range.
  //****************************************************************************
  always @(negedge clk)
  begin
    if(~RESETn)
    begin
      r_swap_ena  <= 8'h0F;
      r_24k_ena   <= 0;
      for(i = 0; i < 4; i = i + 1)
      begin
        r_snd_cache[i] <= 0;
      end
    end else begin

      if(~IORQn & ~WRn)
      begin
        case (A[7:0])
          // on write to sound chip address reg, cache address. Get bits 2:1 into 1:0 create a right shift by 1 (divide by 2).
          SOUND_ADDR_CACHE: r_snd_addr_cache <= D[2:1];
          // on write to sound chip data reg, cache data. Write to cached address location.
          SOUND_CACHE: r_snd_cache[{2'b00, r_snd_addr_cache}] <= D;
          //exapand ram to 24k by setting bit 0 to 1
          RAM_24K_ENABLE: r_24k_ena  <= D;
          //swap out bios for ram by setting bit 1 to 0
          SWAP_BIOS_TO_RAM: r_swap_ena <= D;
          default:
          begin
          end
        endcase
      end
    end
  end

endmodule
