clear;
close all
clc

%% Caricamento dell'immagine e scelta dell'immagine da segmentare
% Essendo un'immagine a colori, cerco di capire quale spazio di colori (compresa l'immagine convertita in scala di grigi) sia più adatto per la segmentazione.
% La scelta si è basata sull'istogramma di questi ultimi, scegliendo quello con le valli più marcate, che permettano meglio di segmentare i nuclei tramite thresholding.
% Per la segmentazione iniziale si sarebbe potuto usare anche un Kmeans (k=3 1.Background 2.Citoplasma 3.Nuclei).
% Nonostante ciò ho preferito usare il thresholding nello spazio di colori HSV, in quanto mi ha poi permesso di trovare piu facilmente il valore di intensità del viola scuro.

% Caricamento immagine

image = mat2gray(imread('plasma.jpg')); % mat2gray per convertire l'immagine in double (serve per la moltiplicazione con la maschera binaria)
img = rgb2hsv(image);
img_modified = img; % Copia dell'immagine originale
imshow(image);
title('Original Image');

% Istogrammi per i canali RGB e scala di grigi

H= img(:,:,1);
S = img(:,:,2);
V = img(:,:,3);

figure("Name", 'Istogrammi per i canali HSV'); 
subplot(1,3,1); imhist(H); title('H');
subplot(1,3,2); imhist(S); title('S');
subplot(1,3,3); imhist(V); title('V');

%% Prima segmentazione 
% Ho deciso di segmentare i nuclei e non la cellula completa (nucleo + citoplasma) in quanto la segmentazione di questi ultimi fa si che ci siano meno sovrapposizioni.
% La classificazione successiva, non dovrebbe essere influenzata da questa scelta, in quanto può essere basata su proprietà geometriche e statistiche dei nuclei.
% Applico un thresholding manuale dopo aver osservato gli istogrammi. 
% Il canale H è stato scelto per eliminare esclusivamente il background, mentre il canale S per eliminare il citoplasma.
% H<0.523 è background, maggiore è nuclei piu citoplasma.
% S>0.6 , ho solo i nuclei, minore è citoplasma.

% Soglia per H maggiori di 0.6

H = H > 0.523;

% Soglia per S maggiori di 0.555

S = S > 0.6;

% Aggiungo i canali H e S nuovi in alla copia dell'immagine originale (in HSV), per aggiorare.

img_modified(:,:,1) = H;
img_modified(:,:,2) = S;

% Converto l'immagine modificata in RGB, per poi poterla convertire in scala di grigi e binarizzarla.
% Inverto i colori per avere i nuclei bianchi e lo sfondo nero.

img_modified = hsv2rgb(img_modified);
img_modified = mat2gray(rgb2gray(img_modified));
img_modified = imbinarize(img_modified);
img_modified = max(max(img_modified)) - img_modified;

figure("Name", 'Risultato della prima segmentazione');
imshow((img_modified));
title('Risultato della prima segmentazione');

% Applico operazioni morfologiche per eliminare eventuali rumori e cecrcare di separare nuclei che sono uniti.

img_modified = imopen(img_modified, strel('disk', 2)); % Apertura morfologica
img_modified = bwareaopen(img_modified, 400); % Rimozione di oggetti con area minore di 400 pixel
img_modified = imopen(img_modified, strel('disk', 2)); % Ulteriore apertura morfologica

figure("Name", 'Risultato della prima segmentazione dopo operazioni morfologiche');
imshow((img_modified));
title('Risultato della prima segmentazione dopo operazioni morfologiche');

%% Prima etichettatura degli oggetti e visualizzazione delle bounding box
% Dopo aver segmentato i nuclei, etichetto gli oggetti e visualizzo le bounding box per vedere se ci sono nuclei uniti.
% Come si può vedere, ci sono alcune bounding box "prolematiche" che contengono più nuclei, contandoli quindi come un unico oggetto.
% Per affronatare questo problema, ho scritto un secondo codice ('Es1_Analisi_BB_Problematiche.m') che risolve questo problema.


% Identifico gli oggetti con bwlabel e visualizzo le bounding box

labeledImage = bwlabel(img_modified,4);
measurements = regionprops(labeledImage, 'BoundingBox');
boundingBoxes = [measurements.BoundingBox];
boundingBoxes = reshape(boundingBoxes, 4, []);
boundingBoxes = boundingBoxes';

