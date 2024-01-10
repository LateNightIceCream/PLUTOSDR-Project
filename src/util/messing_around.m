receiver = Receiver();
%receiver.init_radio('usb:0');
%receiver.test_blep()


load('C:\Users\st181028\Desktop\PLUTOSDR-Project\src\util\recordings\rx_capture_2.mat');

% header symbols
% => same number of samples as received signal (Fs * Interpolation)

length(receiver.Header)

headerSyms = qammod(receiver.Header', receiver.ModulationOrder, ...
                         InputType='bit', ...
                         UnitAveragePower=true, ...
                         PlotConstellation=true)
                     
tx_filter = comm.RaisedCosineTransmitFilter( ...
                        'RolloffFactor', receiver.RolloffFactor, ...
                        'FilterSpanInSymbols', receiver.RaisedCosineFilterSpan, ...
                        'OutputSamplesPerSymbol', receiver.Interpolation);
          
headerSamps = tx_filter(headerSyms);


rx_filter = comm.RaisedCosineReceiveFilter(...
                        'RolloffFactor', receiver.RolloffFactor, ...
                        'FilterSpanInSymbols', receiver.RaisedCosineFilterSpan, ...
                        'InputSamplesPerSymbol', receiver.Interpolation, ...
                        'DecimationFactor', 1);

data = rx_filter(data);

headerSamps2 = headerSamps;

size(data)
size(headerSamps2)

%data = data/max(abs(data));
%headerSamps2 = headerSamps2/max(abs(headerSamps2));

XY = xcorr(abs(data), abs(headerSamps2));

figure()
sp(1)=subplot(3,1,1);
plot(abs(headerSamps2));
sp(2)=subplot(3,1,2);
plot(abs(data));
sp(3)=subplot(3,1,3);
plot(abs(XY));

size(XY)