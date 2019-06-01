library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;
use work.image_files.all;
use work.typedefs.all;
entity Game_Drawer is
	port
	(
		clk      : in STD_LOGIC;
		x_sayac  : in STD_LOGIC_VECTOR(9 downto 0);
		button_j : in STD_LOGIC; -- button jump
		button_r : in STD_LOGIC;
		y_sayac  : in STD_LOGIC_VECTOR(9 downto 0);
		score1   : out Std_logic_vector(6 downto 0) := "1000000";
		video_on : in STD_LOGIC;
		manual   : in std_logic;--- 1 biz 0 NN
		rgb      : out STD_LOGIC_VECTOR(23 downto 0)
	);
end Game_Drawer;
architecture Behavioral of Game_Drawer is
	--random
	--Score
	signal scoretmp : integer := 0;
	signal obje_kac : integer := 0;
	--GAME OBJECTS
	--Birds
	signal birdsw      : weights;
	signal birdwinner   : weight;
	signal birdsecond  : weight;
	signal birdsn      : neurons;
	signal birdsspeed  : tenintarray := (0, 0, 0, 0, 0, 0, 0, 0, 0, 0); -- y speed
	signal birdsacc    : tenintarray := (0, 0, 0, 0, 0, 0, 0, 0, 0, 0); -- y acceleration
	signal birdsalpha  : tenintarray := (1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024);-- alpha for drawing (1024 max alpha)
	signal birdsangle  : tenintarray;--rotation
	signal birdsscore  : tenintarray := (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);--rotation
	signal birdsactive : tenintarray := (1, 1, 1, 1, 1, 1, 1, 1, 1, 1);
	signal birdsx      : tenintarray := (100, 100, 100, 100, 100, 100, 100, 100, 100, 100);--X position FOR TEST PURPOSES
	signal birdsy      : tenintarray := (50, 50, 50, 50, 50, 50, 50, 50, 50, 50);--y position
	signal birdsxbig   : tenintarray := (50, 50, 50, 50, 50, 50, 70, 80, 90, 10);--X position fake FOR TEST PURPOSES
	signal birdsybig   : tenintarray := (16384, 16384, 16384, 16384, 16384, 16384, 16384, 16384, 16384, 16384);--y position fake y*64
	--Pipes
	signal pipex      : threeintarray := (640, 640+237, 640+237+237); --- x
	signal pipemiddle : threeintarray:=(232,248,126); --- y middle point
	signal pipesspeed : threeintarray;
	signal pipegap    : integer := 70;
	signal pipemove : threeintarray:=(-400,-400,-400);
	--Clouds
	signal cloudpos_x    : threeintarray := (0, 0, 0); --- cloud x
	signal cloudpos_y    : threeintarray := (0, 0, 0); --- cloud y
	signal cloudpos_xbig : threeintarray := ( - 500, 50, 120); --- cloud x fake *64
	signal cloudpos_ybig : threeintarray := (8400, 6200, 5000); --- cloud y fake *64
	signal cloudalpha    : threeintarray := (64, 64, 64); -- cloud alpha fake
	signal cloudspeed    : threeintarray := (10, 6, 2);-- speed*64
	--globalgame variables
	--signal manual :std_logic:='0';--BUNU SWITCH ILE AL
	signal gameover: std_logic:='0';
	signal gamestate       : integer := 3;
	signal deathbirds      : integer := 0;
	signal gamejuststarted : std_logic := '1'; --- for first time processes
	signal gamexspeed      : integer := 2;
	signal gravity         : integer := 2;
	signal count           : integer := 0;
	signal groundpos			: integer :=0;
	signal gamestart       : std_logic := '0'; --- for gamestartbutton
	signal i               : integer := 0; --loop index i
	signal j               : integer := 0; --loop index j
	signal mountainposy  : integer := 320;
	signal buildingpos     : integer := 0;-- x8 buildin pos
	signal mountainpos     : integer := 0;-- x8 mountain pos
	signal score              : integer := 0; --loop index j
	--Random variables
	signal initialrandomseed : std_logic_vector(15 downto 0) := "1001101001101010";
	signal q                 : std_logic_vector(15 downto 0) := "1001101001101010";--for easy usage purposes
	signal n1, n2, n3        : std_logic;
	--refresh rate 60fps
	signal refresh_reg, refresh_next : integer := 0;
	constant refresh_constant        : integer :=830000 ; --830000 x16;
	signal refresh_tick              : std_logic := '1';
	signal game_over                 : std_logic;
	--x,y pixel indicator
	signal x, y           : integer range 0 to 650;
	signal x_next, y_next : integer range 0 to 650;
	signal x_now, y_now   : integer range 0 to 650;
	signal prex, prey     : integer range 0 to 650;
	--DEBUG VARS
	signal debug1 : integer := 0;
	--color buffers
	signal rgb_reg   : std_logic_vector(23 downto 0);
	signal rgb_reg2  : std_logic_vector(23 downto 0);
	signal rgb_next  : std_logic_vector(6 downto 0);
	signal rgb_red   : integer;
	signal rgb_green : integer;
	signal rgb_blue  : integer;
	--SCREEN BUFFER
	signal gamescreen : screen; -- (1280x960 array for zoominout purposes)
	------------------
	signal temporal : STD_LOGIC;
	signal counter  : integer := 0;
begin----architecture
	--x,y piksel işaretleyicisi
	x_now <= conv_integer(x_sayac);
	y_now <= conv_integer(y_sayac);
	--gamestep refresh ticker
	--refresh_next<= 0 when refresh_reg= refresh_constant else refresh_reg+1;
	-- else '0';
	
	gamestart <= '1';--when button_l='1'; -- game start button pressed
	 -- 16bit counter for processes
	--- global game iteration
	process (clk)
	---variables for draw event
	variable rgb_redt     : integer := 0;
	variable rgb_greent   : integer := 0;
	variable rgb_bluet    : integer := 0;
	variable rgb_redtmp   : integer := 0;
	variable rgb_greentmp : integer := 0;
	variable rgb_bluetmp  : integer := 0;
	variable isalpha      : integer := 0;
	variable nearestpipe  : integer := 0;
	variable currentbird  : integer := 0;
	variable maxscore : integer :=0;
	variable maxindex : integer :=0;
	variable secondplacescore:integer :=0;
	variable secondindex:integer :=0;
	variable numbdivider:integer :=0; -- for sequential divide operations
	variable tempint:integer :=0 ;
	
	--
	begin
		if clk'EVENT and clk = '1' then--if11
			if refresh_reg > refresh_constant then
				refresh_tick <= '1';
				refresh_reg  <= 0;
			else
				refresh_reg <= refresh_reg + 1;
			end if;
			--
			if refresh_tick = '1' and gamestart = '1' and x_now = 0 and y_now = 0 then -- 1 frame cycle 1/60 s --if0
				if count =65536 then 
				 -- count <= count + 1;
					--count<=count+1;
				end if;
			    --
				--refresh_tick<='0';
				--- game initialize
				if gamejuststarted = '1' then -- if1
					-- en sona al gamejuststarted<='0';
					initialrandomseed <= initialrandomseed xor std_logic_vector(to_unsigned(count, 16)); --initial seed randomization
					q                 <= initialrandomseed;
					--- birds
					if gamestate = 0 then --birds values initial if10
					
						
							currentbird:=0;
							birdsalpha(currentbird) <= 256; --initial alpha
							birdsspeed(currentbird) <= 0; --initial speed
							birdsacc(currentbird)   <= 0; --initial acceleration
							birdsangle(currentbird) <= 0; --initial rotation angle
							birdsx(currentbird)     <= 100;
							birdsy(currentbird)     <= 220;
							birdsybig(currentbird)  <= 220 * 64;
							
						
							
								currentbird:=1;
							birdsalpha(currentbird) <= 256; --initial alpha
							birdsspeed(currentbird) <= 0; --initial speed
							birdsacc(currentbird)   <= 0; --initial acceleration
							birdsangle(currentbird) <= 0; --initial rotation angle
							birdsx(currentbird)     <= 100;
							birdsy(currentbird)     <= 220;
							birdsybig(currentbird)  <= 220 * 64;
							
				
							
								currentbird:=2;
							birdsalpha(currentbird) <= 256; --initial alpha
							birdsspeed(currentbird) <= 0; --initial speed
							birdsacc(currentbird)   <= 0; --initial acceleration
							birdsangle(currentbird) <= 0; --initial rotation angle
							birdsx(currentbird)     <= 100;
							birdsy(currentbird)     <= 220;
							birdsybig(currentbird)  <= 220 * 64;
							
					
							
								currentbird:=3;
							birdsalpha(currentbird) <= 256; --initial alpha
							birdsspeed(currentbird) <= 0; --initial speed
							birdsacc(currentbird)   <= 0; --initial acceleration
							birdsangle(currentbird) <= 0; --initial rotation angle
							birdsx(currentbird)     <= 100;
							birdsy(currentbird)     <= 220;
							birdsybig(currentbird)  <= 220 * 64;
							
						
							
							currentbird:=4;
							birdsalpha(currentbird) <= 256; --initial alpha
							birdsspeed(currentbird) <= 0; --initial speed
							birdsacc(currentbird)   <= 0; --initial acceleration
							birdsangle(currentbird) <= 0; --initial rotation angle
							birdsx(currentbird)     <= 100;
							birdsy(currentbird)     <= 220;
							birdsybig(currentbird)  <= 220 * 64;
							
							currentbird:=5;
							birdsalpha(currentbird) <= 256; --initial alpha
							birdsspeed(currentbird) <= 0; --initial speed
							birdsacc(currentbird)   <= 0; --initial acceleration
							birdsangle(currentbird) <= 0; --initial rotation angle
							birdsx(currentbird)     <= 100;
							birdsy(currentbird)     <= 220;
							birdsybig(currentbird)  <= 220 * 64;
							
							gamestate <= 1;
						
					end if;--if10
					--- q <= q(14 downto 0) & n3; --- RANDOM 16-Bit DATA GENERATOR on q
					
					
					
					if gamestate = 1 then --if3
					
					currentbird:=0;			
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,1)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,2)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,3)<=(to_integer(unsigned(q))-32768); ---19 LAB usage 
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,4)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,5)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,6)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,7)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,8)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,9)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,10)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,11)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,12)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,13)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,14)<=(to_integer(unsigned(q))-32768);
				
				currentbird:=1;			
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,1)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,2)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,3)<=(to_integer(unsigned(q))-32768); ---19 LAB usage 
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,4)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,5)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,6)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,7)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,8)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,9)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,10)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,11)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,12)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,13)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,14)<=(to_integer(unsigned(q))-32768);
				
				currentbird:=2;			
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,1)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,2)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,3)<=(to_integer(unsigned(q))-32768); ---19 LAB usage 
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,4)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,5)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,6)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,7)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,8)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,9)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,10)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,11)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,12)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,13)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,14)<=(to_integer(unsigned(q))-32768);
				
				currentbird:=3;			
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,1)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,2)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,3)<=(to_integer(unsigned(q))-32768); ---19 LAB usage 
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,4)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,5)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,6)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,7)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,8)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,9)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,10)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,11)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,12)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,13)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,14)<=(to_integer(unsigned(q))-32768);
				
				currentbird:=4;			
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,1)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,2)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,3)<=(to_integer(unsigned(q))-32768); ---19 LAB usage 
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,4)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,5)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,6)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,7)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,8)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,9)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,10)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,11)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,12)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,13)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,14)<=(to_integer(unsigned(q))-32768);
				
				currentbird:=5;			
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,1)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,2)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,3)<=(to_integer(unsigned(q))-32768); ---19 LAB usage 
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,4)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,5)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,6)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,7)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,8)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,9)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,10)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,11)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,12)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,13)<=(to_integer(unsigned(q))-32768);
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,14)<=(to_integer(unsigned(q))-32768);
					
							gamestate <= 2;
						
					end if;--if3
					if gamestate = 2 then-- if6 gstate2=pipe initialize
						--Initial pipe position x's
						--q <= q(14 downto 0) & n3; --new random
						pipex(0) <= 237 + 2000;--+ to_integer(signed(q))/256; -- 0< q < 256
						--q <= q(14 downto 0) & n3; --new random
						pipex(1) <= 474 + 2000;--+ to_integer(signed(q))/256;
						--q <= q(14 downto 0) & n3; --new random
						pipex(2) <= 711 + 2000;--+ to_integer(signed(q))/256;
						--Initial pipe middle points
						q             <= q(14 downto 0) & n3; --new random
						pipemiddle(0) <= 250;--112+ to_integer(unsigned(q))/256;
						q             <= q(14 downto 0) & n3; --new random
						pipemiddle(1) <= 325;--112+ to_integer(unsigned(q))/256;
						q             <= q(14 downto 0) & n3; --new random
						pipemiddle(2) <= 160;--112+ to_integer(unsigned(q))/256;
						gamestate     <= 3;
					end if;--if6
					gamejuststarted <= '0';
				end if;--end game initialize --if1
				---standart game step
				if (gamestate = 3) then--if20
					--
					-- birdsy(0)<=birdsy(0)+1;
					-- if birdsy(0)>400 then
					-- birdsy(0)<=10;
					-- end if;
					---pipes
					pipex(0) <= pipex(0) - gamexspeed;
					pipex(1) <= pipex(1) - gamexspeed;
					pipex(2) <= pipex(2) - gamexspeed;
					if (pipex(0) <- 72) then
						pipex(0)      <= 640;
						q             <= q(14 downto 0) & n3; --new random
						pipemiddle(0) <= 112 + to_integer(unsigned(q))/256;
						pipemove(0)<=-400;
					end if;
					if (pipex(1) <- 72) then
						pipex(1)      <= 640;
						q             <= q(14 downto 0) & n3; --new random
						pipemiddle(1) <= 112 + to_integer(unsigned(q))/256;
						pipemove(1)<=-400;
					end if;
					if (pipex(2) <- 72) then
						pipex(2)      <= 640;
						q             <= q(14 downto 0) & n3; --new random
						pipemiddle(2) <= 112 + to_integer(unsigned(q))/256;
						pipemove(2)<=-400;
					end if;
					buildingpos <= buildingpos + 1;
					mountainpos <= mountainpos + 3;
					if (pipex(0) < pipex(1) xor pipex(0) < 30) then
						nearestpipe := 0;
					else
						nearestpipe := 1;
					end if;
					if (pipex(nearestpipe) > pipex(2) xor pipex(2) < 30) then
						nearestpipe := 2;
					end if;
					
					
					if(pipex(0)<pipex(1))then					 		
					if(pipex(0)<50)then
					nearestpipe:=1;
					 else
					 nearestpipe:=0;
					end if;
					else 	
					if(pipex(1)<50)then
					nearestpipe:=0;
					 else
					nearestpipe:=1;
					end if;
					
					end if;
					
					if(pipex(nearestpipe)<pipex(2))then					 		
					if(pipex(nearestpipe)<50)then
					nearestpipe:=1;
					 else				 
					end if;
					else 	
					if(pipex(2)<50)then
					 else
					nearestpipe:=2;
					end if;
					
					end if;
					
					
					
					if(manual='0') then
