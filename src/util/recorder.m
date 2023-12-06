% this is used to record the raw signal at the receiver
% and save it to a file for later use

addpath(genpath("../common/"))
addpath(genpath("../receiver/"))
addpath(genpath("../transmitter/"))

close all;

SP = PR_QAM_Tx_Init;
record_signal(SP, 0.0, 5)


function record_signal(SP_Tx, fc_correction, duration)
    % run the transmitter

    rx_center_frequency  = SP_Tx.PlutoCenterFrequency + fc_correction; % might need offset
    rx_sample_rate       = SP_Tx.PlutoFrontEndSampleRate;
    rx_samples_per_frame = SP_Tx.PlutoFrameLength;
    
    % run the receiver
    
    rx = sdrrx('Pluto', ...
           'RadioID', 'usb:0', ...
           'CenterFrequency', rx_center_frequency, ...
           'BasebandSampleRate', rx_sample_rate, ...
           'SamplesPerFrame', rx_samples_per_frame)

    filename = get_filename(rx_center_frequency, rx_sample_rate, rx_samples_per_frame);

    capture(rx, duration, 'Seconds', 'Filename', filename);

    release(rx);
    
end


function filename = get_filename(Fc, Fs, SpF)
    date_fmt = "yyyy_MM_dd[hh:mm:ss]";
    now = string(datetime("now", 'TimeZone', 'UTC'), date_fmt);
    filename = join([string(Fc), string(Fs), string(SpF)], '_');
    filename = sprintf('%s_Fc[%d]_Fs[%d]_SpF[%d].bb', now, Fc, Fs, SpF);
end