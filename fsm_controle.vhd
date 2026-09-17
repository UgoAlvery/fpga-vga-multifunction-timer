--------------------------------------------------------------------
-- fsm_controle
-- FSM de controle du chronometre : 3 etats STOP / RUN / PAUSE.
-- KEY(1) (deja debounce en amont, via l'entite debounce) fait
-- avancer d'un etat a chaque impulsion :
--   STOP  --key1--> RUN
--   RUN   --key1--> PAUSE
--   PAUSE --key1--> RUN   (reprise, pas de retour a STOP par ce bouton)
-- Le retour a STOP ne se fait que par reset_n (KEY(0)).
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsm_controle is
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;                     -- KEY(0), actif bas, async
    key1    : in  std_logic;                     -- impulsion debouncee de KEY(1)
    etat    : out std_logic_vector(1 downto 0)   -- 00=STOP, 01=RUN, 10=PAUSE
  );
end entity;

architecture moore of fsm_controle is
  type state_t is (STOP, RUN, PAUSE);
  signal state_reg, state_next : state_t;
begin

  -- registre d'etat
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      state_reg <= STOP;
    elsif rising_edge(clk) then
      state_reg <= state_next;
    end if;
  end process;

  -- logique de transition
  process(state_reg, key1)
  begin
    state_next <= state_reg;
    case state_reg is
      when STOP  => if key1 = '1' then state_next <= RUN;   end if;
      when RUN   => if key1 = '1' then state_next <= PAUSE; end if;
      when PAUSE => if key1 = '1' then state_next <= RUN;   end if;
    end case;
  end process;

  etat <= "00" when state_reg = STOP  else
          "01" when state_reg = RUN   else
          "10";

end architecture;