--					------------Bird1
--					currentbird := 0;
--					--Movement
					if (birdsactive(currentbird) = 1 ) then--if40
						birdsacc(currentbird)   <= birdsacc(currentbird) + gravity;
						birdsspeed(currentbird) <= birdsspeed(currentbird) + birdsacc(currentbird);
						birdsybig(currentbird)  <= birdsybig(currentbird) + birdsspeed(currentbird);
						-- if (manual = '1' and button_j = '0' and birdsspeed(currentbird) > 0) then --birdsybig(0)>12800 then--if21 zıpla
						-- birdsactive(currentbird)<=0;
						-- birdsscore(currentbird)<= birdsscore(currentbird)+abs(pipemiddle(nearestpipe) - birdsy(currentbird) );
						-- end if;--if21
						birdsy(currentbird) <= birdsybig(currentbird)/64;
						if (birdsy(currentbird) > 456 or birdsy(currentbird) <- 24) then ---if39 out of screen
							
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							
						end if;--if 39
						birdsscore(currentbird) <= birdsscore(currentbird) + 1;
						--Neural Network
						birdsn(currentbird, 0) <= pipemiddle(nearestpipe) - birdsy(currentbird);
						birdsn(currentbird, 1) <= pipex(nearestpipe) - 100;
						birdsn(currentbird, 2) <= (birdsw(currentbird, 0) * birdsn(currentbird, 0) + birdsw(currentbird, 5) * birdsn(currentbird, 1))/32768;
						
						
						
						birdsn(currentbird, 3) <= (birdsw(currentbird, 1) * birdsn(currentbird, 0) + birdsw(currentbird, 6) * birdsn(currentbird, 1))/32768;
						birdsn(currentbird, 4) <= (birdsw(currentbird, 2) * birdsn(currentbird, 0) + birdsw(currentbird, 7) * birdsn(currentbird, 1))/32768;
						birdsn(currentbird, 5) <= (birdsw(currentbird, 3) * birdsn(currentbird, 0) + birdsw(currentbird, 8) * birdsn(currentbird, 1))/32768;
						birdsn(currentbird, 6) <= (birdsw(currentbird, 4) * birdsn(currentbird, 0) + birdsw(currentbird, 9) * birdsn(currentbird, 1))/32768;
						birdsn(currentbird, 7) <= (birdsn(currentbird, 2) * birdsw(currentbird, 10) + birdsn(currentbird, 3) * birdsw(currentbird, 11) + birdsn(currentbird, 4) * birdsw(currentbird, 12) + birdsn(currentbird, 5) * birdsw(currentbird, 13) + birdsn(currentbird, 6) * birdsw(currentbird, 14))/65536;
						if(birdsn(currentbird, 2) > 600)then 
						birdsn(currentbird, 2)<=600;
						end if;
						if(birdsn(currentbird, 2) < -600)then 
						birdsn(currentbird, 2)<=-600;
						end if;
						if(birdsn(currentbird, 3) > 600)then 
						birdsn(currentbird, 3)<=600;
						end if;
						if(birdsn(currentbird, 3) < -600)then 
						birdsn(currentbird, 3)<=-600;
						end if;
						
						if(birdsn(currentbird, 4) > 600)then 
						birdsn(currentbird, 4)<=600;
						end if;
						if(birdsn(currentbird, 4) < -600)then 
						birdsn(currentbird, 4)<=-600;
						end if;
						if(birdsn(currentbird, 5) > 600)then 
						birdsn(currentbird, 5)<=600;
						end if;
						if(birdsn(currentbird, 5) < -600)then 
						birdsn(currentbird, 5)<=-600;
						end if;
						
						if(birdsn(currentbird, 6) > 600)then 
						birdsn(currentbird, 6)<=600;
						end if;
						if(birdsn(currentbird, 6) < -600)then 
						birdsn(currentbird, 6)<=-600;
						end if;
						
						--10000 threshold
						if (birdsn(currentbird, 7) < 0 and birdsspeed(currentbird) > 0) then --JUMP
							birdsacc(currentbird)   <= 0;
							birdsspeed(currentbird) <= - 300;
						end if;
						----Collision check
						if (pipex(0) > 28 and pipex(0) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(0) + 50)) or (birdsy(currentbird) < pipemiddle(0) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								
							end if;
						end if;
						if (pipex(1) > 28 and pipex(1) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(1) + 50)) or (birdsy(currentbird) < pipemiddle(1) - 50)) then
							
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							
							end if;
						end if;
						if (pipex(2) > 28 and pipex(2) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(2) + 50)) or (birdsy(currentbird) < pipemiddle(2) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								
							end if;
						end if;
					end if;--if40
					-----end bird
					------------Bird1
					
					currentbird := 1;
					--Movement
					if (birdsactive(currentbird) = 1) then--if40
						birdsacc(currentbird)   <= birdsacc(currentbird) + gravity;
						birdsspeed(currentbird) <= birdsspeed(currentbird) + birdsacc(currentbird);
						birdsybig(currentbird)  <= birdsybig(currentbird) + birdsspeed(currentbird);
						-- if (manual = '1' and button_j = '0' and birdsspeed(currentbird) > 0) then --birdsybig(0)>12800 then--if21 zıpla
						-- birdsactive(currentbird)<=0;
						-- birdsscore(currentbird)<= birdsscore(currentbird)+abs(pipemiddle(nearestpipe) - birdsy(currentbird) );
						-- end if;--if21
						birdsy(currentbird) <= birdsybig(currentbird)/64;
						if (birdsy(currentbird) > 456 or birdsy(currentbird) <- 24) then ---if39 out of screen
							
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							
						end if;--if 39
						birdsscore(currentbird) <= birdsscore(currentbird) + 1;
						--Neural Network
						birdsn(currentbird, 0) <= pipemiddle(nearestpipe) - birdsy(currentbird);
						birdsn(currentbird, 1) <= pipex(nearestpipe) - 100;
						birdsn(currentbird, 2) <= (birdsw(currentbird, 0) * birdsn(currentbird, 0) + birdsw(currentbird, 5) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 3) <= (birdsw(currentbird, 1) * birdsn(currentbird, 0) + birdsw(currentbird, 6) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 4) <= (birdsw(currentbird, 2) * birdsn(currentbird, 0) + birdsw(currentbird, 7) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 5) <= (birdsw(currentbird, 3) * birdsn(currentbird, 0) + birdsw(currentbird, 8) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 6) <= (birdsw(currentbird, 4) * birdsn(currentbird, 0) + birdsw(currentbird, 9) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 7) <= (birdsn(currentbird, 2) * birdsw(currentbird, 10) + birdsn(currentbird, 3) * birdsw(currentbird, 11) + birdsn(currentbird, 4) * birdsw(currentbird, 12) + birdsn(currentbird, 5) * birdsw(currentbird, 13) + birdsn(currentbird, 6) * birdsw(currentbird, 14))/65536;
							if(birdsn(currentbird, 2) > 600)then 
						birdsn(currentbird, 2)<=600;
						end if;
						if(birdsn(currentbird, 2) < -600)then 
						birdsn(currentbird, 2)<=-600;
						end if;
						if(birdsn(currentbird, 3) > 600)then 
						birdsn(currentbird, 3)<=600;
						end if;
						if(birdsn(currentbird, 3) < -600)then 
						birdsn(currentbird, 3)<=-600;
						end if;
						
						if(birdsn(currentbird, 4) > 600)then 
						birdsn(currentbird, 4)<=600;
						end if;
						if(birdsn(currentbird, 4) < -600)then 
						birdsn(currentbird, 4)<=-600;
						end if;
						if(birdsn(currentbird, 5) > 600)then 
						birdsn(currentbird, 5)<=600;
						end if;
						if(birdsn(currentbird, 5) < -600)then 
						birdsn(currentbird, 5)<=-600;
						end if;
						
						if(birdsn(currentbird, 6) > 600)then 
						birdsn(currentbird, 6)<=600;
						end if;
						if(birdsn(currentbird, 6) < -600)then 
						birdsn(currentbird, 6)<=-600;
						end if;
						
						--10000 threshold
						if (birdsn(currentbird, 7) < 0 and birdsspeed(currentbird) > 0) then --JUMP
							birdsacc(currentbird)   <= 0;
							birdsspeed(currentbird) <= - 300;
						end if;
						----Collision check
						if (pipex(0) > 28 and pipex(0) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(0) + 50)) or (birdsy(currentbird) < pipemiddle(0) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							
							end if;
						end if;
						if (pipex(1) > 28 and pipex(1) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(1) + 50)) or (birdsy(currentbird) < pipemiddle(1) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								
							end if;
						end if;
						if (pipex(2) > 28 and pipex(2) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(2) + 50)) or (birdsy(currentbird) < pipemiddle(2) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								
							end if;
						end if;
					end if;--if40
					-----end bird
					------------Bird1
					currentbird := 2;
					--Movement
					if (birdsactive(currentbird) = 1) then--if40
						birdsacc(currentbird)   <= birdsacc(currentbird) + gravity;
						birdsspeed(currentbird) <= birdsspeed(currentbird) + birdsacc(currentbird);
						birdsybig(currentbird)  <= birdsybig(currentbird) + birdsspeed(currentbird);
						-- if (manual = '1' and button_j = '0' and birdsspeed(currentbird) > 0) then --birdsybig(0)>12800 then--if21 zıpla
						-- birdsactive(currentbird)<=0;
						-- birdsscore(currentbird)<= birdsscore(currentbird)+abs(pipemiddle(nearestpipe) - birdsy(currentbird) );
						-- end if;--if21
						birdsy(currentbird) <= birdsybig(currentbird)/64;
						if (birdsy(currentbird) > 456 or birdsy(currentbird) <- 24) then ---if39 out of screen
							
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							
						end if;--if 39
						birdsscore(currentbird) <= birdsscore(currentbird) + 1;
						--Neural Network
						birdsn(currentbird, 0) <= pipemiddle(nearestpipe) - birdsy(currentbird);
						birdsn(currentbird, 1) <= pipex(nearestpipe) - 100;
						birdsn(currentbird, 2) <= (birdsw(currentbird, 0) * birdsn(currentbird, 0) + birdsw(currentbird, 5) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 3) <= (birdsw(currentbird, 1) * birdsn(currentbird, 0) + birdsw(currentbird, 6) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 4) <= (birdsw(currentbird, 2) * birdsn(currentbird, 0) + birdsw(currentbird, 7) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 5) <= (birdsw(currentbird, 3) * birdsn(currentbird, 0) + birdsw(currentbird, 8) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 6) <= (birdsw(currentbird, 4) * birdsn(currentbird, 0) + birdsw(currentbird, 9) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 7) <= (birdsn(currentbird, 2) * birdsw(currentbird, 10) + birdsn(currentbird, 3) * birdsw(currentbird, 11) + birdsn(currentbird, 4) * birdsw(currentbird, 12) + birdsn(currentbird, 5) * birdsw(currentbird, 13) + birdsn(currentbird, 6) * birdsw(currentbird, 14))/65536;
							if(birdsn(currentbird, 2) > 600)then 
						birdsn(currentbird, 2)<=600;
						end if;
						if(birdsn(currentbird, 2) < -600)then 
						birdsn(currentbird, 2)<=-600;
						end if;
						if(birdsn(currentbird, 3) > 600)then 
						birdsn(currentbird, 3)<=600;
						end if;
						if(birdsn(currentbird, 3) < -600)then 
						birdsn(currentbird, 3)<=-600;
						end if;
						
						if(birdsn(currentbird, 4) > 600)then 
						birdsn(currentbird, 4)<=600;
						end if;
						if(birdsn(currentbird, 4) < -600)then 
						birdsn(currentbird, 4)<=-600;
						end if;
						if(birdsn(currentbird, 5) > 600)then 
						birdsn(currentbird, 5)<=600;
						end if;
						if(birdsn(currentbird, 5) < -600)then 
						birdsn(currentbird, 5)<=-600;
						end if;
						
						if(birdsn(currentbird, 6) > 600)then 
						birdsn(currentbird, 6)<=600;
						end if;
						if(birdsn(currentbird, 6) < -600)then 
						birdsn(currentbird, 6)<=-600;
						end if;
						
						
						--10000 threshold
						if (birdsn(currentbird, 7) < 0 and birdsspeed(currentbird) > 0) then --JUMP
							birdsacc(currentbird)   <= 0;
							birdsspeed(currentbird) <= - 300;
						end if;
						----Collision check
						if (pipex(0) > 28 and pipex(0) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(0) + 50)) or (birdsy(currentbird) < pipemiddle(0) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								
							end if;
						end if;
						if (pipex(1) > 28 and pipex(1) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(1) + 50)) or (birdsy(currentbird) < pipemiddle(1) - 50)) then
							
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								
							end if;
						end if;
						if (pipex(2) > 28 and pipex(2) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(2) + 50)) or (birdsy(currentbird) < pipemiddle(2) - 50)) then
							
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								
							end if;
						end if;
					end if;--if40
					-----end bird
					------------Bird1
					currentbird := 3;
					--Movement
					if (birdsactive(currentbird) = 1) then--if40
						birdsacc(currentbird)   <= birdsacc(currentbird) + gravity;
						birdsspeed(currentbird) <= birdsspeed(currentbird) + birdsacc(currentbird);
						birdsybig(currentbird)  <= birdsybig(currentbird) + birdsspeed(currentbird);
						-- if (manual = '1' and button_j = '0' and birdsspeed(currentbird) > 0) then --birdsybig(0)>12800 then--if21 zıpla
						-- birdsactive(currentbird)<=0;
						-- birdsscore(currentbird)<= birdsscore(currentbird)+abs(pipemiddle(nearestpipe) - birdsy(currentbird) );
						-- end if;--if21
						birdsy(currentbird) <= birdsybig(currentbird)/64;
						if (birdsy(currentbird) > 456 or birdsy(currentbird) <- 24) then ---if39 out of screen
						
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							
						end if;--if 39
						birdsscore(currentbird) <= birdsscore(currentbird) + 1;
						--Neural Network
						birdsn(currentbird, 0) <= pipemiddle(nearestpipe) - birdsy(currentbird);
						birdsn(currentbird, 1) <= pipex(nearestpipe) - 100;
						birdsn(currentbird, 2) <= (birdsw(currentbird, 0) * birdsn(currentbird, 0) + birdsw(currentbird, 5) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 3) <= (birdsw(currentbird, 1) * birdsn(currentbird, 0) + birdsw(currentbird, 6) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 4) <= (birdsw(currentbird, 2) * birdsn(currentbird, 0) + birdsw(currentbird, 7) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 5) <= (birdsw(currentbird, 3) * birdsn(currentbird, 0) + birdsw(currentbird, 8) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 6) <= (birdsw(currentbird, 4) * birdsn(currentbird, 0) + birdsw(currentbird, 9) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 7) <= (birdsn(currentbird, 2) * birdsw(currentbird, 10) + birdsn(currentbird, 3) * birdsw(currentbird, 11) + birdsn(currentbird, 4) * birdsw(currentbird, 12) + birdsn(currentbird, 5) * birdsw(currentbird, 13) + birdsn(currentbird, 6) * birdsw(currentbird, 14))/65536;
							if(birdsn(currentbird, 2) > 600)then 
						birdsn(currentbird, 2)<=600;
						end if;
						if(birdsn(currentbird, 2) < -600)then 
						birdsn(currentbird, 2)<=-600;
						end if;
						if(birdsn(currentbird, 3) > 600)then 
						birdsn(currentbird, 3)<=600;
						end if;
						if(birdsn(currentbird, 3) < -600)then 
						birdsn(currentbird, 3)<=-600;
						end if;
						
						if(birdsn(currentbird, 4) > 600)then 
						birdsn(currentbird, 4)<=600;
						end if;
						if(birdsn(currentbird, 4) < -600)then 
						birdsn(currentbird, 4)<=-600;
						end if;
						if(birdsn(currentbird, 5) > 600)then 
						birdsn(currentbird, 5)<=600;
						end if;
						if(birdsn(currentbird, 5) < -600)then 
						birdsn(currentbird, 5)<=-600;
						end if;
						
						if(birdsn(currentbird, 6) > 600)then 
						birdsn(currentbird, 6)<=600;
						end if;
						if(birdsn(currentbird, 6) < -600)then 
						birdsn(currentbird, 6)<=-600;
						end if;
						
						--10000 threshold
						if (birdsn(currentbird, 7) < 0 and birdsspeed(currentbird) > 0) then --JUMP
							birdsacc(currentbird)   <= 0;
							birdsspeed(currentbird) <= - 300;
						end if;
						----Collision check
						if (pipex(0) > 28 and pipex(0) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(0) + 50)) or (birdsy(currentbird) < pipemiddle(0) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								
							end if;
						end if;
						if (pipex(1) > 28 and pipex(1) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(1) + 50)) or (birdsy(currentbird) < pipemiddle(1) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								
							end if;
						end if;
						if (pipex(2) > 28 and pipex(2) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(2) + 50)) or (birdsy(currentbird) < pipemiddle(2) - 50)) then
							
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							
							end if;
						end if;
					end if;--if40
					-----end bird
					------------Bird1
					currentbird := 4;
					--Movement
					if (birdsactive(currentbird) = 1) then--if40
						birdsacc(currentbird)   <= birdsacc(currentbird) + gravity;
						birdsspeed(currentbird) <= birdsspeed(currentbird) + birdsacc(currentbird);
						birdsybig(currentbird)  <= birdsybig(currentbird) + birdsspeed(currentbird);
						-- if (manual = '1' and button_j = '0' and birdsspeed(currentbird) > 0) then --birdsybig(0)>12800 then--if21 zıpla
						-- birdsactive(currentbird)<=0;
						-- birdsscore(currentbird)<= birdsscore(currentbird)+abs(pipemiddle(nearestpipe) - birdsy(currentbird) );
						-- end if;--if21
						birdsy(currentbird) <= birdsybig(currentbird)/64;
						if (birdsy(currentbird) > 456 or birdsy(currentbird) <- 24) then ---if39 out of screen
							
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
						
						end if;--if 39
						birdsscore(currentbird) <= birdsscore(currentbird) + 1;
						--Neural Network
						birdsn(currentbird, 0) <= pipemiddle(nearestpipe) - birdsy(currentbird);
						birdsn(currentbird, 1) <= pipex(nearestpipe) - 100;
						birdsn(currentbird, 2) <= (birdsw(currentbird, 0) * birdsn(currentbird, 0) + birdsw(currentbird, 5) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 3) <= (birdsw(currentbird, 1) * birdsn(currentbird, 0) + birdsw(currentbird, 6) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 4) <= (birdsw(currentbird, 2) * birdsn(currentbird, 0) + birdsw(currentbird, 7) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 5) <= (birdsw(currentbird, 3) * birdsn(currentbird, 0) + birdsw(currentbird, 8) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 6) <= (birdsw(currentbird, 4) * birdsn(currentbird, 0) + birdsw(currentbird, 9) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 7) <= (birdsn(currentbird, 2) * birdsw(currentbird, 10) + birdsn(currentbird, 3) * birdsw(currentbird, 11) + birdsn(currentbird, 4) * birdsw(currentbird, 12) + birdsn(currentbird, 5) * birdsw(currentbird, 13) + birdsn(currentbird, 6) * birdsw(currentbird, 14))/65536;
							if(birdsn(currentbird, 2) > 600)then 
						birdsn(currentbird, 2)<=600;
						end if;
						if(birdsn(currentbird, 2) < -600)then 
						birdsn(currentbird, 2)<=-600;
						end if;
						if(birdsn(currentbird, 3) > 600)then 
						birdsn(currentbird, 3)<=600;
						end if;
						if(birdsn(currentbird, 3) < -600)then 
						birdsn(currentbird, 3)<=-600;
						end if;
						
						if(birdsn(currentbird, 4) > 600)then 
						birdsn(currentbird, 4)<=600;
						end if;
						if(birdsn(currentbird, 4) < -600)then 
						birdsn(currentbird, 4)<=-600;
						end if;
						if(birdsn(currentbird, 5) > 600)then 
						birdsn(currentbird, 5)<=600;
						end if;
						if(birdsn(currentbird, 5) < -600)then 
						birdsn(currentbird, 5)<=-600;
						end if;
						
						if(birdsn(currentbird, 6) > 600)then 
						birdsn(currentbird, 6)<=600;
						end if;
						if(birdsn(currentbird, 6) < -600)then 
						birdsn(currentbird, 6)<=-600;
						end if;
						
						--10000 threshold
						if (birdsn(currentbird, 7) < 0 and birdsspeed(currentbird) > 0) then --JUMP
							birdsacc(currentbird)   <= 0;
							birdsspeed(currentbird) <= - 300;
						end if;
						----Collision check
						if (pipex(0) > 28 and pipex(0) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(0) + 50)) or (birdsy(currentbird) < pipemiddle(0) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								
							end if;
						end if;
						if (pipex(1) > 28 and pipex(1) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(1) + 50)) or (birdsy(currentbird) < pipemiddle(1) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								
							end if;
						end if;
						if (pipex(2) > 28 and pipex(2) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(2) + 50)) or (birdsy(currentbird) < pipemiddle(2) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							
							end if;
						end if;
					end if;--if40
					-----end bird
					------------Bird1
					currentbird := 5;
					--Movement
					if (birdsactive(currentbird) = 1) then--if40
						birdsacc(currentbird)   <= birdsacc(currentbird) + gravity;
						birdsspeed(currentbird) <= birdsspeed(currentbird) + birdsacc(currentbird);
						birdsybig(currentbird)  <= birdsybig(currentbird) + birdsspeed(currentbird);
						-- if (manual = '1' and button_j = '0' and birdsspeed(currentbird) > 0) then --birdsybig(0)>12800 then--if21 zıpla
						-- birdsactive(currentbird)<=0;
						-- birdsscore(currentbird)<= birdsscore(currentbird)+abs(pipemiddle(nearestpipe) - birdsy(currentbird) );
						-- end if;--if21
						birdsy(currentbird) <= birdsybig(currentbird)/64;
						if (birdsy(currentbird) > 456 or birdsy(currentbird) <- 24) then ---if39 out of screen
							if (manual = '1') then
							else
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							end if;
						end if;--if 39
						birdsscore(currentbird) <= birdsscore(currentbird) + 1;
						--Neural Network
						birdsn(currentbird, 0) <= pipemiddle(nearestpipe) - birdsy(currentbird);
						birdsn(currentbird, 1) <= pipex(nearestpipe) - 100;
						birdsn(currentbird, 2) <= (birdsw(currentbird, 0) * birdsn(currentbird, 0) + birdsw(currentbird, 5) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 3) <= (birdsw(currentbird, 1) * birdsn(currentbird, 0) + birdsw(currentbird, 6) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 4) <= (birdsw(currentbird, 2) * birdsn(currentbird, 0) + birdsw(currentbird, 7) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 5) <= (birdsw(currentbird, 3) * birdsn(currentbird, 0) + birdsw(currentbird, 8) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 6) <= (birdsw(currentbird, 4) * birdsn(currentbird, 0) + birdsw(currentbird, 9) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 7) <= (birdsn(currentbird, 2) * birdsw(currentbird, 10) + birdsn(currentbird, 3) * birdsw(currentbird, 11) + birdsn(currentbird, 4) * birdsw(currentbird, 12) + birdsn(currentbird, 5) * birdsw(currentbird, 13) + birdsn(currentbird, 6) * birdsw(currentbird, 14))/65536;
						--10000 threshold
						if (birdsn(currentbird, 7) < 0 and birdsspeed(currentbird) > 0) then --JUMP
							birdsacc(currentbird)   <= 0;
							birdsspeed(currentbird) <= - 300;
							
						end if;
						----Collision check
						if (pipex(0) > 28 and pipex(0) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(0) + 50)) or (birdsy(currentbird) < pipemiddle(0) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							
							end if;
						end if;
						if (pipex(1) > 28 and pipex(1) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(1) + 50)) or (birdsy(currentbird) < pipemiddle(1) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								
							end if;
						end if;
						if (pipex(2) > 28 and pipex(2) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(2) + 50)) or (birdsy(currentbird) < pipemiddle(2) - 50)) then
								
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
									
							end if;
						end if;
					end if;--if40

					else--manual
					
					if (birdsy(0) > 456 or birdsy(0) <- 24) then ---if39 out of screen

					gameover<='1';
					
					end if;
					
					
					
					
					
					if (pipex(0) > 28 and pipex(0) < 134) then
					
					if (((birdsy(0) + 24) > (pipemiddle(0) + pipegap )) or (birdsy(0) < pipemiddle(0) - pipegap)) then
					  gameover<='1';
					  
						end if;
						
					end if;
					
					if (pipex(1) > 28 and pipex(1) < 134) then
					if (((birdsy(0) + 24) > (pipemiddle(1) + pipegap)) or (birdsy(0) < pipemiddle(1) - pipegap)) then
					  gameover<='1';
						end if;
					end if;
					if (pipex(2) > 28 and pipex(2) < 134) then
					if (((birdsy(0) + 24) > (pipemiddle(2) + pipegap)) or (birdsy(0) < pipemiddle(2) - pipegap)) then
					  gameover<='1';
						end if;
					end if;
					
					birdsacc(0)   <= birdsacc(0) + gravity;
						birdsspeed(0) <= birdsspeed(0) + birdsacc(0);
						birdsybig(0)  <= birdsybig(0) + birdsspeed(0);
						birdsy(0) <= birdsybig(0)/64;
						
					if(button_j='0' and birdsspeed(0) >0) then
						   
							birdsacc(0)   <= 0;
							birdsspeed(0) <= - 330;
							
							end if;
							
					score<=score+1;
					
					 mountainposy<= 360- birdsy(0)/8;  
					if(gameover='1')then
						
						pipex(0)<=237+237*6;
						pipex(1)<=474+237*6;
						pipex(2)<=711+237*6;
						birdsacc(0)<=0;
						birdsspeed(0)<=0;
						birdsybig(0)<=220*64;
						score<=0;					
						gameover<='0';
					end if;
					
					end if;--- manual 1 endif
				
					
					--					-----end bird
