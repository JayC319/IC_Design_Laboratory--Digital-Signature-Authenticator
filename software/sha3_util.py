"""utility function

In-function utility function for computation usage
"""
import numpy as np


# 1600 bits(1 dimensional array) to 3 dimensional array of 5x5x64
def _1Dto3D(A):
    A_out = np.zeros((5,5,64), dtype = int)
    A_tmp = np.zeros((5,5,64), dtype = int)
    for i in range(5):
        for j in range(5):
            for k in range(64):
                A_out[i][j][k] = A[64 * (5 * j + i) + k]

    return A_out

# XOR sum of theta function
def _XOR_SUM(A, x, z):
    C = A[x][0][z] ^ A[x][1][z] ^ A[x][2][z] ^ A[x][3][z] ^ A[x][4][z]
    return C

# 5x5x64 (three-dimensional array) into 1600 bits(one-dimensional array)
def _3Dto1D(A):
    A_out = np.zeros(1600, dtype = int) # Initialize empty array of size 1600
    A_tmp = np.zeros((5,5,64), dtype = int)
    
    for i in range(5):
        for j in range(5):
            for k in range(64):
                A_out[64 * (5 * j + i ) + k] = A[i][j][k]
    
    return A_out

def _rc(t):
    R = [1] + 7 * [0]
    if t % 255 == 0:
        return 1
    for i in range(t % 255):
        R = [0] + R
        R[0] = R[0] ^ R[8]
        R[4] = R[4] ^ R[8]
        R[5] = R[5] ^ R[8]
        R[6] = R[6] ^ R[8]
        R = R[0:8]
    
    return R[0]


def pad1_0_1(x, m):
    j = ((-m - 2) % x)

    return ([1] + j * [0] + [1])

def bin_to_hex(A):
    token = ''
    binary = token.join(A.astype(str))
    hexidecimal = format(int(binary, 2), '064x')

    return hexidecimal

def txt_to_bin(S_txt):
    lst = list(S_txt)
    asc = [ord(char) for char in lst]
    binary = [list(format(a, '08b')[::-1]) for a in asc]
    S_bin = [int(bit) for char in binary for bit in char]

    return S_bin

def txt_to_hex(S_txt):
    token = ''
    lst = list(S_txt)
    asc = [ord(char) for char in lst]
    binary = [token.join(list(format(a, '08b')[::-1])) for a in asc]
    hexidecimal = [hex(int(b, 2))[2:] for b in binary]
    hexidecimal = token.join(hexidecimal)

    return hexidecimal

def paragragh_to_txt(P):
    S = ''
    for line in P:
        S = S + line
    
    return S

def txt_to_pat(S_txt):
    lst = list(S_txt)
    asc = [ord(char) for char in lst]
    S_bin = [list(format(a, '08b')) for a in asc]
    S_bin = [''.join(char_bin) for char_bin in S_bin]
    pat = ''
    for i in range(len(S_bin)):
        if i == len(S_bin) - 1:
            pat = pat + S_bin[i]
        elif i % 8 == 7:
            pat = pat + S_bin[i] + '\n'
        else:
            pat = pat + S_bin[i] + '_'
    
    return pat

def dec_to_pat(len_dec):
    len_bin = str(format(len_dec, '032b'))
    len_hex = len_bin[0:8] + '_' + len_bin[8:16] + '_' + len_bin[16:24] + '_' + len_bin[24:32]

    return len_hex