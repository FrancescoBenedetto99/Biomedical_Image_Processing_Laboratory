clear;
clc; 
close all;

%% Caricamento dell'immagine dal file .mat

load('es3_2024.mat');
noisy_img = img2; % 1024x1024 uint8

figure;
imshow(noisy_img, []);
title('Immagine Originale');

%% Visualizzazione dell'istogramma dell'immagine
% Dall'istogramma si può notare che l'immagine presenta : picco in corrispondenza del valore 0 e 255, e una campana centrata in 52 (valore più frequente dell'immagine).

figure;
imhist(noisy_img);
title('Istogramma dell''immagine');

%% Visualizzazione del profilo di intensità della riga centrale dell'immagine
% Per visualizzare al meglio come varia l'intensità nell'immagine si è scelto di visualizzare il profilo di intensità della riga centrale, dato che è quella che copre un ampio range di valori.
% Si può notare che il segnale è rumoroso. Infatti presenta degli spike "positivi" (255) e "negativi" campoionati randomicamente. --> Rumore SALE E PEPE
% Per rafforzare questa tesi (e vedere che il rumore non è presente solo nella riga centrale) plotto anche l'intera immagine in uno spazio 3D (terza dimensione = intensità).

row = round(size(noisy_img, 1)/2);
intensity_profile = noisy_img(row, :);

[X, Y] = meshgrid(1:size(noisy_img, 2), 1:size(noisy_img, 1));

figure;
subplot(1, 2, 1);
plot(intensity_profile);
title('Profilo di intensità della riga centrale dell''immagine');
xlabel('Colonna');
ylabel('Intensità');

subplot(1, 2, 2);
surf(X, Y, noisy_img, 'EdgeColor', 'none');
title('Immagine Rumorosa in 3D');
xlabel('Colonne');
ylabel('Righe');
zlabel('Intensità');
colormap jet;

%% Applicazione filtro mediano all'immagine
% Essendo presente rumore di tipo sale e pepe, si è scelto di utilizzare un filtro mediano per la rimozione del rumore.
% Sono state provate diverse dimensioni della finestra del filtro mediano e per ognuna di esse sono stati calcolati il SNR e il PSNR.
% Infine è stata scelta la dimensione della finestra che ha portato a maggiori valori di SNR e PSNR.
% N.B. Per il calcolo delle metriche si è considerata l'immagine filtrata come stima del segnale pulito.


% Calcolo del SNR e del PSNR per diverse dimensioni della finestra del filtro mediano
for window_size = 3:12
    % Applico il filtro mediano con la finestra corrente
    img_filtered = medfilt2(noisy_img, [window_size window_size]);
    
    % Calcolo la potenza del segnale: uso l'immagine filtrata come stima del segnale
    signal_power = mean(img_filtered(:).^2);
    
    % Calcolo la potenza del rumore: differenza tra l'immagine rumorosa e quella filtrata
    noise_power = mean((noisy_img(:) - img_filtered(:)).^2);
    
    % Calcolo del rapporto SNR
    SNR = 10 * log10(signal_power / noise_power);
    
    % Calcolo dell'MSE tra l'immagine rumorosa e quella filtrata
    MSE = mean((noisy_img(:) - img_filtered(:)).^2);
    
    % Calcolo del PSNR
    PSNR = 10 * log10(255^2 / MSE);
    
    % Stampo i risultati per la finestra corrente
    disp(['Window Size: ', num2str(window_size), ' - SNR: ', num2str(SNR), ' dB, PSNR: ', num2str(PSNR), ' dB']);
end

% Scelgo la finestra con i risultati migliori
img_filtered = medfilt2(noisy_img, [3 3]);

%% Risultati post-filtro mediano 3x3
% Dopo aver applicato il filtro mediano 3x3 si può notare che il rumore di tipo sale e pepe è stato rimosso dall'immagine.
% Ciò è confermato anche dal profilo di intensità della riga centrale dell'immagine filtrata e dalla distribuzione 3D dell'immagine filtrata (che risultano piu "smooth")
% Una volta eliminato il rumore sale e pepe, si è più facile vedere come ci sia anche un'altra componente rumorosa.
% Quest'ultima è una sinusoide 2D che varia solo lungo x con ampiezza massima 26 (metà del picco dell'istogramma 52) e frequenza 4/1024 e fase 0. Visibile nella mesh dell'immagine post-filtro mediano.

figure;
subplot(1, 2, 1);
imshow(noisy_img, []);
title('Immagine Originale');

subplot(1, 2, 2);
imshow(img_filtered, []);
title('Immagine Filtrata con Filtro Mediano 3x3');

figure;
subplot(2, 2, 1);
plot(intensity_profile);
title('Profilo di intensità della riga centrale dell''immagine rumorosa');

subplot(2, 2, 2);
intensity_profile_filtered = img_filtered(row, :);
plot(intensity_profile_filtered);
title('Profilo di intensità della riga centrale dell''immagine post-filtro mediano');

