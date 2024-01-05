% this is used to record the raw signal at the receiver
% and save it to a file for later use

addpath(genpath("../common/"))
addpath(genpath("../receiver/"))
addpath(genpath("../transmitter/"))

close all;

%SP = PR_QAM_Tx_Init;
%record_signal(SP, 0.0, 5)


function record_signal(rx, duration)

    filename = get_filename(rx.CenterFrequency, rx.BasebandSampleRate, rx.SamplesPerFrame);

    capture(rx, duration, 'Seconds', 'Filename', filename);

    release(rx);
    
end


function filename = get_filename(Fc, Fs, SpF)
    date_fmt = "yyyy_MM_dd[hh:mm:ss]";
    now = string(datetime("now", 'TimeZone', 'UTC'), date_fmt);
    filename = join([string(Fc), string(Fs), string(SpF)], '_');
    filename = sprintf('%s_Fc[%d]_Fs[%d]_SpF[%d].bb', now, Fc, Fs, SpF);
end