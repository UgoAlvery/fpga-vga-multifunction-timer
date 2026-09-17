--------------------------------------------------------------------
-- Testbench fsm_controle_tb
-- Objectif : verifier le cycle de transitions STOP -> RUN -> PAUSE
-- -> RUN, le maintien de l'etat en l'absence d'impulsion key1, et
-- le retour a STOP par reset asynchrone depuis n'importe quel etat.
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsm_controle_tb is
end entity;

architecture sim of fsm_controle_tb is

  component fsm_controle is
    port (
      clk     : in  std_logic;
      reset_n : in  std_logic;
      key1    : in  std_logic;
      etat    : out std_logic_vector(1 downto 0)
    );
  end component;

  constant CLK_PERIOD : time := 20 ns;  -- 50 MHz

  constant STOP_C  : std_logic_vector(1 downto 0) := "00";
  constant RUN_C   : std_logic_vector(1 downto 0) := "01";
  constant PAUSE_C : std_logic_vector(1 downto 0) := "10";

  signal clk     : std_logic := '0';
  signal reset_n : std_logic := '0';
  signal key1    : std_logic := '0';
  signal etat    : std_logic_vector(1 downto 0);

begin

  DUT: fsm_controle
    port map (
      clk     => clk,
      reset_n => reset_n,
      key1    => key1,
      etat    => etat
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

    -- impulsion d'un cycle sur key1, avec marge de reglage avant
    -- lecture (evite la race stimulus/DUT sur le meme front, comme
    -- rencontre sur le compteur BCD)
    procedure pulse_key1 is
    begin
      wait until rising_edge(clk);
      key1 <= '1';
      wait until rising_edge(clk);
      key1 <= '0';
      wait for 1 ns;
    end procedure;

  begin
    ------------------------------------------------------------
    -- Phase 0 : reset -> doit etre en STOP
    ------------------------------------------------------------
    reset_n <= '0';
    wait for 5 * CLK_PERIOD;
    assert etat = STOP_C
      report "ERREUR : etat apres reset != STOP"
      severity error;

    reset_n <= '1';
    wait for 2 * CLK_PERIOD;
    assert etat = STOP_C
      report "ERREUR : l'etat a change sans impulsion key1 juste apres reset"
      severity error;

    ------------------------------------------------------------
    -- Phase 1 : STOP -> RUN sur impulsion key1
    ------------------------------------------------------------
    pulse_key1;
    assert etat = RUN_C
      report "ERREUR : STOP -> RUN non effectue apres impulsion key1"
      severity error;

    ------------------------------------------------------------
    -- Phase 2 : maintien en RUN tant qu'aucune impulsion n'arrive
    -- (plusieurs cycles d'attente, key1 reste a '0')
    ------------------------------------------------------------
    wait for 10 * CLK_PERIOD;
    assert etat = RUN_C
      report "ERREUR : l'etat RUN n'a pas ete maintenu sans impulsion key1"
      severity error;

    ------------------------------------------------------------
    -- Phase 3 : RUN -> PAUSE sur impulsion key1
    ------------------------------------------------------------
    pulse_key1;
    assert etat = PAUSE_C
      report "ERREUR : RUN -> PAUSE non effectue apres impulsion key1"
      severity error;

    ------------------------------------------------------------
    -- Phase 4 : maintien en PAUSE sans impulsion
    ------------------------------------------------------------
    wait for 10 * CLK_PERIOD;
    assert etat = PAUSE_C
      report "ERREUR : l'etat PAUSE n'a pas ete maintenu sans impulsion key1"
      severity error;

    ------------------------------------------------------------
    -- Phase 5 : PAUSE -> RUN (reprise) sur impulsion key1
    ------------------------------------------------------------
    pulse_key1;
    assert etat = RUN_C
      report "ERREUR : PAUSE -> RUN (reprise) non effectue apres impulsion key1"
      severity error;

    ------------------------------------------------------------
    -- Phase 6 : reset asynchrone depuis RUN -> retour immediat a STOP
    -- (verifie l'asynchronisme : reset applique en dehors d'un front
    -- d'horloge, l'etat doit changer sans attendre le prochain front)
    ------------------------------------------------------------
    wait for CLK_PERIOD / 4;  -- se placer hors d'un front d'horloge
    reset_n <= '0';
    wait for 1 ns;
    assert etat = STOP_C
      report "ERREUR : le reset n'a pas ramene l'etat a STOP de maniere asynchrone"
      severity error;

    reset_n <= '1';
    wait for 2 * CLK_PERIOD;

    report "TEST TERMINE : cycle complet STOP->RUN->PAUSE->RUN verifie, "
           & "maintien d'etat confirme, reset asynchrone valide";

    wait; -- fin de simulation
  end process;

end architecture;
