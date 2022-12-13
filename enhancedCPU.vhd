library IEEE; use IEEE.STD_LOGIC_1164.ALL; USE IEEE.NUMERIC_STD.ALL;

entity enhancedCPU is
    generic(
        vscpu_A_width : integer := 16;
        vscpu_D_width : integer := 8;
        memsize : integer := ((2**8)-1);
        pc_starts_at : std_logic_vector(15 downto 0) := X"0001");
        port(clock,reset,start,mem_write: in std_logic;
            addr : in std_logic_vector( vscpu_A_width-1 downto 0);
				addressRegister: out std_logic_vector(vscpu_A_width-1 downto 0);
				programCounter: out std_logic_vector(vscpu_A_width-1 downto 0);
            data : in std_logic_vector( vscpu_D_width-1 downto 0);
				dataBus : out std_logic_vector(vscpu_D_width-1 downto 0);
				dataRegister : out std_logic_vector(vscpu_D_width-1 downto 0);
				instructionRegister: out std_logic_vector(vscpu_D_width-1 downto 0);
				accumulatorContent : out std_logic_vector(vscpu_D_width-1 downto 0);
				memoryRead: out std_logic; state : out string(1 to 8);
				dataOut : out std_logic_vector(vscpu_D_width-1 downto 0);
				flagRegister : out std_logic_vector(vscpu_D_width-1 downto 0);
				memoryStore: out std_logic);
end entity;

architecture rch of enhancedCPU is

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

type t_state is (	sthalt,stfetch1,stfetch2,stfetch3,stfetch4,stfetch5,stfetch6,stfetch7,
						stfetch8,stadd,stand,stinc,stjmp,stsub,stdnc,stxor,stor,strar,stral,ststa1,
						ststa2,stlda1,stlda2,stout,stjc,stjnc,stjp,stjm,stjpe,stjpo,stjz,stjnz);
