
--------------------------------------------------------------
-- Single port Block RAM with specific size
--------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

library xpm;
use xpm.vcomponents.all;

ENTITY spram_sz IS
	generic (
		addr_width    : integer := 8;
		data_width    : integer := 8;
		numwords      : integer := 2**8;
		mem_init_file : string := "none";
		--mem_name      : string := "MEM" -- for InSystem Memory content editor.
		--mem_name      : string := "0" -- for InSystem Memory content editor.
		mem_name      : string := "" -- for InSystem Memory content editor.
	);
	PORT
	(
		clock   : in  STD_LOGIC;
		address : in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0);
		data    : in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
		enable  : in  STD_LOGIC := '1';
		wren    : in  STD_LOGIC := '0';
		q       : out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		cs      : in  std_logic := '1'
	);
END ENTITY;

ARCHITECTURE SYN OF spram_sz IS
	signal q0 : std_logic_vector((data_width - 1) downto 0);
	signal wea : std_logic;
BEGIN
	q   <= q0 when cs = '1' else (others => '1');
	wea <= wren and cs;

	spram_xpm : xpm_memory_spram
	GENERIC MAP (
		ADDR_WIDTH_A         => addr_width,
		MEMORY_INIT_FILE     => mem_init_file,
		--MEMORY_INIT_PARAM    => mem_name,
		--MEMORY_INIT_FILE     => "none",
		MEMORY_INIT_PARAM    => "",		
		MEMORY_SIZE          => numwords * data_width,
		MEMORY_PRIMITIVE     => "auto",
		AUTO_SLEEP_TIME      => 0,
		ECC_MODE             => "no_ecc",
		WAKEUP_TIME          => "disable_sleep",
		WRITE_DATA_WIDTH_A   => data_width,
		READ_DATA_WIDTH_A    => data_width,
		BYTE_WRITE_WIDTH_A   => data_width,
		READ_LATENCY_A       => 1,
		WRITE_MODE_A         => "write_first",
		READ_RESET_VALUE_A   => "0",
		RST_MODE_A           => "SYNC"
	)
	PORT MAP (
		clka              => clock,
		addra             => address,
		dina              => data,
		ena               => enable,
		wea(0)            => wea,
		douta             => q0,
		sleep             => '0',
		rsta              => '0',
		regcea            => '1',
		injectsbiterra    => '0',
		injectdbiterra    => '0',
		sbiterra          => open,
		dbiterra          => open
	);

END SYN;

--------------------------------------------------------------
-- Single port Block RAM
--------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

library xpm;
use xpm.vcomponents.all;

ENTITY spram IS
	generic (
		addr_width    : integer := 8;
		data_width    : integer := 8;
		mem_init_file : string := "none";
		mem_name      : string := "MEM" -- for InSystem Memory content editor.
	);
	PORT
	(
		clock   : in  STD_LOGIC;
		address : in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0);
		data    : in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
		enable  : in  STD_LOGIC := '1';
		wren    : in  STD_LOGIC := '0';
		q       : out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		cs      : in  std_logic := '1'
	);
END spram;


ARCHITECTURE SYN OF spram IS
BEGIN
	spram_sz : entity work.spram_sz
	generic map(addr_width, data_width, 2**addr_width, mem_init_file, mem_name)
	port map(clock,address,data,enable,wren,q,cs);
END SYN;

--------------------------------------------------------------
-- Dual port Block RAM different parameters on ports
--------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

library xpm;
use xpm.vcomponents.all;

entity dpram_dif is
	generic (
		addr_width_a  : integer := 8;
		data_width_a  : integer := 8;
		addr_width_b  : integer := 8;
		data_width_b  : integer := 8;
		mem_init_file : string := "none"
	);
	PORT
	(
		clock		: in  STD_LOGIC;
		
		address_a	: in  STD_LOGIC_VECTOR (addr_width_a-1 DOWNTO 0);
		data_a		: in  STD_LOGIC_VECTOR (data_width_a-1 DOWNTO 0) := (others => '0');
		enable_a	: in  STD_LOGIC := '1';
		wren_a		: in  STD_LOGIC := '0';
		q_a			: out STD_LOGIC_VECTOR (data_width_a-1 DOWNTO 0);
		cs_a        : in  std_logic := '1';

		address_b	: in  STD_LOGIC_VECTOR (addr_width_b-1 DOWNTO 0) := (others => '0');
		data_b		: in  STD_LOGIC_VECTOR (data_width_b-1 DOWNTO 0) := (others => '0');
		enable_b	: in  STD_LOGIC := '1';
		wren_b		: in  STD_LOGIC := '0';
		q_b			: out STD_LOGIC_VECTOR (data_width_b-1 DOWNTO 0);
		cs_b        : in  std_logic := '1'
	);
