%% QPSK Receiver with ADALM-PLUTO Radio
% This example shows how to use the ADALM-PLUTO Radio System objects
% Copyright 2017-2018 The MathWorks, Inc.


%% Initialization
% Receiver parameter structure
prmQPSKReceiver = PR_QPSK_Rx_Init;
% Specify Radio ID
prmQPSKReceiver.Address = 'usb:0'

%% Code Architecture
% The function runPR_QPSK_Rx implements the QPSK receiver using
% the QPSK receiver System object, QPSKReceiver, and ADALM-PLUTO radio System
% object, comm.SDRRxPluto.
%
% *ADALM-PLUTO Receiver*
%
% This example communicates with the ADALM-PLUTO radio using the ADALM-PLUTO
% Receiver System object. The parameter structure _prmQPSKReceiver_ sets the
% CenterFrequency, Gain, and InterpolationFactor etc.
%
% *QPSK Receiver*
%
% subcomponents:
%
% 1) Automatic Gain Control
%
% 2) Coarse frequency compensation
%
% 3) Timing recovery
%
% 4) Fine frequency compensation
%
% 5) Preamble Detection
%
% 6) Frame Synchronization
%
% 7) Data decoder
%
% For more information about the system components, refer to the
% <matlab:plutoradioQPSKReceiverSimulinkExample QPSK Receiver with ADALM-PLUTO Radio example using
% Simulink>.

%% Execution and Results
% Connect two ADALM-PLUTO Radios to the computer.
% Start the <matlab:edit('PR_QPSK_Tx_Example.m') QPSK Transmitter with
% ADALM-PLUTO Radio> example in one MATLAB session and then start the
% receiver script in another MATLAB session.

printReceivedData = true;    % true if the received data is to be printed

BER = runPR_QPSK_Rx(prmQPSKReceiver, printReceivedData); 

fprintf('Error rate is = %f.\n',BER(1));
fprintf('Number of detected errors = %d.\n',BER(2));
fprintf('Total number of compared samples = %d.\n',BER(3));

