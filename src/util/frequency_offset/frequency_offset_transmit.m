function [SP, tx] = frequency_offset_transmit(SP, fRef)
    sampleRate = SP.PlutoFrontEndSampleRate;
    centerFreq = SP.PlutoCenterFrequency;
    numSamples = SP.PlutoFrameLength;
    % DC would just be vector of all 1
    % >> think about the frequency shift property of the fourier transform
    % e^(jw0 t) * x(t) <=> X(w-w0)
    s1 = exp(1j*2*pi*20e3*[0:numSamples-1]'/sampleRate);  % 20 kHz 
    s2 = exp(1j*2*pi*40e3*[0:numSamples-1]'/sampleRate);  % 40 kHz
    s3 = exp(1j*2*pi*fRef*[0:numSamples-1]'/sampleRate);  % 80 kHz
    s = s1 + s2 + s3;
    s = 0.6*s/max(abs(s)); % Scale signal to avoid clipping in the time domain

    % Set up the transmitter
    % Use the default value of 0 for FrequencyCorrection, which corresponds to
    % the factory-calibrated condition
    tx = sdrtx('Pluto', 'RadioID', 'usb:0', 'CenterFrequency', centerFreq, ...
               'BasebandSampleRate', sampleRate, 'Gain', 0, ...
               'ShowAdvancedProperties', true);
    % Use the info method to show the actual values of various hardware-related
    % properties
    info(tx)
    % Send signals
    disp('Send 3 tones at 20, 40, and 80 kHz');
    
    % do not use transmitRepeat because we dont want to release the
    % transmitter
    % transmitRepeat(tx, s);
 
    currentTime = 0;
    disp('Transmission has started')

    RefSigTime = numSamples / sampleRate % time between samples
    
    fprintf("Running Transmission for %f seconds\n", SP.StopTime)
    
    % Transmission Process
    while currentTime < SP.StopTime

        % Data transmission
        step(tx, s);
        
        % Update simulation time
        currentTime = currentTime + RefSigTime;
    end

    if currentTime ~= 0
        disp('Transmission has ended')
    end

end