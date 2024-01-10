classdef Receiver < RadioBase
    %% Receiver object for adalm Pluto
    
    properties (Constant)
    end
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    properties (Dependent)
    end
    
    properties (Access=private)
        OffsetCalibrationFinished = false;
    end
    
    methods
        %% Class constructor
        function obj = Receiver()
            obj.PlutoGain = 20;
        end
        
        
        %% Initialize the Pluto Radio Object
        function init_radio(obj, pluto_address)
            if ~isempty(obj.Radio)
                release(obj.Radio);
            end
            
            obj.OffsetCalibrationFinished = false;
            obj.PlutoAddress = pluto_address;
            
            % TODO: outsource to member variable
            num_samples = 1024 * 1024; % number of samples in one received frame
            
            obj.Radio = sdrrx('Pluto', ...
                              'RadioID', obj.PlutoAddress, ...
                              'CenterFrequency', obj.CenterFrequency, ...
                              'BasebandSampleRate', obj.Fs, ...
                              'SamplesPerFrame', num_samples, ...
                              'OutputDataType', 'double', ...
                              'ShowAdvancedProperties', true, ...
                              'GainSource', 'manual', ...
                              'Gain', obj.PlutoGain);
            info(obj.Radio);
        end
        
        
        %% Receive frequency offset and calibrate
        function receive_frequency_offset(obj)
            if isempty(obj.Radio)
                error(obj.ERR_RADIO_NOT_INIT);
            end

            obj.OffsetCalibrationFinished = false;
            sampleRate = obj.Fs;
            centerFreq = obj.CenterFrequency;
            numSamples = obj.Radio.SamplesPerFrame;
            fRef = obj.FRef;

            %% Receive and Visualize Signal
            
            disp(['Capture signal and observe the frequency offset' newline])
            receivedSig = obj.Radio(); 
            % save("rx_signal_1", receivedSig)

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
            obj.Radio.FrequencyCorrection = (fReceived - fRef) / (centerFreq + fRef) * 1e6;
            sprintf(['Based on the tone detected at %.3f kHz, ' ...
                     'FrequencyCorrection of the receiver was set to %.4f'], ...
                     fReceived/1000, obj.Radio.FrequencyCorrection);
                 
            obj.OffsetCalibrationFinished = true;
            info(obj.Radio)     
        end
        
        
        %% Receive frame with given duration
        function data = receive(obj, duration, save_data)
            if ~obj.OffsetCalibrationFinished
                error("Please run the offset calibration first");
            end

            disp("Now receiving message frame...");

            %% Receive and Visualize Signal
            [data, mdata] = capture(obj.Radio, duration, 'Seconds');
            
            disp(mdata)

            if save_data == true
                filename = obj.get_filename(obj.Radio.CenterFrequency, ...
                                            obj.Radio.BasebandSampleRate, ...
                                            obj.Radio.SamplesPerFrame);
                save(filename, 'data')
            end

        end
        
        %% ignore this
        function test_blep(obj)
            obj.get_filename()
        end
        
        %% Setters
        
        
        %% Getters
     
        
    end
    
    
    methods (Access=private)
        function filename = get_filename(obj)
            if isempty(obj.Radio)
                error(obj.ERR_RADIO_NOT_INIT)
            end
            Fc = obj.Radio.CenterFrequency;
            Fs = obj.Radio.BasebandSampleRate;
            SpF = obj.Radio.SamplesPerFrame;
            date_fmt = "yyyy_MM_dd[hh:mm:ss]";
            now = string(datetime("now", 'TimeZone', 'UTC'), date_fmt);
            %filename = join([string(Fc), string(Fs), string(SpF)], '_');
            filename = sprintf('%s_Fc[%d]_Fs[%d]_SpF[%d].bb', now, Fc, Fs, SpF);
        end
    end
    
end