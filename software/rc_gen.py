import numpy as np
import sha3_util as util
from os.path import join


def main():
    RC = np.zeros(64, dtype = int)
    for i_rnd in range(24):
        for j in range(6 + 1):
            RC[2 ** j - 1] = util._rc(j + 7 * i_rnd)
        rc_bits = "assign rc_bits[" + str(i_rnd) + "] = 64'b"
        rc_bits += ''.join(str(i) for i in RC)
        rc_bits += ';'
        print(rc_bits)
            
main()