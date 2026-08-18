<div align="center">

# UART Protocol RTL Design & Verification

### Modular Verilog RTL • Self-Checking Verification • FPGA Ready

<p>
  <img src="https://img.shields.io/badge/HDL-Verilog-1f425f?style=for-the-badge&logo=verilog" alt="Verilog">
  <img src="https://img.shields.io/badge/FPGA-Nexys%204-2ea44f?style=for-the-badge" alt="Nexys 4">
  <img src="https://img.shields.io/badge/Simulation-Vivado%20XSim-ff6600?style=for-the-badge" alt="Vivado XSim">
  <img src="https://img.shields.io/badge/Verification-Questa-8a2be2?style=for-the-badge" alt="Questa">
  <img src="https://img.shields.io/badge/Version%20Control-Git-F05032?style=for-the-badge&logo=git" alt="Git">
  <img src="https://img.shields.io/badge/Platform-GitHub-181717?style=for-the-badge&logo=github" alt="GitHub">
</p>

<p>
  <strong>100 MHz</strong> · <strong>115200 Baud</strong> · <strong>16× RX Oversampling</strong> · <strong>8-N-1 UART</strong>
</p>

<p>
  A modular, synthesizable UART RTL implementation with dedicated baud-rate generation,
  transmitter, receiver, integration, and self-checking verification testbenches.
</p>

</div>

---

## 1. Project Overview

| Parameter | Value |
|---|---:|
| System Clock | 100 MHz |
| Baud Rate | 115200 |
| RX Oversampling | 16× |
| Data Bits | 8 |
| Parity | None |
| Stop Bits | 1 |
| UART Format | 8-N-1 |
| Data Order | LSB first |

### Architecture

```text
                    ┌──────────────────────────┐
                    │        UART TOP          │
                    │          uart.v          │
                    │                          │
                    │  ┌────────────────────┐  │
                    │  │  baud_tick_gen.v   │  │
                    │  └───────┬────────────┘  │
                    │          │               │
                    │     TX tick / RX tick    │
                    │       │         │         │
                    │       ▼         ▼         │
                    │  ┌────────┐ ┌────────┐   │
                    │  │ uart_tx│ │ uart_rx│   │
                    │  │  .v    │ │  .v    │   │
                    │  └───┬────┘ └───┬────┘   │
                    │      │          │        │
                    └──────┼──────────┼────────┘
                           │          │
                          TX         RX
```

## 2. UART Protocol

The implemented UART uses an **8-N-1** frame.

```text
Idle ── Start ── D0 ── D1 ── D2 ── D3 ── D4 ── D5 ── D6 ── D7 ── Stop ── Idle
         0       <----------- 8 data bits ----------->        1
```

- Idle line = `1`
- Start bit = `0`
- 8 data bits
- LSB first
- No parity
- Stop bit = `1`

## 3. Repository Structure

```text
uart_protocol_rtl/
│
├── rtl/
│   ├── baud_tick_gen.v
│   ├── uart_tx.v
│   ├── uart_rx.v
│   └── uart.v
│
├── tb/
│   ├── baud_tick_gen_tb.v
│   ├── uart_tx_tb.v
│   ├── uart_rx_tb.v
│   └── uart_tb.v
│
├── constraints/
│   └── <Nexys 4 XDC - planned>
│
├── questa/
│   └── <Questa simulation scripts - planned>
│
├── .gitignore
└── README.md
```

Vivado-generated directories and simulation artifacts are intentionally excluded from version control.

## 4. RTL Modules

### `baud_tick_gen.v`

Generates independent TX and RX timing ticks using a 32-bit phase accumulator.

Parameters:

```verilog
CLOCK_FREQ = 100_000_000
BAUD_RATE  = 115_200
OVERSAMPLE = 16
```

The timing relationship is:

```text
TX tick frequency = BAUD_RATE
RX tick frequency = BAUD_RATE × OVERSAMPLE
```

