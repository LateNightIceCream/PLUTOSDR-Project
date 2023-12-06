function runPR_QAM_Tx_TEST(SP_Tx, radio)

% this includes an injection of the radio structure instead of
% instantiating it here

SP_Tx = QAMBitsGenerator(SP_Tx); % populates SP.tx_symbols

%radio.SamplesPerFrame = SP_Tx.PlutoFrameLength;
radio.Gain = SP_Tx.PlutoGain;

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
