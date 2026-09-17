--------------------------------------------------------------------
-- seg7_decoder_array
-- Decode les 6 digits BCD (0-9) du chrono_counter en 6 sorties
-- 7-segments, une par afficheur physique HEX0-HEX5 de la DE10-Lite.
--
-- Mapping (le moins significatif en premier, convention usuelle) :
--   HEX0 <- cent_units   HEX1 <- cent_tens
--   HEX2 <- sec_units    HEX3 <- sec_tens
--   HEX4 <- min_units    HEX5 <- min_tens
--
-- Segments actifs bas (commun sur les afficheurs 7-seg de la
-- DE10-Lite) : '0' allume le segment, '1' l'eteint. Ordre des bits :
-- seg(6 downto 0) = g,f,e,d,c,b,a
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity seg7_decoder_array is
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
end entity;

architecture rtl of seg7_decoder_array is

  -- Table de decodage BCD -> 7 segments actifs bas (gfedcba).
  -- Entrees hors 0-9 (10-15, cas "don't care" en pratique puisque
  -- le compteur BCD amont ne produit jamais ces valeurs) mappees
  -- sur "tout eteint" par securite.
  function decode(d : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable seg : std_logic_vector(6 downto 0);
  begin
    case d is
      when "0000" => seg := "1000000"; -- 0
      when "0001" => seg := "1111001"; -- 1
      when "0010" => seg := "0100100"; -- 2
      when "0011" => seg := "0110000"; -- 3
      when "0100" => seg := "0011001"; -- 4
      when "0101" => seg := "0010010"; -- 5
      when "0110" => seg := "0000010"; -- 6
      when "0111" => seg := "1111000"; -- 7
      when "1000" => seg := "0000000"; -- 8
      when "1001" => seg := "0010000"; -- 9
      when others => seg := "1111111"; -- eteint (valeur hors BCD, ne devrait pas arriver)
    end case;
    return seg;
  end function;

begin

  HEX0 <= decode(cent_units);
  HEX1 <= decode(cent_tens);
  HEX2 <= decode(sec_units);
  HEX3 <= decode(sec_tens);
  HEX4 <= decode(min_units);
  HEX5 <= decode(min_tens);

end architecture;
