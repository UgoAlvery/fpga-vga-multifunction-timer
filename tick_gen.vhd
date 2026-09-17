--------------------------------------------------------------------
-- tick_gen
-- Diviseur d'horloge generique : produit une impulsion d'un cycle
-- toutes les (DIVISOR) cycles d'horloge.
-- Exemple : a 50 MHz, DIVISOR = 500_000 => tick toutes les 10 ms.
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tick_gen is
  generic (
    DIVISOR : positive := 500000
  );
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    tick    : out std_logic
  );
end entity;

architecture rtl of tick_gen is
  signal count : unsigned(31 downto 0);
begin

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      count <= (others => '0');
      tick  <= '0';
    elsif rising_edge(clk) then
      if count = to_unsigned(DIVISOR - 1, 32) then
        count <= (others => '0');
        tick  <= '1';
      else
        count <= count + 1;
        tick  <= '0';
      end if;
    end if;
  end process;

end architecture;
