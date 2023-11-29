function SP = PR_QAM_Tx_Init
%   Copyright 2017 The MathWorks, Inc.

%% General simulation parameters
SP.Rsym = 0.2e6;             % Symbol rate in Hertz
SP.ModulationOrder = 4;      % QPSK alphabet size
SP.SizeFieldLength = 16; % length in bits of the frame's size field
SP.Interpolation = 7;        % Interpolation factor
SP.Decimation = 1;           % Decimation factor
SP.Tsym = 1/SP.Rsym;  % Symbol time in sec
SP.Fs   = SP.Rsym * SP.Interpolation; % Sample rate
%SP.SamplesPerSymbol = log2(SP.ModulationOrder) * SP.Interpolation;  % samples / symbol * samples / bit

%% Frame Specifications
% [BarkerCode*2 | 'Hello world 000\n' | 'Hello world 001\n' ...];
SP.BarkerCode      = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1];     % Bipolar Barker Code
SP.BarkerLength    = length(SP.BarkerCode);
SP.HeaderLength    = SP.BarkerLength * 2;                   % Duplicate 2 Barker codes to be as a header
SP.Message         = 'Hello world';
SP.MessageLength   = length(SP.Message) + 5;                % 'Hello world 000\n'...
SP.NumberOfMessage = 100;                                          % Number of messages in a frame
SP.PayloadLength   = SP.NumberOfMessage * SP.MessageLength * 7; % 7 bits per characters
SP.FrameSize       = (SP.HeaderLength + SP.PayloadLength) ...
    / log2(SP.ModulationOrder);                                    % Frame size in symbols
SP.FrameTime       = SP.Tsym*SP.FrameSize;

%% Tx parameters
SP.RolloffFactor     = 0.5;                                        % Rolloff Factor of Raised Cosine Filter
SP.ScramblerBase     = 2;
SP.ScramblerPolynomial           = [1 1 1 0 1];
SP.ScramblerInitialConditions    = [0 0 0 0];
SP.RaisedCosineFilterSpan = 10; % Filter span of Raised Cosine Tx Rx filters (in symbols)

%% Message generation
msgSet = zeros(100 * SP.MessageLength, 1); 
for msgCnt = 0 : SP.NumberOfMessage - 1
    msgSet(msgCnt * SP.MessageLength + (1 : SP.MessageLength)) = ...
        sprintf('%s %03d\n', SP.Message, msgCnt);
end
bits = de2bi(msgSet, 7, 'left-msb')';
SP.MessageBits = bits(:);

% Pluto transmitter parameters
SP.PlutoCenterFrequency      = 2.41e9;
SP.PlutoGain                 = 0;
SP.PlutoFrontEndSampleRate   = SP.Fs;
SP.PlutoFrameLength          = SP.Interpolation * SP.FrameSize;

% Simulation Parameters
SP.FrameTime = SP.PlutoFrameLength/SP.PlutoFrontEndSampleRate;
SP.StopTime  = 60;