--
--					------------Bird1
					currentbird := 6;
					--Movement
					if (birdsactive(currentbird) = 1) then--if40
						birdsacc(currentbird)   <= birdsacc(currentbird) + gravity;
						birdsspeed(currentbird) <= birdsspeed(currentbird) + birdsacc(currentbird);
						birdsybig(currentbird)  <= birdsybig(currentbird) + birdsspeed(currentbird);
						-- if (manual = '1' and button_j = '0' and birdsspeed(currentbird) > 0) then --birdsybig(0)>12800 then--if21 zıpla
						-- birdsactive(currentbird)<=0;
						-- birdsscore(currentbird)<= birdsscore(currentbird)+abs(pipemiddle(nearestpipe) - birdsy(currentbird) );
						-- end if;--if21
						birdsy(currentbird) <= birdsybig(currentbird)/64;
						if (birdsy(currentbird) > 456 or birdsy(currentbird) <- 24) then ---if39 out of screen
							if (manual = '1') then
							else
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							end if;
						end if;--if 39
						birdsscore(currentbird) <= birdsscore(currentbird) + 1;
						--Neural Network
						birdsn(currentbird, 0) <= pipemiddle(nearestpipe) - birdsy(currentbird);
						birdsn(currentbird, 1) <= pipex(nearestpipe) - 100;
						birdsn(currentbird, 2) <= (birdsw(currentbird, 0) * birdsn(currentbird, 0) + birdsw(currentbird, 5) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 3) <= (birdsw(currentbird, 1) * birdsn(currentbird, 0) + birdsw(currentbird, 6) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 4) <= (birdsw(currentbird, 2) * birdsn(currentbird, 0) + birdsw(currentbird, 7) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 5) <= (birdsw(currentbird, 3) * birdsn(currentbird, 0) + birdsw(currentbird, 8) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 6) <= (birdsw(currentbird, 4) * birdsn(currentbird, 0) + birdsw(currentbird, 9) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 7) <= (birdsn(currentbird, 2) * birdsw(currentbird, 10) + birdsn(currentbird, 3) * birdsw(currentbird, 11) + birdsn(currentbird, 4) * birdsw(currentbird, 12) + birdsn(currentbird, 5) * birdsw(currentbird, 13) + birdsn(currentbird, 6) * birdsw(currentbird, 14))/65536;
						--10000 threshold
						if (birdsn(currentbird, 7) < 1600 and birdsspeed(currentbird) > 0) then --JUMP
							birdsacc(currentbird)   <= 0;
							birdsspeed(currentbird) <= - 300;
						end if;
						----Collision check
						if (pipex(0) > 28 and pipex(0) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(0) + 50)) or (birdsy(currentbird) < pipemiddle(0) - 50)) then
								if manual = '1' then
								else
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								end if;
							end if;
						end if;
						if (pipex(1) > 28 and pipex(1) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(1) + 50)) or (birdsy(currentbird) < pipemiddle(1) - 50)) then
								if manual = '1' then
								else
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								end if;
							end if;
						end if;
						if (pipex(2) > 28 and pipex(2) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(2) + 50)) or (birdsy(currentbird) < pipemiddle(2) - 50)) then
								if manual = '1' then
								else
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								end if;
							end if;
						end if;
					end if;--if40
					-----end bird
					------------Bird1
					currentbird := 7;
					--Movement
					if (birdsactive(currentbird) = 1) then--if40
						birdsacc(currentbird)   <= birdsacc(currentbird) + gravity;
						birdsspeed(currentbird) <= birdsspeed(currentbird) + birdsacc(currentbird);
						birdsybig(currentbird)  <= birdsybig(currentbird) + birdsspeed(currentbird);
						-- if (manual = '1' and button_j = '0' and birdsspeed(currentbird) > 0) then --birdsybig(0)>12800 then--if21 zıpla
						-- birdsactive(currentbird)<=0;
						-- birdsscore(currentbird)<= birdsscore(currentbird)+abs(pipemiddle(nearestpipe) - birdsy(currentbird) );
						-- end if;--if21
						birdsy(currentbird) <= birdsybig(currentbird)/64;
						if (birdsy(currentbird) > 456 or birdsy(currentbird) <- 24) then ---if39 out of screen
							if (manual = '1') then
							else
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							end if;
						end if;--if 39
						birdsscore(currentbird) <= birdsscore(currentbird) + 1;
						--Neural Network
						birdsn(currentbird, 0) <= pipemiddle(nearestpipe) - birdsy(currentbird);
						birdsn(currentbird, 1) <= pipex(nearestpipe) - 100;
						birdsn(currentbird, 2) <= (birdsw(currentbird, 0) * birdsn(currentbird, 0) + birdsw(currentbird, 5) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 3) <= (birdsw(currentbird, 1) * birdsn(currentbird, 0) + birdsw(currentbird, 6) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 4) <= (birdsw(currentbird, 2) * birdsn(currentbird, 0) + birdsw(currentbird, 7) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 5) <= (birdsw(currentbird, 3) * birdsn(currentbird, 0) + birdsw(currentbird, 8) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 6) <= (birdsw(currentbird, 4) * birdsn(currentbird, 0) + birdsw(currentbird, 9) * birdsn(currentbird, 1))/8192;
						birdsn(currentbird, 7) <= (birdsn(currentbird, 2) * birdsw(currentbird, 10) + birdsn(currentbird, 3) * birdsw(currentbird, 11) + birdsn(currentbird, 4) * birdsw(currentbird, 12) + birdsn(currentbird, 5) * birdsw(currentbird, 13) + birdsn(currentbird, 6) * birdsw(currentbird, 14))/65536;
						--10000 threshold
						if (birdsn(currentbird, 7) < 1600 and birdsspeed(currentbird) > 0) then --JUMP
							birdsacc(currentbird)   <= 0;
							birdsspeed(currentbird) <= - 300;
						end if;
						----Collision check
						if (pipex(0) > 28 and pipex(0) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(0) + 50)) or (birdsy(currentbird) < pipemiddle(0) - 50)) then
								if manual = '1' then
								else
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								end if;
							end if;
						end if;
						if (pipex(1) > 28 and pipex(1) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(1) + 50)) or (birdsy(currentbird) < pipemiddle(1) - 50)) then
								if manual = '1' then
								else
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								end if;
							end if;
						end if;
						if (pipex(2) > 28 and pipex(2) < 134) then
							if (((birdsy(currentbird) + 24) > (pipemiddle(2) + 50)) or (birdsy(currentbird) < pipemiddle(2) - 50)) then
								if manual = '1' then
								else
									deathbirds               <= deathbirds + 1;
									birdsactive(currentbird) <= 0;
									birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
								end if;
							end if;
						end if;
					end if;--if40
					-----end bird
					------------Bird1
					currentbird := 8;
					--Movement
					if (birdsactive(currentbird) = 1) then--if40
						birdsacc(currentbird)   <= birdsacc(currentbird) + gravity;
						birdsspeed(currentbird) <= birdsspeed(currentbird) + birdsacc(currentbird);
						birdsybig(currentbird)  <= birdsybig(currentbird) + birdsspeed(currentbird);
						-- if (manual = '1' and button_j = '0' and birdsspeed(currentbird) > 0) then --birdsybig(0)>12800 then--if21 zıpla
						-- birdsactive(currentbird)<=0;
						-- birdsscore(currentbird)<= birdsscore(currentbird)+abs(pipemiddle(nearestpipe) - birdsy(currentbird) );
						-- end if;--if21
						birdsy(currentbird) <= birdsybig(currentbird)/64;
						if (birdsy(currentbird) > 456 or birdsy(currentbird) <- 24) then ---if39 out of screen
							if (manual = '1') then
							else
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							end if;
						end if;--if 39
					
					birdsscore(currentbird) <= birdsscore(currentbird) + 1;
					--Neural Network
					birdsn(currentbird, 0) <= pipemiddle(nearestpipe) - birdsy(currentbird);
					birdsn(currentbird, 1) <= pipex(nearestpipe) - 100;
					birdsn(currentbird, 2) <= (birdsw(currentbird, 0) * birdsn(currentbird, 0) + birdsw(currentbird, 5) * birdsn(currentbird, 1))/8192;
					birdsn(currentbird, 3) <= (birdsw(currentbird, 1) * birdsn(currentbird, 0) + birdsw(currentbird, 6) * birdsn(currentbird, 1))/8192;
					birdsn(currentbird, 4) <= (birdsw(currentbird, 2) * birdsn(currentbird, 0) + birdsw(currentbird, 7) * birdsn(currentbird, 1))/8192;
					birdsn(currentbird, 5) <= (birdsw(currentbird, 3) * birdsn(currentbird, 0) + birdsw(currentbird, 8) * birdsn(currentbird, 1))/8192;
					birdsn(currentbird, 6) <= (birdsw(currentbird, 4) * birdsn(currentbird, 0) + birdsw(currentbird, 9) * birdsn(currentbird, 1))/8192;
					birdsn(currentbird, 7) <= (birdsn(currentbird, 2) * birdsw(currentbird, 10) + birdsn(currentbird, 3) * birdsw(currentbird, 11) + birdsn(currentbird, 4) * birdsw(currentbird, 12) + birdsn(currentbird, 5) * birdsw(currentbird, 13) + birdsn(currentbird, 6) * birdsw(currentbird, 14))/65536;
					--10000 threshold
					if (birdsn(currentbird, 7) < 1600 and birdsspeed(currentbird) > 0) then --JUMP
						birdsacc(currentbird)   <= 0;
						birdsspeed(currentbird) <= - 300;
					end if;
					----Collision check
					if (pipex(0) > 28 and pipex(0) < 134) then
						if (((birdsy(currentbird) + 24) > (pipemiddle(0) + 50)) or (birdsy(currentbird) < pipemiddle(0) - 50)) then
							if manual = '1' then
							else
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							end if;
						end if;
					end if;
					if (pipex(1) > 28 and pipex(1) < 134) then
						if (((birdsy(currentbird) + 24) > (pipemiddle(1) + 50)) or (birdsy(currentbird) < pipemiddle(1) - 50)) then
							if manual = '1' then
							else
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							end if;
						end if;
					end if;
					if (pipex(2) > 28 and pipex(2) < 134) then
						if (((birdsy(currentbird) + 24) > (pipemiddle(2) + 50)) or (birdsy(currentbird) < pipemiddle(2) - 50)) then
							if manual = '1' then
							else
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							end if;
						end if;
					end if;
				end if;--if40
				-----end bird

				------------Bird1
				currentbird := 9;
				--Movement
				if (birdsactive(currentbird) = 1) then--if40
					birdsacc(currentbird)   <= birdsacc(currentbird) + gravity;
					birdsspeed(currentbird) <= birdsspeed(currentbird) + birdsacc(currentbird);
					birdsybig(currentbird)  <= birdsybig(currentbird) + birdsspeed(currentbird);
					-- if (manual = '1' and button_j = '0' and birdsspeed(currentbird) > 0) then --birdsybig(0)>12800 then--if21 zıpla
					-- birdsactive(currentbird)<=0;
					-- birdsscore(currentbird)<= birdsscore(currentbird)+abs(pipemiddle(nearestpipe) - birdsy(currentbird) );
					-- end if;--if21
					birdsy(currentbird) <= birdsybig(currentbird)/64;
					if (birdsy(currentbird) > 456 or birdsy(currentbird) <- 24) then ---if39 out of screen
						if (manual = '1') then
						else
							deathbirds               <= deathbirds + 1;
							birdsactive(currentbird) <= 0;
							birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
						end if;
					end if;--if 39
					birdsscore(currentbird) <= birdsscore(currentbird) + 1;
					--Neural Network
					birdsn(currentbird, 0) <= pipemiddle(nearestpipe) - birdsy(currentbird);
					birdsn(currentbird, 1) <= pipex(nearestpipe) - 100;
					birdsn(currentbird, 2) <= (birdsw(currentbird, 0) * birdsn(currentbird, 0) + birdsw(currentbird, 5) * birdsn(currentbird, 1))/8192;
					birdsn(currentbird, 3) <= (birdsw(currentbird, 1) * birdsn(currentbird, 0) + birdsw(currentbird, 6) * birdsn(currentbird, 1))/8192;
					birdsn(currentbird, 4) <= (birdsw(currentbird, 2) * birdsn(currentbird, 0) + birdsw(currentbird, 7) * birdsn(currentbird, 1))/8192;
					birdsn(currentbird, 5) <= (birdsw(currentbird, 3) * birdsn(currentbird, 0) + birdsw(currentbird, 8) * birdsn(currentbird, 1))/8192;
					birdsn(currentbird, 6) <= (birdsw(currentbird, 4) * birdsn(currentbird, 0) + birdsw(currentbird, 9) * birdsn(currentbird, 1))/8192;
					birdsn(currentbird, 7) <= (birdsn(currentbird, 2) * birdsw(currentbird, 10) + birdsn(currentbird, 3) * birdsw(currentbird, 11) + birdsn(currentbird, 4) * birdsw(currentbird, 12) + birdsn(currentbird, 5) * birdsw(currentbird, 13) + birdsn(currentbird, 6) * birdsw(currentbird, 14))/65536;
					--1600 average expected
					if (birdsn(currentbird, 7) < 1600 and birdsspeed(currentbird) > 0) then --JUMP
						birdsacc(currentbird)   <= 0;
						birdsspeed(currentbird) <= - 300;
					end if;
					----Collision check
					if (pipex(0) > 28 and pipex(0) < 134) then
						if (((birdsy(currentbird) + 24) > (pipemiddle(0) + 50)) or (birdsy(currentbird) < pipemiddle(0) - 50)) then
							if manual = '1' then
							else
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							end if;
						end if;
					end if;
					if (pipex(1) > 28 and pipex(1) < 134) then
						if (((birdsy(currentbird) + 24) > (pipemiddle(1) + 50)) or (birdsy(currentbird) < pipemiddle(1) - 50)) then
							if manual = '1' then
							else
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							end if;
						end if;
					end if;
					if (pipex(2) > 28 and pipex(2) < 134) then
						if (((birdsy(currentbird) + 24) > (pipemiddle(2) + 50)) or (birdsy(currentbird) < pipemiddle(2) - 50)) then
							if manual = '1' then
							else
								deathbirds               <= deathbirds + 1;
								birdsactive(currentbird) <= 0;
								birdsscore(currentbird)  <= birdsscore(currentbird) + abs(pipemiddle(nearestpipe) - birdsy(currentbird));
							end if;
						end if;
					end if;
				end if;--if40
				-----end bird
				if(deathbirds>5 and manual='0'  )then ---generation end if41    and birdsactive(0)=0 and birdsactive(1)=0 and birdsactive(2)=0 and birdsactive(3)=0 and birdsactive(4)=0 and birdsactive(5)=0 
				maxscore:=0;
				secondplacescore:=0;
				--------------------------
				currentbird:=0;
				if(birdsscore(currentbird)>maxscore)then
				maxscore:=birdsscore(currentbird);
				maxindex:=currentbird;
				else
					if(birdsscore(currentbird)>secondplacescore)then
					secondplacescore:=birdsscore(currentbird);
					secondindex:=currentbird;
						end if;
				end if;				
				
				
				--------------------------
				currentbird:=1;
				if(birdsscore(currentbird)>maxscore)then
				maxscore:=birdsscore(currentbird);
				maxindex:=currentbird;
				else
					if(birdsscore(currentbird)>secondplacescore)then
					secondplacescore:=birdsscore(currentbird);
					secondindex:=currentbird;
						end if;
				end if;				
			
				--------------------------
				currentbird:=2;
				if(birdsscore(currentbird)>maxscore)then
				maxscore:=birdsscore(currentbird);
				maxindex:=currentbird;
				else
					if(birdsscore(currentbird)>secondplacescore)then
					secondplacescore:=birdsscore(currentbird);
					secondindex:=currentbird;
						end if;
							
				end if;
				--------------------------
				currentbird:=3;
				if(birdsscore(currentbird)>maxscore)then
				maxscore:=birdsscore(currentbird);
				maxindex:=currentbird;
				else
					if(birdsscore(currentbird)>secondplacescore)then
					secondplacescore:=birdsscore(currentbird);
					secondindex:=currentbird;
						end if;
							
				end if;
				--------------------------
				currentbird:=4;
				if(birdsscore(currentbird)>maxscore)then
				maxscore:=birdsscore(currentbird);
				maxindex:=currentbird;
				else
					if(birdsscore(currentbird)>secondplacescore)then
					secondplacescore:=birdsscore(currentbird);
					secondindex:=currentbird;
						end if;
						
				end if;
				--------------------------
				currentbird:=5;
				if(birdsscore(currentbird)>maxscore)then
				maxscore:=birdsscore(currentbird);
				maxindex:=currentbird;
				else
					if(birdsscore(currentbird)>secondplacescore)then
					secondplacescore:=birdsscore(currentbird);
					secondindex:=currentbird;
						end if;
							
				end if;
				--------------------------
