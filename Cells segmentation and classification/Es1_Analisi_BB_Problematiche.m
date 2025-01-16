%% Bounding Box "Problematiche"
% Questo script permette di visualizzare le bounding box dei nuclei e di analizzare quelle problematiche (più di un nucleo per bb, sovrapposizioni, ecc.).
% Carico l'immagine originale e l'immagine post prima segmentazione dal codice principale, e una volta risolte le "problematiche", salvo il risultato finale da caricare nel codice principale.
% L'obbiettivo è quello di avere nuceli separati e non sovrapposti, che vengano etichettati come oggetti distinti.

clear
close all
clc

%% Caricamento delle immagini

% Carico l'immagine originale e l'immagine modificata binaria

image = imread('plasma.jpg');
data = load('img_modified.mat');
img_modified = mat2gray(data.img_modified);

% Etichetto gli oggetti nell'immagine binaria e calcolo le bounding box

labeledImage = bwlabel(img_modified, 4); 
measurements = regionprops(labeledImage, 'BoundingBox'); 
boundingBoxes = reshape([measurements.BoundingBox], 4, []).'; 

%% Visualizzazione delle bounding box

figure("Name", 'Bounding box sui nuclei');
imshow(image);
title('Bounding box sui nuclei');
hold on;

% Disegno le bounding box sull'immagine

for i = 1:size(boundingBoxes, 1)
    rectangle('Position', boundingBoxes(i, :), 'EdgeColor', 'r', 'LineWidth', 1.5);
end
hold off;

%% Analisi delle bounding box problematiche
% Visuallizzo il risultato della prima segmentazione per le bounding box problematiche e le paragono con la bounding box corrispondente nell'immagine originale.
% Questo mi permette di capire quale sia il problema e come risolverlo.

% Lista delle bounding box che richiedono segmentazione manuale o valutazione

problematicBoundingBoxes = [4, 6, 19, 20, 30, 36, 55, 57, 63, 67, 68, 90, 102, 117];
numBoxes = numel(problematicBoundingBoxes);
boxesPerFigure = 7; % Numero di bounding box per figura

% Itero sulle figure per visualizzare i nuclei delle bounding box problematiche

for fig = 1:2
    figure("Name", ['Bounding box problematiche - Figura ', num2str(fig)]);
    
    % Determino quali bounding box visualizzare nella figura corrente
    startIdx = (fig - 1) * boxesPerFigure + 1;
    endIdx = min(fig * boxesPerFigure, numBoxes);
    currentBoxes = problematicBoundingBoxes(startIdx:endIdx);
    
    % Visualizzo ogni bounding box
    for idx = 1:numel(currentBoxes)
        boxIdx = currentBoxes(idx);
        
        % Trovo le coordinate per il ritaglio
        [row, col] = find(labeledImage == boxIdx);
        rowMin = min(row); rowMax = max(row);
        colMin = min(col); colMax = max(col);
        
        % Ritaglio l'immagine originale e quella binaria
        croppedBinary = labeledImage(rowMin:rowMax, colMin:colMax) > 0;
        croppedOriginal = image(rowMin:rowMax, colMin:colMax, :);
        
        % Visualizzo l'immagine binaria e quella originale
        subplot(boxesPerFigure, 2, 2 * (idx - 1) + 1);
        imshow(croppedBinary);
        title(['Binary - Nucleo ', num2str(boxIdx)]);
        
        subplot(boxesPerFigure, 2, 2 * (idx - 1) + 2);
        imshow(croppedOriginal);
        title(['Original - Nucleo ', num2str(boxIdx)]);
    end
end

%% Segmentazione manuale delle bounding box selezionate
% Note:
% - Bounding box 90: contiene un singolo nucleo che si sta frammentando (lo conisdero come uno).
% - Bounding box 117: contiene due nuclei parziali sul bordo (considerati come uno).
% - Le altre bounding box contengono ciascuna 2/3 nuclei, da segmentare manualmente. Per 2 casi ci sono parti che si sovrappongono.
% Essendo quindi pochissimi casi, decido di perdere quella poca informazione. 
% Si potrebbe applicare Hough circles ma solo per casi in cui le cellule hanno forma circolare come bb 20. Per le altre andrei ad approssimare troppo le altre forme come cerchi.


manualBoxes = [4, 6, 19, 20, 30, 36, 55, 57, 63, 67, 68, 102]; % Bounding box da segmentare

for i = 1:numel(manualBoxes)
    boxIdx = manualBoxes(i);
    
    % Trovo le coordinate per il ritaglio
    [row, col] = find(labeledImage == boxIdx);
    rowMin = min(row); rowMax = max(row);
    colMin = min(col); colMax = max(col);
    
    % Ritaglio l'immagine binaria e quella originale
    croppedBinary = labeledImage(rowMin:rowMax, colMin:colMax) > 0;
    croppedOriginal = image(rowMin:rowMax, colMin:colMax, :);
    currentBinary = croppedBinary; % Copia dell'immagine binaria
    done = false; % Controllo per terminare la segmentazione manuale
    
    % Ciclo per segmentazione manuale
    while ~done
        % Visualizzo l'immagine originale e la binaria corrente
        figure('Name', ['Segmentazione manuale - Nucleo ', num2str(boxIdx)]);
        subplot(1, 2, 1);
        imshow(croppedOriginal);
        title('Immagine Originale');
        
        subplot(1, 2, 2);
        imshow(currentBinary);
        title('Immagine Binaria Corrente');
        
        % Traccio una regione manualmente con drawfreehand
        figure;
        imshow(currentBinary);
        title(['Rimuovere sezioni indesiderate - Nucleo ', num2str(boxIdx)]);
        h = drawfreehand('Color', 'r', 'LineWidth', 2);
        manualMask = createMask(h);
        
        % Aggiorno l'immagine binaria eliminando la regione selezionata
        separatedBinary = currentBinary & ~manualMask;
        currentBinary = separatedBinary;
        
        % Visualizzo il risultato della segmentazione
        figure('Name', ['Risultato segmentazione - Nucleo ', num2str(boxIdx)]);
        subplot(1, 2, 1);
        imshow(croppedBinary);
        title('Prima della separazione');
        
        subplot(1, 2, 2);
        imshow(separatedBinary);
        title('Dopo la separazione');
        
        % Chiedo all'utente se continuare
        choice = questdlg('Vuoi continuare la segmentazione?', 'Segmentazione manuale', 'Sì', 'No', 'Sì');
        if strcmp(choice, 'No')
            done = true;
        end
        close all;
    end
    
    % Aggiorno l'immagine binaria globale con il risultato della segmentazione
    img_modified(rowMin:rowMax, colMin:colMax) = currentBinary;
end

%% Visualizzazione e salvataggio del risultato finale
% Come si può notare, i nuclei sono stati separati correttamente. E valgono come oggetti distinti.
% L'immagine finale viene salvata per essere caricata nel codice principale.

% Etichetto nuovamente l'immagine binaria aggiornata

img_all_separated = img_modified;
labeledImage = bwlabel(img_all_separated, 4);

% Visualizzo l'immagine con i nuclei separati

figure("Name", 'Immagine con nuclei separati');
imshow(label2rgb(labeledImage));
title('Immagine con nuclei separati');

% Salvo il risultato finale

save('img_all_separated.mat', 'img_all_separated');