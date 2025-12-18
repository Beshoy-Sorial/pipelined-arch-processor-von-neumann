library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sign_extend is
    port (
        en      : in  std_logic;
        in16    : in  std_logic_vector(15 downto 0);
        out32   : out std_logic_vector(31 downto 0)
    );
end sign_extend;

architecture rtl of sign_extend is
begin
    process(in16, en)
    begin
        if en = '1' then
            out32 <= std_logic_vector(
                        resize(signed(in16), 32)
                     );
        end if;
    end process;
end rtl;