signal stvar_ff,stvar_ns : t_state := sthalt;
signal pc_ff :		 std_logic_vector(vscpu_a_width-1 downto 0) := pc_starts_at;
signal pc_ns,ar_ff,ar_ns : std_logic_vector(vscpu_a_width-1 downto 0) := (others =>'0');
signal temp16_ns, temp16_ff: std_logic_vector(vscpu_a_width-1 downto 0) := (others =>'0');
signal ir_ff,ir_ns : std_logic_vector(7 downto 0) := (others =>'0');
signal ac_ff,ac_ns,dr_ff,dr_ns,dbus : std_logic_vector(vscpu_D_width-1 downto 0) := (others =>'0');
signal temp8_ns,temp8_ff: std_logic_vector(vscpu_D_width-1 downto 0) := (others =>'0');
signal mem_read,mem_store:std_logic;
TYPE  DATA_ARRAY  IS ARRAY (0 TO MEMSIZE-1) OF std_logic_vector(7 downto 0) ;
SIGNAL mem : DATA_ARRAY;
signal carry,parity,auxCarry,zero,sign: std_logic;
begin
flagRegister(0) <= carry;
flagRegister(1) <= '0';
flagRegister(2) <= parity;
flagRegister(3) <= '0';
flagRegister(4) <= auxCarry;
flagRegister(5) <= '0';
flagRegister(6) <= zero;
flagRegister(7) <= sign;
    process begin
        wait until clock='1';
		  if (reset = '1') then
		  ac_ff <= (others =>'0');
		  pc_ff <= pc_starts_at;
		  ar_ff <= (others =>'0');
		  ir_ff <= (others =>'0');
		  dr_ff <= (others =>'0');
		  temp8_ff <= (others =>'0');
		  temp16_ff <= (others =>'0');

		  else
        stvar_ff <= stvar_ns;
        pc_ff<=pc_ns;
        ac_ff<=ac_ns;
        ar_ff<=ar_ns;
        ir_ff<=ir_ns;
        dr_ff<=dr_ns;
		  temp8_ff <= temp8_ns;
		  temp16_ff <= temp16_ns;
		  end if;
    end process;
    
	process(stvar_ff,start) begin
		stvar_ns <= stvar_ff;
		case ( stvar_ff ) is
			when sthalt => if(start='1')then stvar_ns <= stfetch1; end if; state <= "stathalt";
			when stfetch1 => stvar_ns <= stfetch2; state <= "stfetch1";
			when stfetch2 => stvar_ns <= stfetch3; state <= "stfetch2";
			when stfetch3 => state <= "stfetch3";
				case (ir_ff) is
					when INSTR_add  => stvar_ns <= stfetch4;
					when INSTR_and  => stvar_ns <= stfetch4;
					when INSTR_jmp  => stvar_ns <= stfetch4;
					when INSTR_inc  => stvar_ns <= stinc;
					when INSTR_sub  => stvar_ns <= stfetch4;
					when INSTR_dnc  => stvar_ns <= stdnc;
					when INSTR_xor  => stvar_ns <= stfetch4;
					when INSTR_or   => stvar_ns <= stfetch4;
					when INSTR_halt => stvar_ns <= sthalt;
					when INSTR_rar  => stvar_ns <= strar;
					when INSTR_ral  => stvar_ns <= stral;
					when INSTR_sta  => stvar_ns <= stfetch4;
					when INSTR_lda  => stvar_ns <= stfetch4;
					when INSTR_out  => stvar_ns <= stout;
					when INSTR_jc 	 => stvar_ns <= stfetch4;
					when INSTR_jnc  => stvar_ns <= stfetch4;
					when INSTR_jp   => stvar_ns <= stfetch4;
					when INSTR_jm   => stvar_ns <= stfetch4;
					when INSTR_jpe  => stvar_ns <= stfetch4;
					when INSTR_jpo  => stvar_ns <= stfetch4;
					when INSTR_jz   => stvar_ns <= stfetch4;
					when INSTR_jnz  => stvar_ns <= stfetch4;
					when others => null;
				end case;
			when stfetch4 => stvar_ns <= stfetch5; state <= "stfetch4";
			when stfetch5 => stvar_ns <= stfetch6; state <= "stfetch5";
			when stfetch6 => state <= "stfetch6";
				case (ir_ff) is
					when INSTR_add  => stvar_ns <= stadd;
					when INSTR_and  => stvar_ns <= stand;
					when INSTR_jmp  => stvar_ns <= stfetch7;
					when INSTR_sub  => stvar_ns <= stsub;
					when INSTR_xor  => stvar_ns <= stxor;
					when INSTR_or   => stvar_ns <= stor;
					when INSTR_sta  => stvar_ns <= stfetch7;
					when INSTR_lda  => stvar_ns <= stfetch7;
					when INSTR_jc 	 => stvar_ns <= stfetch7;
					when INSTR_jnc  => stvar_ns <= stfetch7;
					when INSTR_jp   => stvar_ns <= stfetch7;
					when INSTR_jm   => stvar_ns <= stfetch7;
					when INSTR_jpe  => stvar_ns <= stfetch7;
					when INSTR_jpo  => stvar_ns <= stfetch7;
					when INSTR_jz   => stvar_ns <= stfetch7;
					when INSTR_jnz  => stvar_ns <= stfetch7;
					when others => null;
				end case;
			when stfetch7 => stvar_ns <= stfetch8; state <= "stfetch7";
			when stfetch8 => state <= "stfetch8";
				case (ir_ff) is
					when INSTR_jmp  => stvar_ns <= stjmp;
					when INSTR_sta  => stvar_ns <= ststa1;
					when INSTR_lda  => stvar_ns <= stlda1;
					when INSTR_jc 	 => stvar_ns <= stjc;
					when INSTR_jnc  => stvar_ns <= stjnc;
					when INSTR_jp   => stvar_ns <= stjp;
					when INSTR_jm   => stvar_ns <= stjm;
					when INSTR_jpe  => stvar_ns <= stjpe;
					when INSTR_jpo  => stvar_ns <= stjpo;
					when INSTR_jz   => stvar_ns <= stjz;
					when INSTR_jnz  => stvar_ns <= stjnz;
					when others => null;
				end case;
			when stadd => stvar_ns <= stfetch1; state <= "statadd ";
			when stand => stvar_ns <= stfetch1; state <= "statand ";
			when stinc => stvar_ns <= stfetch1; state <= "statinc ";
			when stjmp => stvar_ns <= stfetch1; state <= "statjmp ";
			when stsub => stvar_ns <= stfetch1; state <= "statsub ";
			when stdnc => stvar_ns <= stfetch1; state <= "statdnc ";
			when stxor => stvar_ns <= stfetch1; state <= "statxor ";
			when stor  => stvar_ns <= stfetch1; state <= "stator  ";
			when strar => stvar_ns <= stfetch1; state <= "statrar ";
			when stral => stvar_ns <= stfetch1; state <= "statral ";
			when ststa1=> stvar_ns <= ststa2;   state <= "statsta1";
			when ststa2=> stvar_ns <= stfetch1; state <= "statsta2";
			when stlda1=> stvar_ns <= stlda2;   state <= "statlda1";
			when stlda2=> stvar_ns <= stfetch1; state <= "statlda2";
			when stout => stvar_ns <= stfetch1; state <= "statout ";
			when stjc  => stvar_ns <= stfetch1; state <= "statjc  ";
			when stjnc => stvar_ns <= stfetch1; state <= "statjnc ";
			when stjp  => stvar_ns <= stfetch1; state <= "statjp  ";
			when stjm  => stvar_ns <= stfetch1; state <= "statjm  ";
			when stjpe => stvar_ns <= stfetch1; state <= "statjpe ";
			when stjpo => stvar_ns <= stfetch1; state <= "statjpo ";
			when stjz  => stvar_ns <= stfetch1; state <= "statjz  ";
			when stjnz => stvar_ns <= stfetch1; state <= "statjnz ";
		end case;          
	end process;
	
