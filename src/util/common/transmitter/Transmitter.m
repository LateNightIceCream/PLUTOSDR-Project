classdef Transmitter
    %% Singleton transmitter object for Pluto
    
    properties (GetAccess=public, SetAccess=private)
        %% General parameters
        Rsym = 0.2e6;             % Symbol rate in Hertz
        ModulationOrder = 4;      % QPSK alphabet size
        Interpolation = 7;        % Interpolation factor
        Decimation = 1;           % Decimation factor
        
        %% Frame Specifications
        BarkerCode      = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1];     % Bipolar Barker Code
        NumberOfMessages = 100;                                          % Number of messages in a frame
        SizeFieldLength = 16;                                    % length in bits of the frame's size field
        Message = 'Hello Ŵorld'; % character vector, make sure to use SINGLE QUOTES
        % PayloadLength   = SP.NumberOfMessage * SP.MessageLength * 7; % 7 bits per characters
        %FrameSize       = (HeaderLength + SizeFieldLength + PayloadLength + numel(calc_padding_bits(HeaderLength + SizeFieldLength + PayloadLength, ModulationOrder))) ...
        %    / log2(ModulationOrder);                                    % Frame size in symbols
        %FrameTime       = Tsym*FrameSize;
    end
    
    properties (Dependent)
        Tsym;
        Fs;
        %% Frame related
        Header;
        MessageLength;
        PayloadLength;
        FrameSize;
    end
    
    properties (Access=private)
    end
    
    methods
        %% Class constructor
        function obj = Transmitter()
        end
        
        
        %% Initialize the Pluto Radio object
        function init_radio(obj, message)
            obj.Message = message;
            obj.generate_frame_bits(message)
        end
        
        
        %% Generate the message frame
        % This needs to be called before actually transmitting
        % since it will set the appropriate frame size
        function generate_frame_bits(obj, message)
            % initialize frame
            frame = [obj.Header]
            
            % Append payload size field to frame
            %msgsize = size(SP.MessageBits, 1);
            %size_bits = dec2bin(msgsize, SP.SizeFieldLength) == '1';  % == '1' converts string from dec2bin to digit array
            %frame = [frame, size_bits];
        end
        
        %% Setters
        
        % Message
        function obj = set.Message(obj, message)
            if ~ischar(message)
                error("Message should be character array. Remember to use single quotes instead of double quotes for literals.")
            end
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
            % 'Hello world 000\n'...
            MessageLength = strlength(obj.Message) + 5;
        end
        
        
        % Payload Length (bits)
        function PayloadLength = get.PayloadLength(obj)
            % 16 bits per character
            PayloadLength   = obj.NumberOfMessages * obj.MessageLength * 16;
        end
        
        
        % TODO
        % Total frame size including message (bits)
        function FrameSize = get.FrameSize(obj)
            %s = length(obj.Header) + obj.SizeFieldLength + 
            %FrameSize = (length(obj.Header) + obj.SizeFieldLength + PayloadLength + numel(calc_padding_bits(HeaderLength + SizeFieldLength + PayloadLength, ModulationOrder)))
            obj.generate_payload_bits()
            FrameSize = 1;
        end
        
        % function FrameSamples
        
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
            
            msgLength = obj.MessageLength
            numMessages = obj.NumberOfMessages
            %nums = str2num(obj.Message)
            disp(obj.Message)
            charnums = double(obj.Message)
            bits = de2bi(charnums, 16, 'left-msb')
            
            % TODO: reshape into 1D-list
            
            %fullmsg = strjoin(repmat(obj.Message, 1, numMessages), "");
            %bits = de2bi(fullmsg, 7, 'left-msb');
            %bits = bits(:);
        end
        
    end
    
end