addpath(genpath("../src"));

num_models_1 = 5;
num_models_2 = 10;

%% Load all point clouds and save in a single .mat file
data_dir = "path/to/point/clouds";
odir = "path/to/output/directory";

dirs = dir(data_dir);

for i=1:size(dirs, 1)
    if dirs(i).isdir && (dirs(i).name ~= "." && dirs(i).name ~= ".." && dirs(i).name ~= "._.DS_Store")
        files = dir(fullfile(dirs(i).folder, dirs(i).name, "leafoff/csv/*.csv"));
        if size(files, 1) > 0
            disp(strcat("Processing directory '", dirs(i).name, "' with ", string(size(files, 1)), " trees"));
            clear Ps;
            clear shifts;
            for j=1:size(files, 1)
                P = readmatrix(fullfile(files(j).folder, files(j).name), 'NumHeaderLines', 1);
                P = P(:,1:3);
                shift = mean(P);
                P = P - shift; % Apply global shift
                tree_name = strsplit(files(j).name, ".");
                tree_name = tree_name(1);
                Ps.("ti_" + tree_name) = P;
                shifts.("ti_" + tree_name) = shift;
            end
            
            disp("Saving clouds .mat...");
            dir_label = strrep(dirs(i).name, ".", "-");
            cloud_name = strcat("paracou_", dir_label);
            cloud_file = fullfile(odir, cloud_name);
            save(cloud_file, "-struct", "Ps");
            
            disp("Saving global shifts...");
            shifts_file = fullfile(odir, strcat(cloud_name, "_shifts"));
            save(shifts_file, "-struct", "shifts");

            %% Define the input parameters
            disp("Defining input parameters...");
            create_input();
            inputs = define_input(cloud_name, 2, 3, 2);

            %% Use |make_models| to produce QSMs
            disp("Making models...")
            qsm_file = fullfile(odir, strcat("QSMs_", cloud_name));
            QSMs = make_models_parallel(cloud_file, qsm_file, num_models_1, inputs);

            %% Select optimal QSMs
            disp("Selecting optimal QSMs...");
            opt_qsm_file = fullfile(odir, strcat("OptimalQSMs_", cloud_name));
            [TreeData, OptModels, OptInputs, OptQSM] = select_optimum(QSMs, 'all_mean_dis', opt_qsm_file);
            
            %% Estimate uncertainty more reliably (this can take a while) (optional)
            % disp("Making models with optimal input parameters for uncertainty estimation...");
            % QSMs2 = make_models_parallel(cloud_name, strcat("QSMs_", dir_label, "_2"), num_models_2, OptInputs);

            % disp("Estimating precision...");
            % [TreeData, OptQSMs, OptQSM] = estimate_precision(QSMs, QSMs2, TreeData, OptModels, strcat(dir_label, "_2"));
        else
            disp(strcat("Skipped empty directory: ", dirs(i).name))
        end
    end
end
