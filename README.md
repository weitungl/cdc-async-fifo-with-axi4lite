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

### Hierarchy & Functional Modules
* `axi_lite_fifo_wbridge` (wclk domain): Handles AXI4-Lite Write Address(AW), Write Data(W) and Write Response(B) channel
* handshakes.
