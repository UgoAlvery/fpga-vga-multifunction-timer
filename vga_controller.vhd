-- VGA Controller 640x480@60Hz
-- Couleur de fond selon FSM + barre de progression des centièmes
-- Architecture: Compteurs H/V -> Détection zones -> Logique couleur (combinatoire)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_controller is
  port (
    pixel_clk   : in  std_logic;                     -- 25 MHz
    reset_n     : in  std_logic;                     -- actif bas, async

    -- Entrées venant du reste du design
    etat        : in  std_logic_vector(1 downto 0);  -- "00"=STOP, "01"=RUN, "10"=PAUSE
    cent_tens   : in  std_logic_vector(3 downto 0);  -- dizaine des centiemes (BCD, 0-9)
    cent_units  : in  std_logic_vector(3 downto 0);  -- unite des centiemes (BCD, 0-9)

    -- Sorties vers port VGA
    VGA_R       : out std_logic_vector(3 downto 0);
    VGA_G       : out std_logic_vector(3 downto 0);
    VGA_B       : out std_logic_vector(3 downto 0);
    VGA_HS      : out std_logic;                     -- sync horiz (actif bas)
    VGA_VS      : out std_logic                      -- sync vert (actif bas)
  );
end entity vga_controller;

architecture rtl of vga_controller is

  -- Timings VESA 640x480@60Hz (pixel_clk = 25 MHz)
  -- Horizontal: 640 active + 16 front + 96 sync + 48 back = 800 total
  -- Vertical:   480 active + 10 front + 2 sync + 33 back = 525 total
  
  constant H_ACTIVE  : integer := 640;
  constant H_FRONT   : integer := 16;
  constant H_SYNC    : integer := 96;
  constant H_BACK    : integer := 48;
  constant H_TOTAL   : integer := H_ACTIVE + H_FRONT + H_SYNC + H_BACK; -- 800
  constant H_SYNC_START : integer := H_ACTIVE + H_FRONT; -- 656
  constant H_SYNC_END   : integer := H_ACTIVE + H_FRONT + H_SYNC; -- 752
  
  constant V_ACTIVE  : integer := 480;
  constant V_FRONT   : integer := 10;
  constant V_SYNC    : integer := 2;
  constant V_BACK    : integer := 33;
  constant V_TOTAL   : integer := V_ACTIVE + V_FRONT + V_SYNC + V_BACK; -- 525
  constant V_SYNC_START : integer := V_ACTIVE + V_FRONT; -- 490
  constant V_SYNC_END   : integer := V_ACTIVE + V_FRONT + V_SYNC; -- 492
  
  -- Localisation de la barre de progression
  constant BAR_LINE_START : integer := 401;
  constant BAR_LINE_END   : integer := 439;
  constant BAR_MAX_WIDTH  : integer := 594;
  constant PX_PER_CENTIEME : integer := 6;
  
  signal h_counter : unsigned(9 downto 0);  -- 0-799
  signal v_counter : unsigned(9 downto 0);  -- 0-524
  
  signal h_sync_out : std_logic;
  signal v_sync_out : std_logic;
  
  signal in_active_h : std_logic;
  signal in_active_v : std_logic;
  signal in_active_display : std_logic;
  
  -- Calcul de largeur de barre
  signal bar_width : unsigned(9 downto 0);
  signal cents_value : unsigned(6 downto 0);  -- 0-99 max, 7 bits suffisent
  signal bar_width_calc : unsigned(11 downto 0);  -- Résultat multiplication avant resize
  signal in_bar_zone : std_logic;
  signal in_bar_h : std_logic;
  signal in_bar_v : std_logic;
  
  -- Signaux de couleur interne
  signal bg_red, bg_green, bg_blue : std_logic_vector(3 downto 0);

