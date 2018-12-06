
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY TB_SPI IS
END TB_SPI;
 
ARCHITECTURE behavior OF TB_SPI IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT SPI
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         i_start : IN  std_logic;
         o_sclk : OUT  std_logic;
         i_miso : IN  std_logic;
         o_cs : OUT  std_logic;
         o_data_out : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal start : std_logic := '0';
   signal miso : std_logic := '0';

 	--Outputs
   signal sclk : std_logic;
   signal cs : std_logic;
   signal data_out : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   
   --integer
   signal i : integer :=0;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: SPI PORT MAP (
          clk => clk,
          rst => rst,
          i_start => start,
          o_sclk => sclk,
          i_miso => miso,
          o_cs => cs,
          o_data_out => data_out
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process; 

   -- Stimulus process
   stim_proc: process
   begin		

      wait for clk_period*10;
      
      start <= '1';

      -- insert stimulus here

      for i in 0 to 50 loop
        wait for clk_period*1;
		miso <= not(miso);
	  end loop; 

      wait;
   end process;

END;
