% Calculates an array of padding bits needed to pad the message
% with the **bit** size message_size, given the modulation order 
% modulation_order
function pad_bits = calc_padding_bits(message_size, modulation_order)
    % message_size should include header + payload
    bits_per_symbol = log2(modulation_order);
    remainder = rem(message_size, bits_per_symbol);
    if (remainder == 0)
        n_pad_bits = 0;
    else
        n_pad_bits = bits_per_symbol - remainder;
    end
    pad_bits = zeros(n_pad_bits, 1)';
end