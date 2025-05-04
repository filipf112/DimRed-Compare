function pca_tsne_gui
    % Tworzenie GUI
    fig = figure('Name', 'PCA vs t-SNE', 'Position', [100, 100, 700, 550]);

    % Przycisk do wczytywania danych
    uicontrol('Style', 'pushbutton', 'String', 'Wczytaj dane', ...
        'Position', [50, 500, 100, 30], 'Callback', @load_data);

    % Przycisk do uruchamiania analizy
    uicontrol('Style', 'pushbutton', 'String', 'Uruchom analizę', ...
        'Position', [550, 500, 120, 30], 'Callback', @run_analysis);

    % Checkboxy dla PCA i t-SNE
    cb_pca = uicontrol('Style', 'checkbox', 'String', 'PCA', ...
        'Position', [200, 505, 50, 20], 'Value', 1);
    cb_tsne = uicontrol('Style', 'checkbox', 'String', 't-SNE', ...
        'Position', [270, 505, 60, 20], 'Value', 1);

    % Dropdowny na zmienne
    popup_data = uicontrol('Style', 'popupmenu', 'String', {'Wybierz dane'}, ...
        'Position', [50, 450, 150, 25]);
    popup_labels = uicontrol('Style', 'popupmenu', 'String', {'Wybierz etykiety'}, ...
        'Position', [250, 450, 150, 25]);

    % Radio button do wyboru 2D/3D
    uicontrol('Style', 'text', 'Position', [50, 410, 100, 15], 'String', 'Wymiary:');
    dimension_popup = uicontrol('Style', 'popupmenu', 'String', {'2D', '3D'}, ...
        'Position', [120, 410, 80, 20]);

    % Parametry PCA
    uicontrol('Style', 'text', 'Position', [50, 360, 120, 15], 'String', 'Wariancja PCA (%):');
    pca_variance_edit = uicontrol('Style', 'edit', 'String', '95', ...
        'Position', [180, 355, 50, 25]);

    % Parametry t-SNE
    uicontrol('Style', 'text', 'Position', [50, 310, 100, 15], 'String', 'Perplexity t-SNE:');
    tsne_perplexity_edit = uicontrol('Style', 'edit', 'String', '30', ...
        'Position', [180, 305, 50, 25]);

    uicontrol('Style', 'text', 'Position', [50, 270, 120, 15], 'String', 'Learning Rate t-SNE:');
    tsne_lr_edit = uicontrol('Style', 'edit', 'String', '200', ...
        'Position', [180, 265, 50, 25]);

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

        % Pobierz wybrane zmienne
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

        labels_for_color = grp2idx(data.labels);

        % Pobierz parametry
        pca_variance = str2double(get(pca_variance_edit, 'String')) / 100;
        tsne_perplexity = str2double(get(tsne_perplexity_edit, 'String'));
        tsne_lr = str2double(get(tsne_lr_edit, 'String'));
        selected_pca = get(cb_pca, 'Value');
        selected_tsne = get(cb_tsne, 'Value');

        dim_option_raw = get(dimension_popup, 'Value'); % 1 dla 2D, 2 dla 3D
        if dim_option_raw == 1
            tsne_dims = 2;
        else
            tsne_dims = 3;
        end

        % Sprawdzenie poprawności parametrów t-SNE
        n_samples = size(data.X, 1);
        if tsne_perplexity > (n_samples - 1) / 3
            warndlg(sprintf('Perplexity za duże! Dla %d próbek, max to około %.1f.', n_samples, (n_samples - 1) / 3), 'Błąd Perplexity');
            return;
        end

        % Nowe okno wynikowe
        figure;
        num_plots = selected_pca + selected_tsne;
        idx = 1;

        if selected_pca
            subplot(1, num_plots, idx);
            perform_pca(labels_for_color, dim_option_raw, pca_variance);
            idx = idx + 1;
        end
        if selected_tsne
            subplot(1, num_plots, idx);
            perform_tsne(labels_for_color, tsne_dims, tsne_perplexity, tsne_lr);
        end
    end

    function perform_pca(labels_for_color, dim_option, variance_threshold)
        [coeff, score, latent, ~, explained] = pca(data.X);
        cumulative_explained = cumsum(explained)/100;

        % Znalezienie minimalnej liczby komponentów
        num_components = find(cumulative_explained >= variance_threshold, 1, 'first');
        disp(['PCA - liczba komponentów dla progu ' num2str(variance_threshold*100) '%: ' num2str(num_components)]);

        if dim_option == 1 % 2D
            scatter(score(:,1), score(:,2), 20, labels_for_color, 'filled');
            title(['PCA 2D (Var ', num2str(variance_threshold*100), '%)']);
            xlabel('PC1'); ylabel('PC2');
        else % 3D
            scatter3(score(:,1), score(:,2), score(:,3), 20, labels_for_color, 'filled');
            title(['PCA 3D (Var ', num2str(variance_threshold*100), '%)']);
            xlabel('PC1'); ylabel('PC2'); zlabel('PC3');
            view(3);
        end
    end

    function perform_tsne(labels_for_color, num_dimensions, perplexity, learning_rate)
        disp(['t-SNE parametry: Perplexity=' num2str(perplexity) ', LearningRate=' num2str(learning_rate) ', NumDimensions=' num2str(num_dimensions)]);
        reduced = tsne(data.X, ...
            'NumDimensions', num_dimensions, ...
            'Perplexity', perplexity, ...
            'LearnRate', learning_rate);

        if num_dimensions == 2
            scatter(reduced(:,1), reduced(:,2), 20, labels_for_color, 'filled');
            title('t-SNE 2D');
            xlabel('Dim 1'); ylabel('Dim 2');
        elseif num_dimensions == 3
            scatter3(reduced(:,1), reduced(:,2), reduced(:,3), 20, labels_for_color, 'filled');
            title('t-SNE 3D');
            xlabel('Dim 1'); ylabel('Dim 2'); zlabel('Dim 3');
            view(3);
        end
    end

end
