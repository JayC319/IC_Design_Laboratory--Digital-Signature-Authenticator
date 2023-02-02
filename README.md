# Contributors ✨
<table>
  <tbody>
    <tr>
      <td align="center"><a href="https://github.com/JayC319"><img src="https://avatars.githubusercontent.com/u/67352558?v=4" width="100px;" alt="JhaoWei Chen"/><br /><sub><b>JhaoWei Chen</b></sub></a><br />
      <td align="center"><a href="https://github.com/nthu108011244"><img src="https://avatars.githubusercontent.com/u/79581483?v=4" width="100px;" alt="TangI Wang"/><br /><sub><b>TangI Wang</b></sub></a><br />
      <td align="center"><a href="https://github.com/108061107"><img src="https://avatars.githubusercontent.com/u/79581724?v=4" width="100px;" alt="YuSheng Lin"/><br /><sub><b>YuSheng Lin</b></sub></a><br />  
    </tr>
  </tbody>
</table>

# Prerequisite (Cell-Based Circuit Design Tool)
## Frontend Design Tool

### Functional Verification
```
Synopsys VCS
```
<p align="center">
  <img src="https://images.synopsys.com/is/image/synopsys/VCS?qlt=82&wid=1200&ts=1634855595959&$responsive$&fit=constrain&dpr=off" width="400" title="encrpyt_flow">
</p>


### Automated Debug System
```
Synopsys Verdi
```
<p align="center">
  <img src="https://images.synopsys.com/is/image/synopsys/Verdi-Fig1?qlt=82&wid=1200&ts=1596142743792&$responsive$&fit=constrain&dpr=off" width="400" title="encrpyt_flow">
</p>

### RTL synthesis solution
```
Synopsys Design Compiler
```
<p align="center">
  <img src="https://images.synopsys.com/is/image/synopsys/CS12320_fig1?qlt=82&wid=1200&ts=1596142705371&$responsive$&fit=constrain&dpr=off" width="400" title="encrpyt_flow">
</p>
  
## BackEnd Design Tool

### Implementation System
```
Cadence Innovus
```

### Static Timing Analysis
```
Synopsys PrimeTime
```

## Logic Equivalence Checking
```
Cadence Conformal
```
  
## Cell Library
```
Cadence GPDK 45 nm
```
# Design & Innovations
### Data Flow Overview
We aim to implement a digital authentication flow of message or document on hardware. In general, transmitter hashes the message / document through hashing algorithm. Then, encrypted the hashed value with private key with corresponding public key. For the receiver side, they can decrypt the cipher and hash again with the received message / document simultaneously. Eventually, they compared two hashed value, one from decryption, the other from hashing to see whether the message / document is authentic or manipulated.

### Novelty
Our approach is that we can implement the key generating part from another set of hashing algorithm on the message / document, so that no
public key is needed. For the receiver, they first hash
the message / document with two given hashing
algorithm and then decrypt the cipher then compare
the two hashed value. For this protocol, as long as
the message or the key is not manipulated, the
authentication works and it’s very nearly impossible
for only manipulating message / document to
deceive the receiver with false message / document
since the hashing algorithm - SHA256 / SHA3-
256 we applied in this hardware both have low
collision rate.

### Digital Signature Generation
<p align="center">
  <img src="./img/encrypt_flow.png" width="500" title="encrpyt_flow">
</p>

### Verificate Authenticity
<p align="center">
  <img src="./img/decrypt_flow.png" width="500" title="decrpyt_flow">
</p>

# About Hardware
### Top Module View
<p align="center">
  <img src="./img/top_view.png" width="500" title="Top Module View">
</p>


### Layout View
<p align="center">
  <img src="./img/layout_result.png" width="700" title="Layout Result">
</p>


### I/O Definition
<div align="center">

| Type   | Name          | bits | Description                                 |
| ------ | ------------- | ---- | ------------------------------------------- |
| Input  | clk           | 1    | Clock                                       |
| Input  | srst_n        | 1    | System reset                                |
| Input  | enable        | 1    | Trigger hardware<br>operation               |
| Input  | mode          | 1    | encrypt / decrypt                             |
| Input  | msg_sram_data | 64   | message data                                |
| Input  | m_len         | 14   | message length<br>(byte)                    |
| Input  | cph_sram_data | 8    | cipher data                                 |
| Output | valid         | 1    | indicates data validity                     |
| Output | verify        | 1    | show that if cipher<br>verifies the message |
| Output | result        | 64   | for cipher output                           |
| Output | msg_sram_addr | 11   | address for message data                    |
| Output | cph_sram_addr | 5    | address for cipher data                     |

</div>
 
### Power Analysis

<div align="center">
  
| Power Analysis          | Pre Layout | Post Layout<br>(pre-sim waveform) | Post Layout<br>(post-sim waveform) |
| ----------------------- | ---------- | --------------------------------- | ---------------------------------- |
| Net Switching Power (W) | 2.76E-04   | 1.30E-03                          | 1.38E-03                           |
| Cell Internal Power (W) | 2.06E-03   | 2.12E-03                          | 2.22E-03                           |
| Cell Leakage Power (W)  | 6.03E-06   | 7.31E-06                          | 7.31E-06                           |
| X Transition Power (W)  | 2.65E-07   | 5.54E-07                          | 5.02E-07                           |
| Glitching Power (W)     | 7.61E-07   | 1.23E-04                          | 1.02E-06                           |
| Total Power (W)         | 2.35E-03   | 3.43E-03                          | 3.60E-03                           |

</div>

### Area 

<div align="center">

|                | area ( um<sup>2</sup>) | core utilization |
| -------------- | ---------------------- | ---------------- |
| synthesis area | 241509.46              | 100%             |
| APR area       | 284199.26              | 85%              |

</div>

### Clock Period constrain

<div align="center">

|                  | timing (ns) |
| ---------------- | ----------- |
| synthesis timing | 2.35        |
| APR timing       | 3.2         |

</div>

# Referenced Work
<a id="1">[1]</a> 
secworks
/
aes.
Mar 10, 2022.
<br />
https://github.com/secworks/aes

<a id="1">[2]</a> 
secworks
/
sha256.
Feb 17, 2022.
<br />
https://github.com/secworks/sha256

# Referenced Paper
<a id="1">[1]</a> 
Secure Hash Standard. 
Federal Information Processing Standards Publication.
August 1 2002.

<a id="1">[2]</a> 
Penny Pritzker, Willie May., SHA-3 Standard:
Permutation-Based Hash and Extendable-Output
Functions., Federal Information Processing Standards
Publication. August 2015.

<a id="1">[3]</a> 
Advanced Encryption Standard., Federal Information
Processing Standards Publication., November 26, 2001.
