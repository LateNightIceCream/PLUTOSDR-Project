classdef Transmitter < RadioBase
    %% Transmitter object for adalm Pluto
    
    properties (Constant)
        NumberOfMessages = 100; % Number of messages in a frame
    end
    
    properties (GetAccess=public, SetAccess=private)
        Message = 'Replace this message by calling init_radio';
    end
    
    properties (Dependent)
        MessageLength;
        PayloadSizeBits;
        FrameSizeBits;
        FrameSizeSymbols;
        FrameSizeSamples;
    end
    
    methods
        %% Class constructor
        function obj = Transmitter()
        end
        
        
        %% Initialize the Pluto Radio Object
        function init_radio(obj, pluto_address, message)
            
            % the message needs to be known beforehand because
            % the total frame size for the pluto has to be correct
            % from the beginning to carry the offset setting over.
            % TODO: this is only relevant for the receiver, no?
            
            obj.init_message_transmission(message);
            
            obj.PlutoAddress = pluto_address;
            
            if ~isempty(obj.Radio)
                release(obj.Radio);
            end
            
            % Use the default value of 0 for FrequencyCorrection, which corresponds to
            % the factory-calibrated condition
            obj.Radio = sdrtx('Pluto', ...
                              'RadioID', obj.PlutoAddress, ...
                              'CenterFrequency', obj.CenterFrequency, ...
                              'BasebandSampleRate', obj.Fs, ...
                              'Gain', obj.PlutoGain, ...
                              'ShowAdvancedProperties', true);
            info(obj.Radio);
        end
        
        
        %% Transmit the message symbols via Pluto
        function transmit_message(obj, duration_sec)
            
            if isempty(obj.Radio)
                error("Radio object not initialized. Call init_radio(...) first.");
            end
            
            if isempty(obj.Symbols)
                error("No symbols to send.");
            end
            
            %radio.Gain = obj.PlutoGain;
            time_per_sample = obj.FrameSizeSamples / obj.Fs;

            step(obj.Radio, obj.Symbols);
            disp('Transmission has started')
            currentTime = 0;
            % Transmission Process
            while currentTime < duration_sec
                % Data transmission
                step(obj.Radio, obj.Symbols);

                % Update simulation time
                currentTime = currentTime + time_per_sample;
            end

            if currentTime ~= 0
                disp('Transmission has ended')
            end

            release(radio);
        end

        
        %% Transmit frequency offset signals
        function transmit_frequency_offset_signals(obj, duration_sec)
            
            if isempty(obj.Radio)
                error("Radio object not initialized. Call init_radio(...) first.");
            end
            
            sampleRate = obj.Fs;
            numSamples = obj.FrameSizeSamples;
    
            function s = get_ref_sin(frequency)
                sw = dsp.SineWave;
                sw.Amplitude = 1.0;
                sw.Frequency = frequency;
                sw.ComplexOutput = true;
                sw.SampleRate = sampleRate;
                sw.SamplesPerFrame = numSamples;
                s = sw();
            end

            fRef = obj.FRef;
            
            % Send signals
            disp('Sending 3 tones at 20, 40, and 80 kHz');

            % do not use transmitRepeat because we dont want to release the
            % transmitter
            % transmitRepeat(tx, s);

            s = get_ref_sin(20e3) + get_ref_sin(40e3) + get_ref_sin(fRef);
            s = 0.6*s/max(abs(s));

            RefSigTime = numSamples / sampleRate;
            
            % Transmission Process
            step(obj.Radio, s); % for connecting
            disp('Transmission has started');
            fprintf("Running Offset Transmission for %f seconds\n", duration_sec)
            currentTime = 0;
            while currentTime < duration_sec
                step(obj.Radio, s);
                currentTime = currentTime + RefSigTime;
            end

            if currentTime ~= 0
                disp('Transmission has ended')
            end
        end
        
        %% Setters
        
        % Message
        function set.Message(obj, message)
            if ~ischar(message)
                error("Message should be character array. Remember to use single quotes instead of double quotes for literals.")
            end
            obj.Message = message;
        end
        
        
        %% Getters
        
        % Message Length (characters)
        function MessageLength = get.MessageLength(obj)
            MessageLength = strlength(obj.Message);
        end
        
        
        % Payload Length (bits)
        function PayloadSizeBits = get.PayloadSizeBits(obj)
            PayloadSizeBits = obj.NumberOfMessages * obj.MessageLength * obj.BITS_PER_CHARACTER;
        end
        
        
        % Total frame size including message (bits)
        function FrameSizeBits = get.FrameSizeBits(obj)
            useful_size = length(obj.Header) + obj.SizeFieldLength + obj.PayloadSizeBits;
            padding_size = numel(calc_padding_bits(useful_size, obj.ModulationOrder));
            FrameSizeBits = (useful_size + padding_size);
        end
        
        
        % Total frame size in Symbols
        function FrameSizeSymbols = get.FrameSizeSymbols(obj)
            FrameSizeSymbols = obj.FrameSizeBits / log2(obj.ModulationOrder);
        end
        
        
        % Total frame size in Samples (without sampling rate)
        function FrameSizeSamples = get.FrameSizeSamples(obj)
            FrameSizeSamples = obj.FrameSizeSymbols * obj.Interpolation;
        end
        
    end
    
    
    methods (Access=private)
        
        %% Prepare the message transmission
        function obj = init_message_transmission(obj, message)
            obj.Message = message;
            frame_bits = obj.generate_frame_bits();
            obj.Symbols = obj.generate_symbols(frame_bits);
        end
        
        
        %% Generate the message frame
        % This needs to be called before actually transmitting
        % since it will set the appropriate frame size
        function frame_bits = generate_frame_bits(obj)
            % initialize frame
            frame_bits = [obj.Header];
            
            % generate the message
            message_bits = obj.generate_payload_bits();
            
            % Append payload size field to frame
            msgsize = numel(message_bits);
            size_bits = dec2bin(msgsize, obj.SizeFieldLength) == '1';  % == '1' converts string from dec2bin to digit array
            
            % Zero-Padding for the payload
            pad_bits = calc_padding_bits(numel(frame_bits) + numel(size_bits) + numel(message_bits), obj.ModulationOrder);
            non_header_bits = [size_bits, message_bits, pad_bits];
            
            % Scramble everything but the header
            scrambler = comm.Scrambler( ...
                        obj.ScramblerBase, ...
                        obj.ScramblerPolynomial, ...
                        obj.ScramblerInitialConditions);
            scrambled_bits = scrambler(non_header_bits')';
            
            frame_bits = [frame_bits, scrambled_bits];
        end
        
        
        %% Modulate the given bits (list of 1/0)
        function symbols = generate_symbols(obj, bits)
            qam_symbols = qammod(bits', obj.ModulationOrder, ...
                                 InputType='bit', ...
                                 UnitAveragePower=true, ...
                                 PlotConstellation=true);

            tx_filter = comm.RaisedCosineTransmitFilter( ...
                        'RolloffFactor', obj.RolloffFactor, ...
                        'FilterSpanInSymbols', obj.RaisedCosineFilterSpan, ...
                        'OutputSamplesPerSymbol', obj.Interpolation);

            symbols = tx_filter(qam_symbols);
        end
        
        
        %% Converts message to payload bits
        % repeats the message and converts the message string to
        % a bit array
        function bits = generate_payload_bits(obj)
            numMessages = obj.NumberOfMessages;
            % convert characters to numeric representation
            charnums = double(obj.Message);
            % convert to binary
            bitrows = de2bi(charnums, obj.BITS_PER_CHARACTER, 'left-msb');
            % reshape into 1D-List
            bits = reshape(bitrows.', 1, []);
            % repeat the message
            bits = repmat(bits, 1, numMessages);
        end
        
        %%
        % used to test that the payload bits are generated correctly and
        % can be recovered to characters
        function test_payload_generation(obj)
            obj.Message = 'test message!➦';
            bits = obj.generate_payload_bits();
            % check that the length matches
            disp("bitlength:");
            disp(length(bits));
            disp("calclength:");
            disp(obj.PayloadSizeBits);
            obj.BITS_PER_CHARACTER * obj.NumberOfMessages
            % perform the reverse
            bitrows = reshape(bits, obj.BITS_PER_CHARACTER, obj.NumberOfMessages * obj.MessageLength)
            %size(bitrows)
            bitrows'
            nums = bi2de(bitrows', 'left-msb')
            char(nums)
        end

        % convert number of bits to number of samples
        % TODO: need to test this
        function nsamples = num_samples(obj, nbits)
            nsymbols = obj.num_symbols(nbits);
            nsamples = nsymbols * obj.Interpolation;
        end
        
        % convert number of bits to number of symbols
        function nsymbols = num_symbols(obj, nbits)
            nsymbols = nbits / log2(obj.ModulationOrder);
        end
        
    end
    
end