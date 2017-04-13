
library ieee;
use ieee.std_logic_1164.all;

entity ControlUnit is
	port(
		clock	: in  std_logic;
		reset	: in  std_logic;
		status: in  std_logic_vector(15 downto 0);
		MFC	: in  std_logic;
		IR		: in  std_logic_vector(15 downto 0);
		
		RF_write	: out std_logic;
		C_select	: out std_logic_vector(1 downto 0);
		B_select : out std_logic;
		Y_select	: out std_logic_vector(1 downto 0);
		ALU_op	: out std_logic_vector(1 downto 0);
		A_inv		: out std_logic;
		B_inv		: out std_logic;
		C_in		: out std_logic;
		MEM_read	: out std_logic;
		MEM_write: out std_logic;
		MA_select: out std_logic;
		IR_enable: out std_logic;
		PC_select: out std_logic_vector(1 downto 0);
		PC_enable: out std_logic;
		INC_select: out std_logic;
		extend	: out std_logic_vector(2 downto 0);
		Status_enable : out std_logic;
		-- for ModelSim debugging only
		debug_state	: out std_logic_vector(2 downto 0)
	);
end ControlUnit;

architecture implementation of ControlUnit is
	signal current_state : std_logic_vector(2 downto 0);
	signal next_state   	: std_logic_vector(2 downto 0);
	signal WMFC				: std_logic;
	signal OP_code			: std_logic_vector(2 downto 0);
	signal OPX				: std_logic_vector(3 downto 0);
	signal N,C,V,Z			: std_logic;
