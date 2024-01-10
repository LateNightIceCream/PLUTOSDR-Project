function [SP, tx] = frequency_offset_transmit(SP, plutoAddr, duration_sec)
    
    sampleRate = SP.PlutoFrontEndSampleRate;
    centerFreq = SP.PlutoCenterFrequency;
    %numSamples = SP.PlutoFrameLength;
    numSamples = 1.0/20e3 * sampleRate * 2;
    
    function s = get_ref_sin(frequency)
        sw = dsp.SineWave;
        sw.Amplitude = 1.0;
        sw.Frequency = frequency;
        sw.ComplexOutput = true;
        sw.SampleRate = sampleRate;
        sw.SamplesPerFrame = numSamples;
        s = sw();
    end

    fRef = 80e3;
    
    % DC would just be vector of all 1
    % >> think about the frequency shift property of the fourier transform
    % e^(jw0 t) * x(t) <=> X(w-w0)
    
    %s1 = exp(1j*2*pi*20e3*[0:numSamples-1]'/sampleRate);  % 20 kHz 
    %s2 = exp(1j*2*pi*40e3*[0:numSamples-1]'/sampleRate);  % 40 kHz
    %s3 = exp(1j*2*pi*fRef*[0:numSamples-1]'/sampleRate);  % 80 kHz
    %s = s1 + s2 + s3;
    %s = 0.6*s/max(abs(s)); % Scale signal to avoid clipping in the time domain

    % Set up the transmitter
    % Use the default value of 0 for FrequencyCorrection, which corresponds to
    % the factory-calibrated condition
    tx = sdrtx('Pluto', ...
               'RadioID', plutoAddr, ...
               'CenterFrequency', centerFreq, ...
               'BasebandSampleRate', sampleRate, ...
               'Gain', 0, ...
               'ShowAdvancedProperties', true);
    info(tx)
    
    % Send signals
    disp('Send 3 tones at 20, 40, and 80 kHz');
    
    % do not use transmitRepeat because we dont want to release the
    % transmitter
    % transmitRepeat(tx, s);
 
    currentTime = 0;
    disp('Transmission has started')

    RefSigTime = numSamples / sampleRate % time between samples
    
    fprintf("Running Offset Transmission for %f seconds\n", duration_sec)
    
    s_20k = get_ref_sin(20e3);
    s_40k = get_ref_sin(40e3);
    s_ref = get_ref_sin(fRef);
    s = s_20k + s_40k + s_ref;
    s = 0.6*s/max(abs(s));
    
    %transmitRepeat(tx, s);

    disp("GO")

    %runtime = tic
    %while toc(runtime) < duration_sec
    %for counter = 1:20
    %    disp('hey')
    %    tx(s);
    %end
    %end
    
    
    RefSigTime = numSamples/sampleRate;
    
    %plot(abs(s))
    
    %step(tx, s); % for connecting
    currentTime = 0;
    % Transmission Process

    while currentTime < 10
    
        % Data transmission
        %tx(s);
        %disp("step")
        %underflow = tx(s)
        
        % Update simulation time
        currentTime = currentTime + RefSigTime;
    end

    if currentTime ~= 0
        disp('Transmission has ended')
    end

end


