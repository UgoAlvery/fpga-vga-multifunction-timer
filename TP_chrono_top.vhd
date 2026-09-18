--------------------------------------------------------------------
-- TP_chrono_top
-- Assemblage complet : debounce du bouton Start/Pause/Restart, FSM
-- de controle, generation du tick 10ms, chrono_counter (3 etages
-- BCD), decodage 7-segments, chenillard, prechargement du minuteur
-- (SW(9:1) = secondes totales, converties en BCD, actif tant qu'on
-- est en STOP+minuteur), et sortie VGA (PLL 25MHz + controleur VGA).
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TP_chrono_top is
  port (
    MAX10_CLK1_50 : in  std_logic;
    KEY : in  std_logic_vector(1 downto 0);  -- KEY(0)=reset async actif bas, KEY(1)=Start/Pause/Restart
    SW  : in  std_logic_vector(9 downto 0);  -- SW(0)=mode chrono/minuteur, SW(9:1)=reload (pas encore cable)

    LEDR : out std_logic_vector(9 downto 0);

    HEX0 : out std_logic_vector(6 downto 0);
    HEX1 : out std_logic_vector(6 downto 0);
    HEX2 : out std_logic_vector(6 downto 0);
    HEX3 : out std_logic_vector(6 downto 0);
    HEX4 : out std_logic_vector(6 downto 0);
    HEX5 : out std_logic_vector(6 downto 0);

    VGA_R  : out std_logic_vector(3 downto 0);
    VGA_G  : out std_logic_vector(3 downto 0);
    VGA_B  : out std_logic_vector(3 downto 0);
    VGA_HS : out std_logic;
    VGA_VS : out std_logic
  );
end entity;

architecture structural of TP_chrono_top is

  component debounce is
    port (
      clk       : in  std_logic;
      reset_n   : in  std_logic;
      btn_in    : in  std_logic;
      btn_pulse : out std_logic
    );
  end component;

  component fsm_controle is
    port (
      clk     : in  std_logic;
      reset_n : in  std_logic;
      key1    : in  std_logic;
      etat    : out std_logic_vector(1 downto 0)
    );
  end component;

  component tick_gen is
    generic (
      DIVISOR : positive := 500000
    );
    port (
      clk     : in  std_logic;
      reset_n : in  std_logic;
      tick    : out std_logic
    );
  end component;

  component chrono_counter is
    port (
      clk       : in  std_logic;
      reset_n   : in  std_logic;
      tick_10ms : in  std_logic;
      count_up  : in  std_logic;
      load      : in  std_logic;

      load_cent_tens   : in  std_logic_vector(3 downto 0);
      load_cent_units  : in  std_logic_vector(3 downto 0);
      load_sec_tens    : in  std_logic_vector(3 downto 0);
      load_sec_units   : in  std_logic_vector(3 downto 0);
      load_min_tens    : in  std_logic_vector(3 downto 0);
      load_min_units   : in  std_logic_vector(3 downto 0);

      cent_tens  : out std_logic_vector(3 downto 0);
      cent_units : out std_logic_vector(3 downto 0);
      sec_tens   : out std_logic_vector(3 downto 0);
      sec_units  : out std_logic_vector(3 downto 0);
      min_tens   : out std_logic_vector(3 downto 0);
      min_units  : out std_logic_vector(3 downto 0)
    );
  end component;

  component chenillard is
    generic (
      WIDTH : positive := 8
    );
    port (
      clk     : in  std_logic;
      reset_n : in  std_logic;
      enable  : in  std_logic;
      leds    : out std_logic_vector(WIDTH - 1 downto 0)
    );
  end component;

  component seconds_to_bcd is
    port (
      total_seconds : in  unsigned(8 downto 0);
      min_tens   : out std_logic_vector(3 downto 0);
      min_units  : out std_logic_vector(3 downto 0);
      sec_tens   : out std_logic_vector(3 downto 0);
      sec_units  : out std_logic_vector(3 downto 0)
    );
  end component;

  component seg7_decoder_array is
    port (
      cent_units : in  std_logic_vector(3 downto 0);
      cent_tens  : in  std_logic_vector(3 downto 0);
      sec_units  : in  std_logic_vector(3 downto 0);
      sec_tens   : in  std_logic_vector(3 downto 0);
      min_units  : in  std_logic_vector(3 downto 0);
      min_tens   : in  std_logic_vector(3 downto 0);

      HEX0 : out std_logic_vector(6 downto 0);
      HEX1 : out std_logic_vector(6 downto 0);
      HEX2 : out std_logic_vector(6 downto 0);
      HEX3 : out std_logic_vector(6 downto 0);
      HEX4 : out std_logic_vector(6 downto 0);
      HEX5 : out std_logic_vector(6 downto 0)
    );
  end component;

  component pll_vga is
    port (
      areset : in  std_logic := '0';
      inclk0 : in  std_logic := '0';
      c0     : out std_logic;
      locked : out std_logic
    );
  end component;

  component vga_controller is
    port (
      pixel_clk   : in  std_logic;
      reset_n     : in  std_logic;
      etat        : in  std_logic_vector(1 downto 0);
      cent_tens   : in  std_logic_vector(3 downto 0);
      cent_units  : in  std_logic_vector(3 downto 0);
      VGA_R       : out std_logic_vector(3 downto 0);
      VGA_G       : out std_logic_vector(3 downto 0);
      VGA_B       : out std_logic_vector(3 downto 0);
      VGA_HS      : out std_logic;
      VGA_VS      : out std_logic
    );
  end component;

  signal reset_n : std_logic;
  signal key1_pulse : std_logic;
  signal etat : std_logic_vector(1 downto 0);
  signal running : std_logic;

  signal tick_10ms_raw : std_logic;
  signal chrono_tick   : std_logic;
  signal key1_raw      : std_logic;   -- KEY(1) inverse (actif haut) avant debounce
  signal count_up_sig  : std_logic;   -- SW(0) inverse, sens de comptage
  signal chenillard_en : std_logic;   -- enable du chenillard

  signal cent_tens, cent_units : std_logic_vector(3 downto 0);
  signal sec_tens,  sec_units  : std_logic_vector(3 downto 0);
  signal min_tens,  min_units  : std_logic_vector(3 downto 0);

  signal sw_total_sec : unsigned(8 downto 0);
  signal load_sig      : std_logic;
  signal load_min_tens_sig, load_min_units_sig : std_logic_vector(3 downto 0);
  signal load_sec_tens_sig, load_sec_units_sig : std_logic_vector(3 downto 0);
  signal timer_at_zero : std_logic;

  signal pixel_clk_sig : std_logic;
  signal pll_areset    : std_logic;
  signal pll_locked    : std_logic;
  signal vga_reset_n   : std_logic;

  constant ZERO4 : std_logic_vector(3 downto 0) := (others => '0');

