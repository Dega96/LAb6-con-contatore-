library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SRAM_SW_AR_256x8 is
port( Address : in std_logic_vector (7 downto 0);
		Data_in : in signed(7 downto 0);
		Data_out : out signed(7 downto 0);
		cs, write_0_read_1, clock: in std_logic
		);
end SRAM_SW_AR_256x8;

architecture Struct of SRAM_SW_AR_256x8 is
component RAM_256x8 is
port (Address : in std_logic_vector (7 downto 0);
		Data_in : in signed(7 downto 0);
		Data_out : out signed(7 downto 0);
		cs, write_0_read_1, clock : in std_logic);
end component;
begin
Mema : RAM_256x8 port map (Address, Data_in, Data_out, cs, write_0_read_1, clock);
end Struct; 	