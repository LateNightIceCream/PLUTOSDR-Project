function recording_rx(rx)


    %% Receive and Visualize Signal
    
    received_signal = rx();
    
    %save("rx_signal_1", receivedSig)
    
    plot(abs(received_signal));
    

end