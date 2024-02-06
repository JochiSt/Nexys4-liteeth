--------------------------------------------------------------------------------
-- Generate all clocks needed for the Ethernet implementation
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- for using the Xilinx cells
LIBRARY UNISIM;
USE UNISIM.vcomponents.ALL;

ENTITY Ethernet_PLL IS
    PORT (
        CLK100MHz : IN STD_LOGIC;

        CLK125MHz : OUT STD_LOGIC;
        CLK50MHz  : OUT STD_LOGIC
    );
END Ethernet_PLL;

ARCHITECTURE Behavioral OF Ethernet_PLL IS

    -- PLL 0
    SIGNAL PLL_0_CLK_FB : STD_LOGIC := '0';
    SIGNAL PLL_0_locked : STD_LOGIC := '0';

BEGIN

    -- PLL for CLK generation of the Ethernet PHY
    -- running internally with 100 MHz * 10 = 1 GHz
    PLLE2_BASE_0 : PLLE2_BASE
    GENERIC MAP(
        BANDWIDTH          => "OPTIMIZED", -- OPTIMIZED, HIGH, LOW
        CLKFBOUT_MULT      => 10,          -- Multiply value for all CLKOUT, (2-64)
        CLKFBOUT_PHASE     => 0.0,         -- Phase offset in degrees of CLKFB, (-360.000-360.000).
        CLKIN1_PERIOD      => 10.0,        -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).

        -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
        CLKOUT0_DIVIDE     => 8,           -- 1000 MHz / 8 = 125 MHz
        CLKOUT1_DIVIDE     => 20,          -- 1000 MHz / 20 = 50 MHz
        CLKOUT2_DIVIDE     => 1,
        CLKOUT3_DIVIDE     => 1,
        CLKOUT4_DIVIDE     => 1,
        CLKOUT5_DIVIDE     => 1,

        -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
        CLKOUT0_DUTY_CYCLE => 0.5,
        CLKOUT1_DUTY_CYCLE => 0.5,
        CLKOUT2_DUTY_CYCLE => 0.5,
        CLKOUT3_DUTY_CYCLE => 0.5,
        CLKOUT4_DUTY_CYCLE => 0.5,
        CLKOUT5_DUTY_CYCLE => 0.5,

        -- CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
        CLKOUT0_PHASE      => 0.0,
        CLKOUT1_PHASE      => 0.0,
        CLKOUT2_PHASE      => 0.0,
        CLKOUT3_PHASE      => 0.0,
        CLKOUT4_PHASE      => 0.0,
        CLKOUT5_PHASE      => 0.0,

        DIVCLK_DIVIDE      => 1,      -- Master division value, (1-56)
        REF_JITTER1        => 0.0,    -- Reference input jitter in UI, (0.000-0.999).
        STARTUP_WAIT       => "FALSE" -- Delay DONE until PLL Locks, ("TRUE"/"FALSE")
    )
    PORT MAP(
        -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
        CLKOUT0  => CLK125MHz,    -- 1-bit output: CLKOUT0
        CLKOUT1  => CLK50MHz,     -- 1-bit output: CLKOUT1
        CLKOUT2  => OPEN,         -- 1-bit output: CLKOUT2
        CLKOUT3  => OPEN,         -- 1-bit output: CLKOUT3
        CLKOUT4  => OPEN,         -- 1-bit output: CLKOUT4
        CLKOUT5  => OPEN,         -- 1-bit output: CLKOUT5

        -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
        CLKFBOUT => PLL_0_CLK_FB, -- 1-bit output: Feedback clock
        LOCKED   => PLL_0_locked, -- 1-bit output: LOCK
        CLKIN1   => CLK100MHZ,    -- 1-bit input: Input clock

        -- Control Ports: 1-bit (each) input: PLL control ports
        PWRDWN   => '0',          -- 1-bit input: Power-down
        RST      => '0',          -- 1-bit input: Reset

        -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
        CLKFBIN  => PLL_0_CLK_FB  -- 1-bit input: Feedback clock
    );

END Behavioral;
