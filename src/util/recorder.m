% this is used to record the raw signal at the receiver
% and save it to a file for later use

addpath(genpath("../common/"))
addpath(genpath("../receiver/"))
addpath(genpath("../transmitter/"))

close all;


% run the transmitter

prmQAMTransmitter = PR_QAM_Tx_Init;
prmQAMTransmitter = QAMBitsGenerator(prmQAMTransmitter);


% run the receiver

rx_center_frequency  = prmQAMTransmitter.PlutoCenterFrequency; % might need offset
rx_sample_rate       = prmQAMTransmitter.PlutoFrontEndSampleRate;
rx_samples_per_frame = prmQAMTransmitter.PlutoFrameLength;

rx = sdrrx('Pluto', ...
           'RadioID', 'usb:0', ...
           'CenterFrequency', rx_center_frequency, ...
           'BasebandSampleRate', rx_sample_rate, ...
           'SamplesPerFrame', rx_samples_per_frame)

filename = get_filename(rx_center_frequency, rx_sample_rate, rx_samples_per_frame);
       
capture(rx,5,'Seconds', 'Filename', filename);
       
release(rx);


function filename = get_filename(Fc, Fs, SpF)
    date_fmt = "yyyy_MM_dd[hh:mm:ss]";
    now = string(datetime("now", 'TimeZone', 'UTC'), date_fmt);
    filename = join([string(Fc), string(Fs), string(SpF)], '_');
    filename = sprintf('%s_Fc[%d]_Fs[%d]_SpF[%d].bb', now, Fc, Fs, SpF);
end