--				currentbird:=6;
--				if(birdsscore(currentbird)>maxscore)then
--				maxscore:=birdsscore(currentbird);
--				maxindex:=currentbird;
--				else
--					if(birdsscore(currentbird)>secondplacescore)then
--					secondplacescore:=birdsscore(currentbird);
--					secondindex:=currentbird;
--						end if;
--					
--				end if;
				--------------------------
--				currentbird:=7;
--				if(birdsscore(currentbird)>maxscore)then
--				maxscore:=birdsscore(currentbird);
--				maxindex:=currentbird;
--				else
--					if(birdsscore(currentbird)>secondplacescore)then
--					secondplacescore:=birdsscore(currentbird);
--					secondindex:=currentbird;
--						end if;
--						
--				end if;
--				--------------------------
--				currentbird:=8;
--				if(birdsscore(currentbird)>maxscore)then
--				maxscore:=birdsscore(currentbird);
--				maxindex:=currentbird;
--				else
--					if(birdsscore(currentbird)>secondplacescore)then
--					secondplacescore:=birdsscore(currentbird);
--					secondindex:=currentbird;
--						end if;
--								
--				end if;
--				--------------------------
--				currentbird:=9;
--				if(birdsscore(currentbird)>maxscore)then
--				maxscore:=birdsscore(currentbird);
--				maxindex:=currentbird;
--				else
--					if(birdsscore(currentbird)>secondplacescore)then
--					secondplacescore:=birdsscore(currentbird);
--					secondindex:=currentbird;
--						end if;				
--				end if;
				
				---award the winner 
				birdwinner(0)<= birdsw(maxindex,0);
				birdwinner(1)<= birdsw(maxindex,1);
				birdwinner(2)<= birdsw(maxindex,2);
				birdwinner(3)<= birdsw(maxindex,3);
				birdwinner(4)<= birdsw(maxindex,4);
				birdwinner(5)<= birdsw(maxindex,5);
				birdwinner(6)<= birdsw(maxindex,6);
				birdwinner(7)<= birdsw(maxindex,7);
				birdwinner(8)<= birdsw(maxindex,8);
				birdwinner(9)<= birdsw(maxindex,9);
				birdwinner(10)<= birdsw(maxindex,10);
				birdwinner(11)<= birdsw(maxindex,11);
				birdwinner(12)<= birdsw(maxindex,12);
				birdwinner(13)<= birdsw(maxindex,13);
				birdwinner(14)<= birdsw(maxindex,14);
				--teselli reward to second bird 
				birdsecond(0)<= birdsw(secondindex,0);
				birdsecond(1)<= birdsw(secondindex,1);
				birdsecond(2)<= birdsw(secondindex,2);
				birdsecond(3)<= birdsw(secondindex,3);
				birdsecond(4)<= birdsw(secondindex,4);
				birdsecond(5)<= birdsw(secondindex,5);
				birdsecond(6)<= birdsw(secondindex,6);
				birdsecond(7)<= birdsw(secondindex,7);
				birdsecond(8)<= birdsw(secondindex,8);
				birdsecond(9)<= birdsw(secondindex,9);
				birdsecond(10)<= birdsw(secondindex,10);
				birdsecond(11)<= birdsw(secondindex,11);
				birdsecond(12)<= birdsw(secondindex,12);
				birdsecond(13)<= birdsw(secondindex,13);
				birdsecond(14)<= birdsw(secondindex,14);
				
				----best 2 scores calculated
				----genetic algorithm 
				-- 1 stay same
				-- 2 1st + 1/64 mutation 
				-- 3 1st+ 1/16 mutation 
				-- 4 1st+ 1/8 mutation 
				-- 5 2nd+ 1/8 mutation 
				-- 6 (1st+2nd)/2+ 1/32 mutation 
				-- 7 (1st+2nd)/2+ 1/16 mutation 
				-- 8 (1st+2nd)/2+ 1/8 mutation 
				-- 9 random genes
				--10 random genes
				
				
				--First bird stay same
				currentbird:=0;
				birdsw(currentbird,0)<=birdwinner(0);
				birdsw(currentbird,1)<=birdwinner(1);
				birdsw(currentbird,2)<=birdwinner(2);
				birdsw(currentbird,3)<=birdwinner(3);
				birdsw(currentbird,4)<=birdwinner(4);
				birdsw(currentbird,5)<=birdwinner(5);
				birdsw(currentbird,6)<=birdwinner(6);
				birdsw(currentbird,7)<=birdwinner(7);
				birdsw(currentbird,8)<=birdwinner(8);
				birdsw(currentbird,9)<=birdwinner(9);
				birdsw(currentbird,10)<=birdwinner(10);
				birdsw(currentbird,11)<=birdwinner(11);
				birdsw(currentbird,12)<=birdwinner(12);
				birdsw(currentbird,13)<=birdwinner(13);
				birdsw(currentbird,14)<=birdwinner(14);
				
				--1+1/64
				currentbird:=1;
				numbdivider:=64;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,0)<=birdwinner(0)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,1)<=birdwinner(1)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,2)<=birdwinner(2)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,3)<=birdwinner(3)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,4)<=birdwinner(4)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,5)<=birdwinner(5)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,6)<=birdwinner(6)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,7)<=birdwinner(7)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,8)<=birdwinner(8)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,9)<=birdwinner(9)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,10)<=birdwinner(10)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,11)<=birdwinner(11)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,12)<=birdwinner(12)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,13)<=birdwinner(13)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,14)<=birdwinner(14)+(to_integer(unsigned(q))-32768)/numbdivider;
				--1+1/16
				currentbird:=2;
				numbdivider:=16;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,0)<=birdwinner(0)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,1)<=birdwinner(1)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,2)<=birdwinner(2)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,3)<=birdwinner(3)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,4)<=birdwinner(4)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,5)<=birdwinner(5)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,6)<=birdwinner(6)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,7)<=birdwinner(7)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,8)<=birdwinner(8)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,9)<=birdwinner(9)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,10)<=birdwinner(10)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,11)<=birdwinner(11)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,12)<=birdwinner(12)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,13)<=birdwinner(13)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,14)<=birdwinner(14)+(to_integer(unsigned(q))-32768)/numbdivider;
				
				
				--1+1/8
				currentbird:=3;
				numbdivider:=8;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,0)<=birdwinner(0)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,1)<=birdwinner(1)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,2)<=birdwinner(2)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,3)<=birdwinner(3)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,4)<=birdwinner(4)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,5)<=birdwinner(5)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,6)<=birdwinner(6)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,7)<=birdwinner(7)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,8)<=birdwinner(8)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,9)<=birdwinner(9)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,10)<=birdwinner(10)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,11)<=birdwinner(11)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,12)<=birdwinner(12)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,13)<=birdwinner(13)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,14)<=birdwinner(14)+(to_integer(unsigned(q))-32768)/numbdivider;
				
				--2+1/8
				currentbird:=4;
				numbdivider:=8;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,0)<=birdsecond(0)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,1)<=birdsecond(1)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,2)<=birdsecond(2)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,3)<=birdsecond(3)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,4)<=birdsecond(4)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,5)<=birdsecond(5)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,6)<=birdsecond(6)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,7)<=birdsecond(7)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,8)<=birdsecond(8)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,9)<=birdsecond(9)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,10)<=birdsecond(10)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,11)<=birdsecond(11)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,12)<=birdsecond(12)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,13)<=birdsecond(13)+(to_integer(unsigned(q))-32768)/numbdivider;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,14)<=birdsecond(14)+(to_integer(unsigned(q))-32768)/numbdivider;
				
				--(1+2)/2 +1/32
				currentbird:=5;		
				--numbdivider:=8;
				q <= q(14 downto 0) & n3; --new random			
				birdsw(currentbird,0)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,1)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,2)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,3)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,4)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,5)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,6)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,7)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,8)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,9)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,10)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,11)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,12)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,13)<=to_integer(unsigned(q))-32768;
				q <= q(14 downto 0) & n3; --new random					
				birdsw(currentbird,14)<=to_integer(unsigned(q))-32768;
				
				--(1+2)/2 +1/16
