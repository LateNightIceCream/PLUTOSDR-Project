
addpath(genpath("../../transmitter/"))

SP_Rx = PR_QAM_Tx_Init

[SP_Rx, rx] = frequency_offset_receive(SP_Rx);