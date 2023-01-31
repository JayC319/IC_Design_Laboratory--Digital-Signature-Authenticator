for x in range(5):
    for y in range(5):
        for z in range(64):
            print(f"lane_pi_kai_n[{5*y+ x}][{z}] = lane_rho_pi[{(x+3*y)%5 + 5*x}][{z}];")