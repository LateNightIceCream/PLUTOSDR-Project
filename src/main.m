addpath(genpath("./common/"))
addpath(genpath("./receiver/"))
addpath(genpath("./transmitter/"))

close all;

% Transmitter parameter structure
prmQAMTransmitter = PR_QAM_Tx_Init;
prmQAMTransmitter = QAMBitsGenerator(prmQAMTransmitter);

scatterplot(prmQAMTransmitter.qam_symbols)
scatterplot(prmQAMTransmitter.tx_symbols)

spectrumAnalyzer = dsp.SpectrumAnalyzer('SampleRate', prmQAMTransmitter.Fs);
spectrumAnalyzer(prmQAMTransmitter.tx_symbols)

eyediagram(prmQAMTransmitter.tx_symbols, prmQAMTransmitter.Interpolation); % splits into real/imaginary

plot(abs(prmQAMTransmitter.tx_symbols(1:300)));

% Specify Radio ID
% prmQAMTransmitter.Address = 'usb:0';
% for network virtual environment: 'RadioID', 'ip:192.168.2.1'
% there is also a config file in the local drive of the adalm pluto (usb)
% with this information
prmQAMTransmitter.Address = 'ip:192.168.2.1';

%% ADALM-PLUTO Communication

% actually run the transmission on the pluto
runPR_QAM_Tx(prmQAMTransmitter);
