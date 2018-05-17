library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SRAM_SW_AR_1024x8 is
port( Address : in std_logic_vector (7 downto 0);
      DATA_IN : in signed(7 downto 0);
		DATA_OUT_A, DATA_OUT_B, DATA_OUT_C, DATA_OUT_D : out signed(7 downto 0);
		CS : in std_logic_vector(3 downto 0);
		Write_0_read_1, clock : in std_logic
		);
end SRAM_SW_AR_1024x8;

architecture Struct of SRAM_SW_AR_1024x8 is

component SRAM_SW_AR_256x8 is
port( Address : in std_logic_vector (7 downto 0);
		Data_in : in signed(7 downto 0);
		Data_out : out signed(7 downto 0);
		cs, write_0_read_1, clock : in std_logic
		);
end component;
begin 
Ram_0 : SRAM_SW_AR_256X8 port map (Address, data_in, DATA_OUT_A, CS(0), Write_0_read_1, Clock);
Ram_1 : SRAM_SW_AR_256X8 port map (Address, data_in, DATA_OUT_B, CS(1), Write_0_read_1, Clock);
Ram_2 : SRAM_SW_AR_256X8 port map (Address, data_in, DATA_OUT_C, CS(2), Write_0_read_1, Clock);
Ram_3 : SRAM_SW_AR_256X8 port map (Address, data_in, DATA_OUT_D, CS(3), Write_0_read_1, Clock);
end Struct;