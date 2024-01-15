classdef RadioBase < handle
    properties (Constant)
        BITS_PER_CHARACTER = 16; % do not change this
        
        %% General parameters
        Rsym = 0.2e6;             % Symbol rate in Hertz
        ModulationOrder = 4;      % QPSK alphabet size
        Interpolation = 7;        % Interpolation factor, not necessarily "common", but here it is.
        Decimation = 7;           % Decimation factor
        
        %% Frame Specifications
        BarkerCode = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1]; % Bipolar Barker Code
        SizeFieldLength = 16;
        
        %% Pluto transmitter parameters
        CenterFrequency = 2.41e9;
        
        %% Tx Parameters
        RolloffFactor = 0.5; % Rolloff Factor of Raised Cosine Filter
        ScramblerBase = 2;
        ScramblerPolynomial = [1 1 1 0 1];
        ScramblerInitialConditions = [0 0 0 0];
        RaisedCosineFilterSpan = 10; % Filter span of Raised Cosine Tx Rx filters (in symbols)
        
        %% Frequqency Offset Parameters
        FRef = 80e3; % frequency used for offset calibration
    end
    
    properties(Constant, Access=protected)
        ERR_RADIO_NOT_INIT = "Radio object not initialized. Call init_radio(...) first.";
    end
    
    properties(Dependent)
        Tsym;
        Fs;
        Header;
    end
    
    properties (GetAccess=public, SetAccess=protected)
        PlutoAddress = '';
        PlutoGain = 0;
        Symbols = []; % received or transmitted symbols
    end
    
    properties (Access=protected)
        Radio; % The radio object
    end
    
    methods
        %% Getters
        
        % Symbol duration (s)
        function Tsym = get.Tsym(obj)
            Tsym = 1/Common.Rsym;
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
        
    end
end