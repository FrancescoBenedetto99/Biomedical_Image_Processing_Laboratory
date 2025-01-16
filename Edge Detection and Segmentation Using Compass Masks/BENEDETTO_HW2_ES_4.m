clear
close all
clc

%% Parte 1: Caricamento dell'immagine e miglioramento dei bordi

% Caricamento dell'immagine di input e conversione in double

image = im2double(imread("disk1.jpg"));

% Regolazione del contrasto per evidenziare meglio i dettagli

contrast_image = imadjust(image);

% Conversione in uint8 per poter applicare locallapfilt

image_uint8 = im2uint8(image);

% Applicazione del filtro Laplaciano locale per migliorare i bordi
% I parametri sigma e alpha controllano la scala spaziale del filtro e l'intensità della modifica.
% Sigma basso minore di 1 per mettere in evidenza bordi fini e dettagliati.
% Alpha più alto, ma comunque moderato, altrimenti l'immagine risulterebbe troppo contrastata e troverei bordi dove non ci sono.

sigma = 0.4; 
alpha = 0.8; 
laplacian_filtered_image = locallapfilt(image_uint8, sigma, alpha);

% Conversione del risultato in double per ulteriori elaborazioni

laplacian_filtered_image = im2double(laplacian_filtered_image);

% Applicazione di un filtro high-boost per ulteriore enfasi dei bordi
% Essendo il valore centrale minore di 8, l'immagine viene visualizzata come negativo dell'originale (sembra che il contrasto sia migliore)

high_boost_filter = [-1 -1 -1; -1 3 -1; -1 -1 -1];
enhanced_image = conv2(laplacian_filtered_image, high_boost_filter, "same");

% Visualizzazione dell'immagine migliorata
figure('Name', 'Confronto Immagini Originale e Migliorata');
subplot(1, 2, 1);
imshow(image, []);
title('Immagine Originale');
subplot(1, 2, 2);
imshow(enhanced_image, []);
title('Immagine Migliorata con Filtro High-Boost');

%% Parte 2: Rilevamento dei bordi con maschere Sobel Compass

% Definizione delle otto maschere per rilevare i bordi in diverse direzioni

compassMasks = {
    [-1 -2 -1; 0 0 0; 1 2 1],  % N
    [-2 -1 0; -1 0 1; 0 1 2],  % NE
    [-1 0 1; -2 0 2; -1 0 1],  % E
    [0 1 2; -1 0 1; -2 -1 0],  % SE
    [1 2 1; 0 0 0; -1 -2 -1],  % S
    [2 1 0; 1 0 -1; 0 -1 -2],  % SW
    [1 0 -1; 2 0 -2; 1 0 -1],  % W
    [0 -1 -2; 1 0 -1; 2 1 0]   % NW
};

% Applicazione delle maschere maschere Sobel per rilevare i bordi

response_images = zeros(size(enhanced_image, 1), size(enhanced_image, 2), 8);
for i = 1:8
    response_images(:, :, i) = imfilter(enhanced_image, compassMasks{i}, 'same');
end

% Somma assoluta delle risposte lungo la terza dimensione per ottenere una mappa di bordi combinata
% Facendo la somma si ottiene un'immagine in cui i bordi (ora rilevati in tutte le direzioni) sono evidenziati in modo più chiaro rispetto alle singole risposte

sobel_combined_response = sum(abs(response_images), 3);

% Visualizzazione delle risposte individuali delle maschere

figure('Name', 'Risposte delle Maschere Sobel Compass');
for i = 1:8
    subplot(2, 4, i);
    imshow(response_images(:, :, i), []);
    title(sprintf('Maschera Compass %d', i));
end