begin
	OP_code <= IR(2 downto 0);
	OPX <= IR(6 downto 3);
	N <= status(3);
	C <= status(2);
	V <= status(1);
	Z <= status(0);

	-- for debugging only
	debug_state <= current_state;

	-- current state DFFs
	process(clock, reset)
	begin
		if (reset = '1') then
			current_state <= "000";
		elsif rising_edge(clock) then
			current_state <= next_state;
		end if;
	end process;

	-- next state function
	process(current_state, WMFC, MFC)
	begin
	case current_state is
	      when "000"  =>  
					next_state <= "001";		-- start with stage 1
	      when "001"  =>  
				if (WMFC='0') then 
					next_state <= "010";   	-- not wait for mem (for clarity, not necessary)
		     elsif (MFC='1') then 
					next_state <= "010";   	-- mem ready
		     else 		
					next_state <= "001";		-- mem not ready
				end if; 
	      when "010"  =>  
					next_state <= "011";
	      when "011"  =>  
					next_state <= "100";
	      when "100"  =>  
				if (WMFC='0') then 
					next_state <= "101";    -- not wait for mem
		     elsif (MFC='1') then 
					next_state <= "101";    -- mem ready
		     else 		
					next_state <= "100"; 	-- mem not ready
				end if;  
	      when "101"  =>  
					next_state <= "001";
	      when others =>  
					next_state <= "000"; 	-- something wrong, reset
	end case;
	end process;

	
	-- Mealy output function
	process(current_state, MFC, OP_code, OPX, N, C, V, Z)
	begin
		-- set all output signals to the default 0
		RF_write <= '0'; C_select <= "00";  B_select <= '0'; Y_select <= "00";
		ALU_op <= "00"; A_inv <= '0'; B_inv <= '0'; C_in <= '0';
		MEM_read <= '0'; MEM_write <= '0'; MA_select <= '0'; IR_enable <= '0';
		PC_select <= "00"; PC_enable <= '0'; INC_select <= '0'; extend <= "000";
		Status_enable <= '0';
		-- set internal WMFC signal to the default 0
		WMFC <= '0'; 

		-- set output signals and WMFC for each instruction and each stage
	--Stage1 fetch--
	if (current_state = "001") then
		MA_select <= '1';
		MEM_read <= '1';
		MEM_write <= '0';
		WMFC <= '1';
		if (MFC = '1') then
			IR_enable <= '1';
		else
			IR_enable <= '0';
		end if;
		INC_select <= '0';
		PC_select <= "01";
		if (MFC = '1') then
			PC_enable <= '1';
		else 
			PC_enable <= '0';
		end if;
	end if;
			
	if (OP_code = "000") AND (OPX = "0000") then --add
		if (current_state = "010") then
		elsif (current_state = "011") then
			B_select <= '0'; 
			ALU_op   <= "11"; 
			A_inv <= '0'; B_inv <= '0'; C_in <= '0';
		elsif (current_state = "100") then
			Y_select <= "00";
		elsif (current_state = "101") then
			RF_write <= '1'; 
			C_select <= "01";	
		end if;
	end if;
	
	if (OP_code = "011")then --addi
		if (current_state = "010") then
		elsif (current_state = "011") then
			extend <= "000";
			B_select <= '1'; 
			ALU_op   <= "11"; 
			A_inv <= '0'; B_inv <= '0'; C_in <= '0';
		elsif (current_state = "100") then
			Y_select <= "00";
		elsif (current_state = "101") then
			RF_write <= '1'; 
			C_select <= "00";	
		end if;
	end if;

	
	if (OP_code = "000") AND (OPX = "0001")then --sub
		if (current_state = "010") then
		elsif (current_state = "011") then
			B_select <= '0'; 
			ALU_op   <= "11"; 
			A_inv <= '0'; B_inv <= '1'; C_in <= '1';
		elsif (current_state = "100") then
			Y_select <= "00";
		elsif (current_state = "101") then
			RF_write <= '1'; 
			C_select <= "01";	
		end if;
	end if;
	
	if (OP_code = "000") AND (OPX = "0010")then --and
		if (current_state = "010") then
		elsif (current_state = "011") then
			B_select <= '0'; 
			ALU_op   <= "00"; 
			A_inv <= '0'; B_inv <= '0'; C_in <= '0';
		elsif (current_state = "100") then
			Y_select <= "00";
		elsif (current_state = "101") then
			RF_write <= '1'; 
			C_select <= "01";	
		end if;
	end if;
	
	if (OP_code = "000") AND (OPX = "0011")then --or
		if (current_state = "010") then
		elsif (current_state = "011") then
			B_select <= '0'; 
			ALU_op   <= "01"; 
			A_inv <= '0'; B_inv <= '0'; C_in <= '0';
		elsif (current_state = "100") then
			Y_select <= "00";
		elsif (current_state = "101") then
			RF_write <= '1'; 
			C_select <= "01";	
		end if;
	end if;
	
	if (OP_code = "100")then --ori
		if (current_state = "010") then
		elsif (current_state = "011") then
			extend <= "000";
			B_select <= '1'; 
			ALU_op   <= "01"; 
			A_inv <= '0'; B_inv <= '0'; C_in <= '0';
		elsif (current_state = "100") then
			Y_select <= "00";
		elsif (current_state = "101") then
			RF_write <= '1'; 
			C_select <= "00";	
		end if;
	end if;

	
	if (OP_code = "101") then --orhi
		if (current_state = "010") then
		elsif (current_state = "011") then
			extend <= "000";
			B_select <= '1'; 
			ALU_op   <= "01"; 
			A_inv <= '0'; B_inv <= '0'; C_in <= '0';
		elsif (current_state = "100") then
			Y_select <= "00";
		elsif (current_state = "101") then
			RF_write <= '1'; 
			C_select <= "00";	
		end if;
	end if;

	
	if (OP_code = "000") AND (OPX = "0100")then --xor
		if (current_state = "010") then
		elsif (current_state = "011") then
			B_select <= '0'; 
			ALU_op   <= "10"; 
			A_inv <= '0'; B_inv <= '0'; C_in <= '0';
		elsif (current_state = "100") then
			Y_select <= "00";
		elsif (current_state = "101") then
			RF_write <= '1'; 
			C_select <= "01";	
		end if;
	end if;
	
	if (OP_code = "000") AND (OPX = "0101")then --nand
		if (current_state = "010") then
		elsif (current_state = "011") then
			B_select <= '0'; 
			ALU_op   <= "01"; 
			A_inv <= '1'; B_inv <= '1'; C_in <= '0';
		elsif (current_state = "100") then
			Y_select <= "00";
		elsif (current_state = "101") then
			RF_write <= '1'; 
			C_select <= "01";	
		end if;
	end if;
	
	if (OP_code = "000") AND (OPX = "0110")then --nor
		if (current_state = "010") then
		elsif (current_state = "011") then
			B_select <= '0'; 
			ALU_op   <= "00"; 
			A_inv <= '1'; B_inv <= '1'; C_in <= '0';
		elsif (current_state = "100") then
			Y_select <= "00";
		elsif (current_state = "101") then
			RF_write <= '1'; 
			C_select <= "01";	
		end if;
	end if;
	
	if (OP_code = "000") AND (OPX = "0111")then --xnor
		if (current_state = "010") then
		elsif (current_state = "011") then
			B_select <= '0'; 
			ALU_op   <= "10"; 
			A_inv <= '0'; B_inv <= '1'; C_in <= '0';
		elsif (current_state = "100") then
			Y_select <= "00";
		elsif (current_state = "101") then
			RF_write <= '1'; 
			C_select <= "01";	
		end if;
	end if;
	
end process;
	
end implementation;
	
