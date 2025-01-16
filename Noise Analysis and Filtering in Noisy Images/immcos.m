function A=immcos(amp,N,THETA,FREQ,FI)
    % amp = amplitude
    % N = A dimension (squared matrix)
    % THETA = tilt cosinusoid with respect to x axis in radiants
    % FREQ = spatial frequency in cycles/samples (1/FREQ=samples/cycles)
    % FI = cosinusoid phase (e.g. : 0=cos; -pi/2=sin)
    
    
    WX=2*pi*cos(THETA)*FREQ ;% pulse along x axis
    WY=2*pi*sin(THETA)*FREQ ;% pulse along y axis
    for IX=1:N,
        for IY=1:N,
            ICOL=IX; % column index - x coord.
            IRIGA=IY; % row index - y coord.
            A(IRIGA,ICOL)=amp*cos(WX*IX+WY*IY+FI);
        end
    end
    