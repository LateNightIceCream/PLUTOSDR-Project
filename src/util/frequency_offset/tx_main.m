
addpath(genpath("../../transmitter/"))

SP = PR_QAM_Tx_Init

% send the signal for frequency offset calibration
disp("Transmitting offset calibration signals...")
[SP, tx] = frequency_offset_transmit(SP, 80e3); % we cannot release the tx structure because it changes the frequency offset of the hardware for some reason
disp("Offset calibration finished...")

% Problem: setting up Tx with some number of samples per frame
% then => inside runPRQAM... we call the bits generator which might add
% some padding => could be different sizes
% and we cant change the tx samplesperframe without releasing it (and
% creating a new one)
% so it needs to be correct from the beginning

% send the message
disp("Transmitting message...")
runPR_QAM_Tx_TEST(SP, tx);
disp("Finished message transmission.")

release(tx)