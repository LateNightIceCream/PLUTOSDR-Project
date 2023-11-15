function runPR_QAM_Tx(SP_Tx)
%#codegen

%   Copyright 2017 The MathWorks, Inc.

%persistent hTx radio
%if isempty(hTx)
    % Initialize the components
    % Create and configure the transmitter System object
    %hTx = QPSKTransmitter(...
    %    'UpsamplingFactor',             SP_Tx.Interpolation, ...
    %    'RolloffFactor',                SP_Tx.RolloffFactor, ...
    %    'RaisedCosineFilterSpan',       SP_Tx.RaisedCosineFilterSpan, ...
    %    'MessageBits',                  SP_Tx.MessageBitst, ...
    %    'MessageLength',                SP_Tx.MessageLength, ...
    %    'NumberOfMessage',              SP_Tx.NumberOfMessage, ...
    %    'ScramblerBase',                SP_Tx.ScramblerBase, ...
    %    'ScramblerPolynomial',          SP_Tx.ScramblerPolynomial, ...
    %    'ScramblerInitialConditions',   SP_Tx.ScramblerInitialConditions);
    
    % Create and configure the Pluto System object.
    radio = sdrtx('Pluto');
    radio.RadioID               = SP_Tx.Address;
    radio.CenterFrequency       = SP_Tx.PlutoCenterFrequency;
    radio.BasebandSampleRate    = SP_Tx.PlutoFrontEndSampleRate;
    radio.SamplesPerFrame       = SP_Tx.PlutoFrameLength;
    radio.Gain                  = SP_Tx.PlutoGain;
%end

currentTime = 0;
disp('Transmission has started')
    
    % Transmission Process
while currentTime < SP_Tx.StopTime
    % Bit generation, modulation and transmission filtering
    %data = step(hTx);

    % Data transmission
    step(radio, SP_Tx.tx_symbols);

    % Update simulation time
    currentTime = currentTime+SP_Tx.FrameTime;
end

if currentTime ~= 0
    disp('Transmission has ended')
end    

release(radio);

end
