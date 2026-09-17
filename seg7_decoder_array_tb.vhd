--------------------------------------------------------------------
-- Testbench seg7_decoder_array_tb
-- Objectif :
--   1) Verifier que chaque chiffre 0-9 produit le bon motif
--      7-segments actif bas, sur un seul digit isole (cent_units),
--      les 5 autres etant figes a 0.
--   2) Verifier le mapping digit -> afficheur physique (chaque
--      digit doit piloter le bon HEXx et aucun autre) en imposant
--      6 valeurs distinctes simultanement.
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seg7_decoder_array_tb is
end entity;

architecture sim of seg7_decoder_array_tb is

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

  signal cent_units, cent_tens : std_logic_vector(3 downto 0) := (others => '0');
  signal sec_units,  sec_tens  : std_logic_vector(3 downto 0) := (others => '0');
  signal min_units,  min_tens  : std_logic_vector(3 downto 0) := (others => '0');

  signal HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : std_logic_vector(6 downto 0);

  -- table de reference : motifs attendus pour 0-9 (gfedcba, actif bas)
  type seg_table_t is array (0 to 9) of std_logic_vector(6 downto 0);
  constant EXPECTED : seg_table_t := (
    0 => "1000000",
    1 => "1111001",
    2 => "0100100",
    3 => "0110000",
    4 => "0011001",
    5 => "0010010",
    6 => "0000010",
    7 => "1111000",
    8 => "0000000",
    9 => "0010000"
  );

begin

  DUT: seg7_decoder_array
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

  stim_process: process
  begin
    ------------------------------------------------------------
    -- Phase 1 : balayage des 10 chiffres sur cent_units, les
    -- 5 autres digits restant a 0 (verifie via HEX0 uniquement,
    -- et confirme au passage que HEX1-5 restent constants sur "0")
    ------------------------------------------------------------
    for i in 0 to 9 loop
      cent_units <= std_logic_vector(to_unsigned(i, 4));
      wait for 10 ns;

      assert HEX0 = EXPECTED(i)
        report "ERREUR : decodage chiffre " & integer'image(i)
               & " incorrect sur HEX0"
        severity error;

      assert HEX1 = EXPECTED(0) and HEX2 = EXPECTED(0) and HEX3 = EXPECTED(0)
             and HEX4 = EXPECTED(0) and HEX5 = EXPECTED(0)
        report "ERREUR : un afficheur non cible par ce test a change de motif "
               & "(chiffre teste = " & integer'image(i) & ")"
        severity error;
    end loop;

    cent_units <= (others => '0');
    wait for 10 ns;

    ------------------------------------------------------------
    -- Phase 2 : verification du mapping digit -> afficheur.
    -- On impose 6 valeurs distinctes et on verifie que chaque
    -- HEXx affiche bien le chiffre de SON digit source, et pas
    -- celui d'un autre (detecterait un mapping croise/inverse).
    ------------------------------------------------------------
    cent_units <= std_logic_vector(to_unsigned(1, 4));
    cent_tens  <= std_logic_vector(to_unsigned(2, 4));
    sec_units  <= std_logic_vector(to_unsigned(3, 4));
    sec_tens   <= std_logic_vector(to_unsigned(4, 4));
    min_units  <= std_logic_vector(to_unsigned(5, 4));
    min_tens   <= std_logic_vector(to_unsigned(6, 4));
    wait for 10 ns;

    assert HEX0 = EXPECTED(1)
      report "ERREUR mapping : HEX0 devrait afficher cent_units (1)" severity error;
    assert HEX1 = EXPECTED(2)
      report "ERREUR mapping : HEX1 devrait afficher cent_tens (2)" severity error;
    assert HEX2 = EXPECTED(3)
      report "ERREUR mapping : HEX2 devrait afficher sec_units (3)" severity error;
    assert HEX3 = EXPECTED(4)
      report "ERREUR mapping : HEX3 devrait afficher sec_tens (4)" severity error;
    assert HEX4 = EXPECTED(5)
      report "ERREUR mapping : HEX4 devrait afficher min_units (5)" severity error;
    assert HEX5 = EXPECTED(6)
      report "ERREUR mapping : HEX5 devrait afficher min_tens (6)" severity error;

    report "TEST TERMINE : 10 chiffres verifies + mapping des 6 digits confirme";

    wait; -- fin de simulation
  end process;

end architecture;
