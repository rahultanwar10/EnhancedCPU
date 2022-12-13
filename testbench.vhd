library ieee ; use ieee.std_logic_1164.all ;

entity testbench is end entity ;

architecture tb of testbench is 
constant A_WIDTH : integer := 16 ; 
constant D_WIDTH : integer := 8 ;
constant INSTR_add : std_logic_vector( 7 downto 0 ) := X"01" ;
constant INSTR_and : std_logic_vector( 7 downto 0 ) := X"02" ;
constant INSTR_jmp : std_logic_vector( 7 downto 0 ) := X"03" ;
constant INSTR_inc : std_logic_vector( 7 downto 0 ) := X"04" ;
constant INSTR_sub : std_logic_vector( 7 downto 0 ) := X"05" ;
constant INSTR_dnc : std_logic_vector( 7 downto 0 ) := X"06" ;
constant INSTR_xor : std_logic_vector( 7 downto 0 ) := X"07" ;
constant INSTR_or  : std_logic_vector( 7 downto 0 ) := X"08" ;
constant INSTR_halt: std_logic_vector( 7 downto 0 ) := X"09" ;
constant INSTR_rar : std_logic_vector( 7 downto 0 ) := X"0A" ;
constant INSTR_ral : std_logic_vector( 7 downto 0 ) := X"0B" ;
constant INSTR_sta : std_logic_vector( 7 downto 0 ) := X"0C" ;
constant INSTR_lda : std_logic_vector( 7 downto 0 ) := X"0D" ;
constant INSTR_out : std_logic_vector( 7 downto 0 ) := X"0E" ;
constant INSTR_jc  : std_logic_vector( 7 downto 0 ) := X"0F" ;
constant INSTR_jnc : std_logic_vector( 7 downto 0 ) := X"10" ;
constant INSTR_jp  : std_logic_vector( 7 downto 0 ) := X"11" ;
constant INSTR_jm  : std_logic_vector( 7 downto 0 ) := X"12" ;
constant INSTR_jpe : std_logic_vector( 7 downto 0 ) := X"13" ;
constant INSTR_jpo : std_logic_vector( 7 downto 0 ) := X"14" ;
constant INSTR_jz  : std_logic_vector( 7 downto 0 ) := X"15" ;
constant INSTR_jnz : std_logic_vector( 7 downto 0 ) := X"16" ;

signal clk , reset , start , write_en : std_logic ;
signal addr : std_logic_vector( A_WIDTH-1 downto 0 ) ; 
signal data : std_logic_vector ( D_WIDTH-1 downto 0 ) ;
signal dataBus : std_logic_vector(D_WIDTH-1 downto 0);
signal dataRegister : std_logic_vector(D_WIDTH-1 downto 0);
signal instructionRegister: std_logic_vector(7 downto 0);
signal addressRegister: std_logic_vector(A_WIDTH-1 downto 0);
signal programCounter: std_logic_vector(A_WIDTH-1 downto 0);
signal accumulatorContent: std_logic_vector(D_WIDTH-1 downto 0);
signal dataOut,flagRegister: std_logic_vector(D_width-1 downto 0);
signal memoryRead,memoryStore: std_logic;
signal state : string(1 to 8);

procedure do_synch_active_high_half_pulse (	signal formal_p_clk : in std_logic ; 
															signal formal_p_sig : out std_logic) is
begin
		wait until formal_p_clk='0' ;  formal_p_sig <= '1' ;
		wait until formal_p_clk='1' ;  formal_p_sig <= '0' ;
end procedure ;

procedure do_program (	signal formal_p_clk : in std_logic ; 
								signal formal_p_write_en : out std_logic ; 
								signal formal_p_addr_out , formal_p_data_out : out std_logic_vector ;
								formal_p_ADDRESS_in , formal_p_DATA_in : in std_logic_vector) is
begin
		 wait until formal_p_clk='0' ;  formal_p_write_en <= '1' ;
		 formal_p_addr_out <= formal_p_ADDRESS_in ; 
		 formal_p_data_out <= formal_p_DATA_in ;
		 wait until formal_p_clk='1' ;  formal_p_write_en <='0' ;
end procedure ;

begin

ddut_vscpu : entity work.enhancedCPU(rch) port map(clock => clk, reset => reset, start => start,
														mem_write => write_en, addr => addr, data => data,
														dataBus => dataBus,dataRegister => dataRegister,
														instructionRegister => instructionRegister,
														addressRegister => addressRegister,
														programCounter => programCounter,
														accumulatorContent => accumulatorContent,
														dataOut => dataOut,memoryRead => memoryRead, 
														state => state,flagRegister=>flagRegister, 
														memoryStore => memoryStore) ;
													
														
             
process 
begin
    clk <= '0' ;
    for i in 0 to 280 loop 
      wait for 1 ns ; clk <= '1' ;  wait for 1 ns ; clk <= '0';
    end loop ;
    wait ;
end process ;

