--------------------------------------------------------------------
-- TP_chrono_top
-- Premier assemblage testable sur carte, sans le VGA (ajoute plus
-- tard). Couvre : debounce du bouton Start/Pause/Restart, FSM de
-- controle, generation du tick 10ms, chrono_counter (3 etages BCD),
-- decodage 7-segments vers HEX0-HEX5.
--
-- Points volontairement laisses ouverts a ce stade :
--   - Prechargement du minuteur (load/load_*) : fige a '0' / zero
--     tant que le mapping SW(9 downto 1) -> MM:SS n'est pas arrete.
--   - LEDR(9 downto 2) (chenillard) : non cable, brique a ecrire.
--   - VGA : hors perimetre de ce premier test materiel.
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

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
    HEX5 : out std_logic_vector(6 downto 0)
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

  signal reset_n : std_logic;
  signal key1_pulse : std_logic;
  signal etat : std_logic_vector(1 downto 0);
  signal running : std_logic;

  signal tick_10ms_raw : std_logic;
  signal chrono_tick   : std_logic;

  signal cent_tens, cent_units : std_logic_vector(3 downto 0);
  signal sec_tens,  sec_units  : std_logic_vector(3 downto 0);
  signal min_tens,  min_units  : std_logic_vector(3 downto 0);

  constant ZERO4 : std_logic_vector(3 downto 0) := (others => '0');

begin

  reset_n <= KEY(0);
  running <= '1' when etat = "01" else '0';

  ------------------------------------------------------------------
  -- Debounce du bouton Start/Pause/Restart
  ------------------------------------------------------------------
  U_DEBOUNCE: debounce
    port map (
      clk       => MAX10_CLK1_50,
      reset_n   => reset_n,
      btn_in    => not KEY(1),
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

  chrono_tick <= tick_10ms_raw and running;

  ------------------------------------------------------------------
  -- Chrono/minuteur : 3 etages BCD chaines
  -- (load et prechargement non cables pour ce premier test)
  ------------------------------------------------------------------
  U_CHRONO: chrono_counter
    port map (
      clk       => MAX10_CLK1_50,
      reset_n   => reset_n,
      tick_10ms => chrono_tick,
      count_up  => not SW(0),
      load      => '0',

      load_cent_tens  => ZERO4,
      load_cent_units => ZERO4,
      load_sec_tens   => ZERO4,
      load_sec_units  => ZERO4,
      load_min_tens   => ZERO4,
      load_min_units  => ZERO4,

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
  -- LEDR : indicateurs disponibles des ce stade
  --   LEDR(0) : mode (passthrough SW(0))
  --   LEDR(1) : etat RUN
  --   LEDR(9 downto 2) : chenillard -- PAS ENCORE CABLE (a zero)
  ------------------------------------------------------------------
  LEDR(0) <= SW(0);
  LEDR(1) <= running;
  LEDR(9 downto 2) <= (others => '0');

end architecture;