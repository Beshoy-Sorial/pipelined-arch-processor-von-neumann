library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg32 is
    Port (
        clk    : in  STD_LOGIC;                     -- Clock signal
        reset  : in  STD_LOGIC;                     -- Asynchronous reset
        en     : in  STD_LOGIC;                     -- Write enable
        d      : in  STD_LOGIC_VECTOR(31 downto 0); -- 32-bit Data input
        q      : out STD_LOGIC_VECTOR(31 downto 0)  -- 32-bit Data output
    );
end reg32;

architecture Behavioral of reg32 is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset the output to all zeros
            q <= (others => '0');
        elsif rising_edge(clk) then
            -- Only update the output if Enable is high
            if en = '1' then
                q <= d;
            end if;
        end if;
    end process;
end Behavioral;