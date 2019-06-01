library IEEE;
 use IEEE.STD_LOGIC_1164.ALL;
 use IEEE.STD_LOGIC_ARITH.ALL;
 use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vga_kontrol is
     Port ( clk            : in  STD_LOGIC;
	         clk1           :out  STD_LOGIC;
					 
                basla       : in  STD_LOGIC;
                reset        : in  STD_LOGIC;
                button_j   : IN std_logic;
                button_r   : IN std_logic;
					 rgb1          : out  STD_LOGIC_VECTOR (23 downto 0);
					 blank         : out STD_LOGIC :='1';
				    sync          : out STD_LOGIC :='1';
						score1    : out Std_logic_vector(6 downto 0) ;
                h_s           : out  STD_LOGIC;
                v_s            : out  STD_LOGIC;
					manual :in std_logic--- manual mode 
					 );
      end vga_kontrol;

architecture Behavioral of vga_kontrol is

COMPONENT Game_Drawer
    Port ( clk              : in  STD_LOGIC;
                 x_sayac    : in  STD_LOGIC_VECTOR(9 downto 0);
                 button_j    :in STD_LOGIC; -- button jump
                 button_r    :in STD_LOGIC;
                 y_sayac    : in STD_LOGIC_VECTOR(9 downto 0);
								 score1 : out Std_logic_vector(6 downto 0) :="1000000";
                 video_on  : in  STD_LOGIC; 
					  manual : in std_logic;--- 1 biz 0 NN
                 rgb             : out  STD_LOGIC_VECTOR(23 downto 0));
  END COMPONENT;

COMPONENT sync_mod
PORT( clk            : IN std_logic;
              clk1   : OUT std_logic;
              reset        : IN std_logic;
              basla       : IN std_logic;          
              y_sayac   : OUT std_logic_vector(9 downto 0);
              x_sayac   : OUT std_logic_vector(9 downto 0);
              h_s           : OUT std_logic;
              v_s            : OUT std_logic;
              video_on   : OUT std_logic );
END COMPONENT;



signal x,y:std_logic_vector(9 downto 0);
signal video:std_logic;
signal rgbsig :STD_LOGIC_VECTOR (6 downto 0);
begin
 U1: Game_Drawer PORT MAP( clk ,  x, button_j  ,  button_r,  y, score1,   video ,manual , rgb1);
 
 --rgb1<=  rgbsig(6)&rgbsig(5)&"000000"& rgbsig(4)&rgbsig(3)&"000000" & rgbsig(2)&rgbsig(1)&"000000";


																																																			 

 U2: sync_mod PORT MAP( clk => clk,clk1=>clk1, reset => reset, basla => basla, y_sayac => y, x_sayac =>x , h_s => h_s ,
                                 v_s => v_s, video_on =>video );
end Behavioral;
