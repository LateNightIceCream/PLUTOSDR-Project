addpath(genpath("../../transmitter/"))

SP_Rx = PR_QAM_Tx_Init

[SP_Rx, rx, sa] = frequency_offset_receive(SP_Rx);

% sa() this errors b



release(rx);