%% later: determine time span needed to sample the entire Tx frame

close all;

%% just to generate a testing Tx frame => delete later
addpath(genpath("../"))
prmQAMTransmitter = PR_QAM_Tx_Init;
prmQAMTransmitter = QAMBitsGenerator(prmQAMTransmitter);

scatterplot(prmQAMTransmitter.tx_symbols)

%%
% Receiver parameter structure
prmQAMReceiver = PR_QAM_Rx_Init;
prmQAMReceiver = QAMReceiver(prmQAMReceiver, prmQAMTransmitter.tx_symbols);

%scatterplot(prmQAMTransmitter.tx_symbols)

%spectrumAnalyzer = dsp.SpectrumAnalyzer('SampleRate', prmQAMTransmitter.Fs);
%spectrumAnalyzer(prmQAMTransmitter.tx_symbols)

%eyediagram(prmQAMTransmitter.tx_symbols, prmQAMTransmitter.Interpolation); % splits into real/imaginary

%plot(abs(prmQAMTransmitter.tx_symbols(1:300)));

% Specify Radio ID
%prmQAMTransmitter.Address = 'usb:0';
% for network virtual environment: 'RadioID', 'ip:192.168.2.1'
% there is also a config file in the local drive of the adalm pluto (usb)
% with this information

%% ADALM-PLUTO Communication

% actually run the transmission on the pluto
%runPR_QAM_Tx(prmQAMTransmitter);

%% Appendix
% This example uses the following script and helper functions:
%
% * <matlab:edit('runPR_QPSK_Tx.m') runPR_QPSK_Tx.m>
% * <matlab:edit('PR_QPSK_Tx_Init.m') PR_QPSK_Tx_Init.m>
% * <matlab:edit('QPSKTransmitter.m') QPSKTransmitter.m>
% * <matlab:edit('QPSKBitsGenerator.m') QPSKBitsGenerator.m>
