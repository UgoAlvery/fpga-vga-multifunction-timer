library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bcd_counter_2digit is
  generic (
    MAX : integer range 0 to 99 := 99  -- 99 pour centiemes, 59 pour sec/min
  );
  port (
    clk        : in  std_logic;
    reset_n    : in  std_logic;
    enable     : in  std_logic;                     -- tick (1 cycle) qui fait avancer/reculer
    count_up   : in  std_logic;                     -- '1' = incremente, '0' = decremente
    load       : in  std_logic;                      -- chargement synchrone (preset minuteur)
    load_tens  : in  std_logic_vector(3 downto 0);
    load_units : in  std_logic_vector(3 downto 0);
    digit_tens  : out std_logic_vector(3 downto 0);
    digit_units : out std_logic_vector(3 downto 0);
    carry_out  : out std_logic;                     -- pulse 1 cycle : rollover MAX -> 0 (montee)
    borrow_out : out std_logic                       -- pulse 1 cycle : rollover 0 -> MAX (descente)
  );
end entity;

architecture rtl of bcd_counter_2digit is
  signal tens, unit_val : unsigned(3 downto 0);
begin

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      tens     <= (others => '0');
      unit_val <= (others => '0');
      carry_out  <= '0';
      borrow_out <= '0';

    elsif rising_edge(clk) then
      carry_out  <= '0';
      borrow_out <= '0';

      if load = '1' then
        tens     <= unsigned(load_tens);
        unit_val <= unsigned(load_units);

      elsif enable = '1' then
        if count_up = '1' then
          if unit_val = 9 then
            unit_val <= (others => '0');
            if tens = to_unsigned(MAX / 10, 4) then
              tens <= (others => '0');
              carry_out <= '1';
            else
              tens <= tens + 1;
            end if;
          else
            unit_val <= unit_val + 1;
          end if;

        else
          if unit_val = 0 then
            if tens = 0 then
              tens     <= to_unsigned(MAX / 10, 4);
              unit_val <= to_unsigned(MAX mod 10, 4);
              borrow_out <= '1';
            else
              tens     <= tens - 1;
              unit_val <= to_unsigned(9, 4);
            end if;
          else
            unit_val <= unit_val - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  digit_tens  <= std_logic_vector(tens);
  digit_units <= std_logic_vector(unit_val);

end architecture;
