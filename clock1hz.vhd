library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clock1hz is
    Port (
        clk_in : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        clk_out: out STD_LOGIC
    );
end clock1hz;

architecture Behavioral of clock1hz is
    signal temporal: STD_LOGIC;
    signal counter : integer := 0;
begin
    frequency_divider: process (reset, clk_in) begin
        if (reset = '1') then
            temporal <= '0';
            counter <= 0;
        elsif rising_edge(clk_in) then
            if (counter = 24999999) then
                temporal <= NOT(temporal);
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    
    clk_out <= temporal;
end Behavioral;