figure("Name", 'Etichettatura - Nuclei uniti');
imshow(img_modified);
title('Etichettatura - Nuclei uniti');
hold on;
for i = 1:size(boundingBoxes, 1)
    rectangle('Position', boundingBoxes(i,:), 'EdgeColor', 'r', 'LineWidth', 1.5);
end
hold off;

% Salvo img_modified come .mat per usarla nel codice adibito alla segmentazione delle bounding box problematiche

save('img_modified.mat', 'img_modified');

%% Seconda segmentazione post analisi delle bounding box problematiche
% Dopo aver analizzato le bounding box problematiche, carico il risultato dell'analisi fatta nell'altro codice e visulizzo la nuova segmentazione.
% Come si può vedere, i nuclei prima uniti, sono stati separati correttamente e ora valgono come oggetti distinti (ognuno ha la propria bounding box).


% Carico l'immagine segmentata post analisi delle bounding box problematiche

data = load('img_all_separated.mat');
img_modified = mat2gray(data.img_all_separated);

% Riempio i buchi nei nuclei (per avere meno errore nel calcolo successivo dell'area)

img_modified = imfill(img_modified, 26, 'holes');

% Etichetto nuovamente gli oggetti
% Calcolo anche l'eccentricità, l'area e i pixel di ogni oggetto. Variabili che mi serviranno per la classificazione.

labeledImage = bwlabel(img_modified,4);
measurements = regionprops(labeledImage, 'BoundingBox', 'Area', 'Eccentricity', 'PixelIdxList');
boundingBoxes = [measurements.BoundingBox];
boundingBoxes = reshape(boundingBoxes, 4, []);
boundingBoxes = boundingBoxes';

figure("Name", 'Etichettatura - Nuclei separati');
imshow(img_modified.*image);
title('Etichettatura - Nuclei separati');
hold on;
for i = 1:size(boundingBoxes, 1)
    rectangle('Position', boundingBoxes(i,:), 'EdgeColor', 'r', 'LineWidth', 1.5);
end
hold off;

%% Classificazione dei nuclei e salvataggio delle metriche
% Le classi dei nuclei su cui mi baso per la classificazione sono 2: SANE e MALATE.
% All'interno della classe MALATE, considero anche i nuclei di cui la classificazione è ambigua. 
% Questo permette di avere una recall più alta per avere il minor numero minore possibile di falsi negativi.
% La classificazione si basa su 4 proprietà: area, eccentricità, deviazione standard dell'intensità e intensità media del canale V.
% - Area: nuclei più grandi (area maggiore) possono essere sintomo di malattia.
% - Eccentricità: nuclei poco circolari (eccentricità alta) possono essere sintomo di malattia (il nucleo inizia a cambiare forma).
% - Deviazione standard dell'intensità: nuclei con texture poco uniforme (std più alta) possono essere sintomo di malattia.
% - Intensità media del canale V: nuclei con colore che tende al rosa possono essere sintomo di malattia.
% N.B. Questo approccio tende ad automatizzare la classificazione. Per scegleire precisamnte le cellule che si voogliono manualmente si potrebbe usare bwselect.


% Moltiplico la maschera binaria con l'immagine originale RGB per poter visualizzare la segmentazione con i colori originali.

rgbImage = img_modified .* image;

% Conversione a scala di grigi per calcolare la STD della videointensità

grayImage = mat2gray(rgb2gray(rgbImage));

% Parametri per la classificazione ( migliori valori per questa imagine specifica)
% Per generalizzare il codice, sarebbe opportuno diminuire la soglia dell'eccntricità circa a 0.70 (0.48+19) e modificare le soglie.
% In questo caso l asoglia dell'eccentricità è stata aumentata per classificare meglio i nuclei ai bordi dell'immagine (essendo tagliati sono meno circolari).

areaThreshold = 2050;            % Soglia di area 
eccentricityThreshold = 0.9;    % Soglia di eccentricità 
stdThreshold = 0.3;           % Soglia di STD 
VThreshold = 0.63;               % Soglia di intensità del canale V (sotto 0.63 è viola scuro, sopra è rosa)

% Creazione delle maschere binarie per le due classi

maskGoodCells = false(size(img_modified));  % Maschera per cellule SANE
maskBadCells = false(size(img_modified));   % Maschera per cellule MALATE

% Liste per raccogliere le proprietà delle cellule per ogni classe
goodCellsStats = [];
badCellsStats = [];

% Classificazione dei nuclei

for i = 1:numel(measurements)
    % Ottengo la bounding box e l'area del nucleo
    area = measurements(i).Area;
    eccentricity = measurements(i).Eccentricity;
    pixelIdx = measurements(i).PixelIdxList; % Indici dei pixel del nucleo per calcolare avgV e std solo del nucleo e non della bounding box
    
    % Calcolo il valore medio dell'intensità del canale V
    avgV = mean(V(pixelIdx));
    
    % Calcolo la deviazione standard e l'intensità media sulla scala di grigi
    avgGray = mean(grayImage(pixelIdx));
    stdGray = std(grayImage(pixelIdx));
    
    % Classifico il nucleo in base ai criteri
    if area < areaThreshold && eccentricity < eccentricityThreshold && stdGray < stdThreshold && avgV < VThreshold
        % Cellula SANA
        maskGoodCells(pixelIdx) = true;
        goodCellsStats = cat(1, goodCellsStats, [area, eccentricity, avgGray, stdGray, avgV]); % Salvo le metriche della cellula SANA
    else
        % Cellula MALATA
        maskBadCells(pixelIdx) = true;
        badCellsStats = cat(1, badCellsStats, [area, eccentricity, avgGray, stdGray, avgV]); % Salvo le metriche della cellula MALATA
    end
end

%% Calcolo delle statistiche come media e deviazione standard

% Numero di cellule SANE e MALATE

numGoodCells = size(goodCellsStats, 1);
numBadCells = size(badCellsStats, 1);

% Statistiche (media ± std) per ogni classe

goodStats = mean(goodCellsStats, 1);
goodStatsStd = std(goodCellsStats, 0, 1);

badStats = mean(badCellsStats, 1);
badStatsStd = std(badCellsStats, 0, 1);

%% Visualizzazione delle statistiche
% N.B. La deviazione standard è simile per le due classi, dato che sono stati utilizzati i nuclei (texture più uniforme rispetto a nuclo + citoplasma)

fprintf('Numero di cellule buone: %d\n', numGoodCells);
fprintf('Numero di cellule cattive: %d\n', numBadCells);

fprintf('\nCellule Buone (media ± std):\n');
fprintf('Area: %.2f ± %.2f\n', goodStats(1), goodStatsStd(1));
fprintf('Eccentricità: %.2f ± %.2f\n', goodStats(2), goodStatsStd(2));
fprintf('Intensità (grayscale): %.2f ± %.2f\n', goodStats(3), goodStatsStd(3));
fprintf('Deviazione Intensità (grayscale): %.2f ± %.2f\n', goodStats(4), goodStatsStd(4));
fprintf('Intensità media del canale V: %.2f ± %.2f\n', goodStats(5), goodStatsStd(5));

fprintf('\nCellule Cattive (media ± std):\n');
fprintf('Area: %.2f ± %.2f\n', badStats(1), badStatsStd(1));
fprintf('Eccentricità: %.2f ± %.2f\n', badStats(2), badStatsStd(2));
fprintf('Intensità (grayscale): %.2f ± %.2f\n', badStats(3), badStatsStd(3));
fprintf('Deviazione Intensità (grayscale): %.2f ± %.2f\n', badStats(4), badStatsStd(4));
fprintf('Intensità media del canale V: %.2f ± %.2f\n', badStats(5), badStatsStd(5));

%% Visualizzazione dei risultati
% Visualizzazione maschere
figure;
subplot(1, 2, 1);
imshow(maskGoodCells .* rgbImage, []);
title('Cellule SANE');

subplot(1, 2, 2);
imshow(maskBadCells .* rgbImage, []);
title('Cellule MALATE');

% Sovrapposizione delle maschere sull'immagine originale
figure;
imshow(image);
hold on;
visboundaries(maskGoodCells, 'Color', 'g', 'LineWidth', 1.5);
visboundaries(maskBadCells, 'Color', 'r', 'LineWidth', 1.5);
title('Classificazione Cellule (Verde: SANE, Rosso: MALATE)');
hold off;