--------------------------------------------------------------------
-- chenillard
-- Une seule LED active qui rebondit d'un bout a l'autre du registre
-- ("va-et-vient", style K2000), avancant d'une position a chaque
-- impulsion sur enable.
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity chenillard is
  generic (
    WIDTH : positive := 8
  );
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    enable  : in  std_logic;                       -- avance d'une position par impulsion
    leds    : out std_logic_vector(WIDTH - 1 downto 0)
  );
end entity;

architecture rtl of chenillard is
  signal position  : integer range 0 to WIDTH - 1;
  signal going_up  : std_logic;  -- '1' = position croissante, '0' = decroissante
begin

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      position <= 0;
      going_up <= '1';
    elsif rising_edge(clk) then
      if enable = '1' then
        if going_up = '1' then
          if position = WIDTH - 1 then
            going_up <= '0';
            position <= position - 1;
          else
            position <= position + 1;
          end if;
        else
          if position = 0 then
            going_up <= '1';
            position <= position + 1;
          else
            position <= position - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  process(position)
    variable tmp : std_logic_vector(WIDTH - 1 downto 0);
  begin
    tmp := (others => '0');
    tmp(position) := '1';
    leds <= tmp;
  end process;

end architecture;