mem_read <='1' when 	stvar_ff=stfetch2 or stvar_ff=stfetch5 or stvar_ff=stfetch8 or 
							stvar_ff = stlda2 else '0';
memoryRead <= mem_read;
mem_store <= '1' when stvar_ff = ststa2 else '0';
memoryStore <= mem_store;
process(ac_ff) begin
if (ac_ff = X"00") then zero <= '1'; else zero <= '0'; end if;
if (ac_ff(7) = '1') then sign <= '1'; else sign <= '0'; end if;
if ((ac_ff(7) xor ac_ff(6) xor ac_ff(5) xor ac_ff(4) xor ac_ff(3) xor ac_ff(2) xor 
	ac_ff(1) xor ac_ff(0)) = '0') then parity <= '1'; else parity <= '0'; end if;
end process;
    process(stvar_ff,pc_ff,ac_ff,dr_ff,ir_ff,ar_ff,dbus,temp8_ff,temp16_ff)
    begin
        pc_ns <= pc_ff;
        ac_ns <= ac_ff;
        ar_ns <= ar_ff;
        ir_ns <= ir_ff;
        dr_ns <= dr_ff;
		  temp8_ns <= temp8_ff;
		  temp16_ns <= temp16_ff;
		  accumulatorContent <= ac_ff;
		  dataRegister <= dr_ff;
		  instructionRegister <= ir_ff;
		  addressRegister <= ar_ff;
	     programCounter <= pc_ff;	
        case ( stvar_ff ) is
        when sthalt => null;
		  when stfetch1 =>	ar_ns <= pc_ff; addressRegister <= ar_ns;
        when stfetch2 => 	ir_ns <= dbus; instructionRegister <= ir_ns;
									pc_ns <= std_logic_vector(unsigned(pc_ff)+1);
									programCounter <= pc_ns;
		  when stfetch3 =>	null;
        when stfetch4 => 	ar_ns <= pc_ff; addressRegister <= ar_ns;
		  when stfetch5 =>	dr_ns <= dbus; dataRegister <= dr_ns;
									pc_ns <= std_logic_vector(unsigned(pc_ff)+1);
									programCounter <= pc_ns;
		  when stfetch6 =>	null;
        when stfetch7 => 	ar_ns <= pc_ff; addressRegister <= ar_ns;
									temp8_ns  <= dr_ff;
		  when stfetch8 =>	dr_ns <= dbus; dataRegister <= dr_ns;
									pc_ns <= std_logic_vector(unsigned(pc_ff)+1);
									programCounter <= pc_ns;
        when stadd => 		ac_ns <= std_logic_vector(unsigned(ac_ff)+unsigned(dr_ff)) ;
									accumulatorContent <= ac_ns;
									if (to_integer(unsigned(ac_ff))+to_integer(unsigned(dr_ff)) > 255) then carry <='1'; 
									else carry <='0'; end if;
									if (to_integer(unsigned(ac_ff(3 downto 0)))+to_integer(unsigned(dr_ff(3 downto 0))) > 15) then auxCarry <='1'; 
									else auxCarry <='0'; end if;
        when stand => 		ac_ns <= ac_ff and dr_ff; accumulatorContent <= ac_ns;
        when stinc => 		ac_ns <= std_logic_vector(unsigned(ac_ff)+ 1) ;
									accumulatorContent <= ac_ns;
        when stjmp => 		pc_ns <= temp8_ff & dr_ff; programCounter <= pc_ns;
		  when stsub => 		ac_ns <= std_logic_vector(unsigned(ac_ff)-unsigned(dr_ff)) ;
									accumulatorContent <= ac_ns;
		  when stdnc => 		ac_ns <= std_logic_vector(unsigned(ac_ff)- 1) ;
									accumulatorContent <= ac_ns;
		  when stxor => 		ac_ns <= ac_ff xor dr_ff; accumulatorContent <= ac_ns;
		  when stor  =>		ac_ns <= ac_ff or dr_ff; accumulatorContent <= ac_ns;
		  when strar =>		ac_ns <= ac_ff(0) & ac_ff(vscpu_D_width-1 downto 1);
									accumulatorContent <= ac_ns;
		  when stral =>		ac_ns <= ac_ff(vscpu_D_width-2 downto 0) & ac_ff(vscpu_D_width-1);
									accumulatorContent <= ac_ns;
		  when ststa1=>		temp16_ns <= temp8_ff & dr_ff;
		  when ststa2=>		null;
		  when stlda1 =>		ar_ns <= temp8_ns & dr_ff; addressRegister <= ar_ns;
		  when stlda2 =>		ac_ns <= dbus; accumulatorContent <= ac_ns;
		  when stout =>		dataOut <= ac_ff; 
		  when stjc 	  => if (carry = '1') then pc_ns <= temp8_ff & dr_ff; 
		                 else pc_ns <=std_logic_vector(unsigned(pc_ff)+1); end if;
							  programCounter <= pc_ns;
		  when stjnc => if (carry = '0') then pc_ns <= temp8_ff & dr_ff; 
		                 else pc_ns <=std_logic_vector(unsigned(pc_ff)+1); end if;
							  programCounter <= pc_ns;
		  when stjp => if (sign = '0') then pc_ns <= temp8_ff & dr_ff; 
		                 else pc_ns <=std_logic_vector(unsigned(pc_ff)+1); end if;
							  programCounter <= pc_ns;
		  when stjm => if (sign = '1') then pc_ns <= temp8_ff & dr_ff; 
		                 else pc_ns <=std_logic_vector(unsigned(pc_ff)+1); end if;
							  programCounter <= pc_ns;
		  when stjpe=> if (parity = '1') then pc_ns <= temp8_ff & dr_ff; 
		                 else pc_ns <=std_logic_vector(unsigned(pc_ff)+1); end if;
							  programCounter <= pc_ns;
		  when stjpo=> if (parity = '0') then pc_ns <= temp8_ff & dr_ff; 
		                 else pc_ns <=std_logic_vector(unsigned(pc_ff)+1); end if;
							  programCounter <= pc_ns;
		  when stjz => if (zero = '1') then pc_ns <= temp8_ff & dr_ff;
		                 else pc_ns <=std_logic_vector(unsigned(pc_ff)+1); end if;
							  programCounter <= pc_ns;
		  when stjnz   => if (zero = '0') then pc_ns <= temp8_ff & dr_ff;
		                 else pc_ns <=std_logic_vector(unsigned(pc_ff)+1); end if;
							  programCounter <= pc_ns;
        end case;
    end process;
	process begin
		wait until clock='1';
		if(mem_write ='1') then mem(to_integer(unsigned(addr))) <= data; end if;
		if(mem_store ='1') then mem(to_integer(unsigned(temp16_ff))) <= ac_ff; end if;
	end process;

	process begin
		wait until clock='1';
		if(stvar_ff = stfetch1) then
		report "Accumulator Contents = " & integer'image(to_integer(unsigned(ac_ff))); end if;
	end process;
dbus <= mem(to_integer(unsigned(ar_ff))) when mem_read ='1' else (others =>'0');
dataBus <= dbus;
end rch;