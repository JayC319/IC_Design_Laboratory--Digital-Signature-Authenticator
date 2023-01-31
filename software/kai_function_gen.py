for y in range(5):
    for x in range(5):
        print(f"kai_and_product_n[{5*y+x}] = (lane_pi_kai[{(x+1)%5 + 5*y}] ^ 64'b1) & lane_pi_kai[{(x+2)%5 + 5*y}];")