process
begin
	reset <= '0' ;  start <= '0' ; write_en <= '0' ;
	addr <= X"0000" ;  data <= X"00" ;
	do_synch_active_high_half_pulse ( clk, reset ) ; -- acc=0
	do_program ( clk, write_en, addr, data, X"0001" , INSTR_add   	) ; 
	do_program ( clk, write_en, addr, data, X"0002" , X"09"			) ; 
	do_program ( clk, write_en, addr, data, X"0003" , INSTR_and   	) ; 
	do_program ( clk, write_en, addr, data, X"0004" , X"08"			) ; 
	do_program ( clk, write_en, addr, data, X"0005" , INSTR_inc   	) ; 
	do_program ( clk, write_en, addr, data, X"0006" , INSTR_dnc    ) ; 
	do_program ( clk, write_en, addr, data, X"0007" , INSTR_sub   	) ; 
	do_program ( clk, write_en, addr, data, X"0008" , X"02"			) ; 
	do_program ( clk, write_en, addr, data, X"0009" , INSTR_or		) ;
	do_program ( clk, write_en, addr, data, X"000A" , X"0F"			) ; 
	do_program ( clk, write_en, addr, data, X"000B" , INSTR_xor		) ; 
	do_program ( clk, write_en, addr, data, X"000C" , X"08"			) ; 
	do_program ( clk, write_en, addr, data, X"000D" , INSTR_rar		) ; 
	do_program ( clk, write_en, addr, data, X"000E" , INSTR_ral		) ; 
	do_program ( clk, write_en, addr, data, X"000F" , INSTR_out		) ;
	do_program ( clk, write_en, addr, data, X"0010" , INSTR_jmp		) ; 
	do_program ( clk, write_en, addr, data, X"0011" , X"00"			) ;
	do_program ( clk, write_en, addr, data, X"0012" , X"60"			) ;
	do_program ( clk, write_en, addr, data, X"0060" , INSTR_sta    ) ;
	do_program ( clk, write_en, addr, data, X"0061" , X"00"			) ; 
	do_program ( clk, write_en, addr, data, X"0062" , X"50"			) ; 
	do_program ( clk, write_en, addr, data, X"0063" , INSTR_and   	) ; 
	do_program ( clk, write_en, addr, data, X"0064" , X"00"			) ;
	do_program ( clk, write_en, addr, data, X"0065" , INSTR_jz     ) ;
	do_program ( clk, write_en, addr, data, X"0066" , X"00"			) ;
	do_program ( clk, write_en, addr, data, X"0067" , X"70"			) ;
	do_program ( clk, write_en, addr, data, X"0070" , INSTR_add   	) ; 
	do_program ( clk, write_en, addr, data, X"0071" , X"09"			) ;
	do_program ( clk, write_en, addr, data, X"0072" , INSTR_jnz    ) ;
	do_program ( clk, write_en, addr, data, X"0073" , X"00"			) ;
	do_program ( clk, write_en, addr, data, X"0074" , X"80"			) ;
	do_program ( clk, write_en, addr, data, X"0080" , INSTR_add   	) ; 
	do_program ( clk, write_en, addr, data, X"0081" , X"FF"			) ;
	do_program ( clk, write_en, addr, data, X"0082" , INSTR_jc     ) ;
	do_program ( clk, write_en, addr, data, X"0083" , X"00"			) ;
	do_program ( clk, write_en, addr, data, X"0084" , X"90"			) ;
	do_program ( clk, write_en, addr, data, X"0090" , INSTR_add   	) ; 
	do_program ( clk, write_en, addr, data, X"0091" , X"02"			) ;
	do_program ( clk, write_en, addr, data, X"0092" , INSTR_jnc    ) ;
	do_program ( clk, write_en, addr, data, X"0093" , X"00"			) ;
	do_program ( clk, write_en, addr, data, X"0094" , X"A0"			) ;
	do_program ( clk, write_en, addr, data, X"00A0" , INSTR_jp     ) ;
	do_program ( clk, write_en, addr, data, X"00A1" , X"00"			) ;
	do_program ( clk, write_en, addr, data, X"00A2" , X"B0"			) ;
	do_program ( clk, write_en, addr, data, X"00B0" , INSTR_sub   	) ; 
	do_program ( clk, write_en, addr, data, X"00B1" , X"0B"			) ;
	do_program ( clk, write_en, addr, data, X"00B2" , INSTR_jm     ) ;
	do_program ( clk, write_en, addr, data, X"00B3" , X"00"			) ;
	do_program ( clk, write_en, addr, data, X"00B4" , X"C0"			) ;
	do_program ( clk, write_en, addr, data, X"00C0" , INSTR_jpe    ) ;
	do_program ( clk, write_en, addr, data, X"00C1" , X"00"			) ;
	do_program ( clk, write_en, addr, data, X"00C2" , X"D0"			) ;
	do_program ( clk, write_en, addr, data, X"00D0" , INSTR_add   	) ; 
	do_program ( clk, write_en, addr, data, X"00D1" , X"02"			) ;
	do_program ( clk, write_en, addr, data, X"00D2" , INSTR_jpo    ) ;
	do_program ( clk, write_en, addr, data, X"00D3" , X"00"			) ;
	do_program ( clk, write_en, addr, data, X"00D4" , X"E0"			) ;
	do_program ( clk, write_en, addr, data, X"00E0" , INSTR_lda    ) ;
	do_program ( clk, write_en, addr, data, X"00E1" , X"00"			) ; 
	do_program ( clk, write_en, addr, data, X"00E2" , X"50"			) ;
	do_program ( clk, write_en, addr, data, X"00E3" , INSTR_halt   ) ;	
	do_synch_active_high_half_pulse ( clk, start ) ; 
    wait ;
end process; end architecture ;