begin

  reset_n <= KEY(0);
  running <= '1' when etat = "01" else '0';
  key1_raw     <= not KEY(1);
  count_up_sig <= not SW(0);
  chenillard_en <= (tick_10ms_raw and running) and not (timer_at_zero and not count_up_sig);
  pll_areset  <= not reset_n;                 -- ALTPLL : reset actif haut
  vga_reset_n <= reset_n and pll_locked;      -- pas de sortie VGA tant que la PLL n'est pas stable

  -- Prechargement du minuteur : actif en continu tant qu'on est a
  -- l'arret (STOP) et en mode minuteur (SW(0)='1') -- l'affichage
  -- reflete alors en temps reel le reglage des switches, et se fige
  -- des le demarrage (KEY(1)).
  sw_total_sec <= unsigned(SW(9 downto 1));
  load_sig <= '1' when (etat = "00" and SW(0) = '1') else '0';

  ------------------------------------------------------------------
  -- Debounce du bouton Start/Pause/Restart
  ------------------------------------------------------------------
  U_DEBOUNCE: debounce
    port map (
      clk       => MAX10_CLK1_50,
      reset_n   => reset_n,
      btn_in    => key1_raw,
      btn_pulse => key1_pulse
    );

  ------------------------------------------------------------------
  -- FSM de controle STOP/RUN/PAUSE
  ------------------------------------------------------------------
  U_FSM: fsm_controle
    port map (
      clk     => MAX10_CLK1_50,
      reset_n => reset_n,
      key1    => key1_pulse,
      etat    => etat
    );

  ------------------------------------------------------------------
  -- Tick 10 ms, actif uniquement en etat RUN
  ------------------------------------------------------------------
  U_TICK: tick_gen
    generic map ( DIVISOR => 500000 )
    port map (
      clk     => MAX10_CLK1_50,
      reset_n => reset_n,
      tick    => tick_10ms_raw
    );

  chrono_tick <= (tick_10ms_raw and running) and not (timer_at_zero and not count_up_sig);

  -- Detection "minuteur a zero" : bloque le tick en mode descendant
  -- pour figer l'affichage a 00:00:00 au lieu de reboucler vers
  -- 99:59:99 (borrow). Sans effet en mode ascendant.
  timer_at_zero <= '1' when (cent_tens = ZERO4 and cent_units = ZERO4 and
                             sec_tens  = ZERO4 and sec_units  = ZERO4 and
                             min_tens  = ZERO4 and min_units  = ZERO4)
                    else '0';

  ------------------------------------------------------------------
  -- Conversion SW(9 downto 1) (secondes totales, binaire) -> BCD
  ------------------------------------------------------------------
  U_PRESET: seconds_to_bcd
    port map (
      total_seconds => sw_total_sec,
      min_tens   => load_min_tens_sig,
      min_units  => load_min_units_sig,
      sec_tens   => load_sec_tens_sig,
      sec_units  => load_sec_units_sig
    );

  ------------------------------------------------------------------
  -- Chrono/minuteur : 3 etages BCD chaines
  ------------------------------------------------------------------
  U_CHRONO: chrono_counter
    port map (
      clk       => MAX10_CLK1_50,
      reset_n   => reset_n,
      tick_10ms => chrono_tick,
      count_up  => count_up_sig,
      load      => load_sig,

      load_cent_tens  => ZERO4,
      load_cent_units => ZERO4,
      load_sec_tens   => load_sec_tens_sig,
      load_sec_units  => load_sec_units_sig,
      load_min_tens   => load_min_tens_sig,
      load_min_units  => load_min_units_sig,

      cent_tens  => cent_tens,
      cent_units => cent_units,
      sec_tens   => sec_tens,
      sec_units  => sec_units,
      min_tens   => min_tens,
      min_units  => min_units
    );

  ------------------------------------------------------------------
  -- Decodage 7-segments
  ------------------------------------------------------------------
  U_SEG: seg7_decoder_array
    port map (
      cent_units => cent_units,
      cent_tens  => cent_tens,
      sec_units  => sec_units,
      sec_tens   => sec_tens,
      min_units  => min_units,
      min_tens   => min_tens,
      HEX0 => HEX0, HEX1 => HEX1, HEX2 => HEX2,
      HEX3 => HEX3, HEX4 => HEX4, HEX5 => HEX5
    );

  ------------------------------------------------------------------
  -- Chenillard, actif uniquement en RUN, cadence sur le tick d'affichage
  ------------------------------------------------------------------
  U_CHENILLARD: chenillard
    generic map ( WIDTH => 8 )
    port map (
      clk     => MAX10_CLK1_50,
      reset_n => reset_n,
      enable  => chenillard_en,
      leds    => LEDR(9 downto 2)
    );

  ------------------------------------------------------------------
  -- LEDR : indicateurs disponibles des ce stade
  --   LEDR(0) : mode (passthrough SW(0))
  --   LEDR(1) : etat RUN
  --   LEDR(9 downto 2) : chenillard, cable ci-dessus
  ------------------------------------------------------------------
  LEDR(0) <= SW(0);
  LEDR(1) <= running;

  ------------------------------------------------------------------
  -- PLL : 50 MHz (MAX10_CLK1_50) -> 25 MHz (pixel clock VGA)
  ------------------------------------------------------------------
  U_PLL_VGA: pll_vga
    port map (
      areset => pll_areset,
      inclk0 => MAX10_CLK1_50,
      c0     => pixel_clk_sig,
      locked => pll_locked
    );

  ------------------------------------------------------------------
  -- Controleur VGA (couleur de fond + barre selon etat FSM et
  -- centiemes de seconde)
  ------------------------------------------------------------------
  U_VGA: vga_controller
    port map (
      pixel_clk   => pixel_clk_sig,
      reset_n     => vga_reset_n,
      etat        => etat,
      cent_tens   => cent_tens,
      cent_units  => cent_units,
      VGA_R       => VGA_R,
      VGA_G       => VGA_G,
      VGA_B       => VGA_B,
      VGA_HS      => VGA_HS,
      VGA_VS      => VGA_VS
    );

end architecture;