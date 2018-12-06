
--------- SPIokkcsout3

--------------------------------------------------------------------------------

--   SPI
   
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity SPI is

	generic (
		DATA_WIDTH	: integer := 16
	);
 
	port (
	    clk	   		: in  std_logic;          -- clock
		rst			: in  std_logic;		-- synch reset
		start		: in  std_logic;		-- start data transfer
		sclk		: out std_logic;      		-- DCLOCK
		miso    	: in  std_logic;        	-- DOUT from ADC    --master in, slave out
		cs      	: out std_logic; 	-- slave select (Active Low)
		data_out	: out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0')  -- adc parallel data 
	);
		 
end entity;

architecture Behavioral of SPI is

--------------------------------------------------------------

	type adc_state_type is (IDLE, DATA_TRANSFER); 
   	signal adc_state, adc_next_state : adc_state_type := IDLE;

	signal transfer_end : std_logic := '0';
	signal rx_data   	: std_logic_vector (DATA_WIDTH-1 downto 0):= (others => '0');
	signal bit_cnt		: integer range 0 to  DATA_WIDTH := 0;
	signal bit_cnt_en	: std_logic := '0';
	signal bit_cnt_rst	: std_logic := '0';
  
begin

--------------------------------------------------------------

	sclk <= clk;
	
	NEXT_STATE_DECODE: process (adc_state, start, transfer_end)
		begin

			adc_next_state <= idle;			

			case (adc_state) is

		  		when IDLE =>
					if (start = '1') then
						adc_next_state <= DATA_TRANSFER;
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

		  if (clk'event and clk = '1') then
		  	adc_state <= adc_next_state;       
		  end if;

	   end process;

--------------------------------------------------------------

	OUTPUT_DECODE: process (adc_state)
		begin

			cs <= '1';
			bit_cnt_en <= '0';
			bit_cnt_rst <= '0';
 
			case (adc_state) is

		  		when IDLE =>
					bit_cnt_rst <= '1';

				when DATA_TRANSFER =>
					cs <= '0';
					bit_cnt_en <= '1';

				when others =>
					cs <= '1';
					bit_cnt_en <= '0';
					bit_cnt_rst <= '0';

			end case;
		
		end process;

--------------------------------------------------------------

	BIT_COUNTER: process (clk)
		begin
		
			if (clk'event and clk='1') then
				if (bit_cnt_rst = '1') then
					bit_cnt <= 0;
				elsif (bit_cnt_en = '1') then
					bit_cnt <= bit_cnt + 1;
				end if;
			end if;

		end process;

	transfer_end <= '1' when bit_cnt = DATA_WIDTH else '0'; 
	
--------------------------------------------------------------
	
    SHIFT_REG: process (clk)
        begin
            if (clk'event and clk='1') then
				if(rst = '1') then
					rx_data <= (others => '0');
                elsif(bit_cnt_en = '1') then
                    rx_data <= rx_data(DATA_WIDTH-2 downto 0) & miso;
                end if;
            end if;
        end process;
		
		data_out <= rx_data;
	
end;
