addpath(genpath("../src"));
clear Ps;

num_models_1 = 5;
num_models_2 = 10;

%% Load all point clouds and save in a single .mat file
% data_dir = "../../../2019_FrenchGuiana/TLS_segmentation/tls2trees/clouds/2023-03-30_full_plot/*/leafoff/csv"
% files = dir(fullfile(data_dir, "*.csv"));
data_dir = "../../../2019_FrenchGuiana/TLS_segmentation/tls2trees/clouds/2023-03-30_full_plot";
dirs = dir(data_dir);

% for i=1:6
for i=1:size(dirs, 1)
    if dirs(i).isdir && (dirs(i).name ~= "." && dirs(i).name ~= ".." && dirs(i).name ~= "._.DS_Store")
        files = dir(fullfile(dirs(i).folder, dirs(i).name, "leafoff/csv/*.csv"));
        if size(files, 1) > 0
            disp(strcat("Processing directory '", dirs(i).name, "' with ", string(size(files, 1)), " trees"));
            % for j=1:2
            for j=1:size(files, 1)
                disp(strcat("Reading tree", files(j).name, "..."));
                % las = lasFileReader(fullfile(files(i).folder, files(i).name));
                % pcd = readPointCloud(las);
                % P = pcd.Location;
                P = readmatrix(fullfile(files(j).folder, files(j).name), 'NumHeaderLines', 1);
                P = P(:,1:3);
                P = P - mean(P); % Apply global shift
                tree_name = strsplit(files(j).name, ".");
                tree_name = tree_name(1);
                Ps.("ti_" + tree_name) = P;
            end
            
            disp("Saving clouds .mat...");
            qsm_name = strcat("paracou_", dirs(i).name);
            qsm_name = strrep(qsm_name,".","_");
            save(qsm_name, "-struct", "Ps");

            %% Define the input parameters
            disp("Defining input parameters...");
            create_input();
            inputs = define_input(qsm_name, 2, 3, 2);

            %% Use |make_models| to produce QSMs
            disp("Making models...")
            QSMs = make_models_parallel(qsm_name, strcat("QSMs_", dirs(i).name, "_1"), num_models_1, inputs);

            %% Select optimal QSMs
            disp("Selecting optimal QSMs...");
            [TreeData, OptModels, OptInputs, OptQSM] = select_optimum(QSMs, 'all_mean_dis', strcat(dirs(i).name, "_1"));
            % save("qsm1", "TreeData", "OptModels", "OptInputs", "OptQSM")

            %% Estimate uncertainty more reliably
            disp("Making models with optimal input parameters for uncertainty estimation...");
            QSMs2 = make_models_parallel(qsm_name, strcat("QSMs_", dirs(i).name, "_2"), num_models_2, OptInputs);

            disp("Estimating precision...");
            [TreeData, OptQSMs, OptQSM] = estimate_precision(QSMs, QSMs2, TreeData, OptModels, strcat(dirs(i).name, "_2"));
        else
            disp(strcat("Skipped empty directory: ", dirs(i).name))
        end
    end
end
