x = 1
y = 0

offset = [1,62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14]

for t in range(24):
    ## 3.a
    print(f"assign lane_rho_{t+1} = {{lane_theta_rho[{t+1}][{(offset[t]-1)}:0], lane_theta_rho[{t+1}][63:{(offset[t])}]}};")

    x_n = y
    y_n = (2 * x + 3 * y) % 5
    
    x = x_n
    y = y_n