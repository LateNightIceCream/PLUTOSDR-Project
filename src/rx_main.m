

receiver = Receiver();
receiver.init_radio('usb:0');

waitforbuttonpress;
receiver.receive_frequency_offset();

waitforbuttonpress;
receiver.receive(3.0, false);