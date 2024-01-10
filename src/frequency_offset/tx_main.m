
addpath(genpath("../../transmitter/"))

SP = PR_QAM_Tx_Init

% send the signal for frequency offset calibration
disp("Transmitting offset calibration signals...")
[SP, tx] = frequency_offset_transmit(SP, 'ip:192.168.2.1', 15.0); % we cannot release the tx structure because it changes the frequency offset of the hardware for some reason
disp("Offset calibration finished...")

% send the message
disp("Transmitting message...")
runPR_QAM_Tx_TEST(SP, tx);
disp("Finished message transmission.")

%release(tx)