%% Modifica: Binarizzazione con Soglia Manuale
% Binarizzazione della mappa dei bordi utilizzando una soglia manuale
% Soglia molto bassa (rispetto all'intensità della somma precedente) per
% evidenziare anche il bordo del quadrato in basso a detrsa con poco
% contrasto, porta comunque molto rumore.

manual_threshold = 1; 
binary_edges = sobel_combined_response > manual_threshold;

% Visualizzazione della binarizzazione con la soglia manuale
figure('Name', 'Binarizzazione della Mappa dei bordi');
subplot(1, 2, 1);
imshow(sobel_combined_response, []);
title('Risposta Sobel Combined');
subplot(1, 2, 2);
imshow(binary_edges, []);
title(['Binarizzazione con Soglia ', num2str(manual_threshold)]);

%% Parte 4: Prima pulizia 

% Rimozione del rumore eliminando piccoli oggetti
% La funzione bwareaopen rimuove gli oggetti con un'area inferiore a 17 pixel.
% Il valore scelto è il giusto compromesso tra mantenere i bordi del già frammentato quadrato "difficile" e lasciare come rumore principale ...
% ... solo i piccoli cerchietti. Quest'ultimi saranno considerati come oggetti in bwlabel perchè dopo questapulizia avranno connettività inferiore a 4.

clean_edges = bwareaopen(binary_edges, 17);  

% Visualizzazione dei bordi puliti
figure('Name', 'Prima Pulizia');
imshow(clean_edges);
title('Prima Pulizia');

%% Parte 6: Eliminazione di oggetti indesiderati
% I valori di Area e Eccentricity sono stati scelti a tentativi per identificare i cerchietti indesiderati
% Eccentrcità <1 per considerare solo oggetti simili a cerchi. (0 è un cerchio perfetto, 1 è un'ellisse degenere a una linea).
% Il ciclo for itera su tutte le regioni etichettate.
% Per ogni regione, verifica se l'area è compresa tra 25 e 2000 e se l'eccentricità è inferiore a 0.8.
% Se la regione soddisfa questi criteri, la bounding box viene arrotondata e la maschera finale viene aggiornata per includere solo le regioni selezionate.



% Etichettatura degli oggetti

[L,NUM] = bwlabel(clean_edges,4);
RGB = label2rgb(L);

% Visualizzazione degli oggetti etichettati

figure("Name", "Oggetti Etichettati");
imshow(RGB,[])
title("Oggetti Etichettati");

% Calcolo delle proprietà delle regioni etichettate

properties = regionprops(L, 'Area', 'BoundingBox', 'Eccentricity');

% Creazione di una maschera che identifica i cerchietti fastidiosi
final_mask = false(size(clean_edges));
for i = 1:length(properties)
    if properties(i).Area > 25 && properties(i).Area < 2000 && properties(i).Eccentricity < 0.8 
       % Ottieni le coordinate della bounding box dell'oggetto
        bbox = round(properties(i).BoundingBox); 
        
        % Assicurati che le coordinate siano entro i limiti dell'immagine
        row_start = max(1, bbox(2));
        row_end = min(size(L, 1), bbox(2) + bbox(4) - 1);
        col_start = max(1, bbox(1));
        col_end = min(size(L, 2), bbox(1) + bbox(3) - 1);

        % Aggiorna la maschera finale per l'oggetto corrente
        final_mask(row_start:row_end, col_start:col_end) = ...
            L(row_start:row_end, col_start:col_end) == i;
    end
end

% Visualizzazione dei cerchietti indesiderati

figure('Name', 'Cerchietti Indesiderati');
imshow(final_mask, []);
title('Cerchietti Indesiderati');

% Eliminazione dei cerchietti indesiderati

binary_image = clean_edges - final_mask;


% Visualizzazione dell'immagine binaria finale

figure('Name', 'Immagine Binaria Finale');
imshow(binary_image, []);
title('Immagine Binaria Finale');

%% Pulizia intermedia
% Dopo aver provato quasi tutti i tentativi con operazioni "teoriche" (Hough, HPF con samp2, ecc..) per riuscire contemporanemente
% a pulire l'immagine e allo stesso tempo mantenere i bordi del quadrato in
% basso a destra ho deciso di utilizzare un "trick". 
% Essendo 12 quadrati equidistanziati tra loro che coprono 360 gradi, significa che ognuno è ruotato rispetto all'altro di 30 gradi.
% Perciò ho sostituito un quadrato ben segmentato cercando di centrare al meglio le ROI utilizzate.


% Definizione di un elemento strutturante quadrato di dimensione 3x3
se_erode = strel('square', 3); 

% Applicazione dell'operazione di erosione all'immagine binaria per rimuovere piccole imperfezioni residue

eroded_image = imerode(binary_image, se_erode);

% Visualizzazione del risultato dell'erosione

figure('Name', 'Post-erosione'); 
imshow(eroded_image, []); 
title('Immagine Post-erosione');

% Estrazione della ROI che contiene il quadrato "difficile"
% La ROI si trova attorno alla riga 590 e colonna 676, con altezza 124 pixel e larghezza 142 pixel

roi_region = eroded_image(590:590+124, 676:676+142); 

% Estrazione di una seconda ROI
% Questa si trova con coordinate di partenza riga 732 e colonna 405, con stesse altezza e largezza (le ROI devono avere dimensioni uguali)

roi_region2 = eroded_image(732:732+124, 405:405+142);

% Visualizzazione delle due ROI estratte

figure('Name', 'ROI 1 e 2');
subplot(1, 2, 1); 
imshow(roi_region, []); 
title('ROI Quadrato "Difficile"'); 
subplot(1, 2, 2); 
imshow(roi_region2, []); 
title('ROI Quadrato ben segmentato'); 

% Rotazione della ROI 2 di 60 gradi (è stato preso il quadrato in basso centrale e ruotato di 60 = 30 * 2 )
% La funzione imrotate ruota l'immagine di 60 gradi con interpolazione NN (default) e taglio della dimensione per mantenere stesse dimensioni di ROI

rotated_roi = imbinarize(imrotate(roi_region2, 60, 'crop')) + 0; % La binarizzazione assicura valori binari (0 o 1) + 0 altrimenti era type logical e


% Visualizzazione della ROI 1 e della ROI ruotata
figure('Name', 'ROI 1 e 2');
subplot(1, 2, 1); % Mostra la ROI 1
imshow(roi_region, []); 
title('ROI Quadrato "Difficile"');
subplot(1, 2, 2); % Mostra la ROI ruotata
imshow(rotated_roi, []); 
title('ROI Quadrato ben segmentato e ruotato');

% Copia dell'immagine binaria originale

processed_image = eroded_image; 

% Sovrascrivo la regione originale con il quadrato ruotato
processed_image(590:590+124, 676:676+142) = rotated_roi;

% Visualizzazione dell'immagine elaborata

figure('Name', 'Immagine Elaborata');
imshow(processed_image, []);
title('Immagine Elaborata');


%% Pulizia finale 

[L,NUM] = bwlabel(processed_image);
properties = regionprops(L, 'Area', 'BoundingBox');



% Creazione di una maschera che identifica il cerchio grande e gli utlimi
% oggetti piccoli rimanenti
% Inizializza una maschera finale vuota (di dimensioni uguali a 'clean_edges')
final_mask = false(size(processed_image));

% Itera su tutte le proprietà degli oggetti
for i = 1:length(properties)
    % Filtro per area inferiore a 2000 oppure con un valore specifico di Area
    if properties(i).Area > 500 && properties(i).Area<10000
        % Ottieni le coordinate della bounding box dell'oggetto
        bbox = round(properties(i).BoundingBox); 
        
        % Assicurati che le coordinate siano entro i limiti dell'immagine
        row_start = max(1, bbox(2));
        row_end = min(size(L, 1), bbox(2) + bbox(4) - 1);
        col_start = max(1, bbox(1));
        col_end = min(size(L, 2), bbox(1) + bbox(3) - 1);

        % Aggiorna la maschera finale per l'oggetto corrente
        final_mask(row_start:row_end, col_start:col_end) = ...
            L(row_start:row_end, col_start:col_end) == i;
    end
end


% Visualizzazione della maschera dei quadrati
figure('Name', 'Quadrati Segmentati');
imshow(final_mask, []);
title('Quadrati Segmentati');

%% Risultato Finale
% Applicazione di operazioni morfologiche finali per avere edge più sottili.
% Prima di fare il thinning ho applicato una dilatazione per avere meno edge spuri.

se = strel('disk',4); 

final_eroded_image = imdilate(final_mask, se); 

final_thin = bwmorph(final_eroded_image, 'thin',17);

final_no_spur = bwmorph(final_thin, 'spur', 10);

% Visualizzazione dell'immagine binaria finale
figure('Name', 'Immagine Binaria Finale');
imshow(final_no_spur, []);
title('Immagine Binaria Finale');