begin

  -- ============================================================================
  -- COMPTEURS H/V et SYNCHROS
  -- ============================================================================
  
  process(pixel_clk, reset_n)
  begin
    if reset_n = '0' then
      h_counter <= (others => '0');
      v_counter <= (others => '0');
    elsif rising_edge(pixel_clk) then
      if h_counter = H_TOTAL - 1 then
        h_counter <= (others => '0');
        if v_counter = V_TOTAL - 1 then
          v_counter <= (others => '0');
        else
          v_counter <= v_counter + 1;
        end if;
      else
        h_counter <= h_counter + 1;
      end if;
    end if;
  end process;

  -- Génération des signaux de synchronisation (actifs bas)
  h_sync_out <= '0' when (h_counter >= H_SYNC_START and h_counter < H_SYNC_END) else '1';
  v_sync_out <= '0' when (v_counter >= V_SYNC_START and v_counter < V_SYNC_END) else '1';

  VGA_HS <= h_sync_out;
  VGA_VS <= v_sync_out;

  -- ============================================================================
  -- DÉTECTION ZONES D'AFFICHAGE (combinatoire)
  -- ============================================================================
  
  in_active_h <= '1' when h_counter < H_ACTIVE else '0';
  in_active_v <= '1' when v_counter < V_ACTIVE else '0';
  in_active_display <= in_active_h and in_active_v;

  -- ============================================================================
  -- CALCUL LARGEUR BARRE DE PROGRESSION
  -- ============================================================================
  
  -- Reconstituer la valeur de centièmes (BCD) en décimal
  -- cents = cent_tens * 10 + cent_units (0-99)
  -- Utiliser to_integer() pour éviter les problèmes de largeur de bits en multiplication
  cents_value <= to_unsigned(
    to_integer(unsigned(cent_tens)) * 10 + to_integer(unsigned(cent_units)),
    7
  );
  
  -- Largeur = centièmes * 6 pixels
  -- Idem : to_integer() pour contrôler la largeur du résultat
  bar_width_calc <= to_unsigned(
    to_integer(cents_value) * PX_PER_CENTIEME,
    12
  );
  
  bar_width <= resize(bar_width_calc, 10);  -- Resize à 10 bits (max 1023, donc 594 rentre dedans)
  
  -- Zone verticale de la barre (lignes 401-439)
  in_bar_v <= '1' when (v_counter >= BAR_LINE_START and v_counter <= BAR_LINE_END) else '0';
  
  -- Zone horizontale de la barre (0 à bar_width)
  in_bar_h <= '1' when (h_counter < bar_width) else '0';
  
  -- On est dans la barre si on est à la fois dans les zones H et V
  in_bar_zone <= in_bar_v and in_bar_h;

  -- ============================================================================
  -- LOGIQUE DE COULEUR (combinatoire)
  -- ============================================================================
  
  -- Couleur de fond selon l'état FSM
  process(etat, cent_tens, cent_units)
  begin
    case etat is
      when "00" =>  -- STOP
        bg_red   <= "0000";
        bg_green <= "0000";
        bg_blue  <= "1111";
      when "01" =>  -- RUN
        bg_red   <= "0000";
        bg_green <= "1111";
        bg_blue  <= "0000";
      when "10" =>  -- PAUSE
        bg_red   <= "1111";
        bg_green <= "0000";
        bg_blue  <= "0000";
      when others =>
        bg_red   <= "0000";
        bg_green <= "0000";
        bg_blue  <= "0000";
    end case;
  end process;

  -- Sélection couleur finale: barre blanche si en zone barre, sinon fond
  process(in_active_display, in_bar_zone, bg_red, bg_green, bg_blue)
  begin
    if in_active_display = '1' then
      if in_bar_zone = '1' then
        -- Barre blanche (RGB = FFF en 4 bits)
        VGA_R <= "1111";
        VGA_G <= "1111";
        VGA_B <= "1111";
      else
        -- Fond selon FSM
        VGA_R <= bg_red;
        VGA_G <= bg_green;
        VGA_B <= bg_blue;
      end if;
    else
      -- Hors zone active: noir (blanking)
      VGA_R <= "0000";
      VGA_G <= "0000";
      VGA_B <= "0000";
    end if;
  end process;

end architecture rtl;
