### SHA testbench
### Notice1: pattern idx is in [1, 5]
# vcs -R +v2k -full64 -f sim.f -debug_acc -l SHA.log \
# +define+PAT_L=1+PAT_U=1 

### AES key testbench
# vcs -R +v2k -full64 -f sim_AESkey.f -debug_acc -l AESkey.log

### AES encrypt testbench
# vcs -R +v2k -full64 -f sim_AESen.f -debug_acc -l AESen.log

### AES decrypt testbench
# vcs -R +v2k -full64 -f sim_AESde.f -debug_acc -l AESde.log

### test all testbench
vcs -R +v2k -full64 -f sim.f -debug_acc -l test_all.log \
+define+PAT_L=1+PAT_U=7 \
+define+TEST_EN