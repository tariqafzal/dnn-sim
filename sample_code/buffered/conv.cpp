// modified the originial pseudocode to include tiling for NBin (l, ll)

#include <stdio.h>
#include <algorithm>

#include "config_conv2.h"

typedef float T;

#include "read_filters.cpp"

#define DEBUG 1
#define PRINT_STATS 0

// Caffe parameters to DianNao Kernel parameters 
int Nxin = data_h;
int Nyin = data_h;
int Kx = kernel_size;
int Ky = kernel_size;
int sx = stride;
int sy = stride;

int Ni = data_c; // also weight_c
int Nn = weight_n;
int No = Nn;

// apron for convolution corner conditions
int Ax = Nxin+2*PAD;
int Ay = Nyin+2*PAD;

int Nxout = (Ax - Kx)/sx + 1;
int Nyout = (Ay - Ky)/sy + 1;

// input
//      l   linear index
//  returns
//      &kx kernel index x
//      &ky kernel index y
//      &ki kernel index i
void get_3d_idx(int l, int & ky, int & kx, int & ki){
    ky = l / (Ni * Kx);
    l -= ky * Ni * Kx;
    kx = l / Ni;
    l -= kx * Ni;
    ki = l;
}

int main(int argc, char** argv){

    int synapseSize = Kx*Ky*Nn*Ni;
    int neuronSize = Ax*Ay*Ni;
    int neuronOutSize = Nyout*Nxout*No;

    if (PRINT_STATS){
        printf("Nxo = %d\n", Nxout);
        printf("Nyo = %d\n", Nyout);
        printf("synapse size = %d\n", synapseSize);
        printf("neuron size = %d\n", neuronSize);
        printf("neuronOut size = %d\n", neuronOutSize);
        printf("datasize = %d Bytes\n", sizeof(T));
    }

    T * sum = new T[Tnn];
    T * synapse = new T[synapseSize];
    T * neuron = new T[neuronSize];
    T * neuron_out = new T[neuronOutSize];

    int bufferCols[Tn][Ti];

    for (int i=0; i<synapseSize; i++){
        synapse[i] = i;
    }
    for (int i=0; i<neuronSize; i++){
        neuron[i] = i;
    }

    int read = read_filters(FILTER_FILE, synapse, synapseSize);
    if (DEBUG) printf("read %d/%d filters\n", read, synapseSize);

    if (DEBUG) printf("Index order: synapse[ky][kx][filter ID][i], neuron[y][x][i]\n");

    int cycle = 0;

    int yout = 0;
    for (int yy = 0; yy <= Ax-Ky; yy += Ty) { // tile x
        int xout = 0;
        for (int xx = 0; xx <= Ay-Kx; xx += Tx) { // tile y
            for (int nnn = 0; nnn < Nn; nnn += Tnn) { // tile n for L1 cache
                for (int y = yy; y < yy + Ty; y += sy) { // slide window in y
                    for (int x = xx; x < xx + Tx; x += sx) { // slide window in x
                        // calculate outputs for one window with one Tnn of weights

                        // initialize sum
                        for (int nn = nnn; (nn < nnn + Tnn) && (nn < Nn); nn += Tn) { // tile for output buffer
                            for (int n = nn; n < nn + Tn; n++) {
                                sum[n] = 0;
                            }
                        }

                        for (int ll = 0; ll < Ky*Kx*Ni; ll += Tii){ // tiled for input buffer, ll = input chunk index
                            for (int nn = nnn; (nn < nnn + Tnn) && (nn < Nn); nn += Tn) { // tile for output buffer

                                // l = linearized index for kx, ky, ii
                                for (int l = ll; l < ll+Tii && l < Ky*Kx*Ni ; l += Ti) {
                                    int ky, kx, ii;
                                    get_3d_idx(l, ky, kx, ii); 

                                    if (DEBUG >= 1) {
                                        printf("%6d: sum[%2d] += synapse[%2d][%2d][%2d][%2d] * neuron[%2d][%2d][%2d]\n", 
                                                cycle++, nn,             ky,  kx,  nn,  ii,           ky+y,kx+x,ii);
                                    }
                                    // These loops happen in parallel in one pipe_op:
                                    for (int n = nn; (n < nn + Tn) && (n < Nn); n++){
                                        for (int i = ii; (i < ii + Ti) && (i < Ni); i++){

                                            //sum[n] += synapse[ky][kx][n][i] * neuron[ky + y][kx + x][i];
                                            int sIdx = ( (ky*Kx +  kx) * Nn + n ) * Ni + i;
                                            int nIdx = ( (ky+y) * Ax + (kx+x) ) * Ni + i;
                                            sum[n] += synapse[sIdx] * neuron[nIdx];
                                            if (DEBUG >= 2) {
                                                printf("sum[%d] += synapse[%d][%d][%d][%d] * neuron[%d][%d][%d] = %f * %f \n", 
                                                        n,                 ky, kx, n, i,            ky+y, kx+x, i, synapse[sIdx], neuron[nIdx]);
                                            }
                                        }// for i
                                    }// for n
                                }// for l
                            } // for nn
                        }// for ll

                        // store results in output buffer to DRAM
                        for (int nn = nnn; (nn < nnn + Tnn) && (nn < Nn); nn += Tn) { // tile for output buffer
                            for (int n = nn; (n < nn + Tn) && (n < Nn); n++){
                                //neuron_out[yout][xout][n] = sum[n];
                                int idx = (yout * Nxout + xout) * No + n;
                                neuron_out[idx] = sum[n];
                            }
                        }
                    } 
                    xout++; 
                } 
                yout++;
            }
        }
    }
    if (DEBUG >= 1){
        for (int x = 0; x < Nxout; x++){
            for (int y = 0; y < Nyout; y++){
                for (int n = 0; n < No; n++){
                    int idx = (y * Nxout + x) * No + n;
                    printf("out %d:%f\n", idx, neuron_out[idx]);
                }
            }
        }
    }
    

    return 0;
}
