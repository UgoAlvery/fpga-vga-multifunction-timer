--------------------------------------------------------------------
-- chrono_counter
-- Chainage de 3 instances de bcd_counter_2digit :
--   centiemes (MAX=99) --carry_out--> secondes (MAX=59) --carry_out--> minutes (MAX=99)
--
-- Le tick d'entree (tick_10ms) cadence l'etage des centiemes.
-- Chaque etage ne fait avancer le suivant que lors de son propre
-- rollover (carry_out en montee, borrow_out en descente), d'ou le
-- chainage direct carry/borrow -> enable de l'etage superieur.
--
-- Les ports load_* de chaque etage sont exposes tels quels au
-- sommet : le mapping des 9 bits SW(9 downto 1) vers ces 6 champs
-- BCD (tens/units x centiemes/secondes/minutes) reste a definir.
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity chrono_counter is
  port (
    clk       : in  std_logic;
    reset_n   : in  std_logic;
    tick_10ms : in  std_logic;   -- pulse 1 cycle toutes les 10 ms
    count_up  : in  std_logic;   -- '1' = chrono ascendant, '0' = minuteur descendant (SW(0))
    load      : in  std_logic;   -- prechargement synchrone (minuteur), commun aux 3 etages

    -- valeurs de prechargement, un champ BCD par digit (a cabler
    -- depuis SW(9 downto 1) une fois le format choisi)
    load_cent_tens   : in  std_logic_vector(3 downto 0);
    load_cent_units  : in  std_logic_vector(3 downto 0);
    load_sec_tens    : in  std_logic_vector(3 downto 0);
    load_sec_units   : in  std_logic_vector(3 downto 0);
    load_min_tens    : in  std_logic_vector(3 downto 0);
    load_min_units   : in  std_logic_vector(3 downto 0);

    -- affichage : 6 digits BCD, un par afficheur HEX0-HEX5
    cent_tens  : out std_logic_vector(3 downto 0);
    cent_units : out std_logic_vector(3 downto 0);
    sec_tens   : out std_logic_vector(3 downto 0);
    sec_units  : out std_logic_vector(3 downto 0);
    min_tens   : out std_logic_vector(3 downto 0);
    min_units  : out std_logic_vector(3 downto 0)
  );
end entity;

architecture structural of chrono_counter is

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

  -- enable de chaque etage : le premier vient du tick externe, les
  -- suivants viennent du rollover (carry ou borrow selon le sens)
  -- de l'etage precedent
  signal enable_cent, enable_sec, enable_min : std_logic;

  signal carry_cent, borrow_cent : std_logic;
  signal carry_sec,  borrow_sec  : std_logic;
  signal carry_min,  borrow_min  : std_logic;  -- non chaines plus haut (etage terminal)

begin

  enable_cent <= tick_10ms;

  -- l'etage superieur avance sur le rollover du precedent, qu'il
  -- soit ascendant (carry) ou descendant (borrow) : un seul des
  -- deux est actif a un instant donne selon count_up
  enable_sec <= carry_cent or borrow_cent;
  enable_min <= carry_sec  or borrow_sec;

  --------------------------------------------------------------
  -- Etage centiemes (MAX = 99)
  --------------------------------------------------------------
  U_CENT: bcd_counter_2digit
    generic map ( MAX => 99 )
    port map (
      clk         => clk,
      reset_n     => reset_n,
      enable      => enable_cent,
      count_up    => count_up,
      load        => load,
      load_tens   => load_cent_tens,
      load_units  => load_cent_units,
      digit_tens  => cent_tens,
      digit_units => cent_units,
      carry_out   => carry_cent,
      borrow_out  => borrow_cent
    );

  --------------------------------------------------------------
  -- Etage secondes (MAX = 59)
  --------------------------------------------------------------
  U_SEC: bcd_counter_2digit
    generic map ( MAX => 59 )
    port map (
      clk         => clk,
      reset_n     => reset_n,
      enable      => enable_sec,
      count_up    => count_up,
      load        => load,
      load_tens   => load_sec_tens,
      load_units  => load_sec_units,
      digit_tens  => sec_tens,
      digit_units => sec_units,
      carry_out   => carry_sec,
      borrow_out  => borrow_sec
    );

  --------------------------------------------------------------
  -- Etage minutes (MAX = 99, pas de limite horaire dans ce sujet)
  -- -- etage terminal, carry/borrow non reboucles (pas d'etage
  -- "heures")
  --------------------------------------------------------------
  U_MIN: bcd_counter_2digit
    generic map ( MAX => 99 )
    port map (
      clk         => clk,
      reset_n     => reset_n,
      enable      => enable_min,
      count_up    => count_up,
      load        => load,
      load_tens   => load_min_tens,
      load_units  => load_min_units,
      digit_tens  => min_tens,
      digit_units => min_units,
      carry_out   => carry_min,
      borrow_out  => borrow_min
    );

end architecture;
