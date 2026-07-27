# AXI4-Lite Asynchronous FIFO for Cross-Clock Domain (CDC) Transfers

## Project overview
This project presents a tape-out ready, fully verified AXI4-Lite Asynchronous FIFO designed for cross-clock domain 
(CDC) data transfers under asymmetric frequencies using the SkyWater 130nm PDK.  
The design addresses critical hardware challenges including frequency drift resilience, PPA trade-off exploration, 
and physical timing closure. The architecture achieved a 200 MHz (5.0 ns) clock period with zero timing violations 
and a DRC/LVS-clean physical layout.

## Architecture
The system decouples AXI4-Lite transactions into separate write(`wclk`) and read(`rclk`) clock domains, connected via a
dual-port RAM array and multi-stage Gray-code synchronizers.

<img width="2582" height="762" alt="image" src="https://github.com/user-attachments/assets/c28a6119-66b0-41cd-be13-ead3f8ed86f8" />
*Figure 1: Full Block Diagram showing AXI4-Lite Write/Read Bridges, CDC top hierarchy, and dual-clock routing.*

### Hierarchy & Functional Modules
* **`axi4_lite_fifo_wbridge`** (`wclk` domain): Handles AXI4-Lite Write Address (AW), Write Data (W), and Write Response (B) channel handshakes. Converts AXI writes into internal `fifo_w_en` and applies backpressure when `full`.
* **`axi4_lite_fifo_rbridge`** (`rclk` domain): Handles Read Address (AR) and Read Data (R) channel handshakes. Asserts `SLVERR` (`2'b10`) upon illegal read attempts on an empty FIFO.
* **`cdc_top`**: Core CDC Async FIFO wrapper bringing together pointer handlers, RAM storage, and synchronizer pipelines.
  * **`wptr_handler` & `rptr_handler`**: Maintains binary/Gray pointers, performs single-bit Gray code conversion, and generates `full` / `empty` flags. 
  * **`sync_stages`**: Multi-stage (default 2-Stage) DFF synchronizers to mitigate metastability across asymmetric clock boundaries.
  * **`fifo`**: Dual-port storage array accepting independent read and write addresses.

## KeyDesign Choices & Hardware Optimizations
### 1. Robust CDC Handshake & Driver Retry
* **Gray-Code Pointer Sync**: Prevents multi-bit skew hazards when crossing clock domain boundaries.
* **Driver Retry Mechanism**: Under asymmetric frequencies, pointer synchronization latency (2 clock cycles) can trigger premature `SLVERR` responses. The testbench incorporates an AXI Read Driver retry mechanism that re-issues transactions until receiving `OKAY` in the testbench read-back mode, guaranteeing 100% data readback alignment with zero scoreboard errors.

### 2. Critical Path Bottleneck Resolution (RTL Decoupling)
* **Problem**: In the baseline design (limited to 6.2 ns), OpenLane STA identified that `b_rptr[0]` inside `rptr_handler` suffered from high fan-out (>50), driving both pointer update logic (b_rptr_next) and wide FIFO address MUX trees (`raddr`).
* **Solution**: Decoupled the driver path generating `b_rptr_next` from the combinational path driving `raddr`. Splitting the fan-out load reduced propagation delay with **zero area overhead** and constant sequential DFF count (404 DFFs).

### 3. Backend Hold-Margin Tuning
* **Problem**: OpenLane resizer inserted excessive high-delay hold buffers to resolve local hold violations, which degraded setup slack.
* **Solution**: Enforced `PL_RESIZER_HOLD_SLACK_MARGIN = 0.02` in `config.json`. This relaxed over-conservative hold slack targets, preventing excessive buffer insertion while ensuring clean timing closure at 5.0 ns.

---

## Physical Implementation & PPA Results

### Configuration Exploration (8.0 ns Baseline)
*Evaluated across different FIFO depths and synchronizer stages under SkyWater 130nm:*

| Configuration | FIFO Depth / Sync Stage | Total Area (μm²) | Std Cell Count | DFF Count (Seq) | Total Power (mW) | Leakage Power (W) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Default (Optimal)** | **Depth 8, 2-Stage** | **39,727.60** | **3,066** | **404** | **9.77** | **2.29 × 10⁻⁸** |
| Depth 4 | Depth 4, 2-Stage | 25,656.10 | 1,178 | 268 | 6.34 | 1.33 × 10⁻⁸ |
| Depth 16 | Depth 16, 2-Stage | 61,215.10 | 4,739 | 668 | 12.97 | 3.84 × 10⁻⁸ |
| Depth 32 | Depth 32, 2-Stage | 108,769.00 | 9,732 | 1,188 | 21.48 | 7.21 × 10⁻⁸ |
| 3-Stage Sync | Depth 8, 3-Stage | 40,185.60 | 2,056 | 412 | 9.54 | 2.41 × 10⁻⁸ |

> **Selection Insight**: Depth 8 provides sufficient dynamic buffering during asymmetric CDC transfers without incurring the heavy area penalty of Depth 16.

### Final Physical Timing Closure (@ 5.0 ns Target)

