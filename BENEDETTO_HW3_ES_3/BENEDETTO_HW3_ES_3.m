%% PUNTO A: Calcolo dell'aspect ratio del blister

%% Sezione 1A: Caricamento e Preprocessing dell'immagine
% Dopo aver analizzato i vari spazi di colore, tramite colorThresholder, ho notato che la trasformazione in YCbCr permette di separare facilmente il colore verde dal blister.
% Si può subito notare che la forma del blister non è rettangolare, ma trapezoidale. Questo è dovuto alla prospettiva con cui è stata scattata la foto.
% Per questo motivo, è necessario raddrizzare (warping) l'immagine per ottenere un'immagine con il blister allineato con gli assi dell'immagine.

close all
clear 
clc

% Carica l'immagine
img = imread('blister.jpg');

% Dimensioni dell'immagine
img_height = size(img, 1); % Altezza 
img_width = size(img, 2);  % Larghezza 

% Trasformo l'immagine in spazio YCbCr per facilitare la separazione dei canali
img_ycbcr = rgb2ycbcr(img);

% Estraggo il canale cr e applico una soglia a 125 per binarizzare
img_cr = img_ycbcr(:,:,3);
img_cr = img_cr > 125; 

% Visualizza il risultato del thresholding
figure;
imshow(img_cr);
title('Maschera del blister');

%% Sezione 2A: Rilevamento dei bordi con Canny e dilatazione dell'immagine
% Per raddrizzare l'immagine, è necessario individuare le linee principali dell'oggetto, perciò tramite Canny ho rilevato i bordi del blister che sono stati successivamente dilatati per enfatizzarli.
% Dopo aver rilevato i bordi, ho applicato la trasformata di Hough per trovare le 4 linee principali dell'oggetto.
% Nonostante i picchi della trasformata siano stati impotati a 4, sono state trovate 6 linee, di cui 2 molto corte e inutili (in basso a sinistra sul bordo)
% Per questo motivo, ho selezionato le 4 linee più lunghe per garantire che vengano considerati i bordi più importanti dell'oggetto.

% Applico l'algoritmo di Canny per rilevare i bordi
contour = edge(img_cr, 'Canny');

% Dilatazione dell'immagine per enfatizzare i bordi rilevati
se = strel('disk', 5); 
processed_img = imdilate(contour, se);

% Calcolo la trasformata di Hough per rilevare le linee nell'immagine
[H, theta, rho] = hough(processed_img);
peaks = houghpeaks(H, 4); % Trova i 4 picchi principali (le 4 linee principali)
lines = houghlines(processed_img, theta, rho, peaks);


% Calcolo la lunghezza di ciascuna linea usando la distanza euclidea
line_lengths = zeros(1, length(lines));
for i = 1:length(lines)
    point1 = lines(i).point1;
    point2 = lines(i).point2;
    line_lengths(i) = sqrt((point1(1) - point2(1))^2 + (point1(2) - point2(2))^2);
end

% Ordino le linee in base alla lunghezza in ordine decrescente
[~, sorted_indices] = sort(line_lengths, 'descend');

% Seleziono le 4 linee più lunghe (le principali)
lines = lines(sorted_indices(1:4));

% Visualizzo le 4 linee più lunghe
figure;
imshow(img);
hold on;
for i = 1:length(lines)
    xy = [lines(i).point1; lines(i).point2];
    plot(xy(:,1), xy(:,2), 'LineWidth', 2, 'Color', 'red');
end
title('Linee principali del blister');

%% Sezione 4A: Rette e punti di intersezione
% Calcolo le equazioni delle rette che giacciono sulle linee principali e trovo i punti di intersezione tra di esse. 
% Questi punti di intersezione definiscono i vertici del contorno del blister e servono per avere i punti di riferimento per il successivo raddrizzamento dell'immagine.
% Dopo aver calcolato tali punti, vengono filtrati per assicurarsi che siano all'interno dei limiti dell'immagine (eliminando così i 2 vanishing points).
% Infine ordino i punti di intersezione in senso orario in modo tale da poter mappare coretteamente i vertici del blister.
% N.B: essendo presenti 2 vanishing points significa che le due coppie di rette non sono parallele, ma si intersecano nei suddetti punti.

