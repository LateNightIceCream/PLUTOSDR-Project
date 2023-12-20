function SP = QAMBitsGenerator(SP)
    
    % Barker code -> unipolar
    % Scramble Message
    % Header = BarkerBits(2x) + MsgBits
    
    %% Generate unipolar Barker Code and duplicate it as header
    ubc = ((SP.BarkerCode + 1) / 2)';
    header = (repmat(ubc,2,1))';
    frame = [header];
    
    %% Append payload size field to frame
    msgsize = size(SP.MessageBits, 1);
    size_bits = dec2bin(msgsize, SP.SizeFieldLength) == '1';  % == '1' converts string from dec2bin to digit array
    frame = [frame, size_bits];
    
    %% Scramble the message bits
    scrambler = comm.Scrambler( ...
                SP.ScramblerBase, ...
                SP.ScramblerPolynomial, ...
                SP.ScramblerInitialConditions);
    
    scrambledMsgBits = scrambler(SP.MessageBits);
    
    %% Zero-Padding for the payload
    % The padding goes after the message
    % When using binary inputs, the number of rows in the input must be 
    % an integer multiple of the number of bits per symbol.
    %n_pad_bits = rem(size(scrambledMsgBits, 1) + size(frame', 1), log2(SP.ModulationOrder));
    %pad_bits = zeros(n_pad_bits, 1)';
    pad_bits = calc_padding_bits(size(scrambledMsgBits, 1) + size(frame', 1), SP.ModulationOrder);
    frame = [frame, scrambledMsgBits', pad_bits];
    
    %% Modulation (generate symbols)fiesl
    SP.qam_symbols = qammod(frame', SP.ModulationOrder, ...
                         InputType='bit', ...
                         UnitAveragePower=true, ...
                         PlotConstellation=true);
                     
    tx_filter = comm.RaisedCosineTransmitFilter( ...
                'RolloffFactor', SP.RolloffFactor, ...
                'FilterSpanInSymbols', SP.RaisedCosineFilterSpan, ...
                'OutputSamplesPerSymbol', SP.Interpolation);
            
    SP.tx_symbols = tx_filter(SP.qam_symbols);
    SP.F
    
end
