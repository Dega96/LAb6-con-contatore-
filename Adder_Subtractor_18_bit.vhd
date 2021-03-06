library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Sommatore con parallelismo da 18 bit
entity Adder_Subtractor_18_bit is
generic (n : integer := 18);
	port(
			Add_n_Sub : IN std_logic;
			a, b : IN signed (n-1 downto 0);
			y	  : Out signed (n-1 downto 0)
		 );
end Adder_Subtractor_18_bit;

architecture behav of Adder_Subtractor_18_bit is

begin
	process (a,b, Add_n_Sub)
		begin	
			if(Add_n_Sub = '1') then
				y<= a-b;
			else 
				y <= a+b;
			end if;   
		end process;
 
end behav;