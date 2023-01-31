read_file -type verilog top.v
read_file -type verilog padding.v
read_file -type verilog SHA2.v
read_file -type verilog sha2_w_ctr.v
read_file -type verilog SHA3.v
read_file -type verilog transmission.v
read_file -type verilog verification.v
read_file -type verilog AES.v
read_file -type verilog AES_decrypt.v
read_file -type verilog AES_encrypt.v
read_file -type verilog AES_inverse_gf.v
read_file -type verilog AES_key_ctr.v



current_goal lint/lint_rtl -alltop

run_goal

capture spyglass.rpt {write_report moresimple}


current_goal lint/lint_turbo_rtl -alltop
run_goal
capture -append spyglass.rpt {write_report moresimple}

current_goal lint/lint_functional_rtl -alltop
run_goal
capture -append spyglass.rpt {write_report moresimple}


current_goal lint/lint_abstract -alltop
run_goal
capture -append spyglass.rpt {write_report moresimple}


current_goal adv_lint/adv_lint_struct -alltop
run_goal
capture -append spyglass.rpt {write_report moresimple}

current_goal adv_lint/adv_lint_verify -alltop
run_goal
capture -append spyglass.rpt {write_report moresimple}
