--------------------------------------------------------------------
-- seconds_to_bcd
-- Convertit un nombre total de secondes (0 a 511, sur 9 bits) en
-- deux paires de digits BCD : minutes (0-8) et secondes (0-59).
-- Purement combinatoire : la plage etant petite, la division/modulo
-- se synthetise sans probleme sur ces largeurs.
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seconds_to_bcd is
  port (
    total_seconds : in  unsigned(8 downto 0);  -- 0 a 511 secondes

    min_tens   : out std_logic_vector(3 downto 0);
    min_units  : out std_logic_vector(3 downto 0);
    sec_tens   : out std_logic_vector(3 downto 0);
    sec_units  : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of seconds_to_bcd is
begin

  process(total_seconds)
    variable total_int : integer range 0 to 511;
    variable minutes    : integer range 0 to 8;
    variable seconds    : integer range 0 to 59;
  begin
    total_int := to_integer(total_seconds);
    minutes   := total_int / 60;
    seconds   := total_int mod 60;

    min_tens  <= std_logic_vector(to_unsigned(minutes / 10, 4));
    min_units <= std_logic_vector(to_unsigned(minutes mod 10, 4));
    sec_tens  <= std_logic_vector(to_unsigned(seconds / 10, 4));
    sec_units <= std_logic_vector(to_unsigned(seconds mod 10, 4));
  end process;

end architecture;
