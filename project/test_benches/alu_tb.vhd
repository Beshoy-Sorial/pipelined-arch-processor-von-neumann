LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;

ENTITY alu_tb IS
END ENTITY alu_tb;

ARCHITECTURE behavior OF alu_tb IS
	CONSTANT n : INTEGER := 32; -- 32-bit operands (same as ALU)
	CONSTANT clock_period : TIME := 10 ns;

	SIGNAL clk           : STD_LOGIC := '0';
	SIGNAL reset         : STD_LOGIC := '0';
	SIGNAL data_in1      : STD_LOGIC_VECTOR(n - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL data_in2      : STD_LOGIC_VECTOR(n - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL operation     : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
	SIGNAL counter       : STD_LOGIC := '0';
	SIGNAL data_out      : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
	SIGNAL Restore       : STD_LOGIC;
	SIGNAL store         : STD_LOGIC;
	SIGNAL flag_values   : STD_LOGIC_VECTOR(2 DOWNTO 0);

	-- Test counters
	SIGNAL test_count : INTEGER := 0;
	SIGNAL pass_count : INTEGER := 0;
	SIGNAL fail_count : INTEGER := 0;

	-- Helper function to convert std_logic to string
	FUNCTION sl_to_str(sl : STD_LOGIC) RETURN STRING IS
	BEGIN
		IF sl = '1' THEN
			RETURN "1";
		ELSE
			RETURN "0";
		END IF;
	END FUNCTION;

	-- Helper function for flag interpretation
	FUNCTION flags_to_str(flags : STD_LOGIC_VECTOR(2 DOWNTO 0)) RETURN STRING IS
	BEGIN
		RETURN "N=" & sl_to_str(flags(2)) & " Z=" & sl_to_str(flags(1)) & " C=" & sl_to_str(flags(0));
	END FUNCTION;

BEGIN

	-- Instantiate UUT
	UUT : ENTITY WORK.alu
	GENERIC MAP (n => n)
	PORT MAP (
		reset => reset,
		clk => clk,
		data_in1 => data_in1,
		data_in2 => data_in2,
		operation => operation(3 DOWNTO 0),
		counter => counter,
		data_out => data_out,
		Restore => Restore,
		store => store,
		flag_values => flag_values
	);

	-- Clock generation
	clk_process : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR clock_period / 2;
		clk <= '1';
		WAIT FOR clock_period / 2;
	END PROCESS clk_process;

	-- Stimulus process
	stim_proc: PROCESS

		PROCEDURE test_alu(
			test_name : IN STRING;
			op : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			in1 : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
			in2 : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
			cnt : IN STD_LOGIC;
			expected_out : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
			exp_carry : IN STD_LOGIC := '0';
			exp_zero : IN STD_LOGIC := '0';
			exp_neg : IN STD_LOGIC := '0'
		) IS
		BEGIN
			test_count <= test_count + 1;
			operation <= op;
			data_in1 <= in1;
			data_in2 <= in2;
			counter <= cnt;
			
			WAIT UNTIL rising_edge(clk);
			WAIT FOR 2 ns; -- settle time
			
			IF data_out = expected_out AND 
			   flag_values(0) = exp_carry AND
			   flag_values(1) = exp_zero AND
			   flag_values(2) = exp_neg THEN
				REPORT "[PASS] " & test_name SEVERITY NOTE;
				pass_count <= pass_count + 1;
			ELSE
				REPORT "[FAIL] " & test_name SEVERITY ERROR;
				REPORT "  Expected: " & INTEGER'IMAGE(TO_INTEGER(UNSIGNED(expected_out))) & 
						" (" & flags_to_str(exp_neg & exp_zero & exp_carry) & ")" SEVERITY ERROR;
				REPORT "  Got:      " & INTEGER'IMAGE(TO_INTEGER(UNSIGNED(data_out))) & 
						" (" & flags_to_str(flag_values) & ")" SEVERITY ERROR;
				fail_count <= fail_count + 1;
			END IF;
		END PROCEDURE;

	BEGIN
		-- Initial reset
		reset <= '1';
		WAIT FOR clock_period * 2;
		reset <= '0';
		WAIT FOR clock_period;

		REPORT "========================================" SEVERITY NOTE;
		REPORT "    ALU BASIC TESTBENCH" SEVERITY NOTE;
		REPORT "========================================" SEVERITY NOTE;

		-- Test 0001: ADD Operation
		test_alu("ADD: 5 + 3 = 8", "0001", 
				 STD_LOGIC_VECTOR(TO_UNSIGNED(5, n)),
				 STD_LOGIC_VECTOR(TO_UNSIGNED(3, n)),
				 '0',
				 STD_LOGIC_VECTOR(TO_UNSIGNED(8, n)));

		-- Test 0010: SUB Operation
		test_alu("SUB: 10 - 3 = 7", "0010",
				 STD_LOGIC_VECTOR(TO_UNSIGNED(10, n)),
				 STD_LOGIC_VECTOR(TO_UNSIGNED(3, n)),
				 '0',
				 STD_LOGIC_VECTOR(TO_UNSIGNED(7, n)));

		-- Test 0011: AND Operation
		test_alu("AND: 0xFF AND 0x0F = 0x0F", "0011",
				 X"000000FF",
				 X"0000000F",
				 '0',
				 X"0000000F");

		-- Test 0100: MOV/First
		test_alu("MOV: Pass 0x12345678", "0100",
				 X"12345678",
				 X"87654321",
				 '0',
				 X"12345678");

		-- Test 0101: Second
		test_alu("Second: Output in2 (0x22222222)", "0101",
				 X"11111111",
				 X"22222222",
				 '0',
				 X"22222222");

		-- Test 0110: First until counter (SWAP)
		test_alu("SWAP: Counter=0, select first", "0110",
				 X"AAAAAAAA",
				 X"BBBBBBBB",
				 '0',
				 X"AAAAAAAA");

		test_alu("SWAP: Counter=1, select second", "0110",
				 X"CCCCCCCC",
				 X"DDDDDDDD",
				 '1',
				 X"DDDDDDDD");

		-- Test 0111: SetC
		test_alu("SetC: Set carry flag", "0111",
				 STD_LOGIC_VECTOR(TO_UNSIGNED(100, n)),
				 STD_LOGIC_VECTOR(TO_UNSIGNED(200, n)),
				 '0',
				 STD_LOGIC_VECTOR(TO_UNSIGNED(100, n)),
				 exp_carry => '1');

		-- Test 1000: INC
		test_alu("INC: 5 + 1 = 6", "1000",
				 STD_LOGIC_VECTOR(TO_UNSIGNED(5, n)),
				 STD_LOGIC_VECTOR(TO_UNSIGNED(0, n)),
				 '0',
				 STD_LOGIC_VECTOR(TO_UNSIGNED(6, n)));

		-- Test 1001: NOT
		test_alu("NOT: NOT(0xAAAAAAAA) = 0x55555555", "1001",
				 X"AAAAAAAA",
				 STD_LOGIC_VECTOR(TO_UNSIGNED(0, n)),
				 '0',
				 X"55555555");

		-- Test 1010: Add 2
		test_alu("Add 2: 100 + 2 = 102", "1010",
				 STD_LOGIC_VECTOR(TO_UNSIGNED(100, n)),
				 STD_LOGIC_VECTOR(TO_UNSIGNED(0, n)),
				 '0',
				 STD_LOGIC_VECTOR(TO_UNSIGNED(102, n)));

		-- Test 1011: Restore
		test_alu("Restore: Pass through data (0x99999999)", "1011",
				 X"99999999",
				 STD_LOGIC_VECTOR(TO_UNSIGNED(0, n)),
				 '0',
				 X"99999999");

		WAIT FOR clock_period * 2;

		-- Summary Report
		REPORT "========================================" SEVERITY NOTE;
		REPORT "          TESTBENCH SUMMARY" SEVERITY NOTE;
		REPORT "========================================" SEVERITY NOTE;
		REPORT "Total Tests Run:  " & INTEGER'IMAGE(test_count) SEVERITY NOTE;
		REPORT "Tests Passed:     " & INTEGER'IMAGE(pass_count) SEVERITY NOTE;
		REPORT "Tests Failed:     " & INTEGER'IMAGE(fail_count) SEVERITY NOTE;
		REPORT "========================================" SEVERITY NOTE;

		IF fail_count = 0 THEN
			REPORT "    ALL TESTS PASSED SUCCESSFULL" SEVERITY NOTE;
		ELSE
			REPORT "    SOME TESTS FAILED - CHECK ABOVE" SEVERITY ERROR;
		END IF;
		REPORT "========================================" SEVERITY NOTE;

		WAIT;

	END PROCESS stim_proc;

END ARCHITECTURE behavior;

