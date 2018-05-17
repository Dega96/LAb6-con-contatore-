library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM_256x8 is 
port ( Address : in std_logic_vector (7 downto 0);
		 Data_in : in signed(7 downto 0);
		 data_out: out signed(7 downto 0);
		 cs, write_0_read_1, clock : in std_logic);
end RAM_256x8;

architecture Struct of RAM_256x8 is


begin


process(clock, cs, address, write_0_read_1, data_in) is
			
type ram_array is array (0 to 255) of signed(7 downto 0) ;
variable  mem : ram_array;

begin
--data_out<=(others=>'Z');
if (cs='1') then
	if (  write_0_read_1='1' ) then
--if( write_0_read_1='1') then
	Data_out<= mem(to_integer(unsigned(Address)));
--end if;
--end if;

	elsif(clock'event and clock= '1') then
		if (write_0_read_1='0') then
--if (cs='1') then
			mem(to_integer(unsigned(Address))) := Data_in;
		end if;
	end if;
end if;
end process;


end Struct;