For this project:

```text
TX = 115200 Hz
RX = 1843200 Hz
```

### `uart_tx.v`

Serializes an 8-bit parallel byte into an 8-N-1 UART frame.

```text
Idle → Start → D0 → D1 → ... → D7 → Stop → Idle
```

The transmitter provides status information such as `tx_busy`.

### `uart_rx.v`

Receives the asynchronous serial input and reconstructs the original 8-bit byte using 16× oversampling.

The receiver detects the start bit, samples the data bits, assembles the byte, checks the stop bit, and produces `rx_valid` and `rx_busy` status signals.

### `uart.v`

Integrates the baud generator, transmitter, and receiver into one UART interface.

```text
baud_tick_gen
      │
      ├──────────► uart_tx
      │
      └──────────► uart_rx
```

## 5. Verification Strategy

Verification was performed progressively:

```text
Stage 1 → Baud Tick Generator
Stage 2 → UART TX
Stage 3 → UART RX
Stage 4 → Full UART Loopback
Stage 5 → FPGA Hardware Validation (planned)
```

## 6. Stage 1 — Baud Tick Generator

Testbench:

```text
tb/baud_tick_gen_tb.v
```

The testbench checks reset behavior, TX/RX tick activity, and measured timing periods.

Expected periods:

```text
TX ≈ 8680.556 ns
RX ≈ 542.535 ns
```

Observed simulation behavior:

```text
TX ticks detected : 3
RX ticks detected : 55
TX period         : 8680000 ps-equivalent simulation interval
RX period         : approximately 540000 ps-equivalent simulation interval
```

The measured RX interval alternates slightly because the generated tick is quantized to the 100 MHz system clock.

**Result: STAGE 1 — PASS**

## 7. Stage 2 — UART TX

Testbench:

```text
tb/uart_tx_tb.v
```

The transmitter was verified with:

```text
0x00
0xFF
0x55
0xAA
0x41
0x5A
```

For each frame the testbench checks:

- Start bit = `0`
- Eight data bits
- LSB-first ordering
- Stop bit = `1`
- Frame timing

All tested frames passed.

**Result: UART TX TEST — PASS**

## 8. Stage 3 — UART RX

Testbench:

```text
tb/uart_rx_tb.v
```

The receiver was verified for:

- Start-bit detection
- 16× oversampling
- Data-bit sampling
- LSB-first reconstruction
- Stop-bit handling
- `rx_valid` pulse behavior
- Received data correctness

**Result: UART RX TEST — PASS**

## 9. Stage 4 — Full UART Loopback

Testbench:

```text
tb/uart_tb.v
```

The transmitter output is connected directly to the receiver input:

```text
UART TX ─────────► UART RX
```

The following values were transmitted and successfully received:

| TX Data | RX Data | Result |
|---|---|---|
| `0x00` | `0x00` | PASS |
| `0xFF` | `0xFF` | PASS |
| `0x55` | `0x55` | PASS |
| `0xAA` | `0xAA` | PASS |
| `0x41` | `0x41` | PASS |
| `0x5A` | `0x5A` | PASS |

For every byte:

```text
[PASS] RX data matched
[PASS] rx_valid pulse completed
```

**Result: UART LOOPBACK TEST — PASS**

## 10. Simulation Environment

Current verification environment:

```text
HDL              : Verilog
Simulator        : Xilinx Vivado XSim
Vivado Version   : 2019.2
Clock            : 100 MHz
Baud Rate        : 115200
RX Oversampling  : 16×
```

The testbenches are self-checking and report PASS/FAIL results during simulation.

## 11. Questa-Altera Verification

The project is being extended to use **Questa-Altera FPGA Edition** for independent RTL simulation.

Planned flow:

```text
Verilog RTL
    ↓
vlog compilation
    ↓
Elaboration
    ↓
vsim
    ↓
Waveform inspection
    ↓
Self-checking testbench
```

