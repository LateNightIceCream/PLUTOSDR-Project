function [SP, rx] = frequency_offset_receive(SP)

    % Set up the receiver
    % Use the default value of 0 for FrequencyCorrection, which corresponds to
    % the factory-calibrated condition
    sampleRate = SP.PlutoFrontEndSampleRate;
    centerFreq = SP.PlutoCenterFrequency;
    numSamples = SP.PlutoFrameLength; % 1024 * 1024
 
    rx = sdrrx('Pluto', 'RadioID', 'usb:0', 'CenterFrequency', centerFreq, ...
               'BasebandSampleRate', sampleRate, 'SamplesPerFrame', numSamples, ...
               'OutputDataType', 'double', 'ShowAdvancedProperties', true);
    % Use the info method to show the actual values of various hardware-related
    % properties
    info(rx)

    %% Receive and Visualize Signal

    disp(['Capture signal and observe the frequency offset' newline])
    % recording!
    receivedSig = rx(); 
    save("rx_signal_1", receivedSig)

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

end