
library IEEE;
 use IEEE.STD_LOGIC_1164.ALL;
 use IEEE.STD_LOGIC_ARITH.ALL;
 use IEEE.STD_LOGIC_UNSIGNED.ALL;
 use ieee.numeric_std.all;
 use work.typedefs.all;
 
 
 entity Game_controller is
 Port (
 clk: in std_logic;
 inputweights : in weights;
 pipedistancex : in integer;
 pipedistancey : in integer;
 outweights : out weights;
 score: out integer
 
 );
 end Game_controller;
 
 
 
 architecture bhv of Game_controller is
 
--refresh 60fps
signal refresh_reg,refresh_next:integer;
constant refresh_constant:integer:=830000;
signal refresh_tick:std_logic;
signal game_over:std_logic;

 begin
 
 
 ---
 process(clk)
     begin
         if clk'event and clk='1' then
              refresh_reg<=refresh_next;       
         end if;
     end process;

refresh_next<= 0 when refresh_reg= refresh_constant else   refresh_reg+1;
refresh_tick<= '1' when refresh_reg = 0 else '0';








 
 end bhv;