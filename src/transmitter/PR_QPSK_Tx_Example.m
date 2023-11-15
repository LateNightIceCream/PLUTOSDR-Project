%% QPSK Transmitter with ADALM-PLUTO Radio

% Copyright 2017-2018 The MathWorks, Inc.

% Transmitter parameter structure
prmQPSKTransmitter = PR_QPSK_Tx_Init
% Specify Radio ID
prmQPSKTransmitter.Address = 'usb:0';

% ADALM-PLUTO Radio> example in another MATLAB session.

%runPR_QPSK_Tx(prmQPSKTransmitter);

%% Appendix
% This example uses the following script and helper functions:
%
% * <matlab:edit('runPR_QPSK_Tx.m') runPR_QPSK_Tx.m>
% * <matlab:edit('PR_QPSK_Tx_Init.m') PR_QPSK_Tx_Init.m>
% * <matlab:edit('QPSKTransmitter.m') QPSKTransmitter.m>
% * <matlab:edit('QPSKBitsGenerator.m') QPSKBitsGenerator.m>
