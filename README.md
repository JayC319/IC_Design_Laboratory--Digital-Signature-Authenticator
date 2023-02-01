
# How to use ?
### Prerequisite

# Innovations
> Quote to be finished

### Digital Signature Generation

### Verificate Authenticity

# About Hardware
### Top Module View
<p align="center">
  <img src="./img/top_view.png" width="500" title="Top Module View">
</p>


### I/O Definition



| Type   | Name          | bits | Description                                 |
| ------ | ------------- | ---- | ------------------------------------------- |
| Input  | clk           | 1    | Clock                                       |
| Input  | srst_n        | 1    | System reset                                |
| Input  | enable        | 1    | Trigger hardware<br>operation               |
| Input  | mode          | 1    | encrypt/decrypt                             |
| Input  | msg_sram_data | 64   | message data                                |
| Input  | m_len         | 14   | message length<br>(byte)                    |
| Input  | cph_sram_data | 8    | cipher data                                 |
| Output | valid         | 1    | indicates data validity                     |
| Output | verify        | 1    | show that if cipher<br>verifies the message |
| Output | result        | 64   | for cipher output                           |
| Output | msg_sram_addr | 11   | address for message data                    |
| Output | cph_sram_addr | 5    | address for cipher data                     |


### Layout View


 <p align="center">
  <img src="./img/layout_result.png" width="600" title="Layout Result">
</p>
 
 
### Power Analysis

 <p align="center">
  <img src="./img/power_analysis.png" width="550"  title="Layout Result">
</p>

### Area 
|                | area ( um2) | core utilization |
|----------------|-------------|------------------|
| synthesis area | 241509.46   |                  |
| APR area       | 284199.26   | 85%              |

### Clock Period constrain
|                  | timing (ns) |
|------------------|-------------|
| synthesis timing | 2.35        |
| APR timing       | 3.2         |


# Referenced Work