end entity;


ARCHITECTURE SYN OF dpram_dif IS

	signal q0 : std_logic_vector((data_width_a - 1) downto 0);
	signal q1 : std_logic_vector((data_width_b - 1) downto 0);
	signal wea : std_logic;
	signal web : std_logic;
	

BEGIN
	q_a <= q0 when cs_a = '1' else (others => '1');
	q_b <= q1 when cs_b = '1' else (others => '1');
	wea <= wren_a and cs_a;
	web <= wren_b and cs_b;

	dpram_xpm : xpm_memory_tdpram
	GENERIC MAP (
		ADDR_WIDTH_A         => addr_width_a,
		ADDR_WIDTH_B         => addr_width_b,
		READ_DATA_WIDTH_A    => data_width_a,
		READ_DATA_WIDTH_B    => data_width_b,
		WRITE_DATA_WIDTH_A   => data_width_a,
		WRITE_DATA_WIDTH_B   => data_width_b,
		BYTE_WRITE_WIDTH_A   => data_width_a,
		BYTE_WRITE_WIDTH_B   => data_width_b,
		MEMORY_INIT_FILE     => mem_init_file,
		MEMORY_INIT_PARAM    => "0",
		--MEMORY_INIT_PARAM    => "",
		MEMORY_SIZE          => (2**addr_width_a) * data_width_a,
		MEMORY_PRIMITIVE     => "auto",
		CLOCKING_MODE        => "common_clock",
		READ_LATENCY_A       => 1,
		READ_LATENCY_B       => 1,
		WRITE_MODE_A         => "write_first",
		WRITE_MODE_B         => "write_first",
		RST_MODE_A           => "SYNC",
		RST_MODE_B           => "SYNC"
	)
	PORT MAP (
		clka              => clock,
		ena               => enable_a,
		wea(0)            => wea,
		addra             => address_a,
		dina              => data_a,
		douta             => q0,
		clkb              => clock,
		enb               => enable_b,
		web(0)            => web,
		addrb             => address_b,
		dinb              => data_b,
		doutb             => q1,
		sleep             => '0',
		rsta              => '0',
		rstb              => '0',
		regcea            => '1',
		regceb            => '1',
		injectsbiterra    => '0',
		injectsbiterrb    => '0',
		injectdbiterra    => '0',
		injectdbiterrb    => '0',
		sbiterra          => open,
		sbiterrb          => open,
		dbiterra          => open,
		dbiterrb          => open
	);

END SYN;


--------------------------------------------------------------
-- Dual port Block RAM different parameters and clocks on ports
--------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

library xpm;
use xpm.vcomponents.all;

entity dpram_difclk is
	generic (
		addr_width_a  : integer := 8;
		data_width_a  : integer := 8;
		addr_width_b  : integer := 8;
		data_width_b  : integer := 8;
		mem_init_file : string := "none"
	);
	PORT
	(
		clk_a		: in  STD_LOGIC;
		clk_b		: in  STD_LOGIC;
		
		address_a	: in  STD_LOGIC_VECTOR (addr_width_a-1 DOWNTO 0);
		data_a		: in  STD_LOGIC_VECTOR (data_width_a-1 DOWNTO 0) := (others => '0');
		enable_a	: in  STD_LOGIC := '1';
		wren_a		: in  STD_LOGIC := '0';
		q_a			: out STD_LOGIC_VECTOR (data_width_a-1 DOWNTO 0);
		cs_a        : in  std_logic := '1';

		address_b	: in  STD_LOGIC_VECTOR (addr_width_b-1 DOWNTO 0) := (others => '0');
		data_b		: in  STD_LOGIC_VECTOR (data_width_b-1 DOWNTO 0) := (others => '0');
		enable_b	: in  STD_LOGIC := '1';
		wren_b		: in  STD_LOGIC := '0';
		q_b			: out STD_LOGIC_VECTOR (data_width_b-1 DOWNTO 0);
		cs_b        : in  std_logic := '1'
	);
