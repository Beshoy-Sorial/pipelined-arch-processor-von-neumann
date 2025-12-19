library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity one_bit_counter is
    Port ( clk : in STD_LOGIC;
           counter_enable : in STD_LOGIC;
           count_out : out STD_LOGIC);
end one_bit_counter;

architecture Behavioral of one_bit_counter is
    signal count : STD_LOGIC := '0';
begin
    
    process(clk, counter_enable)
    begin
        -- Asynchronous reset when counter_enable goes low
        if counter_enable = '0' then
            count <= '0';
        elsif rising_edge(clk) then
            -- Toggle the counter on each clock edge when enabled
            count <= not count;
        end if;
    end process;
    
    count_out <= count;
    
end Behavioral;