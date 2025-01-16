% Esercizio 2

clear
close all
clc

%% Step 1: Caricamento dell'immagine e visualizzazione
% Caricare l'immagine
img = imread('h2_PET_image.tif');
[M, N] = size(img); % 582x375 uint8
img = im2double(img); % Conversione da uint8 in double

%  Visualizzare l'immagine
figure
imshow(img), title('Immagine originale');

%% Trasformazione logaritmica 
% Separazione delle componenti lighting (basse frequenze) e reflectance (alte frequenze)

log_img = log(1 + img); % +1 per evitare log(0) = -Inf (Nell'immagine originale ci sono valori nulli)

%% Trasformata di Fourier bidimensionale all'immagine logaritmica

F = fft2(log_img);
F_shift = fftshift(F); % Shift del centro di Fourier
F_mag = abs(F_shift); % Magnitudine

% Creazione della griglia di coordinate nello spazio delle frequenze (per visualizzare la mesh della trasformata e calcolare le distanze dal centro)
[u, v] = meshgrid(1:N, 1:M); 
% Centrare le coordinate
u = u - ceil(N/2);
v = v - ceil(M/2);

%% Costruzione del filtro H(u,v)

A = 0.25;
B = 2;
C = 2;
D0 = min(M, N) / 8;
D = sqrt(u.^2 + v.^2); % Distanza dal centro
H = A + C ./ (1 + (D0 ./ D) .^B); % Filtro H(u,v)

% Visualizzazione del filtro
% Come si può vedere, il filtro attenua (<1) le basse frequenze (lighting) e amplifica (>1) le alte frequenze (reflectance) come da definizione di filtro omomorfico
figure
subplot(1,2,1), imshow(H, []), title('Filtro H(u,v) (Proiezione 2D)'), xlabel('x'), ylabel('y');
subplot(1,2,2), mesh(u, v, H), title('Filtro H(u,v)'), xlabel('u'), ylabel('v'), zlabel('H(u,v)'); 

%% Applicazione del filtro

G_shift = F_shift .* H;
G_mag = abs(G_shift); % Magnitudine

% Visualizzazione della trasformata di Fourier pre-filtro e post-filtro
% Log della magnitudine per visualizzare meglio la differenza tra le frequenze 
figure
subplot(2,2,1),mesh(u, v, F_mag), title('Magnitude Trasformata di Fourier Pre-filtro'), xlabel('u'), ylabel('v');
subplot(2,2,2),mesh(u, v, log(1 + F_mag)), title('Log Magnitude Trasformata di Fourier Pre-filtro'), xlabel('u'), ylabel('v'); 

subplot(2,2,3), mesh(u, v, G_mag), title('Magnitude Trasformata di Fourier Post-filtro'), xlabel('u'), ylabel('v');
subplot(2,2,4), mesh(u, v, log(1 + G_mag)), title('Log Magnitude Trasformata di Fourier Post-filtro'), xlabel('u'), ylabel('v');

%% Trasformata inversa di Fourier

G = ifftshift(G_shift);     
g = real(ifft2(G)); 

%% Trasformazione inversa logaritmica   
% Trasformazione inversa logaritmica per ottenere l'immagine filtrata finale

img_finale = exp(g) - 1; % -1 per annullare il +1 fatto in precedenza

% Visualizzazione dell'immagine a tutti i passaggi (originale, logaritmica, fft, fft filtrata, inversa fft, inversa logaritmica = finale)
figure
subplot(2,3,1), imshow(img), title('Immagine originale');
subplot(2,3,2), imshow(log_img, []), title('Trasformazione logaritmica');
subplot(2,3,3), imshow(log(1 + F_mag), []), title('Log Magnitude Trasformata di Fourier Pre-filtro');
subplot(2,3,4), imshow(log(1 + G_mag), []), title('Log Magnitude Trasformata di Fourier Post-filtro');
subplot(2,3,5), imshow(g, []), title('Inversa Trasformata di Fourier');
subplot(2,3,6), imshow(img_finale,[]), title('Immagine filtrata finale');

% Visualizzazione dell'immagine iniziale e finale
figure
subplot(1,2,1), imshow(img), title('Immagine originale');
subplot(1,2,2), imshow(img_finale, []), title('Immagine filtrata finale');