subplot(2, 2, 3);
surf(X, Y, noisy_img, 'EdgeColor', 'none');
title('Immagine Rumorosa in 3D');

subplot(2, 2, 4);
surf(X, Y, img_filtered, 'EdgeColor', 'none');
title('Immagine post-filtro mediano in 3D');

%% Calcolo il parametro d con cui è stato aggiunto il rumore all'immagine (noisy_img = imnoise(img, 'salt & pepper', d))

% Conto i pixel neri (0) nell'immagine rumorosa
num_black_noisy = sum(noisy_img(:) == 0);

% Conto i pixel neri (0) nell'immagine filtrata
num_black_filtered = sum(img_filtered(:) == 0);

% Calcolo il numero di pixel "pepper" (neri aggiunti dal rumore)
num_pepper_pixels = num_black_noisy - num_black_filtered;

% Conto i pixel bianchi (255) nell'immagine rumorosa
num_white_noisy = sum(noisy_img(:) == 255);

% Conto i pixel bianchi (255) nell'immagine filtrata
num_white_filtered = sum(img_filtered(:) == 255);

% Calcolo il numero di pixel "salt" (bianchi aggiunti dal rumore)
num_salt_pixels = num_white_noisy - num_white_filtered;

% Calcolo il numero totale di pixel alterati (salt + pepper)
num_altered_pixels = num_salt_pixels + num_pepper_pixels;

% Calcolo la densità del rumore d
total_pixels = numel(noisy_img);  % Numero totale di pixel nell'immagine
d = num_altered_pixels / total_pixels;  % Densità del rumore

% Visualizzo i risultati e i due istogrammi
disp(['Numero di pixel "pepper" (neri): ', num2str(num_pepper_pixels)]);
disp(['Numero di pixel "salt" (bianchi): ', num2str(num_salt_pixels)]);
disp(['Densità totale del rumore d: ', num2str(d)]);

figure;
imhist(noisy_img);
hold on;
imhist(img_filtered);
title('Istogramma dell''immagine rumorosa e dell''immagine filtrata');
legend('Immagine Rumorosa', 'Immagine Filtrata');

%% Mappa del rumore sale e pepe
% Identifico i pixel di rumore "pepper" e "salt" come i pixel neri (0) e bianchi (255) nell'immagine rumorosa che sono stati cambiati dopo il filtraggio.

% Identifico i pixel di rumore "pepper" e "salt"
pepper_map = (noisy_img == 0) & (img_filtered ~= 0); % Pixel neri cambiati dopo il filtraggio
salt_map = (noisy_img == 255) & (img_filtered ~= 255); % Pixel bianchi cambiati dopo il filtraggio

% Visualizzo le mappe di distribuzione del rumore
figure;
subplot(1, 2, 1);
imshow(~pepper_map);
title('Distribuzione dei Pixel "Pepper"');
subplot(1, 2, 2);
imshow(salt_map);
title('Distribuzione dei Pixel "Salt"');

img_filtered = mat2gray(img_filtered); % Immagine filtrata nel range [0, 1] / double per fare la differenza con la sinusoide

%% Creo immagine sinusoidale 2d

amp = 26/255; % 26 (diviso 255 per normalizzare nel range) è la metà del picco nell'istogramma. 
N = 1024;
THETA = 0;
FREQ = 4/1024; % 4 cicli di sinusoide in 1024 pixel
FI = 0;

WA=immcos(amp,N,THETA,FREQ,FI);
WA = WA + min(min(WA)); % Aggiungo (il minimo di WA) un offset per avere valori positivi che vadano da 0 a 52 (come nella sinusoide rumorosa)

%% Differeza tra immagine sinusoidale e immagine filtrata
% La sinusoide è un rumore di tipo additivo, quindi sottraggo la sinusoide all'immagine filtrata per ottenere l'immagine pulita.

diff = imsubtract(img_filtered, WA);
diff = mat2gray(diff);

figure
subplot(1,3,1)
imshow(WA,[])
title('Immagine sinusoidale 2D')
subplot(1,3,2)
imshow(img_filtered)
title('Immagine filtrata')
subplot(1,3,3)
imshow(diff)
title('Differenza tra immagine sinusoidale e immagine filtrata')

%% Visualizzazione dell'istogramma della immagine post-differenza e enhancement dell'immagine
% Come si può notare il picco in corrispondenza del valore 52 è stato rimosso.
% Applico imadjust per migliorare l'istogramma dell'immagine post-differenza.

diff = imadjust(diff, stretchlim(diff), [0 1]);

figure
imhist(diff)
title('Istogramma immagine post-differenza e enhancement')

%% Visualizzo il risultato finale
% Come si può notare l'immagine finale non presenta più la sinusoide 2D e il rumore sale e pepe, rendendo l'immagine in 3D più "smooth".

figure
subplot(3,1,1)
imshow(diff, [])
title('Immagine finale')
subplot(3,1,2)
mesh(diff)
title('Immagine finale in 3D')
subplot(3,1,3)
imhist(diff)
title('Istogramma immagine finale')

figure
imshow(diff, [])
title('Immagine finale')