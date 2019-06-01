library ieee;
use ieee.std_logic_1164.all;

entity random_data_generator is
    port (
        por:                in  std_logic;
        sys_clk:            in  std_logic;
        random_flag:        in  std_logic;
        random_data:        out std_logic_vector (15 downto 0)
    );
end entity random_data_generator;

architecture behavioral of random_data_generator is
    signal q:             std_logic_vector(15 downto 0);
    signal n1, n2, n3:    std_logic;
begin
    process (por, sys_clk) -- ADDED por to sensitivity list
    begin
        if por = '0' then 
            q <= "1100111001101010";
        elsif falling_edge(sys_clk) then
            if random_flag = '1' then
            q <= q(14 downto 0) & n3;  -- REMOVED after 10 ns;
            end if;
        end if;
    end process;
    -- MOVED intermediary products to concurrent signal assignments:
    n1 <= q(15) xor q(13);
    n2 <= n1 xor q(11); --  REMOVED after 10 ns;
    n3 <= n2 xor q(10); --  REMOVED after 10 ns;

    random_data <= q;
end architecture behavioral;