
-- ADS7816 Driver
   
-- caution: maximum input clock speed: 50 MHz
-- T_SUCS: minimum time from CS negedge to SCLK rising edge
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity ADS7816_driver is

	generic (
		DATA_WIDTH	: integer := 16;
		T_SUCS		: integer := 3
	);
 
	port (
	    clk	   		: in  std_logic;          	-- clock
		rst			: in  std_logic;			-- synch reset
		i_start		: in  std_logic;			-- start data transfer
		o_sclk		: out std_logic := '0';		-- DCLOCK
		i_miso    	: in  std_logic;        	-- DOUT from ADC    --master in, slave out
		o_cs      	: out std_logic := '0'; 	-- slave select (Active Low)
		o_data_out	: out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0')  -- adc parallel data 
	);
		 
end entity;

architecture Behavioral of ADS7816_driver is

--------------------------------------------------------------

	type adc_state_type is (IDLE, T_SUCS_WAIT, DATA_TRANSFER); 
   	signal adc_state, adc_next_state : adc_state_type := IDLE;

	signal transfer_end : std_logic := '0';
	signal t_sucs_done	: std_logic := '0';
	signal shift_in		: std_logic := '0';
	
	signal rx_data   	: std_logic_vector (DATA_WIDTH-1 downto 0):= (others => '0');
	
	signal timer		: integer range 0 to (DATA_WIDTH + T_SUCS) := 0;
	signal timer_en		: std_logic := '0';
	signal timer_rst	: std_logic := '0';
  
begin

--------------------------------------------------------------
	
	NEXT_STATE_DECODE: process (adc_state, i_start, transfer_end, t_sucs_done)
		begin

			adc_next_state <= idle;			

			case (adc_state) is

		  		when IDLE =>
					if (i_start = '1') then
						adc_next_state <= T_SUCS_WAIT;
					else
					    adc_next_state <= IDLE;
					end if;
					
				when T_SUCS_WAIT =>
				    if (t_sucs_done = '1') then
				        adc_next_state <= DATA_TRANSFER;
				    else
				    	adc_next_state <= T_SUCS_WAIT;
				    end if;

				when DATA_TRANSFER =>
					if (transfer_end = '1') then
						adc_next_state <= IDLE;
					else
					    adc_next_state <= DATA_TRANSFER;
					end if;

				when others =>
					adc_next_state <= idle;

			end case;      

		end process;

--------------------------------------------------------------

	SYNC_PROC: process (clk)
	   begin

		  if (clk'event and clk = '0') then
		  	adc_state <= adc_next_state;       
		  end if;

	   end process;

--------------------------------------------------------------

	OUTPUT_DECODE: process (adc_state)
		begin

			o_cs <= '1';
			timer_en <= '0';
			timer_rst <= '0';
			shift_in <= '0';
 
			case (adc_state) is

		  		when IDLE =>
					timer_rst <= '1';
					
				when T_SUCS_WAIT =>
					timer_en <= '1';
					o_cs <= '0';

				when DATA_TRANSFER =>
					o_cs <= '0';
					shift_in <= '1';
					timer_en <= '1';

				when others =>
					o_cs <= '1';
					timer_en <= '0';
					timer_rst <= '0';

			end case;
		
		end process;

--------------------------------------------------------------

	BIT_COUNTER: process (clk)
		begin
		
			if (clk'event and clk='0') then
				if (timer_rst = '1') then
					timer <= 0;
				elsif (timer_en = '1') then
					timer <= timer + 1;
				end if;
			end if;

		end process;

	t_sucs_done  <= '1' when timer = T_SUCS else '0';	--whaiting atleast 50 ns
	transfer_end <= '1' when timer = (DATA_WIDTH + T_SUCS) else '0'; 
	
--------------------------------------------------------------
	
    SHIFT_REG: process (clk)
        begin
            if (clk'event and clk='1') then
				if(rst = '1') then
					rx_data <= (others => '0');
                elsif(shift_in = '1') then
                    rx_data <= rx_data(DATA_WIDTH-2 downto 0) & i_miso;	--MSB first order
                end if;
            end if;
        end process;

--------------------------------------------------------------
		
	o_sclk <= clk when (shift_in = '1') else '0'; --disabling clock until t_SUCS is passed
	o_data_out <= rx_data;
	
end;