The planned repository area is:

```text
questa/
├── run_uart.do
└── ...
```

This adds practical experience with command-line RTL simulation, waveform debugging, and simulation scripting.

## 12. FPGA Hardware Validation

Hardware validation is planned using the **Digilent Nexys 4 (non-DDR)** board.

Planned additions:

```text
uart_fpga_top.v
constraints/
└── uart_nexys4.xdc
```

Target architecture:

```text
                 Nexys 4
                    │
              100 MHz Clock
                    │
                    ▼
              uart_fpga_top
                    │
                    ▼
                  uart
               ┌────┴────┐
               │         │
              TX         RX
               │         │
               └────┬────┘
                    │
                USB-UART
                    │
                    ▼
                    PC
```

This hardware stage is intentionally kept separate from the already-verified UART core.

## 13. Design Parameters

The baud generator is parameterized:

```verilog
parameter integer CLOCK_FREQ = 100_000_000;
parameter integer BAUD_RATE  = 115_200;
parameter integer OVERSAMPLE = 16;
```

The same architecture can therefore be adapted to other clock and baud-rate combinations.

## 14. Verification Test Patterns

The selected test patterns exercise different serial bit patterns:

```text
0x00 → 00000000
0xFF → 11111111
0x55 → 01010101
0xAA → 10101010
0x41 → ASCII 'A'
0x5A → ASCII 'Z'
```

These cover all-zero data, all-one data, alternating patterns, and representative ASCII characters.

## 15. RTL Concepts Demonstrated

- Synchronous sequential logic
- Finite-state-machine based control
- Parameterized RTL
- Phase-accumulator timing generation
- UART protocol framing
- Serial-to-parallel conversion
- Parallel-to-serial conversion
- 16× oversampling
- Status and handshake signals
- Self-checking testbenches
- RTL functional verification
- Waveform-based debugging
- Simulation scripting
- Modular RTL architecture

## 16. Tools

| Tool | Purpose |
|---|---|
| Verilog HDL | RTL implementation |
| Xilinx Vivado 2019.2 | FPGA development and XSim simulation |
| Vivado XSim | RTL functional simulation |
| Questa-Altera FPGA Edition | Independent RTL simulation |
| Git | Version control |
| GitHub | Source-code management |

## 17. Project Status

| Component | Status |
|---|---|
| Baud Tick Generator | ✅ Completed |
| UART TX | ✅ Completed |
| UART RX | ✅ Completed |
| UART Integration | ✅ Completed |
| XSim Verification | ✅ Completed |
| Full Loopback Simulation | ✅ Passed |
| Questa Verification | 🔄 In Progress |
| Nexys 4 Hardware Test | ⏳ Planned |

## 18. Future Improvements

Possible extensions include:

- Configurable data width
- Configurable stop-bit count
- Parity generation and checking
- Break detection
- Framing-error detection
- Overrun detection
- RX noise filtering
- FIFO-based buffering
- Hardware flow control
- AXI4-Lite register interface
- Interrupt-driven interface
- Formal verification
- FPGA resource/utilization analysis
- Multi-baud-rate verification

These are outside the current simple UART scope.

## 19. Learning Outcomes

The project follows a complete RTL development workflow:

```text
Specification
     ↓
Architecture
     ↓
RTL Design
     ↓
Unit Verification
     ↓
Integration
     ↓
Loopback Verification
     ↓
Independent Simulator Verification
     ↓
FPGA Hardware Validation
```

The project demonstrates practical UART protocol implementation together with modular RTL design, self-checking verification, simulation, and preparation for FPGA deployment.

## 20. Author

**Aravindhan**

GitHub:  
https://github.com/aravindhan1

Project:  
https://github.com/aravindhan1/uart_protocol_rtl

## License

This project is intended for educational, portfolio, and RTL/VLSI learning purposes.
