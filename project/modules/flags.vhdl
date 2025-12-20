library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Reg3BitStoreRestore is
    Port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        store    : in  STD_LOGIC; -- Save current data to cache
        restore  : in  STD_LOGIC; -- Load data from cache to main
        load     : in  STD_LOGIC; -- Standard write enable
        data_in  : in  STD_LOGIC_VECTOR(2 downto 0);  
        data_out : out STD_LOGIC_VECTOR(2 downto 0)
    );
end Reg3BitStoreRestore;

architecture Behavioral of Reg3BitStoreRestore is
    signal main_reg   : STD_LOGIC_VECTOR(2 downto 0);
    signal shadow_reg : STD_LOGIC_VECTOR(2 downto 0);
begin

    process(clk, rst)
    begin
        if rst = '1' then
            main_reg   <= (others => '0');
            shadow_reg <= (others => '0');
        elsif rising_edge(clk) then
            
            -- Priority 1: Restore old value from Cache
            if restore = '1' then
                main_reg <= shadow_reg;
            
            -- Priority 2: Store current value into Cache
            elsif store = '1' then
                shadow_reg <= main_reg;
            
            -- Priority 3: Standard Load
            elsif load = '1' then
                main_reg <= data_in;
            end if;
            
        end if;
    end process;

    data_out <= main_reg;

end Behavioral;