library IEEE;
 use IEEE.STD_LOGIC_1164.ALL;
 use IEEE.STD_LOGIC_ARITH.ALL;
 use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Score is
     Port (       
						input : in std_logic_vector(11 downto 0);						
	               score1 : out Std_logic_vector(7 downto 0);
						score2 : out Std_logic_vector(7 downto 0);
						score3 : out Std_logic_vector(7 downto 0));
      end Score;

architecture Behavioral of Score is
begin
with input(3 downto 0) select
score1 <=

"1000000" when "0000",
"1001111" when "0001",
"0100100" when "0010",
"0110000" when "0011",
"0011001" when "0100",
"0010010" when "0101",
"0000010" when "0110",
"0111000" when "0111",
"0000000" when "1000",
"0011000" when "1001",
"0100000" when "1010",
"0000011" when "1011",
"1000110" when "1100",
"0100001" when "1101",
"0000110" when "1110",
"0001110" when others;
with input(7 downto 4) select
score2 <=

"1000000" when "0000",
"1001111" when "0001",
"0100100" when "0010",
"0110000" when "0011",
"0011001" when "0100",
"0010010" when "0101",
"0000010" when "0110",
"0111000" when "0111",
"0000000" when "1000",
"0011000" when "1001",
"0100000" when "1010",
"0000011" when "1011",
"1000110" when "1100",
"0100001" when "1101",
"0000110" when "1110",
"0001110" when others;
with input(11 downto 8) select
score3 <=

"1000000" when "0000",
"1001111" when "0001",
"0100100" when "0010",
"0110000" when "0011",
"0011001" when "0100",
"0010010" when "0101",
"0000010" when "0110",
"0111000" when "0111",
"0000000" when "1000",
"0011000" when "1001",
"0100000" when "1010",
"0000011" when "1011",
"1000110" when "1100",
"0100001" when "1101",
"0000110" when "1110",
"0001110" when others;
end behavioral;
