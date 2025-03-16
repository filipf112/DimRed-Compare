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

    % Dropdowny na zmienne
    popup_data = uicontrol('Style', 'popupmenu', 'String', {'Wybierz dane'}, ...
        'Position', [50, 300, 150, 25]);
    popup_labels = uicontrol('Style', 'popupmenu', 'String', {'Wybierz etykiety'}, ...
        'Position', [250, 300, 150, 25]);

    % Przechowywanie danych
    data = struct('loaded', [], 'X', [], 'labels', []);

    function load_data(~, ~)
        [file, path] = uigetfile('*.mat', 'Wybierz plik .mat');
        if file
            data.loaded = load(fullfile(path, file));
            fields = fieldnames(data.loaded);
            set(popup_data, 'String', fields);
            set(popup_labels, 'String', [{'brak'}, fields']);
            disp('Dane załadowane. Wybierz zmienne z listy.');
        end
    end

    function run_analysis(~, ~)
        if isempty(data.loaded)
            errordlg('Najpierw załaduj dane!', 'Błąd');
            return;
        end

        % Pobierz wybrane zmienne z dropdownów
        idx_data = get(popup_data, 'Value');
        fields = get(popup_data, 'String');
        data.X = data.loaded.(fields{idx_data});

        idx_labels = get(popup_labels, 'Value');
        fields_labels = get(popup_labels, 'String');
        if strcmp(fields_labels{idx_labels}, 'brak')
            data.labels = ones(size(data.X, 1), 1);
        else
            data.labels = data.loaded.(fields_labels{idx_labels});
        end

        % Zamieniamy etykiety na indeksy kategorii do scattera
        labels_for_color = grp2idx(data.labels);

        selected_pca = get(cb_pca, 'Value');
        selected_tsne = get(cb_tsne, 'Value');

        figure;
        if selected_pca
            subplot(1, selected_pca + selected_tsne, 1);
            perform_pca(labels_for_color);
        end
        if selected_tsne
            subplot(1, selected_pca + selected_tsne, selected_pca + 1);
            perform_tsne(labels_for_color);
        end
    end

    function perform_pca(labels_for_color)
        [coeff, score] = pca(data.X);
        scatter(score(:,1), score(:,2), 20, labels_for_color, 'filled');
        title('PCA'); xlabel('PC1'); ylabel('PC2');
    end

    function perform_tsne(labels_for_color)
        reduced = tsne(data.X, 'NumDimensions', 2);
        scatter(reduced(:,1), reduced(:,2), 20, labels_for_color, 'filled');
        title('t-SNE'); xlabel('Dim 1'); ylabel('Dim 2');
    end
end