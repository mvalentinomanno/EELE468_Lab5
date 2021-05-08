library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Avalon2Simulink is
	port(
		sys_clk		: in std_logic;
		sys_reset	: in std_logic;
		avalon_slave_address : in std_logic_vector(2 downto 0);
		avalon_slave_write   : in std_logic;
		avalon_slave_writedata : in std_logic_vector(31 downto 0);
		avalon_slave_read	: in std_logic;
		avalon_slave_readdata	: out std_logic_vector(31 downto 0);
		avalon_streaming_source_data : out std_logic_vector(23 downto 0);
		avalon_streaming_source_valid : out std_logic;
		avalon_streaming_source_channel : out std_logic;
		avalon_Streaming_sink_data : in std_logic_vector(23 downto 0);
		avalon_streaming_sink_valid : in std_logic;
		avalon_streaming_sink_channel : in std_logic
		);
end entity Avalon2Simulink;

architecture Avalon2Simulink_arch of Avalon2Simulink is

	component dataplane
		port(
			clk	: in std_logic;
			reset : in std_logic;
			clk_enable : in std_logic;
			input_signal : in std_logic_vector(23 downto 0);
			delay_samples : in std_logic_vector(15 downto 0);
			echo_gain : in std_logic_vector(15 downto 0);
			enable : in std_logic;
			ce_out : out std_logic;
			output_signal : out std_logic_vector(23 downto 0)
		
		);
	end component;

	signal data_l_ADC : std_logic_vector(23 downto 0);
	signal data_l_DAC : std_logic_vector(23 downto 0);
	signal data_r_ADC : std_logic_vector(23 downto 0);
	signal data_r_DAC : std_logic_vector(23 downto 0);
	
	signal l_en : std_logic := '1';
	signal l_delay_samp : std_logic_vector(15 downto 0) := "0010011100010000";
	signal l_echo_gain : std_logic_vector(15 downto 0) := x"6000";
	signal r_en	: std_logic := '1';
	signal r_delay_samp : std_logic_vector(15 downto 0) := "0010011100010000";
	signal r_echo_gain : std_logic_vector(15 downto 0) := x"6000";
	
	signal zeros31 : std_logic_vector(30 downto 0) := (others => '0');	
	signal zeros16 : std_logic_vector(15 downto 0) := (others => '0');
begin

process (sys_clk)
	begin
		if rising_Edge(sys_clk) then
			if avalon_streaming_sink_valid = '1' then
				if avalon_Streaming_sink_channel = '0' then --left channel
					data_l_ADC <= avalon_streaming_sink_data;
					avalon_streaming_source_data <= data_l_DAC;
					avalon_streaming_source_channel <= '0';
					avalon_streaming_source_valid <= '1';
				else --right channel
					data_r_ADC <= avalon_streaming_sink_data;
					avalon_streaming_source_data <= data_r_DAC;
					avalon_streaming_source_channel <= '1';
					avalon_streaming_source_valid <= '1';
				end if;
			else
				avalon_streaming_source_valid <= '0';
			end if;
		end if;
	end process;
	
	
	process(sys_clk) is --read registers
	begin
		if rising_edge(sys_clk) and avalon_slave_read ='1' then
			case avalon_slave_address is
				when "000" => avalon_slave_readdata <= zeros31 & l_en;
				when "001" => avalon_slave_readdata <= zeros16 & l_delay_samp;
				when "010" => avalon_slave_readdata <= zeros16 & l_echo_gain;
				when "100" => avalon_slave_readdata <= zeros31 & r_en;
				when "101" => avalon_slave_readdata <= zeros16 & r_delay_samp;
				when "110" => avalon_slave_readdata <= zeros16 & r_echo_gain;
				when others => avalon_slave_readdata <= (others => '0');
			end case;
		end if;
	end process;
	
	process(sys_clk) is
	begin
		if rising_edge(sys_clk) and avalon_slave_write = '1' then
			case avalon_slave_address is
				when "000" => l_en <= avalon_slave_writedata(0);
				when "001" => l_delay_samp <= avalon_slave_writedata(15 downto 0);
				when "010" => l_echo_gain <= avalon_slave_writedata(15 downto 0);
				when "100" => r_en <= avalon_slave_writedata(0);
				when "101" => r_delay_samp <= avalon_slave_writedata(15 downto 0);
				when "110" => r_echo_gain <= avalon_slave_writedata(15 downto 0);
				when others =>
			end case;
		end if;
	end process;
	
	right : dataplane port map(
		clk	=> sys_clk,
		reset	=> sys_reset,
		clk_enable => '1',
		input_signal => data_r_ADC,
		delay_samples => r_delay_samp,
		echo_gain => r_echo_gain,
		enable => r_en,
		ce_out => open,
		output_signal => data_r_DAC
	);
	
		
	left : dataplane port map(
		clk	=> sys_clk,
		reset	=> sys_reset,
		clk_enable => '1',
		input_signal => data_l_ADC,
		delay_samples => l_delay_samp,
		echo_gain => l_echo_gain,
		enable => l_en,
		ce_out => open,
		output_signal => data_l_DAC
	);
	
end architecture; 