--				currentbird:=6;
--				numbdivider:=16;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,0)<=(birdsecond(0)+birdwinner(0))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,1)<=(birdsecond(1)+birdwinner(1))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,2)<=(birdsecond(2)+birdwinner(2))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,3)<=(birdsecond(3)+birdwinner(3))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,4)<=(birdsecond(4)+birdwinner(4))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,5)<=(birdsecond(5)+birdwinner(5))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,6)<=(birdsecond(6)+birdwinner(6))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,7)<=(birdsecond(7)+birdwinner(7))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,8)<=(birdsecond(8)+birdwinner(8))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,9)<=(birdsecond(9)+birdwinner(9))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,10)<=(birdsecond(10)+birdwinner(10))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,11)<=(birdsecond(11)+birdwinner(11))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,12)<=(birdsecond(12)+birdwinner(12))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,13)<=(birdsecond(13)+birdwinner(13))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,14)<=(birdsecond(14)+birdwinner(14))/2+to_integer(unsigned(q))/numbdivider;
--				
--				--(1+2)/2 +1/8
--				currentbird:=7;
--				numbdivider:=8;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,0)<=(birdsecond(0)+birdwinner(0))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,1)<=(birdsecond(1)+birdwinner(1))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,2)<=(birdsecond(2)+birdwinner(2))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,3)<=(birdsecond(3)+birdwinner(3))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,4)<=(birdsecond(4)+birdwinner(4))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,5)<=(birdsecond(5)+birdwinner(5))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,6)<=(birdsecond(6)+birdwinner(6))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,7)<=(birdsecond(7)+birdwinner(7))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,8)<=(birdsecond(8)+birdwinner(8))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,9)<=(birdsecond(9)+birdwinner(9))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,10)<=(birdsecond(10)+birdwinner(10))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,11)<=(birdsecond(11)+birdwinner(11))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,12)<=(birdsecond(12)+birdwinner(12))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,13)<=(birdsecond(13)+birdwinner(13))/2+to_integer(unsigned(q))/numbdivider;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,14)<=(birdsecond(14)+birdwinner(14))/2+to_integer(unsigned(q))/numbdivider;
--				
--				--random birds 
--				currentbird:=8;
--				--numbdivider:=8;
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,0)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,1)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,2)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,3)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,4)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,5)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,6)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,7)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,8)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,9)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,10)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,11)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,12)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,13)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,14)<=to_integer(unsigned(q));
--				--random birds 
--				currentbird:=9;
--				--numbdivider:=8;
--			
--
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,1)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,2)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,3)<=to_integer(unsigned(q)); ---19 LAB usage 
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,4)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,5)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,6)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,7)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,8)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,9)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,10)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,11)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,12)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,13)<=to_integer(unsigned(q));
--				q <= q(14 downto 0) & n3; --new random					
--				birdsw(currentbird,14)<=to_integer(unsigned(q));
--				
				--ALL BIRD WEIGHTS ASSIGNED
				--reset setting for new generation 
				
				--generation<=generation+1;
				deathbirds<=0;
				--bird reset
				currentbird:=0;	
				birdsacc(currentbird)<=0;
				birdsspeed(currentbird)<=0;
				birdsscore(currentbird)<=0;
				birdsactive(currentbird)<=1;
				birdsangle(currentbird) <= 0; --initial rotation angle
				birdsy(currentbird)     <= 220;--y reset
				birdsybig(currentbird)  <= 220 * 64;--ybig reset
				--bird reset
				currentbird:=1;	
				birdsacc(currentbird)<=0;
				birdsspeed(currentbird)<=0;
				birdsscore(currentbird)<=0;
				birdsactive(currentbird)<=1;
				birdsangle(currentbird) <= 0; --initial rotation angle
				birdsy(currentbird)     <= 220;--y reset
				birdsybig(currentbird)  <= 220 * 64;--ybig reset
				--bird reset
				currentbird:=2;	
				birdsacc(currentbird)<=0;
				birdsspeed(currentbird)<=0;
				birdsscore(currentbird)<=0;
				birdsactive(currentbird)<=1;
				birdsangle(currentbird) <= 0; --initial rotation angle
				birdsy(currentbird)     <= 220;--y reset
				birdsybig(currentbird)  <= 220 * 64;--ybig reset
				--bird reset
				currentbird:=3;	
				birdsacc(currentbird)<=0;
				birdsspeed(currentbird)<=0;
				birdsscore(currentbird)<=0;
				birdsactive(currentbird)<=1;
				birdsangle(currentbird) <= 0; --initial rotation angle
				birdsy(currentbird)     <= 220;--y reset
				birdsybig(currentbird)  <= 220 * 64;--ybig reset
				--bird reset
				currentbird:=4;	
				birdsacc(currentbird)<=0;
				birdsspeed(currentbird)<=0;
				birdsscore(currentbird)<=0;
				birdsactive(currentbird)<=1;
				birdsangle(currentbird) <= 0; --initial rotation angle
				birdsy(currentbird)     <= 220;--y reset
				birdsybig(currentbird)  <= 220 * 64;--ybig reset
				--bird reset
				currentbird:=5;	
				birdsacc(currentbird)<=0;
				birdsspeed(currentbird)<=0;
				birdsscore(currentbird)<=0;
				birdsactive(currentbird)<=1;
				birdsangle(currentbird) <= 0; --initial rotation angle
				birdsy(currentbird)     <= 220;--y reset
				birdsybig(currentbird)  <= 220 * 64;--ybig reset
				--bird reset
