addpath(genpath("../../transmitter/"))
addpath(genpath("../../receiver/"))
addpath(genpath("../frequency_offset/"))

close all;

SP = PR_QAM_Rx_Init

pause(4);

% measure and apply the frequency correction to rx
%[SP_Rx, rx, sa] = frequency_offset_receive(SP_Rx);


% Set up the receiver
% Use the default value of 0 for FrequencyCorrection, which corresponds to
% the factory-calibrated condition
sampleRate = SP.PlutoFrontEndSampleRate;
centerFreq = SP.PlutoCenterFrequency;
numSamples = 1024*1024; % 1024 * 1024

fRef = 80e3;

rx = sdrrx('Pluto', 'RadioID', 'ip:192.168.2.1', 'CenterFrequency', centerFreq, ...
           'BasebandSampleRate', sampleRate, 'SamplesPerFrame', numSamples, ...
           'OutputDataType', 'double',...
           'ShowAdvancedProperties', true, ...
           'GainSource', 'manual', ...
           'Gain', 20);
% Use the info method to show the actual values of various hardware-related
% properties
info(rx)

%% Receive and Visualize Signal

disp(['Capture signal and observe the frequency offset' newline])
% recording!
receivedSig = rx(); 
%save("rx_signal_1", receivedSig)

% Find the tone that corresponds to the 80 kHz transmitted tone
y = fftshift(abs(fft(receivedSig)));
[~, idx] = findpeaks(y,'MinPeakProminence',max(0.5*y));
fReceived = (max(idx)-numSamples/2-1)/numSamples*sampleRate; % get the actual frequency of the peak

% Plot the spectrum
sa = dsp.SpectrumAnalyzer('SampleRate', sampleRate, 'SpectralAverages', 4);
sa.Title = sprintf('Tone Expected at 80 kHz, Actually Received at %.3f kHz', ...
                   fReceived/1000);
receivedSig = reshape(receivedSig, [], 16); % Reshape into 16 columns
for i = 1:size(receivedSig, 2)
    sa(receivedSig(:,i));
end

%% Estimate and Apply the Value of FrequencyCorrection

rx.FrequencyCorrection = (fReceived - fRef) / (centerFreq + fRef) * 1e6;
msg = sprintf(['Based on the tone detected at %.3f kHz, ' ...
               'FrequencyCorrection of the receiver should be set to %.4f'], ...
               fReceived/1000, rx.FrequencyCorrection);
disp(msg);
info(rx)

w = waitforbuttonpress;



disp("Starting recording")
received_signal = rx();
figure
plot(abs(received_signal));

release(rx);