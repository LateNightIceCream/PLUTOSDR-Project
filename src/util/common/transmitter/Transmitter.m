classdef Transmitter
    %% Singleton transmitter object for Pluto
    
    properties (Constant)
        
        BITS_PER_CHARACTER = 16; % do not change this
        
        %% General parameters
        Rsym = 0.2e6;             % Symbol rate in Hertz
        ModulationOrder = 4;      % QPSK alphabet size
        Interpolation = 7;        % Interpolation factor
        Decimation = 1;           % Decimation factor
        
        %% Frame Specifications
        BarkerCode = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1]; % Bipolar Barker Code
        NumberOfMessages = 100; % Number of messages in a frame
        SizeFieldLength = 16;
        
        %% Tx Parameters
        RolloffFactor = 0.5; % Rolloff Factor of Raised Cosine Filter
        ScramblerBase = 2;
        ScramblerPolynomial = [1 1 1 0 1];
        ScramblerInitialConditions = [0 0 0 0];
        RaisedCosineFilterSpan = 10; % Filter span of Raised Cosine Tx Rx filters (in symbols)

    end
    
    properties (GetAccess=public, SetAccess=private)
        % length in bits of the frame's size field
        Message = 'Hello Ŵorld'; % character vector, make sure to use SINGLE QUOTES
        %FrameSize       = (HeaderLength + SizeFieldLength + PayloadLength + numel(calc_padding_bits(HeaderLength + SizeFieldLength + PayloadLength, ModulationOrder))) ...
        %    / log2(ModulationOrder);                                    % Frame size in symbols
        %FrameTime       = Tsym*FrameSize;
        Symbols = [];
    end
    
    properties (Dependent)
        Tsym;
        Fs;
        %% Frame related
        Header;
        MessageLength;
        PayloadLength;
        FrameSizeBits;
        FrameSizeSymbols;
        FrameSizeSamples;
    end
    
    properties (Access=private)
    end
    
    methods
        %% Class constructor
        function obj = Transmitter()
        end
        
        
        %% Initialize the Pluto Radio object
        function init_transmission(obj, message)
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
        
        
        %% Transmit the symbols via Pluto
        function send_message(obj)
            if isempty(obj.Symbols)
                error("No symbols to send.");
            end
            
        end
        
        
        %% Setters
        
        % Message
        function obj = set.Message(obj, message)
            if ~ischar(message)
                error("Message should be character array. Remember to use single quotes instead of double quotes for literals.")
            end
            disp("DONE")
            obj.Message = message;
        end
        
        
        %% Getters
        
        % Symbol duration (s)
        function Tsym = get.Tsym(obj)
            Tsym = 1/obj.Rsym;
        end
        
        
        % Sample rate (Hz)
        function Fs = get.Fs(obj)
            Fs = obj.Interpolation * obj.Rsym;
        end
        
        
        % Header (bipolar array)
        function Header = get.Header(obj)
            ubc = ((obj.BarkerCode + 1) / 2)';
            Header = (repmat(ubc,2,1))';
        end
        
        
        % Message Length (characters)
        function MessageLength = get.MessageLength(obj)
            MessageLength = strlength(obj.Message);
        end
        
        
        % Payload Length (bits)
        function PayloadLength = get.PayloadLength(obj)
            PayloadLength = obj.NumberOfMessages * obj.MessageLength * obj.BITS_PER_CHARACTER;
        end
        
        
        % Total frame size including message (bits)
        function FrameSizeBits = get.FrameSizeBits(obj)
            useful_size = length(obj.Header) + obj.SizeFieldLength + obj.PayloadLength;
            padding_size = numel(calc_padding_bits(useful_size, obj.ModulationOrder));
            FrameSizeBits = (useful_size + padding_size);
        end
        
        
        % Total frame size in Symbols
        function FrameSizeSymbols = get.FrameSizeSymbols(obj)
            FrameSizeSymbols = obj.FrameSizeBits * obj.Interpolation / log2(obj.ModulationOrder);
        end
        
        
        % Total frame size in Samples
        function FrameSizeSamples = get.FrameSizeSamples(obj)
            FrameSizeSamples = obj.FrameSizeSymbols * obj.Fs;
        end
        
    end
    
    methods (Access=private)
        
        % convert number of bits to number of samples
        % TODO: need to test this
        function nsamples = num_samples(obj, nbits)
            nsymbols = obj.num_symbols(nbits);
            nsamples = nsymbols * obj.Fs * obj.Interpolation;
        end
        
        % convert number of bits to number of symbols
        function nsymbols = num_symbols(obj, nbits)
            nsymbols = nbits / log2(obj.ModulationOrder);
        end
        
        % repeat the message and convert the message string to
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
        
        % used to test that the payload bits are generated correctly and
        % can be recovered to characters
        function test_payload_generation(obj)
            obj.Message = 'test message!➦';
            bits = obj.generate_payload_bits();
            % check that the length matches
            disp("bitlength:");
            disp(length(bits));
            disp("calclength:");
            disp(obj.PayloadLength);
            obj.BITS_PER_CHARACTER * obj.NumberOfMessages
            % perform the reverse
            bitrows = reshape(bits, obj.BITS_PER_CHARACTER, obj.NumberOfMessages * obj.MessageLength)
            %size(bitrows)
            bitrows'
            nums = bi2de(bitrows', 'left-msb')
            char(nums)
        end
        
    end
    
end