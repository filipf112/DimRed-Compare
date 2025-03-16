function pca_tsne_gui
    % Tworzenie GUI
    fig = figure('Name', 'PCA vs t-SNE', 'Position', [100, 100, 600, 400]);
    
    % Przycisk do wczytywania danych
    uicontrol('Style', 'pushbutton', 'String', 'Wczytaj dane', ...
        'Position', [50, 350, 100, 30], 'Callback', @load_data);
    
    % Przycisk do uruchamiania analizy
    uicontrol('Style', 'pushbutton', 'String', 'Uruchom analizę', ...
        'Position', [450, 350, 120, 30], 'Callback', @run_analysis);
    
    % Checkboxy dla PCA i t-SNE
    cb_pca = uicontrol('Style', 'checkbox', 'String', 'PCA', ...
        'Position', [200, 355, 50, 20], 'Value', 1);
    cb_tsne = uicontrol('Style', 'checkbox', 'String', 't-SNE', ...
        'Position', [270, 355, 60, 20], 'Value', 1);
    
    % Przechowywanie danych
    data = struct('X', [], 'labels', []);
    
    function load_data(~, ~)
        [file, path] = uigetfile('*.mat', 'Wybierz plik .mat');
        if file
            loaded = load(fullfile(path, file));
            if isfield(loaded, 'normalized_signals')
                data.X = loaded.normalized_signals;
            else
                errordlg('Brak pola normalized_signals w pliku!', 'Błąd');
                return;
            end
            if isfield(loaded, 'labels')
                data.labels = loaded.labels;
            else
                data.labels = ones(size(data.X, 1), 1); % Domyślne etykiety
            end
            disp('Dane załadowane');
        end
    end
    
    function run_analysis(~, ~)
        if isempty(data.X)
            errordlg('Najpierw załaduj dane!', 'Błąd');
            return;
        end
        
        selected_pca = get(cb_pca, 'Value');
        selected_tsne = get(cb_tsne, 'Value');
        
        figure;
        
        if selected_pca
            subplot(1, selected_pca + selected_tsne, 1);
            perform_pca();
        end
        
        if selected_tsne
            subplot(1, selected_pca + selected_tsne, selected_pca + 1);
            perform_tsne();
        end
    end
    
    function perform_pca()
        [coeff, score] = pca(data.X);
        numComponents = min(2, size(score, 2));
        reduced = score(:, 1:numComponents);
        scatter(reduced(:,1), reduced(:,2), 20, data.labels, 'filled');
        title('PCA'); xlabel('PC1'); ylabel('PC2');
    end
    
    function perform_tsne()
        reduced = tsne(data.X, 'NumDimensions', 2);
        scatter(reduced(:,1), reduced(:,2), 20, data.labels, 'filled');
        title('t-SNE'); xlabel('Dim 1'); ylabel('Dim 2');
    end
end
