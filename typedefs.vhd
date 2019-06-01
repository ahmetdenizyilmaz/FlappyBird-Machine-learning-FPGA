library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package typedefs is
---10 birds at the time

  
type lookuptable is array(0 to 359) of integer; 
type weight is array(0 to 14) of integer;
type weights is array(0 to 9 ,0 to 14) of integer;--16 bits = 2^16 = 65536  15 weights
type neurons is array(0 to 9, 0 to 7) of integer;-- 16bits 2input 5 neurons (1 layer) 1 out
type tenintarray is array(0 to 9) of integer; 

type threeintarray is array(0 to 2) of integer;
type flappyimage is array (0 to 17-1, 0 to 12-1) of integer;
type mountimage is array (0 to 26-1, 0 to 10-1) of integer;
type buildimage is array (0 to 20-1, 0 to 21-1) of integer;
type sayiimage is array (0 to 50-1, 0 to 6-1) of integer;
type pipeimage is array (0 to 23) of integer;
type groundimage is array (0 to 7-1, 0 to 7-1) of integer;

type screen is array(0 to 127,0 to 95) of integer;

end package typedefs;