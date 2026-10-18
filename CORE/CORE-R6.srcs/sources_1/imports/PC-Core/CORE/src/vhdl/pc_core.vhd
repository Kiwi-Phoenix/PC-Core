----------------------------------------------------------------------------------
-- Main Wrapper for the PC Core.
-- Ported from the MiSTer PC Core.
-- 
--   Aug 2026   David Raynor (Kiwi)
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   

entity pc_core is
      Port (
        reset       : in std_logic;    
        clk_sys     : in std_logic;
        clk_uart1   : in std_logic;   
        clk_uart2   : in std_logic;
        clk_vga     : in std_logic;
        clk_mpu     : in std_logic
       );
end pc_core;

architecture RTL of pc_core is

    type IP_TYPE is record
        reset : std_logic;
        clk_sys : std_logic;
        clk_uart1 : std_logic;
        clk_uart2 : std_logic;
        clk_vga : std_logic;
        clk_mpu : std_logic;
    end record;

signal ip : IP_TYPE;

begin

-- Map IP ports to signals
ip.reset        <= reset;
ip.clk_sys      <= clk_sys;
ip.clk_uart1    <= clk_uart1;
ip.clk_uart2    <= clk_uart2;      
ip.clk_vga      <= clk_vga;
ip.clk_mpu      <= clk_mpu;


-- Instantiate the PC Core ------------------------------------------------------------------
SYSTEM_INST : entity work.system
    port map (
         reset              => ip.reset
        ,clk_sys            => ip.clk_sys
                        
        -- Fill in some defaults until it can be wired up properly
        ,clock_rate         => 0
        ,l1_disable         => '0'
        ,l2_disable         => '0'

        ,fdd_request        => open
        ,ide0_request       => open
        ,ide1_request       => open
        ,floppy_wp          => (others => '0')

        ,joystick_dis      => (others => '0')
        ,joystick_dig_1    => (others => '0')
        ,joystick_dig_2    => (others => '0')
        ,joystick_ana_1    => (others => '0') 
        ,joystick_ana_2    => (others => '0')
        ,joystick_mode      => (others => '0')
        ,joystick_timed     => (others => '0')

        ,mgmt_address       => (others => '0')
        ,mgmt_read          => '0'
        ,mgmt_readdata      => open   
        ,mgmt_write         => '0'
        ,mgmt_writedata     => (others => '0')

        ,ps2_kbclk_in       => '0'
        ,ps2_kbdat_in       => '0'
        ,ps2_kbclk_out      => open
        ,ps2_kbdat_out      => open
        ,ps2_mouseclk_in    => '0'
        ,ps2_mousedat_in    => '0'
        ,ps2_mouseclk_out   => open
        ,ps2_mousedat_out   => open
        ,ps2_reset_n        => open

        ,bootcfg            => (others => '0')
        ,uma_ram            => '0'
        ,syscfg             => open

        ,clk_uart1          => ip.clk_uart1
        ,uart1_rx           => '0'
        ,uart1_tx           => open
        ,uart1_cts_n        => '0'
        ,uart1_dcd_n        => '0'
        ,uart1_dsr_n        => '0'
        ,uart1_rts_n        => open
        ,uart1_dtr_n        => open

        ,clk_uart2          => ip.clk_uart2
        ,uart2_rx           => '0'
        ,uart2_tx           => open   
        ,uart2_cts_n        => '0'
        ,uart2_dcd_n        => '0'
        ,uart2_dsr_n        => '0'
        ,uart2_rts_n        => open
        ,uart2_dtr_n        => open

        ,clk_mpu            => ip.clk_mpu
        ,mpu_rx             => '0'
        ,mpu_tx             => open

        -- Audio  
        ,clk_audio          => '0'
        ,sample_cms_l       => open
        ,sample_cms_r       => open
        ,sample_sb_l        => open
        ,sample_sb_r        => open
        ,sample_opl_l       => open
        ,sample_opl_r       => open
        ,sound_fm_mode      => '0'
        ,sound_cms_en       => '0'
        ,sample_gus_l       => open
        ,sample_gus_r       => open

        ,speaker_out        => open

        ,sbp                => open

        ,vol_master_l       => open
        ,vol_master_r       => open
        ,vol_voice_l        => open
        ,vol_voice_r        => open
        ,vol_midi_l         => open
        ,vol_midi_r         => open
        ,vol_cd_l           => open
        ,vol_cd_r           => open
        ,vol_line_l         => open
        ,vol_line_r         => open
        ,vol_spk            => open
        ,vol_en             => open

        -- Video
        ,clk_vga            => ip.clk_vga
        ,clock_rate_vga     => (others => '0')    

        ,video_ce           => open
        ,video_blank_n      => open
        ,video_hsync        => open
        ,video_vsync        => open
        ,video_r            => open
        ,video_g            => open
        ,video_b            => open
        ,video_f60          => '0'
        ,video_pal_a        => open
        ,video_pal_d        => open
        ,video_pal_we       => open
        ,video_start_addr   => open
        ,video_width        => open
        ,video_height       => open
        ,video_flags        => open
        ,video_stride       => open
        ,video_off          => open
        ,video_fb_en        => '0'
        ,video_lores        => '0'
        ,video_border       => '0'

        ,ddram_clk          => open
        ,ddram_busy         => '0'
        ,ddram_burstcnt     => open
        ,ddram_addr         => open
        ,ddram_dout         => (others => '0')
        ,ddram_dout_ready   => '0'
        ,ddram_rd           => open
        ,ddram_din          => open
        ,ddram_be           => open
        ,ddram_we           => open

        ,pll_locked         => '0'
        ,sdram_clk          => open
        ,sdram_cke          => open
        ,sdram_a            => open
        ,sdram_ba           => open
        ,sdram_dq           => open   -- INOUT port
        ,sdram_dqml         => open
        ,sdram_dqmh         => open
        ,sdram_nCS          => open
        ,sdram_nCAS         => open
        ,sdram_nRAS         => open        
        ,sdram_nWE          => open

    );




end architecture;
