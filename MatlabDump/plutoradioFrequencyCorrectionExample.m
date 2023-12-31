%% Frequency Correction for ADALM-PLUTO Radio
%
% The FrequencyCorrection property specifies the parts-per-million change
% to the baseband sample rate and the center frequency. The default value
% is 0.
%
% Copyright 2017-2019 The MathWorks, Inc.

%% Algorithm for Estimating Frequency Correction
%
%% Set up the Transmitter and the Receiver  (2 Adalms e.g. at USB0 and USB1)
%
% Set up parameters and signals
sampleRate = 200e3;
centerFreq = 2.42e9;
fRef = 80e3;
s1 = exp(1j*2*pi*20e3*[0:10000-1]'/sampleRate);  % 20 kHz
s2 = exp(1j*2*pi*40e3*[0:10000-1]'/sampleRate);  % 40 kHz
s3 = exp(1j*2*pi*fRef*[0:10000-1]'/sampleRate);  % 80 kHz
s = s1 + s2 + s3;
s = 0.6*s/max(abs(s)); % Scale signal to avoid clipping in the time domain

% Set up the transmitter
% Use the default value of 0 for FrequencyCorrection, which corresponds to
% the factory-calibrated condition
tx = sdrtx('Pluto', 'RadioID', 'usb:1', 'CenterFrequency', centerFreq, ...
           'BasebandSampleRate', sampleRate, 'Gain', 0, ...
           'ShowAdvancedProperties', true);
% Use the info method to show the actual values of various hardware-related
% properties
txRadioInfo = info(tx)
% Send signals
disp('Send 3 tones at 20, 40, and 80 kHz');
transmitRepeat(tx, s);

% Set up the receiver
% Use the default value of 0 for FrequencyCorrection, which corresponds to
% the factory-calibrated condition
numSamples = 1024*1024;
rx = sdrrx('Pluto', 'RadioID', 'usb:0', 'CenterFrequency', centerFreq, ...
           'BasebandSampleRate', sampleRate, 'SamplesPerFrame', numSamples, ...
           'OutputDataType', 'double', 'ShowAdvancedProperties', true);
% Use the info method to show the actual values of various hardware-related
% properties
rxRadioInfo = info(rx)

%% Receive and Visualize Signal

disp(['Capture signal and observe the frequency offset' newline])
receivedSig = rx();

% Find the tone that corresponds to the 80 kHz transmitted tone
y = fftshift(abs(fft(receivedSig)));
[~, idx] = findpeaks(y,'MinPeakProminence',max(0.5*y));
fReceived = (max(idx)-numSamples/2-1)/numSamples*sampleRate;

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
rxRadioInfo = info(rx)

%% Receive and Visualize Signal

% Capture 10 frames, but only use the last frame to skip the transient 
% effects due to changing FrequencyCorrection 
disp(['Capture signal and verify frequency correction' newline])
for i = 1:10
    receivedSig = rx();
end

% Find the tone that corresponds to the 80 kHz transmitted tone
% fReceived2 should be very close to 80 kHz
y = fftshift(abs(fft(receivedSig)));
[~,idx] = findpeaks(y,'MinPeakProminence',max(0.5*y));
fReceived2 = (max(idx)-numSamples/2-1)/numSamples*sampleRate;

% Plot the spectrum
sa.Title = '3 Tones Received at 20, 40, and 80 kHz';
receivedSig = reshape(receivedSig, [], 16); % Reshape into 16 columns
for i = 1:size(receivedSig, 2)
    sa(receivedSig(:,i));
end
msg = sprintf('Tone detected at %.3f kHz\n', fReceived2/1000);
disp(msg);

%% Change FrequencyCorrection of the Transmitter
% Now we change the FrequencyCorrection property of the transmitter to
% simulate the effect that the transmitter's oscillator has drifted.

disp(['Change the FrequencyCorrection property of the transmitter to 1 to ' ...
      'simulate the effect that the transmitter''s oscillator has drifted'])
tx.FrequencyCorrection = 1; % 1 ppm
txRadioInfo = info(tx)
tx.transmitRepeat(s);

%% Receive and Visualize Signal

% Capture 10 frames, but use the last frame only to skip the transient 
% effects due to changing FrequencyCorrection 
disp(['Capture signal and observe the frequency offset' newline])
for i = 1:10
    receivedSig = rx();
end

% Find the tone that corresponds to the 80 kHz transmitted tone
% fReceived3 will not be close to 80 kHz because tx.FrequencyCorrection
% has been changed
y = fftshift(abs(fft(receivedSig)));
[~,idx] = findpeaks(y,'MinPeakProminence',max(0.5*y));
fReceived3 = (max(idx)-numSamples/2-1)/numSamples*sampleRate;

% Plot the spectrum
sa.Title = sprintf('Tone Expected at 80 kHz, Actually Received at %.3f kHz', ...
                   fReceived3/1000);
receivedSig = reshape(receivedSig, [], 16); % Reshape into 16 columns
for i = 1:size(receivedSig, 2)
    sa(receivedSig(:,i));
end

%% Estimate and Apply the Value of FrequencyCorrection
% We use the same method to estimate the required parts-per-million
% change to the baseband sample rate and the center frequency of the
% receiver. However, the estimated value needs to be combined appropriately
% with the current setting of FrequencyCorrection, which is nonzero.
% Since $(1+{p_1}/10^6)*(1+{p_2}/10^6) = 1 + ({p_1} + {p_2} + {p_1}*{p_2}*10^{-6})/10^6$,
% applying two changes $p_1$ and $p_2$ successively is equivalent to
% applying a single change of ${p_1} + {p_2} + {p_1}*{p_2}*10^{-6}$ with
% respect to the factory-calibrated condition.

rxRadioInfo = info(rx);
currentPPM = rxRadioInfo.FrequencyCorrection;
ppmToAdd = (fReceived3 - fRef) / (centerFreq + fRef) * 1e6;
rx.FrequencyCorrection = currentPPM + ppmToAdd + currentPPM*ppmToAdd/1e6;
msg = sprintf(['Based on the tone detected at %.3f kHz, ' ...
               'FrequencyCorrection of the receiver should be changed from %.4f to %.4f'], ...
               fReceived3/1000, currentPPM, rx.FrequencyCorrection);
disp(msg);
rxRadioInfo = info(rx)

%% Receive and Visualize Signal

% Capture 10 frames, but use the last frame only to skip the transient
% effects due to changing FrequencyCorrection 
disp(['Capture signal and verify frequency correction' newline])
for i = 1:10
    receivedSig = rx();
end

% Find the tone that corresponds to the 80 kHz transmitted tone
% fReceived4 should be very close to 80 kHz
y = fftshift(abs(fft(receivedSig)));
[~,idx] = findpeaks(y,'MinPeakProminence',max(0.5*y));
fReceived4 = (max(idx)-numSamples/2-1)/numSamples*sampleRate;

% Plot the spectrum
sa.Title = '3 Tones Received at 20, 40, and 80 kHz';
receivedSig = reshape(receivedSig, [], 16); % Reshape into 16 columns
for i = 1:size(receivedSig, 2)
    sa(receivedSig(:,i));
end
msg = sprintf('Tone detected at %.3f kHz', fReceived4/1000);
disp(msg);

% Release the radios
release(tx);
release(rx);

displayEndOfDemoMessage(mfilename)
