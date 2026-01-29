LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL; -- signed / unsigned

ENTITY UDP2LED IS
    GENERIC (
        RESET_RELEASE_CNT : INTEGER := 10000 -- count how many clock cycles the reset should be low after startup

    );
    PORT (
        CLK100MHZ : IN STD_LOGIC;

        PhyRxd   : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
        PhyTxd   : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
        PhyCrs   : IN STD_LOGIC;
        PhyTxEn  : OUT STD_LOGIC;
        PhyRxErr : IN STD_LOGIC;

        PhyMdc      : OUT STD_LOGIC;
        PhyMdio     : INOUT STD_LOGIC;
        PhyClk50Mhz : OUT STD_LOGIC;
        PhyRstn     : OUT STD_LOGIC;

        -- display signals for ARP and UDP packets
        RGB1_Blue  : OUT STD_LOGIC;
        RGB1_Green : OUT STD_LOGIC;
        RGB1_Red   : OUT STD_LOGIC;

        RGB2_Blue  : OUT STD_LOGIC;
        RGB2_Green : OUT STD_LOGIC;
        RGB2_Red   : OUT STD_LOGIC;

        -- Reset and SMI inputs/outputs
        btnCpuReset : IN STD_LOGIC;
        LED         : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
        sw          : IN STD_LOGIC_VECTOR (15 DOWNTO 0)
    );
END UDP2LED;

ARCHITECTURE Behavioral OF UDP2LED IS
    ----------------------------------------------------------------------------
    -- CLOCKS
    ----------------------------------------------------------------------------
    SIGNAL CLK50MHZ : STD_LOGIC := '0';

    ----------------------------------------------------------------------------
    -- RESET
    ----------------------------------------------------------------------------
    SIGNAL reset_cnt : INTEGER RANGE 0 TO RESET_RELEASE_CNT + 1 := 0; -- counter for releasing the reset signal
    SIGNAL reset_n   : STD_LOGIC                                := '0';
    ----------------------------------------------------------------------------

    COMPONENT Ethernet_PLL IS
        PORT (
            CLK100MHz : IN STD_LOGIC;

            CLK125MHz : OUT STD_LOGIC;
            CLK50MHz  : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL CLK125MHz : STD_LOGIC := '0';
    ----------------------------------------------------------------------------
    -- liteeth core (from instatiation template)
    ----------------------------------------------------------------------------
    COMPONENT liteeth_core IS
        PORT (
            rmii_clocks_ref_clk : IN STD_LOGIC;
            rmii_crs_dv         : IN STD_LOGIC;
            rmii_mdc            : OUT STD_LOGIC;
            rmii_mdio           : INOUT STD_LOGIC;
            rmii_rst_n          : OUT STD_LOGIC;
            rmii_rx_data        : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
            rmii_tx_data        : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
            rmii_tx_en          : OUT STD_LOGIC;

            sys_clock : IN STD_LOGIC;
            sys_reset : IN STD_LOGIC;

            udp0_sink_data  : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            udp0_sink_last  : IN STD_LOGIC;
            udp0_sink_ready : OUT STD_LOGIC;
            udp0_sink_valid : IN STD_LOGIC;

            udp0_source_data  : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            udp0_source_error : OUT STD_LOGIC;
            udp0_source_last  : OUT STD_LOGIC;
            udp0_source_ready : IN STD_LOGIC;
            udp0_source_valid : OUT STD_LOGIC
        );
    END COMPONENT;

    --------------------------------------------------------------------------------
    -- SIGNAL templates
    --------------------------------------------------------------------------------
    SIGNAL sys_clock : STD_LOGIC := '0';
    SIGNAL sys_reset : STD_LOGIC := '0';

    -- FPGA to PHY (sending)
    SIGNAL udp0_sink_data  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL udp0_sink_last  : STD_LOGIC                    := '0';
    SIGNAL udp0_sink_ready : STD_LOGIC                    := '0';
    SIGNAL udp0_sink_valid : STD_LOGIC                    := '0';

    -- PHY to FPGA (receiving)
    SIGNAL udp0_source_data  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL udp0_source_error : STD_LOGIC                    := '0';
    SIGNAL udp0_source_last  : STD_LOGIC                    := '0';
    SIGNAL udp0_source_ready : STD_LOGIC                    := '0';
    SIGNAL udp0_source_valid : STD_LOGIC                    := '0';

BEGIN

    ----------------------------------------------------------------------------
    -- clock
    -- generate  50 MHz clock needed for the PHY
    -- generate 200 MHz for the liteeth
    Ethernet_PLL_0 : Ethernet_PLL
    PORT MAP(
        CLK100MHz => CLK100MHZ,

        CLK125MHz => CLK125MHz,
        CLK50MHz  => CLK50MHZ
    );
    -- forward the 50MHz clock to the PHY
    PhyClk50Mhz <= CLK50MHZ;
    sys_clock   <= CLK100MHZ;

    ----------------------------------------------------------------------------
    -- RESET
    -- a simple process removing the reset condition
    proc_reset : PROCESS (clk100MHz) BEGIN
        IF rising_edge(clk100MHz) THEN
            IF reset_n = '0' THEN
                IF reset_cnt < RESET_RELEASE_CNT THEN
                    reset_cnt <= reset_cnt + 1;
                ELSE
                    reset_n <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS proc_reset;

    sys_reset <= NOT reset_n;

    ----------------------------------------------------------------------------
    -- liteeth core instantiation
    liteeth_core_0 : liteeth_core
    PORT MAP(
        rmii_clocks_ref_clk => CLK50MHZ,
        rmii_rst_n          => PhyRstn,
        rmii_mdc            => PhyMdc,
        rmii_mdio           => PhyMdio,

        rmii_rx_data => PhyRxd,
        rmii_crs_dv  => PhyCrs,

        rmii_tx_data => PhyTxd,
        rmii_tx_en   => PhyTxEn,

        sys_clock => sys_clock,
        sys_reset => sys_reset,

        udp0_sink_data  => udp0_sink_data,
        udp0_sink_last  => udp0_sink_last,
        udp0_sink_ready => udp0_sink_ready,
        udp0_sink_valid => udp0_sink_valid,

        udp0_source_data  => udp0_source_data,
        udp0_source_error => udp0_source_error,
        udp0_source_last  => udp0_source_last,
        udp0_source_ready => udp0_source_ready,
        udp0_source_valid => udp0_source_valid
    );

    ----------------------------------------------------------------------------
    -- UDP to LED writer instantiation
    UDP2LED_inst : ENTITY work.UDP_led_writer
        PORT MAP(
            -- system clock and reset
            clk     => CLK100MHZ,
            reset_n => reset_n,

            -- data from liteeth UDP core
            udp_source_valid => udp0_source_valid,
            udp_source_last  => udp0_source_last,
            udp_source_ready => udp0_source_ready,
            udp_source_data  => udp0_source_data,
            udp_source_error => udp0_source_error,

            -- output to the LEDs
            leds => led
        );
END Behavioral;
