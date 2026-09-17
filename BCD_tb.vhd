--------------------------------------------------------------------
-- Testbench BCD_tb
-- Objectif : verifier le compteur BCD 2-chiffres (bcd_counter_2digit)
--   - comptage ascendant avec rollover (carry_out)
--   - comptage descendant avec rollover (borrow_out)
--   - chargement synchrone (load) prioritaire sur enable
-- Instance testee avec MAX = 59 (cas secondes/minutes), le cas le
-- plus general puisque 59 n'est pas un multiple de 10 exact au
-- niveau des dizaines (5 dizaines completes + reste).
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BCD_tb is
end entity;

architecture sim of BCD_tb is

  component bcd_counter_2digit is
    generic (
      MAX : integer range 0 to 99 := 99
    );
    port (
      clk        : in  std_logic;
      reset_n    : in  std_logic;
      enable     : in  std_logic;
      count_up   : in  std_logic;
      load       : in  std_logic;
      load_tens  : in  std_logic_vector(3 downto 0);
      load_units : in  std_logic_vector(3 downto 0);
      digit_tens  : out std_logic_vector(3 downto 0);
      digit_units : out std_logic_vector(3 downto 0);
      carry_out  : out std_logic;
      borrow_out : out std_logic
    );
  end component;

  constant CLK_PERIOD : time := 20 ns;  -- 50 MHz
  constant MAX_C       : integer := 59;

  signal clk        : std_logic := '0';
  signal reset_n    : std_logic := '0';
  signal enable     : std_logic := '0';
  signal count_up   : std_logic := '1';
  signal load       : std_logic := '0';
  signal load_tens  : std_logic_vector(3 downto 0) := (others => '0');
  signal load_units : std_logic_vector(3 downto 0) := (others => '0');
  signal digit_tens  : std_logic_vector(3 downto 0);
  signal digit_units : std_logic_vector(3 downto 0);
  signal carry_out  : std_logic;
  signal borrow_out : std_logic;

  -- valeur decimale reconstruite pour les assertions
  signal value_dec : integer;

begin

  ----------------------------------------------------------------
  -- Instanciation (MAX = 59)
  ----------------------------------------------------------------
  DUT: bcd_counter_2digit
    generic map ( MAX => MAX_C )
    port map (
      clk         => clk,
      reset_n     => reset_n,
      enable      => enable,
      count_up    => count_up,
      load        => load,
      load_tens   => load_tens,
      load_units  => load_units,
      digit_tens  => digit_tens,
      digit_units => digit_units,
      carry_out   => carry_out,
      borrow_out  => borrow_out
    );

  value_dec <= to_integer(unsigned(digit_tens)) * 10
             + to_integer(unsigned(digit_units));

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
  -- Procedure utilitaire : genere une impulsion enable d'un cycle
  ----------------------------------------------------------------
  stim_process: process

    procedure pulse_enable is
    begin
      wait until rising_edge(clk);
      enable <= '1';
      wait until rising_edge(clk);
      enable <= '0';
      -- laisse le temps aux registres du DUT de se mettre a jour
      -- avant toute lecture (evite la race stimulus/DUT sur le
      -- meme front d'horloge)
      wait for 1 ns;
    end procedure;

  begin
    ------------------------------------------------------------
    -- Phase 0 : reset
    ------------------------------------------------------------
    reset_n <= '0';
    wait for 5 * CLK_PERIOD;
    reset_n <= '1';
    wait for 2 * CLK_PERIOD;

    assert value_dec = 0
      report "ERREUR : valeur apres reset != 0 (value_dec = "
             & integer'image(value_dec) & ")"
      severity error;

    ------------------------------------------------------------
    -- Phase 1 : comptage ascendant simple (0 -> 9)
    ------------------------------------------------------------
    count_up <= '1';
    for i in 1 to 9 loop
      pulse_enable;
    end loop;

    assert value_dec = 9
      report "ERREUR : comptage ascendant simple, attendu 9, obtenu "
             & integer'image(value_dec)
      severity error;

    ------------------------------------------------------------
    -- Phase 2 : franchissement dizaine (9 -> 10), pas de carry ici
    -- (carry_out ne doit apparaitre qu'au rollover complet MAX -> 0)
    ------------------------------------------------------------
    pulse_enable;

    assert value_dec = 10
      report "ERREUR : franchissement dizaine, attendu 10, obtenu "
             & integer'image(value_dec)
      severity error;

    assert carry_out = '0'
      report "ERREUR : carry_out actif alors qu'on est a 10 (pas un rollover complet)"
      severity error;

    ------------------------------------------------------------
    -- Phase 3 : atteindre MAX (59) puis rollover -> carry_out = '1'
    -- On est a 10, il faut 49 impulsions pour atteindre 59.
    ------------------------------------------------------------
    for i in 1 to 49 loop
      pulse_enable;
    end loop;

    assert value_dec = MAX_C
      report "ERREUR : n'a pas atteint MAX (" & integer'image(MAX_C)
             & "), obtenu " & integer'image(value_dec)
      severity error;

    -- une impulsion de plus : rollover 59 -> 00 avec carry_out = '1'
    pulse_enable;

    assert value_dec = 0
      report "ERREUR : rollover ascendant, attendu 0, obtenu "
             & integer'image(value_dec)
      severity error;

    assert carry_out = '1'
      report "ERREUR : carry_out non actif lors du rollover MAX -> 0"
      severity error;

    wait until rising_edge(clk);  -- laisser carry_out retomber a '0'

    ------------------------------------------------------------
    -- Phase 4 : chargement synchrone (load), priorite sur enable
    -- On charge 45, en imposant enable='1' en meme temps pour
    -- verifier que load est bien prioritaire.
    ------------------------------------------------------------
    load_tens  <= std_logic_vector(to_unsigned(4, 4));
    load_units <= std_logic_vector(to_unsigned(5, 4));
    load       <= '1';
    enable     <= '1';
    wait until rising_edge(clk);
    load   <= '0';
    enable <= '0';
    wait for CLK_PERIOD;

    assert value_dec = 45
      report "ERREUR : chargement synchrone, attendu 45, obtenu "
             & integer'image(value_dec)
      severity error;

    ------------------------------------------------------------
    -- Phase 5 : comptage descendant depuis 45, franchissement
    -- dizaine descendant (45 -> 39, emprunt sur les unites)
    ------------------------------------------------------------
    count_up <= '0';
    for i in 1 to 6 loop
      pulse_enable;
    end loop;

    assert value_dec = 39
      report "ERREUR : comptage descendant, attendu 39, obtenu "
             & integer'image(value_dec)
      severity error;

    ------------------------------------------------------------
    -- Phase 6 : descendre jusqu'a 0 puis rollover -> borrow_out = '1'
    -- On est a 39, il faut 39 impulsions pour atteindre 0.
    ------------------------------------------------------------
    for i in 1 to 39 loop
      pulse_enable;
    end loop;

    assert value_dec = 0
      report "ERREUR : n'a pas atteint 0 en descendant, obtenu "
             & integer'image(value_dec)
      severity error;

    -- une impulsion de plus : rollover 00 -> MAX avec borrow_out = '1'
    pulse_enable;

    assert value_dec = MAX_C
      report "ERREUR : rollover descendant, attendu " & integer'image(MAX_C)
             & ", obtenu " & integer'image(value_dec)
      severity error;

    assert borrow_out = '1'
      report "ERREUR : borrow_out non actif lors du rollover 0 -> MAX"
      severity error;

    report "TEST TERMINE : toutes les phases executees, value_dec final = "
           & integer'image(value_dec);

    wait; -- fin de simulation
  end process;

end architecture;