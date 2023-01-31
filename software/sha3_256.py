import numpy as np
import glob
import os
import sha3_util as util

#%% SHA3-256 parameter

l = 6
rnd = 24    # values of rounds
b = 1600    # state bitwidth
c = 512     # capacity bitwidth

'''
flow of f-function in SHA3-256:

-> theta -> rho -> pi -> kai -> iota -> 
'''

#%%
####################
# theta function
####################
# modify along column
'''
1. For all pairs (x, z) such that 0 <= x < 5 and 0 <= z < 64, let
    C[x][z] = A[x][0][z] ⊕ A[x][1][z] ⊕ A[x][2][z] ⊕ A[x][3][z] ⊕ A[x][4][z].

2. For all pairs (x, z) such that 0 <= x < 5 and 0 <= z < 64, let
    D[x][z] = C[(x - 1) mod 5][z] ⊕ C[(x + 1) mod 5][(z - 1) mod 64].

3. For all triples (x, y, z) such that 0 <= x < 5, 0 <= y < 5 and 0 <= z < 64, let
    A_out[x][y][z] = A[x][y][z] ⊕ D[x][z].
'''
def theta(A):
    # Initialize 5x5x64 zero array
    A_out = np.zeros((5, 5, 64), dtype = bool)

    for i in range(5):
        for j in range(5):
            for k in range(64):
                D = util._XOR_SUM(A, (i - 1) % 5, k) ^ util._XOR_SUM(A, (i + 1) % 5, (k - 1) % 64)
                A_out[i][j][k] = A[i][j][k] ^ D
    
    return A_out