--				currentbird:=6;	
--				birdsacc(currentbird)<=0;
--				birdsspeed(currentbird)<=0;
--				birdsscore(currentbird)<=0;
--				birdsactive(currentbird)<=1;
--				birdsangle(currentbird) <= 0; --initial rotation angle
--				birdsy(currentbird)     <= 220;--y reset
--				birdsybig(currentbird)  <= 220 * 64;--ybig reset
--				--bird reset
--				currentbird:=7;	
--				birdsacc(currentbird)<=0;
--				birdsspeed(currentbird)<=0;
--				birdsscore(currentbird)<=0;
--				birdsactive(currentbird)<=1;
--				birdsangle(currentbird) <= 0; --initial rotation angle
--				birdsy(currentbird)     <= 220;--y reset
--				birdsybig(currentbird)  <= 220 * 64;--ybig reset
--				--bird reset
--				currentbird:=8;	
--				birdsacc(currentbird)<=0;
--				birdsspeed(currentbird)<=0;
--				birdsscore(currentbird)<=0;
--				birdsactive(currentbird)<=1;
--				birdsangle(currentbird) <= 0; --initial rotation angle
--				birdsy(currentbird)     <= 220;--y reset
--				birdsybig(currentbird)  <= 220 * 64;--ybig reset
--				--bird reset
--				currentbird:=9;	
--				birdsacc(currentbird)<=0;
--				birdsspeed(currentbird)<=0;
--				birdsscore(currentbird)<=0;
--				birdsactive(currentbird)<=1;
--				birdsangle(currentbird) <= 0; --initial rotation angle
--				birdsy(currentbird)     <= 220;--y reset
--				birdsybig(currentbird)  <= 220 * 64;--ybig reset
				
				pipex(0)<=237+1896;
				pipex(1)<=474+1896;
				pipex(2)<=711+1896;
				
				
				--PİPES RESet
				
				
				end if;--if41
				
				-----------
				--cloud movements
				
				groundpos<=groundpos+gamexspeed;
				if(groundpos>5000000) then
				groundpos<=0;
				end if;
				
				birdsangle(0)<=45;
				cloudpos_xbig(0) <= cloudpos_xbig(0) + cloudspeed(0);--uzak
				cloudpos_xbig(1) <= cloudpos_xbig(1) + cloudspeed(1);--orta
				cloudpos_xbig(2) <= cloudpos_xbig(2) + cloudspeed(2);--yakın
				cloudpos_x(0)    <= cloudpos_xbig(0)/64;
				cloudpos_x(1)    <= cloudpos_xbig(1)/64;
				cloudpos_x(2)    <= cloudpos_xbig(2)/64;
				q                <= q(14 downto 0) & n3; --new random
				--cloudpos_ybig(0)<=to_integer(signed(q));
				cloudpos_y(0) <= cloudpos_ybig(0)/64;
				cloudpos_y(1) <= cloudpos_ybig(1)/64;
				cloudpos_y(2) <= cloudpos_ybig(2)/64;
				if pipemove(0)<0 and pipex(0)<640 then
				pipemove(0)<= pipemove(0)+4;
				end if;
				
				if pipemove(1)<0 and pipex(1)<640 then
				pipemove(1)<= pipemove(1)+4;
				end if;
				
				if pipemove(2)<0 and pipex(2)<640 then
				pipemove(2)<= pipemove(2)+4;
				end if;
				
				pipegap<=80+sinlookup((groundpos*5)mod 360)/8192;
				
				if (cloudpos_x(0) > 740) then--if23
					cloudpos_xbig(0) <= - 6400;
				end if;--if23
				if (cloudpos_x(1) > 840) then--if24
					cloudpos_xbig(1) <= - 6400;
				end if;--if24
				if (cloudpos_x(2) > 950) then--if25
					cloudpos_xbig(2) <= - 6400;
				end if;--if25
				---COLLISION DETECTION
				--debug1 <= 0;

				--gamestate<=4;
				refresh_tick <= '0';
			end if;--if20
		end if;-- end game step if0
		---game draw event
		--x 50 y 100
		x       <= x_now;
		y       <= y_now;
		rgb_reg <= "000000000000000000000000";
		rgb_redt   := 0;
		rgb_greent := 0;
		rgb_bluet  := 0;
		if (x > 0 and x < 640 and y > 0 and y < 480) then --if14 --and (prex/=x or prey/=y)
			rgb_red   <= 0;
			rgb_green <= 0;
			rgb_blue  <= 0;
			
			--rgb_next <= std_logic_vector(to_signed(image_bg(x/20,y/20)/2,7));--rgb_next
			-- rgb_red <= image_bg(x/20,y/20)/32*85;
			-- rgb_green<= ((image_bg(x/20,y/20) mod 32)/8)*85;
			-- rgb_blue<= ((image_bg(x/20,y/20) mod 8)/2)*85;
			--
			---sky draw
			rgb_red   <= 0;
			rgb_green <= 170;
			rgb_blue  <= 255;
			
			--3rd cloud
			if (y > cloudpos_y(2) and y < cloudpos_y(2) + 12 * 3 + 1 and x > cloudpos_x(2) and x < cloudpos_x(2) + 17 * 3 + 1) then--if30
				isalpha := image_cloud(((x - cloudpos_x(2))/3), ((y - cloudpos_y(2) - 1)/3)) mod 2;
				if isalpha /= 0 then --if31
					rgb_redt   := image_cloud(((x - cloudpos_x(2))/3), ((y - cloudpos_y(2) - 1)/3))/32 * 85;
					rgb_greent := ((image_cloud(((x - cloudpos_x(2))/3), ((y - cloudpos_y(2) - 1)/3)) mod 32)/8) * 85;
					rgb_bluet  := ((image_cloud(((x - cloudpos_x(2))/3), ((y - cloudpos_y(2) - 1)/3)) mod 8)/2) * 85;
					if (rgb_green mod 85 = 0 and rgb_red mod 85 = 0) then
						
						
						rgb_red   <= (rgb_red * (64 - cloudalpha(2)) + rgb_redt * (cloudalpha(2)))/64;
						rgb_green <= (rgb_green * (64 - cloudalpha(2)) + rgb_greent * (cloudalpha(2)))/64;
						rgb_blue  <= (rgb_blue * (64 - cloudalpha(2)) + rgb_bluet * (cloudalpha(2)))/64;
					
					
					end if;
				end if; --if31
			end if;--if30
			---clouddrawend
			--2nd cloud
			if (y > cloudpos_y(1) and y < cloudpos_y(1) + 12 * 5 + 1 and x > cloudpos_x(1) and x < cloudpos_x(1) + 17 * 5 + 1) then--if28
				isalpha := image_cloud(((x - cloudpos_x(1))/5), ((y - cloudpos_y(1) - 1)/5)) mod 2;
				if isalpha /= 0 then --if29
					rgb_redt   := image_cloud(((x - cloudpos_x(1))/5), ((y - cloudpos_y(1) - 1)/5))/32 * 85;
					rgb_greent := ((image_cloud(((x - cloudpos_x(1))/5), ((y - cloudpos_y(1) - 1)/5)) mod 32)/8) * 85;
					rgb_bluet  := ((image_cloud(((x - cloudpos_x(1))/5), ((y - cloudpos_y(1) - 1)/5)) mod 8)/2) * 85;
					rgb_red   <= (rgb_red * (64 - cloudalpha(1)) + rgb_redt * (cloudalpha(1)))/64;
					rgb_green <= (rgb_green * (64 - cloudalpha(1)) + rgb_greent * (cloudalpha(1)))/64;
					rgb_blue  <= (rgb_blue * (64 - cloudalpha(1)) + rgb_bluet * (cloudalpha(1)))/64;
				end if; --if29
			end if;--if28
			------
			---1st cloud draw
			if (y > cloudpos_y(0) and y < cloudpos_y(0) + 12 * 8 + 1 and x > cloudpos_x(0) and x < cloudpos_x(0) + 17 * 8 + 1) then--if26
				isalpha := image_cloud(((x - cloudpos_x(0) - 1)/8), ((y - cloudpos_y(0) - 1)/8)) mod 2;
				if isalpha /= 0 then --if27
					rgb_redt   := image_cloud(((x - cloudpos_x(0) - 1)/8), ((y - cloudpos_y(0) - 1)/8))/32 * 85;
					rgb_greent := ((image_cloud(((x - cloudpos_x(0) - 1)/8), ((y - cloudpos_y(0) - 1)/8)) mod 32)/8) * 85;
					rgb_bluet  := ((image_cloud(((x - cloudpos_x(0) - 1)/8), ((y - cloudpos_y(0) - 1)/8)) mod 8)/2) * 85;
					rgb_red   <= (rgb_red * (64 - cloudalpha(0)) + rgb_redt * (cloudalpha(0)))/64;
					rgb_green <= (rgb_green * (64 - cloudalpha(0)) + rgb_greent * (cloudalpha(0)))/64;
					rgb_blue  <= (rgb_blue * (64 - cloudalpha(0)) + rgb_bluet * (cloudalpha(0)))/64;
				end if; --if27
			end if;--if26
			--------
			
			
		---solidcloud	
			 if(y>mountainposy-56 and y<mountainposy+5) then--if18
			isalpha := image_mount((x/4 + (mountainpos/2048))mod 20, (y - mountainposy + 56)/4);
			if (isalpha = 17) then --if19
				rgb_red   <= 170;
				rgb_green <= 255;
				rgb_blue  <= 255;
			elsif isalpha = 59 then
				rgb_red   <= 255;
				rgb_green <= 255;
				rgb_blue  <= 255;
			end if;--if19
		end if;--if18
		--buildings
		if (y > mountainposy - 32 and y < mountainposy + 9) then--if18
			isalpha := image_build((x/2 + (buildingpos/256))mod 20, (y - mountainposy + 32)/2) mod 2;
			if isalpha /= 0 then --if19
				rgb_redt   := image_build((x/2 + (buildingpos/256))mod 20, (y - mountainposy + 32)/2)/32 * 85;
				rgb_greent := ((image_build((x/2 + (buildingpos/256))mod 20, (y - mountainposy + 32)/2) mod 32)/8) * 85;
				rgb_bluet  := ((image_build((x/2 + (buildingpos/256))mod 20, (y - mountainposy + 32)/2) mod 8)/2) * 85;
				rgb_red   <= rgb_redt; --(rgb_red*(1024-200) + rgb_redt*(200))/1024;
				rgb_green <= rgb_greent;--(rgb_green*(1024-200) + rgb_greent*(200))/1024;
				rgb_blue  <= rgb_bluet; --(rgb_blue*(1024-200) + rgb_bluet*(200))/1024;
			end if; --if19
		end if;--if18
		--small buildings
		if (y > mountainposy - 16 and y < mountainposy + 5) then--if18
			isalpha := image_build((x + (mountainpos/128))mod 20, (y - mountainposy + 16)) mod 2;
			if isalpha /= 0 then --if19
				rgb_redt   := image_build((x + (mountainpos/128))mod 20, (y - mountainposy + 16))/32 * 85;
				rgb_bluet  := ((image_build((x + (mountainpos/128))mod 20, (y - mountainposy + 16)) mod 32)/8) * 85;
				rgb_greent := ((image_build((x + (mountainpos/128))mod 20, (y - mountainposy + 16)) mod 8)/2) * 85;
				if ((x + (mountainpos/128))/20) mod 4 = 0 then
					rgb_red   <= rgb_redt; --(rgb_red*(1024-200) + rgb_redt*(200))/1024;
					rgb_green <= rgb_greent;--(rgb_green*(1024-200) + rgb_greent*(200))/1024;
					rgb_blue  <= rgb_bluet; --(rgb_blue*(1024-200) + rgb_bluet*(200))/1024;
				elsif ((x + (mountainpos/128))/20) mod 4 = 1 then
					rgb_red   <= 185;
					rgb_green <= rgb_greent;
					rgb_blue  <= rgb_redt;
				elsif ((x + (mountainpos/128))/20) mod 4 = 2 then
					rgb_red   <= rgb_greent;
					rgb_green <= rgb_bluet;
					rgb_blue  <= rgb_redt;
				else
					rgb_red   <= rgb_redt;
					rgb_green <= rgb_bluet;
					rgb_blue  <= rgb_greent;
				end if;
			end if; --if19
		end if;--if18
		--mountain draw
		if (y > mountainposy and y < mountainposy + 31) then--if15
			isalpha := image_mount((x/2 + (mountainpos/64))mod 26, (y - mountainposy)/3) mod 2;
			if isalpha /= 0 then --if16
				rgb_redt   := image_mount((x/2 + (mountainpos/64))mod 26, (y - mountainposy)/3)/32 * 85;
				rgb_greent := ((image_mount((x/2 + (mountainpos/64))mod 26, (y - mountainposy)/3) mod 32)/8) * 85;
				rgb_bluet  := ((image_mount((x/2 + (mountainpos/64))mod 26, (y - mountainposy)/3) mod 8)/2) * 85;
				rgb_red   <= rgb_redt; --(rgb_red*(1024-200) + rgb_redt*(200))/1024;
				rgb_green <= rgb_greent;--(rgb_green*(1024-200) + rgb_greent*(200))/1024;
				rgb_blue  <= rgb_bluet; --(rgb_blue*(1024-200) + rgb_bluet*(200))/1024;
			end if; --if16
		end if;--if15
		-- grass draw
		if (y > mountainposy + 30) then --if17
			rgb_red   <= 85;
			rgb_green <= 255;
			rgb_blue  <= 85;
		end if;--if17
		
		
		--ground
		if (y > mountainposy+115 and y < mountainposy+130 ) then--if18
			isalpha := image_ground(  (x/2 + groundpos/2 )  mod 7, y /2   ) mod 2;
			if isalpha /= 0 then --if19
				rgb_redt   := image_ground(  (x/2 +groundpos/2)  mod 7, (y-mountainposy-115) /2   )/32 * 85;
				rgb_greent := ((image_ground(  (x/2 +groundpos/2)  mod 7, (y-mountainposy-115) /2   ) mod 32)/8) * 85;
				rgb_bluet  := ((image_ground(  (x/2 +groundpos/2)  mod 7, (y-mountainposy-115) /2   ) mod 8)/2) * 85;
				rgb_red   <= rgb_redt; --(rgb_red*(1024-200) + rgb_redt*(200))/1024;
				rgb_green <= rgb_greent;--(rgb_green*(1024-200) + rgb_greent*(200))/1024;
				rgb_blue  <= rgb_bluet; --(rgb_blue*(1024-200) + rgb_bluet*(200))/1024;
			end if; --if19
		end if;--if18
		if (y>=mountainposy+130)then
		
			rgb_red   <= 170;
			rgb_green <= 170;
			rgb_blue  <= 85;
		
		end if;
		
		
		
		
		----Bird draw
		--bird0
		--- açılı döndürme  
		--
		-- ((x - birdsx(currentbird))/2 *coslookup( birdsangle(0)))/65536 +  (y - birdsy(currentbird))/2* sinlookup(birdsangle(0))/65536 ,(-(x- birdsx(currentbird))/2 *sinlookup( birdsangle(0)))/65536 +  (y - birdsy(currentbird))/2* coslookup(birdsangle(0))/65536     
		currentbird := 0;
		if (x > birdsx(currentbird) and x < (birdsx(currentbird) + 34) and y > birdsy(currentbird) and y < (birdsy(currentbird) + 24)) then--if13
			isalpha := image_flappy( (x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2      ) mod 2;
			if isalpha /= 0 then --if12
				rgb_redt   := image_flappy( (x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2          )/32 * 85;
				rgb_greent := ((image_flappy(  (x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2       ) mod 32)/8) * 85;
				rgb_bluet  := ((image_flappy(  (x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2              ) mod 8)/2) * 85;
				rgb_red   <= rgb_redt;
				rgb_green <= rgb_greent;
				rgb_blue  <= rgb_bluet;
			end if; --if12
		end if;--if13
		if(manual='0') then 
	
	--bird1
		currentbird := 1;
		if (x > birdsx(currentbird) and x < (birdsx(currentbird) + 34) and y > birdsy(currentbird) and y < (birdsy(currentbird) + 24)) then--if13
			isalpha := image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 2;
			if isalpha /= 0 then --if12
				rgb_redt   := image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2)/32 * 85;
				rgb_greent := ((image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 32)/8) * 85;
				rgb_bluet  := ((image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 8)/2) * 85;
				rgb_red   <= rgb_greent;
				rgb_green <= rgb_redt;
				rgb_blue  <= rgb_bluet;
			end if; --if12
		end if;--if13
		--bird2
		currentbird := 2;
		if (x > birdsx(currentbird) and x < (birdsx(currentbird) + 34) and y > birdsy(currentbird) and y < (birdsy(currentbird) + 24)) then--if13
			isalpha := image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 2;
			if isalpha /= 0 then --if12
				rgb_redt   := image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2)/32 * 85;
				rgb_greent := ((image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 32)/8) * 85;
				rgb_bluet  := ((image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 8)/2) * 85;
				rgb_red   <= rgb_bluet;
				rgb_green <= rgb_greent;
				rgb_blue  <= rgb_redt;
			end if; --if12
		end if;--if13
		--bird3
		currentbird := 3;
		if (x > birdsx(currentbird) and x < (birdsx(currentbird) + 34) and y > birdsy(currentbird) and y < (birdsy(currentbird) + 24)) then--if13
			isalpha := image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 2;
			if isalpha /= 0 then --if12
				rgb_redt   := image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2)/32 * 85;
				rgb_greent := ((image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 32)/8) * 85;
				rgb_bluet  := ((image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 8)/2) * 85;
				rgb_red   <= rgb_redt;
				rgb_green <= rgb_bluet;
				rgb_blue  <= rgb_greent;
			end if; --if12
		end if;--if13
		--bird4
		currentbird := 4;
		if (x > birdsx(currentbird) and x < (birdsx(currentbird) + 34) and y > birdsy(currentbird) and y < (birdsy(currentbird) + 24)) then--if13
			isalpha := image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 2;
			if isalpha /= 0 then --if12
				rgb_redt   := image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2)/32 * 85;
				rgb_greent := ((image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 32)/8) * 85;
				rgb_bluet  := ((image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 8)/2) * 85;
				rgb_red   <= rgb_bluet;
				rgb_green <= rgb_redt;
				rgb_blue  <= rgb_greent;
			end if; --if12
		end if;--if13
		--bird5
		currentbird := 5;
		if (x > birdsx(currentbird) and x < (birdsx(currentbird) + 34) and y > birdsy(currentbird) and y < (birdsy(currentbird) + 24)) then--if13
			isalpha := image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 2;
			if isalpha /= 0 then --if12
				rgb_redt   := image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2)/32 * 85;
				rgb_greent := ((image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 32)/8) * 85;
				rgb_bluet  := ((image_flappy((x - birdsx(currentbird))/2, (y - birdsy(currentbird))/2) mod 8)/2) * 85;
				rgb_red   <= rgb_greent;
				rgb_green <= rgb_bluet;
				rgb_blue  <= rgb_redt;
			end if; --if12
		end if;--if13
