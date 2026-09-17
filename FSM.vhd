library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce is
  port (
    clk      : in  std_logic;
    reset_n  : in  std_logic;
    btn_in   : in  std_logic;   -- signal brut du bouton
    btn_pulse: out std_logic    -- impulsion 1 cycle sur front montant propre
  );
end entity;

architecture rtl of debounce is
  signal sync_reg   : std_logic_vector(1 downto 0);  -- synchroniseur
  signal tick_cnt    : unsigned(15 downto 0);
  signal tick        : std_logic;
  signal shift_reg    : std_logic_vector(3 downto 0);
  signal stable, stable_prev : std_logic;
begin

  -- 1) synchroniseur 2 bascules
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      sync_reg <= (others => '0');
    elsif rising_edge(clk) then
      sync_reg <= sync_reg(0) & btn_in;
    end if;
  end process;

  -- 2) tick ~1ms (50_000 cycles Ã  50MHz)
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      tick_cnt <= (others => '0');
    elsif rising_edge(clk) then
      if tick_cnt = 49999 then
        tick_cnt <= (others => '0');
      else
        tick_cnt <= tick_cnt + 1;
      end if;
    end if;
  end process;
  tick <= '1' when tick_cnt = 49999 else '0';

  -- 3) shift register échantillonné au tick
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      shift_reg <= (others => '0');
    elsif rising_edge(clk) then
      if tick = '1' then
        shift_reg <= shift_reg(2 downto 0) & sync_reg(1);
      end if;
    end if;
  end process;

  stable <= '1' when shift_reg = "1111" else
            '0' when shift_reg = "0000" else
            stable;  -- maintien si zone grise (transition en cours)

  -- 4) détection de front montant + registre de comparaison
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      stable_prev <= '0';
    elsif rising_edge(clk) then
      stable_prev <= stable;
    end if;
  end process;

  btn_pulse <= stable and not stable_prev;

end architecture;