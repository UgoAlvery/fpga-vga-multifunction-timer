--------------------------------------------------------------------
-- Testbench debounce_tb
-- Objectif : vérifier qu'un signal de bouton "sale" (avec rebonds)
-- ne produit qu'UNE seule impulsion propre en sortie de btn_pulse
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity debounce_tb is
end entity;

architecture sim of debounce_tb is

  component debounce is
    port (
      clk       : in  std_logic;
      reset_n   : in  std_logic;
      btn_in    : in  std_logic;
      btn_pulse : out std_logic
    );
  end component;

  signal clk       : std_logic := '0';
  signal reset_n   : std_logic := '0';
  signal btn_in    : std_logic := '0';
  signal btn_pulse : std_logic;

  constant CLK_PERIOD : time := 20 ns;  -- 50 MHz

  -- compteur d'impulsions observées, pour l'assertion finale
  signal pulse_count : integer := 0;

begin

  ----------------------------------------------------------------
  -- Instanciation
  ----------------------------------------------------------------
  DUT: debounce
    port map (
      clk       => clk,
      reset_n   => reset_n,
      btn_in    => btn_in,
      btn_pulse => btn_pulse
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
  -- Comptage des impulsions détectées (pour vérification)
  ----------------------------------------------------------------
  count_process: process(clk)
  begin
    if rising_edge(clk) then
      if btn_pulse = '1' then
        pulse_count <= pulse_count + 1;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Scénario de stimulus
  ----------------------------------------------------------------
  stim_process: process

    -- procédure utilitaire : impose btn_in pendant une durée donnée
    procedure hold(val : std_logic; d : time) is
    begin
      btn_in <= val;
      wait for d;
    end procedure;

  begin
    ------------------------------------------------------------
    -- Phase 0 : reset
    ------------------------------------------------------------
    reset_n <= '0';
    btn_in  <= '0';
    wait for 5 * CLK_PERIOD;
    reset_n <= '1';
    wait for 5 * CLK_PERIOD;

    ------------------------------------------------------------
    -- Phase 1 : appui avec rebonds réalistes
    -- Le contact "rebondit" pendant ~2 ms avant de se stabiliser
    -- à '1'. On alterne 0/1 sur des durées courtes et irrégulières,
    -- toutes très inférieures à la fenêtre de stabilité (4 ticks
    -- consécutifs à 1 ms => ~4 ms) exigée par le débounce.
    ------------------------------------------------------------
    hold('1', 30 us);
    hold('0', 40 us);
    hold('1', 20 us);
    hold('0', 15 us);
    hold('1', 25 us);
    hold('0', 10 us);
    -- stabilisation définitive à '1'
    hold('1', 10 ms);

    -- Vérification : une seule impulsion doit avoir été comptée
    assert pulse_count = 1
      report "ERREUR : nombre d'impulsions inattendu apres appui (pulse_count = "
             & integer'image(pulse_count) & ", attendu 1)"
      severity error;

    ------------------------------------------------------------
    -- Phase 2 : relâchement avec rebonds
    -- Ne doit générer AUCUNE nouvelle impulsion sur btn_pulse
    -- (le detecteur ne réagit qu'au front montant du signal stable)
    ------------------------------------------------------------
    hold('0', 30 us);
    hold('1', 20 us);
    hold('0', 25 us);
    hold('1', 15 us);
    hold('0', 10 ms);

    assert pulse_count = 1
      report "ERREUR : le relachement a genere une impulsion parasite (pulse_count = "
             & integer'image(pulse_count) & ", attendu toujours 1)"
      severity error;

    ------------------------------------------------------------
    -- Phase 3 : second appui propre, pour vérifier la réutilisabilité
    ------------------------------------------------------------
    hold('1', 10 ms);

    assert pulse_count = 2
      report "ERREUR : le second appui n'a pas ete detecte correctement (pulse_count = "
             & integer'image(pulse_count) & ", attendu 2)"
      severity error;

    report "TEST TERMINE : pulse_count final = " & integer'image(pulse_count);

    wait; -- fin de simulation
  end process;

end architecture;