end if;
		-----PIPE DRAW----
		--Ppipe1
		if (x > pipex(0) and x < pipex(0) + 73) then--if33
			if (y > (pipemiddle(0)+pipemove(0) + pipegap) or y < (pipemiddle(0)-pipemove(0) - pipegap )) then
				rgb_red   <= image_pipe((x - pipex(0))/3)/32 * 85;
				rgb_green <= ((image_pipe((x - pipex(0))/3) mod 32)/8) * 85;
				rgb_blue  <= ((image_pipe((x - pipex(0))/3) mod 8)/2) * 85;
			end if;
		end if;--if33
		----pipe2
		if (x > pipex(1) and x < pipex(1) + 73) then--if33
			if (y > (pipemiddle(1)+pipemove(1) + pipegap) or y < (pipemiddle(1)-pipemove(1) - pipegap )) then
				rgb_red   <= image_pipe((x - pipex(1))/3)/32 * 85;
				rgb_green <= ((image_pipe((x - pipex(1))/3) mod 32)/8) * 85;
				rgb_blue  <= ((image_pipe((x - pipex(1))/3) mod 8)/2) * 85;
			end if;
		end if;--if33
		--pipe3
		if (x > pipex(2) and x < pipex(2) + 73) then--if33
			if (y > (pipemiddle(2)+pipemove(2) + pipegap) or y < (pipemiddle(2)-pipemove(2) - pipegap )) then--if34
				rgb_red   <= image_pipe((x - pipex(2))/3)/32 * 85;
				rgb_green <= ((image_pipe((x - pipex(2))/3) mod 32)/8) * 85;
				rgb_blue  <= ((image_pipe((x - pipex(2))/3) mod 8)/2) * 85;
			end if;--if34
		end if;--if3
		----pipe bitti ---
		rgb_reg <= std_logic_vector(to_unsigned(rgb_red, 8)) & std_logic_vector(to_unsigned(rgb_green, 8)) & std_logic_vector(to_unsigned(rgb_blue, 8));
		--prex<=x;
		--prey<=y;
		else--if14
		rgb_reg <= "000000000000000000000000";
	end if;--if14
	rgb <= rgb_reg;
	-- rgb_reg<=rgb_next(6)&rgb_next(5)&rgb_next(6)&rgb_next(5)&rgb_next(6)&rgb_next(5)&rgb_next(6)&rgb_next(5) & rgb_next(4)&rgb_next(3)&rgb_next(4)&rgb_next(3)&rgb_next(4)&rgb_next(3)&rgb_next(4)&rgb_next(3)& rgb_next(2)&rgb_next(1)&rgb_next(2)&rgb_next(1)&rgb_next(2)&rgb_next(1)&rgb_next(2)&rgb_next(1);
	end if;--if11
end process;
---CONCURRENT RANDOM PROCESS required by LFSR
n1 <= q(15) xor q(13);
n2 <= n1 xor q(11); --
n3 <= n2 xor q(10);
end Behavioral;