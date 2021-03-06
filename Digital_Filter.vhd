LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

Entity Digital_Filter is 
	port (
				clk, start, rst	: in std_logic;
				Data_IN				: in signed( 7 downto 0);
				M 						: out signed( 7 downto 0);
				Data_out_mem_B		: out signed (7 downto 0);
				M_disp				: out std_logic 
			);
end Digital_Filter;

architecture behav of Digital_filter is

--dichiarazione degli stati
	TYPE State_type is (IDLE, WRITE_IN_A, AB, MINUS_D_WR_B, MINUS_D, PLUS_Y, MINUS_Y, LOWER_SAT, GREATER_SAT, EQUAL_SAT, AVERAGE, ATTESA);
	Signal stato	:State_type;
--dichiarazione dei segnali per gli stati
	signal TC1, TC2 : std_logic; --il primo serve per uscire dallo stato di scrittura in A...il secondo per fare la media
	signal active_mem_B: std_logic; -- attiva lo stato  MINUS_D_WR_B per scrivere in B, si attiva dal secondo ciclo in poi
	signal rst_cnt, clear_cnt : std_logic;
	

-- dichiarazione dei segnali per il contatore
	signal cnt_en	: std_logic;
	signal cnt	: unsigned(11 downto 0); -------------------------
	signal cnt_2, cnt_0: std_logic;

-- dichiarazione dei segnali per la Mem_A
	signal data_out_Mem_A, data_in_Mem_A : signed (7 downto 0);
	signal CS_A									 : std_logic;
	signal wr_n_rd_A							 : std_logic;
	
-- dichiarazione dei segnali per la Mem_B
	signal y_mem_B								 : signed (7 downto 0);
	signal CS_B									 : std_logic;
	signal wr_n_rd_B							 : std_logic;
	
-- dichiarazione seganli per le operazioni
	signal data_A_8_bit, data_B_8_bit, data_C_8_bit, data_D_8_bit: signed (7 downto 0);
	signal data_A_10_bit, data_B_10_bit, data_D_10_bit: signed (9 downto 0);

-- dichiarazione dei segnali di ENABLE dei registri
	signal LD_R_1, EN_y_1 			: std_logic;

	
-- dichiarazione dei segnali che escono dai mux e per selezionare il dato che deve uscire
	signal data_mux_1, data_mux_2	: signed (9 downto 0);
	--signal data_mux_3					: signed (7 downto 0);
	signal Sel_2	: std_logic_vector (1 downto 0); --sel del mux3
	signal Sel_1	: std_logic_vector (1 downto 0); --sel del mux1 e mux2
	
-- dichiarazione del segnale per decidere se sommare o sottrare tramite il sommatore_1
	signal Add_n_Sub	: std_logic;
	
-- dichiarazione dei segnali in ingresso e in uscita dal registro Reg_Y
	signal y_prima	  : signed (9 downto 0);
	signal y_dopo	  : signed (9 downto 0);
	
-- dichiarazione segnali per il controllo della saturazione di y e del dato in uscita dal saturatore
	signal a,b	: std_logic;
	signal y_sat	: signed (7 downto 0);
	
-- dichiarazione dei segnali usati per la media...in ingresso al sommatore usiamo data_out
	signal Data_sum_in, Data_sum_out, Data_out_mem_A_18_bit : signed (17 downto 0);   --l'ultimo serve per portare da 8 a 18 il parallelismo del dato letto dalla mem_A
	signal Data_media_in, Data_media_out					: signed (7 downto 0);

-- dichiarazione del segnale di DONE
	signal DONE	: std_logic;
	signal M_disp_sgn : std_logic := '0';
	
	
	--signal p : std_logic := '0';
	
	
	--memoria RAM
	component SRAM_SW_AR_1024x8_DEC is
		port(  ADDRESS : in std_logic_vector (9 downto 0);
				DATA_IN : in signed(7 downto 0);
				DATA_OUT : out signed(7 downto 0);
				CS, WRite_0_read_1, clock : in std_logic
				);
		end component;
		
		--Registro con parallelismo da 8 bit utilizzato per Reg_A Reg_B Reg_C Reg_D Reg_MEDIA
	component Reg_8_bit is
	generic (n : integer := 8);
	port ( D : in signed(n-1 downto 0);
			 Rest_1, Clock, EN_1 : in std_logic;
			 Q : out signed(N-1 downto 0)
			 );
	end component;