% Calcolo i coefficienti (pendenza e intercetta) delle 4 rette
coeffs = zeros(4, 2); % [m, b] per ogni retta
for i = 1:4
    point1 = lines(i).point1;
    point2 = lines(i).point2;
    coeffs(i, 1) = (point2(2) - point1(2)) / (point2(1) - point1(1)); % pendenza m
    coeffs(i, 2) = point1(2) - coeffs(i, 1) * point1(1); % intercetta b
end

% Funzione per calcolare i punti di intersezione tra rette, filtrare quelli validi e ordinarli in senso orario (in base all'angolo rispetto al baricentro)
function [valid_intersections_clockwise] = intersections(coeffs, img_width, img_height, img)
    
    % Calcolo i punti di intersezione
    intersections = [];
    for i = 1:4
        for j = i+1:4
            m1 = coeffs(i, 1); b1 = coeffs(i, 2);
            m2 = coeffs(j, 1); b2 = coeffs(j, 2);
            x = (b2 - b1) / (m1 - m2);
            y = m1 * x + b1;
            intersections = [intersections; x, y]; % Aggiungi il punto di intersezione alla lista concatenando verticalmente
            
        end
    end

    % Filtro i punti interni all'immagine
    valid_intersections = intersections(intersections(:, 1) >= 1 & intersections(:, 1) <= img_width & intersections(:, 2) >= 1 & intersections(:, 2) <= img_height, :);

    % Calcolo il baricentro e ordino i punti in senso orario (per sapere come mappare i vertici del blister)
    centroid = mean(valid_intersections, 1);
    angles = atan2(valid_intersections(:, 2) - centroid(2), valid_intersections(:, 1) - centroid(1));
    [~, sortIdx] = sort(angles, 'ascend');
    valid_intersections_clockwise = valid_intersections(sortIdx, :);

    % Plot dell'immagine e delle rette
    figure; imshow(img); hold on;
    for i = 1:4
        x = 1:img_width; % Estendo la retta su tutta la larghezza dell'immagine
        y = coeffs(i, 1) * x + coeffs(i, 2); % Calcolo le coordinate y
        plot(x, y, 'LineWidth', 2, 'Color', 'red');
    end

    % Plot dei punti di intersezione
    markers = {'ro', 'bs', 'g^', 'md'}; % Marker differenti per ogni punto
    for i = 1:size(valid_intersections_clockwise, 1)
        plot(valid_intersections_clockwise(i, 1), valid_intersections_clockwise(i, 2), ...
             markers{i}, 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', sprintf('Point %d', i));
    end
    title('Rette e punti di intersezione');
    legend show; hold off;
end

% Applico la funzione per calcolare i punti di intersezione
[valid_intersections_clockwise] = intersections(coeffs, img_width, img_height, img);

%% Sezione 5A: Rescaling del trapezio
% Per effettuare il warping di un'immagine contornata da un trapezio, si è pensato prima di ridimensionare il trapezio stesso. Se il warping venisse eseguito direttamente 
% verso un rettangolo, l'aspect ratio dell'oggetto sarebbe distorto, assumendo come valore le proporzioni del rettangolo di destinazione e alterando la forma reale dell'oggetto.
% (Sarebbe come scegliere a priori l'aspect ratio del blister)
% Ridimensionando il trapezio (scaling),invece, si include l'oggetto e una piccola porzione dello sfondo, preservando il rapporto di proporzioni originale. Questo garantisce che, 
% durante la trasformazione proiettiva, l'oggetto mantenga la sua geometria reale, evitando distorsioni indesiderate.

% Calcolo la distanza tra i punti 1 e 2 (lato superiore del trapezio)
d_12 = sqrt((valid_intersections_clockwise(1,1) - valid_intersections_clockwise(2,1))^2 + (valid_intersections_clockwise(1,2) - valid_intersections_clockwise(2,2))^2);

% Coefficiente di rescaling 
scalingFactor = 1.2;

% Applico il rescaling al trapezio
trapezioRescaled = (valid_intersections_clockwise - d_12) * scalingFactor + d_12;

% Plotto il trapezio
figure;
imshow(img);
hold on;
plot([valid_intersections_clockwise(1,1), valid_intersections_clockwise(2,1)], [valid_intersections_clockwise(1,2), valid_intersections_clockwise(2,2)], 'LineWidth', 2, 'Color', 'red');
plot([valid_intersections_clockwise(2,1), valid_intersections_clockwise(3,1)], [valid_intersections_clockwise(2,2), valid_intersections_clockwise(3,2)], 'LineWidth', 2, 'Color', 'red');
plot([valid_intersections_clockwise(3,1), valid_intersections_clockwise(4,1)], [valid_intersections_clockwise(3,2), valid_intersections_clockwise(4,2)], 'LineWidth', 2, 'Color', 'red');
plot([valid_intersections_clockwise(4,1), valid_intersections_clockwise(1,1)], [valid_intersections_clockwise(4,2), valid_intersections_clockwise(1,2)], 'LineWidth', 2, 'Color', 'red');
title('Trapezio');
plot([trapezioRescaled(1,1), trapezioRescaled(2,1)], [trapezioRescaled(1,2), trapezioRescaled(2,2)], 'LineWidth', 2, 'Color', 'b');
plot([trapezioRescaled(2,1), trapezioRescaled(3,1)], [trapezioRescaled(2,2), trapezioRescaled(3,2)], 'LineWidth', 2, 'Color', 'b');
plot([trapezioRescaled(3,1), trapezioRescaled(4,1)], [trapezioRescaled(3,2), trapezioRescaled(4,2)], 'LineWidth', 2, 'Color', 'b');
plot([trapezioRescaled(4,1), trapezioRescaled(1,1)], [trapezioRescaled(4,2), trapezioRescaled(1,2)], 'LineWidth', 2, 'Color', 'b');
title('Trapezio rescaled');

%% Sezione 6A: Nuove rette e nuovi punti di intersezione
% Calcolo le nuove rette che passano per i punti del trapezio rescaled e trovo i nuovi punti di intersezione.
% Inoltre, imposto la pendenza a 0 per le due rette con pendenza minore (le due orizzontali). In questo modo quando andrò a warpare,
% mapperò le due rette orizzontali con gli assi orizzontali dell'immagine. (Non facendo cosi, il blister rimarrebe ruotato dopo il warping)
% Il risultato sarà un trapezio con lati obliqui paralleli a quelli obliqui del blister, e lati orizzontali paralleli agli assi orizzontali dell'immagine.
% N.B. In questo caso i due lati obliqui sono perfettamente specchiati (coefficients con pendenza opposta), nel caso in cui fossero stati diversi, sarebbe stato necessario
% imporre che la pendenza di uno fosse l'opposto dell'altro.

% Traccio le rette che passano per i punti del trapezio rescaled
coeffs = zeros(4, 2); % [m, b] per ogni retta
for i = 1:4
    point1 = trapezioRescaled(i,:);
    point2 = trapezioRescaled(mod(i,4)+1,:);
    coeffs(i, 1) = (point2(2) - point1(2)) / (point2(1) - point1(1)); % pendenza m
    coeffs(i, 2) = point1(2) - coeffs(i, 1) * point1(1); % intercetta b
end

% Trovo i due coefficienti di pendenza più bassi
[~, idx] = sort(abs(coeffs(:,1))); % Ordino per valore assoluto della pendenza
coeffs_low_idx = idx(1:2); % Indici delle due pendenze minori

% Imposto m = 0 per questi due coefficienti
coeffs(coeffs_low_idx, 1) = 0;

% Applico la funzione per calcolare i punti di intersezione
[valid_intersections_clockwise] = intersections(coeffs, img_width, img_height, img);

%% Sezione 7A: Warping dell'immagine e confronto con con bounding box rettangolare
% Applico la trasformazione proiettiva (warping) all'immagine binarizzata del blister per raddrizzarla.
% Si può notare come il blister è stato allineato con gli assi dell'immagine, mantenendo la sua forma originale.
% Per verificare il risultato, ho confrontato il nuovo contorno del blister con la bounding box rettangolare di tale oggetto (la bounding box ha le linee parallele agli dell'immagine).
% Il lato sinistro è leggermente inclintao rispetto all'asse verticale, essendo comunque minimo, si può considerare come un errore di approssimazione.
% Tale errore potrebbe essere dovuto al fatto che il blister ha i bordi negli angoli leggeremente rialzati rispetto al resto della superficie e quindi la trasformazione proiettiva non è perfetta


% Definisco i punti di destinazione per il warping (rettangolo con le stesse dimensioni dell'immagine originale)
dst_points = [0, 0; img_width, 0; img_width, img_height; 0, img_height];

% Calcolo la trasformazione geometrica (trasformazione proiettiva)
tform = fitgeotrans(valid_intersections_clockwise, dst_points, 'projective');

% Applico la trasformazione ai contorni del blister e all'immagine orginale
% 'OutputView' per visualizzare l'immagine raddrizzata con le stesse dimensioni dell'immagine originale
output_img_bordi = imwarp(img_cr, tform, 'OutputView', imref2d([img_height, img_width]));
output_img_originale = imwarp(img, tform, 'OutputView', imref2d([img_height, img_width]));

% Applico Canny per evidenziare i nuovi bordi del blister e dilato per enfatizzarli
output_img_bordi = edge(output_img_bordi, 'Canny');
output_img_bordi = imdilate(output_img_bordi, se);

% Calcolo la bounding box dell'oggetto
stats = regionprops(output_img_bordi, 'BoundingBox');
boundingBox = stats.BoundingBox;

% Plotto il risultato del warping confrontando con la bounding box
figure;
imshow(output_img_bordi);
hold on;
rectangle('Position', boundingBox, 'EdgeColor', 'r', 'LineWidth', 4);
title('Confronto tra i bordi del blister raddrizzato e la bounding box rettangolare');

figure;
imshow(output_img_originale);
title('Blister raddrizzato');
hold on;
rectangle('Position', boundingBox, 'EdgeColor', 'r', 'LineWidth', 4);
title('Confronto tra il blister raddrizzato e la bounding box rettangolare');


%% Sezione 8A: Aspect ratio del blister
% Calcolo l'aspect ratio del blister raddrizzato, approsimandolo al rapporto tra la larghezza e l'altezza della bounding box.
% 3 lati su 4 perfetti (per verificare le angolazioni delle rette ho applicato Hough filtrando solo le linee a 0 e 90 gradi)
% Avrei potuto semplicemente calcolare la bounding box fin dall'inizio, ottenendo un risultato simile. 
% Tuttavia, con questo approccio ho diminuito l'approssimazione (tra trapezio e rettangolo) e considerato anche il caso in cui la foto non sia stata scattata perfettamente dall'alto (perpendicolare al blister), ma con un'inclinazione.


% Estraggo la lunghezza e l'altezza della bounding box
larghezza = boundingBox(3);
altezza = boundingBox(4);

% Calcolo aspect ratio
aspect_ratio = larghezza/altezza;
disp(['Aspect ratio: ', num2str(aspect_ratio)]);





%% PUNTO B: Rilevamento delle pillole PRESE e NON PRESE

%% Sezione 1B: Maschera iniziale delle pillole NON PRESE
% L'idea principale è quella di creare una maschera binaria che identifichi inizialmente le pillole NON PRESE dal blister. 
% Queste ultime, rispetto a quelle prese, sono più facili da rilevare avendo una texture più uniforme.
% Dopo aver analizzato i vari spazi di colore, tramite colorThresholder,
% si è notato che il canale Cb dello spazio YCbCr permette di separare facilmente le pillole NON PRESE dal blister tramite thresholding.


% Croppo la bounding box risultante dal punto A per ottenere un'immagine contenente solo il blister raddrizzato. (Facilita l'analisi che segue)
cropped_img = imcrop(output_img_originale, boundingBox);

% Trasformo l'immagine nello spazio YCbCr 
cropped_img_ycbcr = rgb2ycbcr(cropped_img);

% Estraggo il canale Cb  
cropped_img_cb = cropped_img_ycbcr(:,:,2);

% Thresholding sul canale Cb e inversione dei colori per ottenere una maschera binaria delle aree di interesse
cropped_img_cb = ~(cropped_img_cb > 126); 

% Visualizza il risultato della binarizzazione
figure;
imshow(cropped_img_cb);
title('Maschera delle pillole NON PRESE pre-pulizia');

% Applico l'algoritmo di Canny per rilevare i bordi.
% Sigma = 20 per ridurre il rumore e ottenere bordi più definiti
cropped_img_cb = edge(cropped_img_cb, 'Canny', [], 20);

% Dilato i bordi per enfatizzarli
se = strel('disk', 5); % Elemento strutturale disco
cropped_img_cb = imdilate(cropped_img_cb, se);

% Rimuovo piccole imperfezioni con bwareaopen
cropped_img_cb = bwareaopen(cropped_img_cb, 4000);

% Rimuovo l'oggetto più grande (il blister) per ottenere solo le pillole NON PRESE
% Calcolo proprietà degli oggetti 
stats = regionprops(cropped_img_cb, 'Area', 'PixelIdxList');
areas = [stats.Area];

% Identifico l'oggetto più grande e lo rimuovo
[~, idx] = max(areas); % Indice dell'oggetto più grande
mask = false(size(cropped_img_cb)); % Maschera inizializzata a false
mask(stats(idx).PixelIdxList) = true; % Maschera dell'oggetto più grande
cropped_img_cb(mask) = 0; % Rimuovo l'oggetto

% Identifico i contorni dei bordi delle pillole NON PRESE
contour_non_prese = bwperim(cropped_img_cb);

% Riempio la maschera 
% Questo passaggio serve a riempire lo spazio all'interno delle pillole NON PRESE, servirà successivamente per trovare quelle PRESE
cropped_img_cb = imfill(cropped_img_cb, 'holes');

% Visualizzo la maschera delle pillole NON PRESE post-pulizia
figure;
imshow(cropped_img_cb);
title('Maschera delle pillole NON PRESE post-pulizia');

%% Sezione 2B: Maschera di TUTTE le pillole 
% Per ottenere la maschera delle pillole PRESE, si è pensato di sfruttare la differenza 
% tra la maschera in cui sono presenti TUTTE le pillole e quella in cui sono presenti solo le pillole NON PRESE.
% Per ottenere la maschera di TUTTE le pillole ho usato il thresholding adattativo sull'immagine in scala di grigi.


% Converto l'immagine del blister raddrizzato in scala di grigi
cropped_img_gray = rgb2gray(cropped_img);

% Applico il thresholding adattivo
% La sensibilità è stata impostata ad un valore relativamente basso (dopo vari test) per riuscire a rilevare anche le pillole PRESE (più difficili da rilevare) 
cropped_img_bw = ~imbinarize(cropped_img_gray, 'adaptive','ForegroundPolarity', 'dark', 'Sensitivity', 0.55);

% Visualizzo la maschera di TUTTE le pillole pre-pulizia
figure;
imshow(cropped_img_bw);
title('Maschera di TUTTE le pillole pre-pulizia');

% Dilatazione della maschera per enfatizzare i contorni esterni sottili delle pillole NON PRESE
se = strel('disk', 5);
cropped_img_bw = imdilate(cropped_img_bw, se);

% Rimozione delle impurità e degli oggetti non desiderati
% La soglia dell'area è stata impostata, ad un valore relativamente alto, per eliminare la regione dove riflette il flash (oltre a tutte le piccole imperfezioni)
cropped_img_bw = bwareaopen(cropped_img_bw, 15000); 

% Etichetto gli oggetti nella maschera di TUTTE le pillole post prima pulizia
% Questa parte serve a individuare l'oggetto blister (area massima) e l'escrescenza centrale (eccentricità massima) da rimuovere
labeled_img = bwlabel(cropped_img_bw);
region_props = regionprops(labeled_img, 'Eccentricity', 'Area'); % Calcolo eccentricità e area di ciascun oggetto

% Elimino l'oggetto con area massima (il blister) e l'oggetto con l'eccentricità massima (escrescenza centrale)
[~, idx] = max([region_props.Area]); % Indice dell'oggetto con area massima
cropped_img_bw(labeled_img == idx) = 0; % Rimuovo l'oggetto
[~, idx] = max([region_props.Eccentricity]); % Indice dell'oggetto con eccentricità massima
cropped_img_bw(labeled_img == idx) = 0; % Rimuovo l'oggetto

% A questo punto, la maschera contiene solo i contorni di TUTTE le pillol ed è possibile riempire lo spazio all'interno dei contorni di TUTTE le pillole
cropped_img_bw = imfill(cropped_img_bw, 'holes');

% Visualizzo la maschera di TUTTE le pillole post-pulizia
figure;
imshow(cropped_img_bw);
title('Maschera di TUTTE le pillole post-pulizia');

%% Sezione 3B: Maschera delle pillole PRESE
% Avendo ottenuto la maschera di TUTTE le pillole e quella delle pillole NON PRESE, è possibile ottenere la maschera delle pillole PRESE tramite la differenza tra le due maschere.

% Calcolo la differenza tra le due maschere per ottenere la maschera delle pillole PRESE
cropped_img_cb = cropped_img_bw - cropped_img_cb;

% Visualizzo la maschera delle pillole PRESE
figure;
imshow(cropped_img_cb);
title('Maschera delle pillole PRESE pre-pulizia');

% Come si può notare la maschera ottenuta non è perfetta, infatti è rimasta la sagoma delle pillole NON PRESE. 
% Queste ultime però rispetto a quelle PRESE hanno lo spazio all'interno delle pillole vuoto. 
% Per questo motivo si è deciso di filtrare solo gli oggetti con solidità (che indica quanto un oggetto è pieno) maggiore di 0.8.

% Etichetto gli oggetti nella maschera delle pillole PRESE pre-pulizia
[labeled_img, num_regions] = bwlabel(cropped_img_cb);
region_props = regionprops(labeled_img, 'Solidity'); % Calcolo la solidità di ciascun oggetto

% Elimino tutti gli oggetti con solidità minore di 0.8
for i = 1:num_regions
    if region_props(i).Solidity < 0.8
        cropped_img_cb(labeled_img == i) = 0;
    end
end

% Rimuovo le piccole imperfezioni
cropped_img_cb = bwareaopen(cropped_img_cb, 1000);

% Visualizzo la maschera delle pillole PRESE post-pulizia
figure;
imshow(cropped_img_cb);
title('Maschera delle pillole PRESE post-pulizia');

% Trovo i contorni delle pillole PRESE
cropped_img_cb = edge(cropped_img_cb, 'Canny',[], 20);

% Dilato i bordi per enfatizzarli
cropped_img_cb = imdilate(cropped_img_cb, se);

% Identifico i contorni delle pillole PRESE
contour_prese = bwperim(cropped_img_cb);


%% Sezione 4B: Risultato finale
% Per terminare si visualizzano i contorni delle pillole PRESE e NON PRESE
% PILLOLE PRESE: contorni in rosso
% PILLOLE NON PRESE: contorni in verde


% Sovrappongo i contorni all'immagine del blister raddrizzato
figure;
imshow(cropped_img);
hold on;
visboundaries(contour_non_prese, 'Color', 'g');
visboundaries(contour_prese, 'Color', 'r');
hold off;
title('Contorni delle pillole PRESE e NON PRESE');