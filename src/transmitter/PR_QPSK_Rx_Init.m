function SP = PR_QPSK_Rx_Init
%   Copyright 2017 The MathWorks, Inc.

%% General simulation parameters
SP.Rsym = 0.2e6;             % Symbol rate in Hertz
SP.ModulationOrder = 4;      % QPSK alphabet size
SP.Interpolation = 2;        % Interpolation factor
SP.Decimation = 1;           % Decimation factor
SP.Tsym = 1/SP.Rsym;  % Symbol time in sec
SP.Fs   = SP.Rsym * SP.Interpolation; % Sample rate

%% Frame Specifications
% [BarkerCode*2 | 'Hello world 000\n' | 'Hello world 001\n' ... | 'Hello world 099\n'];
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

%% Rx parameters
SP.RolloffFactor     = 0.5;                      % Rolloff Factor of Raised Cosine Filter
SP.ScramblerBase     = 2;
SP.ScramblerPolynomial           = [1 1 1 0 1];
SP.ScramblerInitialConditions    = [0 0 0 0];
SP.RaisedCosineFilterSpan = 10;                  % Filter span of Raised Cosine Tx Rx filters (in symbols)
SP.DesiredPower                  = 2;            % AGC desired output power (in watts)
SP.AveragingLength               = 50;           % AGC averaging length
SP.MaxPowerGain                  = 60;           % AGC maximum output power gain
SP.MaximumFrequencyOffset        = 6e3;
% Look into model for details for details of PLL parameter choice. 
% Refer equation 7.30 of "Digital Communications - A Discrete-Time Approach" by Michael Rice.
K = 1;
A = 1/sqrt(2);
SP.PhaseRecoveryLoopBandwidth    = 0.01;         % Normalized loop bandwidth for fine frequency compensation
SP.PhaseRecoveryDampingFactor    = 1;            % Damping Factor for fine frequency compensation
SP.TimingRecoveryLoopBandwidth   = 0.01;         % Normalized loop bandwidth for timing recovery
SP.TimingRecoveryDampingFactor   = 1;            % Damping Factor for timing recovery
% K_p for Timing Recovery PLL, determined by 2KA^2*2.7 (for binary PAM),
% QPSK could be treated as two individual binary PAM,
% 2.7 is for raised cosine filter with roll-off factor 0.5
SP.TimingErrorDetectorGain       = 2.7*2*K*A^2+2.7*2*K*A^2;
SP.PreambleDetectorThreshold     = 0.8;

%% Message generation and BER calculation parameters
msgSet = zeros(100 * SP.MessageLength, 1);
for msgCnt = 0 : 99
    msgSet(msgCnt * SP.MessageLength + (1 : SP.MessageLength)) = ...
        sprintf('%s %03d\n', SP.Message, msgCnt);
end
bits = de2bi(msgSet, 7, 'left-msb')';
SP.MessageBits = bits(:);

% For BER calculation masks
SP.BerMask = zeros(SP.NumberOfMessage * length(SP.Message) * 7, 1);
for i = 1 : SP.NumberOfMessage
    SP.BerMask( (i-1) * length(SP.Message) * 7 + ( 1: length(SP.Message) * 7) ) = ...
        (i-1) * SP.MessageLength * 7 + (1: length(SP.Message) * 7);
end
% Pluto receiver parameters
SP.PlutoCenterFrequency      = 1000e6;
SP.PlutoGain                 = 30;
SP.PlutoFrontEndSampleRate   = SP.Fs;
SP.PlutoFrameLength          = SP.Interpolation * SP.FrameSize;

% Experiment parameters
SP.PlutoFrameTime = SP.PlutoFrameLength / SP.PlutoFrontEndSampleRate;
SP.StopTime = 10;
