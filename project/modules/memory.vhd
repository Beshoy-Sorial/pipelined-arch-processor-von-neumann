LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;              -- Add this
USE IEEE.STD_LOGIC_TEXTIO.ALL;   -- Add this

ENTITY memory IS PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        in_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        out_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        address : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        mem_write : IN STD_LOGIC;
        mem_read : IN STD_LOGIC
);
END ENTITY;

ARCHITECTURE mem_behave OF memory IS
        CONSTANT ADDR_WIDTH : INTEGER := 10;
        CONSTANT DATA_WIDTH : INTEGER := 31;
        TYPE mem_array IS ARRAY(0 to (2 ** ADDR_WIDTH) - 1) OF STD_LOGIC_VECTOR(DATA_WIDTH DOWNTO 0);
        
        -- Function to initialize memory from file
        IMPURE FUNCTION init_memory_from_file(file_name : STRING) RETURN mem_array IS
            FILE init_file : TEXT OPEN READ_MODE IS file_name;
            VARIABLE line_buf : LINE;
            VARIABLE temp_mem : mem_array := (OTHERS => (OTHERS => '0'));
            VARIABLE addr : INTEGER := 0;
            VARIABLE data_val : STD_LOGIC_VECTOR(31 DOWNTO 0);
        BEGIN
            WHILE NOT ENDFILE(init_file) AND addr < 2**ADDR_WIDTH LOOP
                READLINE(init_file, line_buf);
                HREAD(line_buf, data_val);  -- Read hex value
                temp_mem(addr) := data_val;
                addr := addr + 1;
            END LOOP;
            FILE_CLOSE(init_file);
            RETURN temp_mem;
        END FUNCTION;
        
        SIGNAL main_memory : mem_array := init_memory_from_file("./memory.txt");
        
BEGIN
        memo_main : PROCESS (clk, reset)
        BEGIN
                IF (reset = '1') THEN
                        out_data <= (OTHERS => '0');
                        -- Don't reinitialize main_memory here, it's already initialized
                ELSIF rising_edge(clk) THEN
                        IF (mem_write = '1') THEN
                                main_memory(to_integer(unsigned(address))) <= in_data;
                        ELSIF (mem_read = '1') THEN
                                out_data <= main_memory(to_integer(unsigned(address)));
                        END IF;
                END IF;
        END PROCESS memo_main;
END ARCHITECTURE;