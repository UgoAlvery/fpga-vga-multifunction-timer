--------------------------------------------------------------------
-- Testbench chenillard_tb
-- Objectif : verifier le cycle complet de rebond va-et-vient sur
-- WIDTH=8 (comme utilise dans TP_chrono_top) :
--   - position initiale a 0 apres reset
--   - montee 0 -> 7, une position par impulsion enable
--   - rebond en haut (7 -> 6, changement de sens)
--   - descente 6 -> 0
--   - rebond en bas (0 -> 1, nouveau changement de sens)
--   - une seule LED active a la fois, a chaque instant
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity chenillard_tb is
end entity;

architecture sim of chenillard_tb is

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

  constant CLK_PERIOD : time := 20 ns;  -- 50 MHz
  constant WIDTH_C     : integer := 8;

  signal clk     : std_logic := '0';
  signal reset_n : std_logic := '0';
  signal enable  : std_logic := '0';
  signal leds    : std_logic_vector(WIDTH_C - 1 downto 0);

  -- fonction utilitaire : construit le motif attendu (une seule LED
  -- a la position donnee)
  function expected_leds(pos : integer) return std_logic_vector is
    variable tmp : std_logic_vector(WIDTH_C - 1 downto 0) := (others => '0');
  begin
    tmp(pos) := '1';
    return tmp;
  end function;

  -- verifie qu'exactement un bit est a '1' dans le vecteur
  function exactly_one_bit(v : std_logic_vector) return boolean is
    variable count : integer := 0;
  begin
    for i in v'range loop
      if v(i) = '1' then
        count := count + 1;
      end if;
    end loop;
    return count = 1;
  end function;

begin

  DUT: chenillard
    generic map ( WIDTH => WIDTH_C )
    port map (
      clk     => clk,
      reset_n => reset_n,
      enable  => enable,
      leds    => leds
    );

  ----------------------------------------------------------------
  -- Horloge
  ----------------------------------------------------------------
  clk_process: process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  ----------------------------------------------------------------
  -- Stimulus
  ----------------------------------------------------------------
  stim_process: process

    procedure pulse_enable is
    begin
      wait until rising_edge(clk);
      enable <= '1';
      wait until rising_edge(clk);
      enable <= '0';
      wait for 1 ns;  -- evite la race stimulus/DUT (cf. compteur BCD)
    end procedure;

  begin
    ------------------------------------------------------------
    -- Phase 0 : reset -> position 0
    ------------------------------------------------------------
    reset_n <= '0';
    wait for 5 * CLK_PERIOD;
    assert leds = expected_leds(0)
      report "ERREUR : position apres reset != 0"
      severity error;

    reset_n <= '1';
    wait for 2 * CLK_PERIOD;
    assert leds = expected_leds(0)
      report "ERREUR : la position a change sans impulsion enable"
      severity error;

    ------------------------------------------------------------
    -- Phase 1 : montee complete 0 -> 7
    ------------------------------------------------------------
    for i in 1 to WIDTH_C - 1 loop
      pulse_enable;
      assert leds = expected_leds(i)
        report "ERREUR : montee, position attendue " & integer'image(i)
        severity error;
      assert exactly_one_bit(leds)
        report "ERREUR : plus d'une LED active simultanement (montee, i="
               & integer'image(i) & ")"
        severity error;
    end loop;

    ------------------------------------------------------------
    -- Phase 2 : rebond en haut, 7 -> 6
    ------------------------------------------------------------
    pulse_enable;
    assert leds = expected_leds(WIDTH_C - 2)
      report "ERREUR : rebond en haut non effectue (attendu position "
             & integer'image(WIDTH_C - 2) & ")"
      severity error;

    ------------------------------------------------------------
    -- Phase 3 : descente complete 6 -> 0
    ------------------------------------------------------------
    for i in WIDTH_C - 3 downto 0 loop
      pulse_enable;
      assert leds = expected_leds(i)
        report "ERREUR : descente, position attendue " & integer'image(i)
        severity error;
      assert exactly_one_bit(leds)
        report "ERREUR : plus d'une LED active simultanement (descente, i="
               & integer'image(i) & ")"
        severity error;
    end loop;

    ------------------------------------------------------------
    -- Phase 4 : rebond en bas, 0 -> 1 (confirme la reprise du cycle)
    ------------------------------------------------------------
    pulse_enable;
    assert leds = expected_leds(1)
      report "ERREUR : rebond en bas non effectue (attendu position 1)"
      severity error;

    ------------------------------------------------------------
    -- Phase 5 : maintien de la position sans impulsion
    ------------------------------------------------------------
    wait for 10 * CLK_PERIOD;
    assert leds = expected_leds(1)
      report "ERREUR : la position a change sans impulsion enable (maintien)"
      severity error;

    report "TEST TERMINE : cycle complet montee/rebond/descente/rebond verifie";

    wait; -- fin de simulation
  end process;

end architecture;