| Metric | Baseline | Final Optimized | Impact |
| :--- | :---: | :---: | :--- |
| **Clock Period** | 6.2 ns (161.3 MHz) | **5.0 ns (200.0 MHz)** | **24% Frequency Improvement** |
| **Total Area** | 39,727.60 μm² | **39,727.60 μm²** | **Zero Area Penalty** |
| **Total Power** | 9.77 mW (@ 125 MHz) | **13.62 mW (@ 200 MHz)** | Controlled Dynamic Power |
| **Physical Status** | - | **DRC & LVS Clean** | Tape-out Ready GDSII |

---

## Full-Chip Layout (GDSII)

<img width="910" height="910" alt="截圖 2026-07-26 中午12 23 39" src="https://github.com/user-attachments/assets/c46ec640-9287-4f2c-a7cd-9f3a94cb57f8" />

*Figure 2: Final OpenLane PNR Full-Chip Physical Layout (SkyWater 130nm) displaying core area, I/O pin placements, power grid, and routed networks.*

---

## Verification Environment

The project implements a **SystemVerilog Class-based Testbench** to thoroughly verify cross-clock domain operations under asymmetric clock frequencies.
To validate robust CDC operation under asymmetric clock frequencies, the verification environment executes four core test scenarios:

#### 1. Test Modes (`test_mode`)
* **`WRITE_ONLY` Mode**: Drives continuous write transactions while keeping reads IDLE. Fills the FIFO to capacity to validate `full` flag assertions and AXI write backpressure (`s_axi_awready`).
* **`READ_BACK` Mode**: Sequentially executes write transactions in the first half, followed by read transactions in the second half. Validates data alignment and exercises the **AXI Read Driver Retry Mechanism** to seamlessly handle CDC synchronization cycles without data loss.
* **`READ_WRITE` Mode**: Concurrently executes simultaneous write and read requests on every cycle, stressing the dual-port RAM access and dual-clock Gray pointer synchronizers.
* **`RANDOM` Mode**: Randomizes transaction types (`WRITE_ONLY`, `READ_ONLY`, `IDLE`) and timing delays to expose unexpected race conditions or edge-case boundary errors.

#### 2. How Correctness Is Guaranteed
* **Scoreboard Data Integrity (`fifo_scoreboard.sv`)**: Independent write/read monitors capture transactions on the fly and feed them to an in-order Golden Reference Queue. **Zero data mismatches and zero transaction drops** confirm 100% functional correctness across all 4 modes.
* **Protocol & Boundary SVA (`fifo_assertion.sv`)**: SystemVerilog Assertions continuously check AXI4-Lite handshakes and internal FIFO boundaries in real time.

---

## Repository Structure

```text
├── rtl/                            # SystemVerilog RTL Sources
│   ├── axi4_lite_fifo_top.sv       # Top-level 
│   ├── axi4_lite_fifo_wbridge.sv   # AXI Write Slave Bridge
│   ├── axi4_lite_fifo_rbridge.sv   # AXI Read Slave Bridge
│   ├── cdc_top.sv                  # Async FIFO core wrapper
│   ├── wptr_handler.sv             # Write pointer logic
│   ├── rptr_handler.sv             # Read pointer logic 
│   ├── sync_stages.sv              # Parameterized N-stage DFF synchronizer
│   └── fifo.sv                     # Dual-port RAM array
├── tb/                             # Class-based Layered Verification Environment
│   ├── tb_top.sv                   # Testbench top (Clock generation, DUT instantiation)
│   ├── fifo_if.sv                  # SystemVerilog Interface connecting TB and DUT
│   ├── fifo_pkg.sv                 # Package importing verification classes & types
│   ├── fifo_transaction.sv         # Sequence Item 
│   ├── fifo_generator.sv           # Random transaction generator
│   ├── fifo_write_driver.sv        # Drives write transactions to DUT
│   ├── fifo_read_driver.sv         # Drives read transactions 
│   ├── fifo_write_monitor.sv       # Captures write interface activity
│   ├── fifo_read_monitor.sv        # Captures read interface activity
│   ├── fifo_scoreboard.sv          # Data integrity checker & FIFO model comparison
│   ├── fifo_env.sv                 # Testbench Environment wrapper
│   └── fifo_assertion.sv           # Concurrent SystemVerilog Assertions (SVA)
├── Makefile                        # Simulation & compilation scripts
├── config.json                     # OpenLane PNR configuration
├── my_constraints.sdc              # Timing constraints file (SDC)
└── README.md                       # Project documentation
```

## 🚀 How to Run & Reproduce

To run the SystemVerilog class-based layered testbench and execute the OpenLane 2 physical design flow:

### 1. Functional Verification (Simulation)
```bash
# Run simulation using Makefile from the root directory
make run

# Enter the OpenLane 2 environment
cd openlane2
nix develop

# Navigate back to your project directory (where config.json is located)
cd /path/to/your/project

# Run OpenLane 2 flow using your config
openlane config.json
```

## Reference & Acknowledgments
* SkyWater 130nm PDK: Google & SkyWater Technology Open Source PDK 

* OpenLane 2 EDA Infrastructure: An open-source automated RTL-to-GDSII flow powered by OpenROAD 

* ARM AXI4-Lite Protocol Specification: ARM AMBA AXI and ACE Protocol Specification (IHI0022E)

## Author
Wei-Tung Lai