end entity;


ARCHITECTURE SYN OF dpram_difclk IS

	signal q0 : std_logic_vector((data_width_a - 1) downto 0);
	signal q1 : std_logic_vector((data_width_b - 1) downto 0);
	signal wea : std_logic;
	signal web : std_logic;

BEGIN
	q_a <= q0 when cs_a = '1' else (others => '1');
	q_b <= q1 when cs_b = '1' else (others => '1');
	wea <= wren_a and cs_a;
	web <= wren_b and cs_b;

	dpram_xpm : xpm_memory_tdpram
	GENERIC MAP (
		ADDR_WIDTH_A         => addr_width_a,
		ADDR_WIDTH_B         => addr_width_b,
		READ_DATA_WIDTH_A    => data_width_a,
		READ_DATA_WIDTH_B    => data_width_b,
		WRITE_DATA_WIDTH_A   => data_width_a,
		WRITE_DATA_WIDTH_B   => data_width_b,
		BYTE_WRITE_WIDTH_A   => data_width_a,
		BYTE_WRITE_WIDTH_B   => data_width_b,
		MEMORY_INIT_FILE     => mem_init_file,
		MEMORY_INIT_PARAM    => "0",		
		--MEMORY_INIT_PARAM    => "",		
		MEMORY_SIZE          => (2**addr_width_a) * data_width_a,
		MEMORY_PRIMITIVE     => "auto",
		CLOCKING_MODE        => "independent_clock",
		READ_LATENCY_A       => 1,
		READ_LATENCY_B       => 1,
		WRITE_MODE_A         => "write_first",
		WRITE_MODE_B         => "write_first",
		RST_MODE_A           => "SYNC",
		RST_MODE_B           => "SYNC"
	)
	PORT MAP (
		clka              => clk_a,
		ena               => enable_a,
		wea(0)            => wea,
		addra             => address_a,
		dina              => data_a,
		douta             => q0,
		clkb              => clk_b,
		enb               => enable_b,
		web(0)            => web,
		addrb             => address_b,
		dinb              => data_b,
		doutb             => q1,
		sleep             => '0',
		rsta              => '0',
		rstb              => '0',
		regcea            => '1',
		regceb            => '1',
		injectsbiterra    => '0',
		injectsbiterrb    => '0',
		injectdbiterra    => '0',
		injectdbiterrb    => '0',
		sbiterra          => open,
		sbiterrb          => open,
		dbiterra          => open,
		dbiterrb          => open
	);

END SYN;

--------------------------------------------------------------
-- Dual port Block RAM same parameters on both ports
--------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

library xpm;
use xpm.vcomponents.all;

entity dpram is
	generic (
		addr_width    : integer := 8;
		data_width    : integer := 8;
		mem_init_file : string := "none"
	);
	PORT
	(
		clock		: in  STD_LOGIC;

		address_a	: in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0);
		data_a		: in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
		enable_a	: in  STD_LOGIC := '1';
		wren_a		: in  STD_LOGIC := '0';
		q_a			: out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		cs_a        : in  std_logic := '1';

		address_b	: in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0) := (others => '0');
		data_b		: in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
		enable_b		: in  STD_LOGIC := '1';
		wren_b		: in  STD_LOGIC := '0';
		q_b			: out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		cs_b        : in  std_logic := '1'
	);
end entity;


ARCHITECTURE SYN OF dpram IS
BEGIN
	ram : entity work.dpram_dif generic map(addr_width,data_width,addr_width,data_width,mem_init_file)
	port map(clock,address_a,data_a,enable_a,wren_a,q_a,cs_a,address_b,data_b,enable_b,wren_b,q_b,cs_b);
END SYN;
