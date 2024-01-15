close all;

receiver = Receiver();
%receiver.init_radio('usb:0');
%receiver.test_blep()


load('C:\Users\st181028\Desktop\PLUTOSDR-Project\src\recordings\rx_capture_2.mat');

% reduce the data for testing
start_idx = 1500002+525065;
end_idx = 1500002 + 665194 + 3;
data = data(start_idx:end_idx);

rx_filter = comm.RaisedCosineReceiveFilter(...
                        'RolloffFactor', receiver.RolloffFactor, ...
                        'FilterSpanInSymbols', receiver.RaisedCosineFilterSpan, ...
                        'InputSamplesPerSymbol', receiver.SamplesPerSymbol, ...
                        'DecimationFactor', 7);

data = rx_filter(data);

% crop the data manually

plot(abs(data));

constplot(data);
reimplot(data);


powered_signal = data.^receiver.ModulationOrder;
Y = fftshift(fft(powered_signal));
L = length(Y);
freq = receiver.Fs/L*(-L/2:L/2-1);

[M, I] = max(abs(Y));

offset_frequency = freq(I) / receiver.ModulationOrder;

sprintf("offset frequency is: %f", offset_frequency)

plot(freq,abs(Y));

Ts = 1/receiver.Fs;
t = linspace(0, Ts * L, L);

size(t)
size(powered_signal)

% fine frequency offset correction might be needed.
% but we're just cheating here by adding 10.0 :)
offset_frequency = offset_frequency + 10.0;

samples = data .* exp(-1i * 2 * pi * offset_frequency * t') .* exp(1i * (pi/4 + pi/2)); % cheating :)

%constplot(samples)
%reimplot(samples)

%samples = data;
sps = receiver.SamplesPerSymbol;
mu = 0.2; % initial estimate of phase of sample
out = zeros(length(samples) + 10, 1);
out_rail = zeros(length(samples) + 10, 1); % stores values, each iteration we need the previous 2 values plus current value
i_in = 1; % input samples index
i_out = 3; % output index (let first two outputs be 0)
while i_out < length(samples) && i_in+16 < length(samples)
    out(i_out) = samples(i_in + floor(mu)); % grab what we think is the "best" sample
    %out[i_out] = samples_interpolated[i_in*16 + int(mu*16)]
    out_rail(i_out) = (real(out(i_out)) > 0) + 1i*(imag(out(i_out)) > 0);
    x = (out_rail(i_out) - out_rail(i_out-2)) * conj(out(i_out-1));
    y = (out(i_out) - out(i_out-2)) * conj(out_rail(i_out-1));
    mm_val = real(y - x);
    mu = mu + sps + 0.3*mm_val;
    i_in = i_in + floor(mu); % round down to nearest int since we are using it as an index
    mu = mu - floor(mu); % remove the integer part of mu
    i_out = i_out + 1; % increment output index
end
out = out(3:i_out-1); % remove the first two, and anything after i_out (that was never filled out)
samples = out; % only include this line if you want to connect this code snippet with the Costas Loop later o


constplot(samples);


data_bits = qamdemod(data, receiver.ModulationOrder, 'OutputType', 'bit');

header_bits = receiver.Header;

figure()
sp(1)=subplot(3,1,1);
stem(header_bits);
sp(2)=subplot(3,1,2);
stem( data_bits(1:100));
sp(3)=subplot(3,1,3);
plot(xcorr(data_bits, header_bits'));


function constplot(x)
    figure()
    scatter(real(x), imag(x));
end

function reimplot(x)
    figure()
    hold on;
    plot(real(x));
    plot(imag(x));
    hold off;
end