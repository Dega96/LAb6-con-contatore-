library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity counter_12_bit_sincrono is
	generic ( N : integer:=12);
	port 
		(
		Cnt_EN_1, CLK, Clear_1: in std_logic; 
	   cnt: buffer unsigned(N-1 downto 0)
		);
		end counter_12_bit_sincrono;
		
architecture struct of counter_12_bit_sincrono is

	begin
		process (clk, clear_1, cnt_en_1)
			begin
			if (clear_1 = '1') then
						--cnt(12 downto 11) <= "11";
						cnt <= (others => '0');
				elsif((CLK'event and CLK='1') and Cnt_En_1 ='1') then
					
					if(Cnt_EN_1 = '1') then
                  cnt <= cnt + 1;
					end if;
            end if;
			end process;
		
	end struct;