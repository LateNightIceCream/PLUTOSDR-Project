
addpath(genpath("../../transmitter/"))

SP = PR_QAM_Tx_Init

% send the signal for frequency offset calibration
disp("Transmitting offset calibration signals...")
[SP, tx] = frequency_offset_transmit(SP, 80e3);

% send the message
disp("Transmitting message...")
runPR_QAM_Tx_TEST(SP, tx);


release(tx)