--Registro con parallelismo da 10 bit utilizzato per Reg_y
	component Reg_10_bit is
	generic (n : integer := 10);
	port ( D : in signed(n-1 downto 0);
			 Rest_1, Clock, EN_1 : in std_logic;
			 Q : out signed(N-1 downto 0)
			 );
	end component;


--Registro con parallelismo da 18 bit utilizzato per Reg_Sum
	component Reg_18_bit is
	generic (n : integer := 18);
	port ( D : in signed(n-1 downto 0);
			 Rest_1, Clock, EN_1 : in std_logic;
			 Q : out signed(N-1 downto 0)
			 );
	end component;

	--contatore
	component counter_12_bit_sincrono is
		generic ( N : integer:=12);
		port 
			(
			Cnt_EN_1, CLK, Clear_1: in std_logic; 
		 cnt: buffer unsigned (N-1 downto 0)
			);
	end component;
	
	--componente decoder
	component Decoder is
	port(
			EN					: in std_logic;
			D					: out std_logic_vector( 3 downto 0);
			sel				: in std_logic_vector( 1 downto 0)
		 );
	end component;
	
	--componente mux per il saturatore
	component mux_4_to_1_8bit is
	port(
			sel	: in std_logic_vector (1 downto 0);
			y1, y2, y3, y4		: in signed (7 downto 0);
			y_sat	: out signed (7 downto 0)
		);
	end component;
	
	--componente mux per il sommatore
	component mux_4_to_1_10bit is
	port(
			sel	: in std_logic_vector (1 downto 0);
			Data_00		: in signed (9 downto 0);
			Data_01		: in signed(9 downto 0);
			Data_10_11	: in signed (9 downto 0);
			y				: out signed (9 downto 0)
		);
	end component;

	--Sommatore con parallelismo da 10 bit utilizzato per i calcoli per valutare il dato da inserire nella Mem_B
	component Adder_Subtractor_10_bit is
	generic (n : integer := 10);
		port(
				Add_n_Sub : IN std_logic;
				a, b : IN signed (n-1 downto 0);
				y	  : Out signed (n-1 downto 0)
			 );
	end component;
	
	--Sommatore con parallelismo da 18 bit utilizzato per il calcolo della media dei dati della Mem_A
	component Adder_Subtractor_18_bit is
	generic (n : integer := 18);
		port(
				Add_n_Sub : IN std_logic;
				a, b : IN signed (n-1 downto 0);
				y	  : Out signed (n-1 downto 0)
			 );
	end component;
	
	
	
	
	begin
	
	FSM_transitions: Process(Rst,  clk)
	begin
		If Rst = '1' then
			stato<= IDLE;
		elsif(clk' event And clk='1') then
			CASE stato is
				WHEN IDLE         => if start = '0' then stato <= IDLE; else stato <= WRITE_IN_A; end if;
				WHEN WRITE_IN_A   => if TC1 = '0' then stato <= WRITE_IN_A; else stato <= ATTESA;end if;-- else stato <= AB ;end if;     --clear_cnt <= '0'; else stato <= AB; clear_cnt <= '1';end if;
				--WHEN WRITE_IN_A   => if p = '0' then stato <= WRITE_IN_A; else stato <=  AB; end if;
				when ATTESA       => stato <= AB;
				WHEN AB				=> if active_mem_B='1' then stato <= MINUS_D_WR_B; else stato <= MINUS_D; end if; --clear_cnt <= '0';
				WHEN MINUS_D_WR_B => if cnt_2='1' then stato <= MINUS_Y; else stato <= PLUS_Y; end if;
				WHEN MINUS_D		=> if cnt_2='1' then stato <= MINUS_Y; else stato <= PLUS_Y; end if;	
				WHEN PLUS_Y       => if ( A='1' and B='0') then  stato <= LOWER_SAT; elsif ( A='0' and B='1') then stato <= GREATER_SAT; else stato<= EQUAL_SAT; end if;
				WHEN MINUS_Y		=> if ( A='1' and B='0') then  stato <= LOWER_SAT; elsif ( A='0' and B='1') then stato <= GREATER_SAT; else stato<= EQUAL_SAT; end if;
				WHEN LOWER_SAT    => if ( TC2='1') then stato <= AVERAGE; else stato <= AB; end if;
				WHEN GREATER_SAT  => if ( TC2='1') then stato <= AVERAGE; else stato <= AB; end if;
				WHEN EQUAL_SAT    => if ( TC2='1') then stato <= AVERAGE; else stato <= AB; end if;
				WHEN AVERAGE		=> if cnt_0='1' then  if start='1' then stato <= AVERAGE; else stato <= IDLE; end if;  else stato <=AVERAGE; end if;	
			end case;
		end if;
	end process;
	
	
	FSM_outputs: Process(stato, start)
		begin			
			CASE stato is
				WHEN IDLE  		=>
											wr_n_rd_A <='0';	wr_n_rd_B <='0'; CS_A <= '0'; CS_B <= '0';
											Add_n_Sub <= '0'; Sel_1 <= "00"; cnt_En <= '0'; DONE <= '0';  
				
				WHEN WRITE_IN_A 	=> 
											wr_n_rd_A <= '0'; CS_A <= '1'; cnt_EN <= '1';
				
				WHEN AB				=> 
											--if (clear_cnt = '1') then clear_cnt_sgn <= '0'; end if;
											clear_cnt<= '0';
											wr_n_rd_A <= '1'; LD_R_1 <= '1';CS_A <= '1'; Add_n_Sub <= '0'; Sel_1 <= "00"; EN_Y_1 <= '1';
				
				WHEN MINUS_D_WR_B =>
											CS_A <= '0'; LD_R_1 <= '0'; EN_Y_1 <= '1'; Add_n_Sub <= '1'; Sel_1 <= "01";
											CS_B <= '1';											 
				
				WHEN MINUS_D => 		CS_A <= '0'; LD_R_1 <= '0'; EN_Y_1 <= '1'; Add_n_Sub <= '1'; Sel_1 <= "01";
				
				WHEN PLUS_Y  => 		Sel_1 <= "10"; Add_n_Sub <= '0';
				
				WHEN MINUS_Y =>
											Sel_1 <= "10";
				
				WHEN LOWER_SAT 	=>
											Sel_2 <= "10";									
						
				
				WHEN GREATER_SAT	=>
											Sel_2 <= "01";
				
				WHEN EQUAL_SAT		=>
											Sel_2 <= "00";
				
				WHEN AVERAGE		=>
											Done <= '1'; EN_Y_1 <= '0';
				
				WHEN Attesa 		=> 
											clear_cnt <= '1';
				
			end case;
	      end process;			
	
	
	
	
	--descrizione signal per switch stati: MINUS_D_WR_B, MINUS_D
	active_mem_B <= (std_logic(cnt(11)) or std_logic( cnt(10)) or std_logic(cnt(9)) or std_logic(cnt(8))
						or std_logic(cnt(7)) or std_logic(cnt(6)) or std_logic(cnt(5))
	   				or std_logic(cnt(4)) or std_logic(cnt(3)) or std_logic(cnt(2)));
	TC1 <= ( std_logic(cnt(9)) and std_logic(cnt(8))
						and std_logic(cnt(7)) and std_logic(cnt(6)) and std_logic(cnt(5))
	   				and std_logic(cnt(4)) and std_logic(cnt(3)) and std_logic(cnt(2)) and std_logic(cnt(1)) and std_logic(cnt(0)) );
	TC2 <= ( std_logic(cnt(11)) and std_logic(cnt(10)) and std_logic(cnt(9)) and std_logic(cnt(8))
						and std_logic(cnt(7)) and std_logic(cnt(6)) and std_logic(cnt(5))
	   				and std_logic(cnt(4)) and std_logic(cnt(3)) and std_logic(cnt(2)));
	cnt_2 <= std_logic(cnt(2));
	cnt_0 <= std_logic(cnt(0));
	
	
--	ciao :process (TC1)
--	begin
--	if (TC1 ='0') then
--		p <= '1';
--	end if;
--	end process;
	
	
	--Descrizione del Data Path...La descrizione avviene seguendo lo schema del data path dall'alto verso il basso 
	
	-- descrizione del contatore
	contatore: 	counter_12_bit_sincrono port map (Cnt_en_1 => cnt_en, clk => clk, clear_1 => rst_cnt, cnt => cnt); 
	rst_cnt<= (rst or clear_cnt);
	
	-- Descrizione della Mem_A
	data_in_Mem_A <= Data_IN;
	Mem_A:	SRAM_SW_AR_1024x8_DEC port map (Address => std_logic_vector(cnt(9 downto 0)), Data_in => data_in_Mem_A, data_out => data_out_mem_A, CS => CS_A, Write_0_read_1=> wr_n_rd_A, clock => clk);
	
	--caricamento e shift dei registri
	Reg_A: 	Reg_8_bit port map (D =>data_out_mem_A , Rest_1 => Rst, Clock => clk , Q =>Data_A_8_bit , EN_1 => LD_R_1 );
	Reg_B: 	Reg_8_bit port map (D =>data_A_8_bit , Rest_1 =>Rst, Clock =>clk , Q => Data_B_8_bit , EN_1 => LD_R_1);
	Reg_C: 	Reg_8_bit port map (D =>data_B_8_bit, Rest_1 => Rst, Clock =>clk, Q => Data_C_8_bit, EN_1 =>LD_R_1);
	Reg_D: 	Reg_8_bit port map (D =>data_C_8_bit, Rest_1 =>Rst, Clock => clk, Q => Data_D_8_bit, EN_1 => LD_R_1);
	
	--operazione di A/4
	Data_A_10_bit <= (Data_A_8_bit(7) & Data_A_8_bit(7) & Data_A_8_bit(7) & Data_A_8_bit(7) & Data_A_8_bit(7 downto 2));
	--incremento del parallelismo del dato_B da 8 a 10 bit
	Data_B_10_bit <= (Data_B_8_bit(7) & Data_B_8_bit(7) & Data_B_8_bit(7 downto 0));
	--operazione di D*2
	Data_D_10_bit <= ( Data_D_8_bit(7) & Data_D_8_bit(7 downto 0) & '0');
	
	--descrizione del mux1
	mux1: 	mux_4_to_1_10bit port map (Data_00 => Data_A_10_bit, Data_01 => y_dopo, Data_10_11 => "0000000000", sel => sel_1, y => data_mux_1);
	mux2: 	mux_4_to_1_10bit port map (Data_00 => data_b_10_bit, Data_01 => Data_D_10_bit, Data_10_11 => y_dopo, sel => sel_1, y => data_mux_2);
	
	--descrizione del sommatore per fare i calcoli per y
	Sommatore_1: 	Adder_Subtractor_10_bit port map(a => data_mux_1, b => data_mux_2, y => y_prima, Add_n_Sub => Add_n_Sub);
	
	--descrizione del registro Reg_Y
	Reg_Y: 	Reg_10_bit port map (D => y_prima, rest_1 => rst, clock => clk, Q => y_dopo, EN_1 => EN_y_1);
	
	--descrizione del saturatore:  logica per settare i valori di A e B e mux... A e B settano Sel2
	A <= y_dopo(9) and not( y_dopo(8) and y_dopo(7));
	B <=  not(y_dopo(9)) and ( y_dopo(8) or y_dopo(7));
	mux_3: mux_4_to_1_8bit port map( sel => sel_2, y1 => y_dopo(7 downto 0), y2 => "01111111", y3 => "10000000", y4 => y_dopo( 7 downto 0), y_sat => y_sat);
	
	--descrizione della Mem_B
	Mem_B:	SRAM_SW_AR_1024x8_DEC port map (Address => std_logic_vector(cnt(11 downto 2)), Data_in => y_sat, data_out => y_mem_B, CS => CS_B,  write_0_read_1=> wr_n_rd_B, clock => clk);
	Data_out_mem_B <= y_mem_B;
	
	--descrizione della struttura che calcola la media
	--aumento del parallelismo del dato letto della memoria A
	Data_out_mem_A_18_bit <= (data_out_mem_A(7) & data_out_mem_A(7) & data_out_mem_A(7) & data_out_mem_A(7)
										& data_out_mem_A(7) & data_out_mem_A(7) & data_out_mem_A(7) & data_out_mem_A(7)
										& data_out_mem_A(7) & data_out_mem_A(7) & data_out_mem_A(7 downto 0));
	--sommo il valore di reg_sum con il valore letto da mem_A
	Sommatore_2:	Adder_subtractor_18_bit port map (a => data_sum_in, b => Data_out_mem_A_18_bit, Add_n_Sub => '0', y => data_sum_out);
	Reg_Sum	  :	Reg_18_bit port map( D => data_sum_out, Rest_1 => Rst, Clock => clk, Q => data_sum_in, EN_1 => LD_R_1);
	Data_Media_IN <= data_sum_in(17 downto 10);
	Reg_M 	  : 	Reg_8_bit port map( D => Data_Media_in, Rest_1 => Rst, Clock => clk, Q => Data_media_out, EN_1 => DONE);
	--associazione del dato di media alla porta di uscita
	M <= Data_media_out;
	

	--descrizione della struttura che mi permette un'eventuale lettura dei dati dalla mem B...puramente combinatoria
	process (done, cnt)
	begin
	if ((DONE and cnt(0) and cnt(1))='1') then
		M_disp_sgn <= '1';
	end if;
	end process;
	M_disp<= M_disp_sgn;
	
end behav;