#%%
####################
# rho function
####################
# modify along lane
'''
1. For z such that 0 <= z < 64, let A_out[0][0][z] = A[0][0][z].

2. Let (x, y) = (1, 0)

3. For t from 0 to 23:
    a. for all z such that 0 <= z < 64, let A_out[x][y][z] = A[x][y][(z - (t + 1) * (t + 2) / 2) mod 64];
    b. let (x, y) = (y, (2x + 3y) mod 5).
'''
def rho(A):
    # Initialize 5x5x64 zero array
    A_out = np.zeros((5, 5, 64), dtype = bool)

    # 1.
    A_out[0][0][:] = A[0][0][:]
    
    # 2.
    x = 1
    y = 0

    # 3.
    for t in range(24):
        ## 3.a
        for z in range(64):
            A_out[x][y][z] = A[x][y][(z - (t + 1) * (t + 2) // 2) % 64]
        ## 3.b
        x_n = y
        y_n = (2 * x + 3 * y) % 5
        
        x = x_n
        y = y_n

    return A_out

#%%
####################
# pi function
####################
# rearrange the position of lanes
'''
1. For all triples (x, y, z) such that 0 <= x < 5, 0 <= y < 5 and 0 <= z < 64, let
    A_out[x][y][z] = A[(x + 3y) mod 5][x][z].
'''
def pi(A):
    # Initialize 5x5x64 zero array
    A_out = np.zeros((5, 5, 64), dtype = bool)

    # 1.
    for i in range(5):
        for j in range(5):
            for k in range(64):
                A_out[i][j][k] = A[(i + 3 * j ) % 5][i][k]
    
    return A_out

#%%
####################
# kai function
####################
# XOR each bit with a non-linear function of two other bits in its row
'''
1. For all triples (x, y, z) such that 0 <= x < 5, 0 <= y < 5 and 0 <= z < 64, let
    A_out[x][y][z] = A[x][y][z] ⊕ (~A[(x + 1) mod 5][y][z] & A[(x + 2) mod 5][y][z]).
'''
def kai(A):
    # Initialize 5x5x64 zero array
    A_out = np.zeros((5, 5, 64), dtype = bool)

    # 1.
    for i in range(5):
        for j in range(5):
            for k in range(64):
                A_out[i][j][k] = A[i][j][k] ^ ((A[(i+1)%5][j][k] ^ 1) & A[(i+2)%5][j][k])
    return A_out

#%%
####################
# iota function
####################
# specitial mapping parameterized by the round index
'''
1. For all triples (x, y, z) such that 0 <= x < 5, 0 <= y < 5 and 0 <= z < 64, let A_out[x][y][z] = A[x][y][z].

2. Let RC = 000 ... 0 (total # = 64)

3. For j from 0 to l, let RC[2 ** j - 1] = rc(j + 7 * i_rnd)

4. For all z such that 0 <= z < 64, let A_out[0][0][z] = A_out[0][0][z] ⊕ RC[z]
'''
def iota(A, i_rnd):
    # Initialize 5x5x64 zero array
    A_out = np.zeros((5, 5, 64), dtype = bool)

    # 1.
    A_out = A
    
    # 2.
    RC = np.zeros(64, dtype = bool)

    # 3.
    for j in range(6 + 1):
        RC[2 ** j - 1] = util._rc(j + 7 * i_rnd)
    
    # 4.
    A_out[0][0][:] = A[0][0][:] ^ RC[:]
    
    return A_out

#%%
# Rnd
def Rnd(A,ir):
    A_out = theta(A)
    A_out = rho(A_out)    
    A_out = pi(A_out)    
    A_out = kai(A_out)    
    A_out = iota(A_out, ir)
    
    return A_out

#%%
# KECCAK-p[b, nr](S)
def KECCAK_P(S):
    A = util._1Dto3D(S)
    for ir in range(rnd):
        A = Rnd(A, ir)  

    S_out = util._3Dto1D(A)

    return S_out

#%%
# KECCAK[512] = SPONGE[KECCAK-p[1600, 24], pad10*1, 1088].
def KECCAK(N, d, c):
    r = b - c
    _P = np.array(N + util.pad1_0_1(r, len(N)))         # concatenation P = N || pad(r, len(N))
    P = np.zeros(len(_P), dtype = int)
    n = int(len(P)/r)                                   # Let n = len(P)/r
    P = np.array_split(_P, n)
    _S = np.zeros(b, dtype = int)                       # Let S = 0^b.
    S = np.zeros(b, dtype = int)
    for i in range(n):                                  # For i from 0 to n-1, let S = f (S ⊕ (Pi || 0c)).
        _S = KECCAK_P(_S ^ (P[i].tolist() + c*[0]))
    
    for i in range(len(_S)//8):                     # flip order in every byte (8 bits)
        for j in range(8):
            S[i*8 + j] = _S[i*8 + (7-j)]
    Z = S[0:d]                                      # If d ≤ |Z|, then return Trunc d (Z); else continue.
    return Z


# SHA3-256(M) = KECCAK[512] (M || 01, 256)
def SHA3_256(M):
    Z = KECCAK(M + [0,1], 256,  c)
    Z = util.bin_to_hex(Z)
    
    return Z

def pattern_check(message):

    M = util.txt_to_bin(message)
    Z = SHA3_256(M)

    print('input: ', message)
    print('output: ', Z)

def pattern_gen(pattern_dir):
    for path in glob.glob(os.path.join(pattern_dir, "*.txt")):

        print(">>> processing: ", path)
        msg_path = "../sim/pattern/msg/" + path.split('/')[-1].split('.')[0] + ".txt"
        len_path = "../sim/pattern/len/" + path.split('/')[-1].split('.')[0] + ".txt"
        out_path = "../sim/golden/SHA3/" + path.split('/')[-1].split('.')[0] + ".txt"

        with open(path) as f:
            P = f.readlines()
        
        S_txt = util.paragragh_to_txt(P)
        S_pat = util.txt_to_pat(S_txt)
        S_len = util.dec_to_pat(len(S_txt))
        M = util.txt_to_bin(S_txt)
        Z = SHA3_256(M)
        print("Length: ", len(S_txt))
        print("Input:  ", S_txt)
        print("Output: ", Z)
        print('\n')

        f_bin = open(msg_path, "w")
        f_bin.write(S_pat)
        f_bin.close()

        f_len = open(len_path, "w")
        f_len.write(S_len)
        f_len.close()

        f_out = open(out_path, "w")
        f_out.write(Z)
        f_out.close()

if __name__ == '__main__':
    ## generate test pattern
    path = '../sim/pattern/paragraph/'
    pattern_gen(path)

    ## check input output immediately
    # message = 'abc'
    # pattern_check(message)
