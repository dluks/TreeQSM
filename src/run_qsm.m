%% Load all point clouds and save in a single .mat file
data_dir = "../../../2019_FrenchGuiana/TLS_segmentation/tls2trees/clouds/2023-03-30_full_plot/*/leafoff/las";
files = dir(fullfile(data_dir, "*.las"));
clear Ps;

for i=1:size(files,1)
    las = lasFileReader(fullfile(files(i).folder, files(i).name));
    pcd = readPointCloud(las);
    P = pcd.Location;
    P = P - mean(P); % Apply global shift
    % Ps(i) = {P};
    tree_name = strsplit(files(i).name, ".");
    tree_name = tree_name(1);
    Ps.("ti_" + tree_name) = P;
end

save("paracou", "-struct", "Ps")

%% Define the input parameters
create_input();
inputs = define_input('paracou', 2, 3, 2)

%% Use |make_models| to produce QSMs
QSMs = make_models_parallel('paracou', 'QSMs_trees', 7, inputs, 'qsm_array_1');

%% Select optimal QSMs
[TreeData, OptModels, OptInputs, OptQSM] = select_optimum(QSMs, 'opt_qsm_1');
% save("qsm1", "TreeData", "OptModels", "OptInputs", "OptQSM")

%% Estimate uncertainty more reliably
QSMs2 = make_models_parallel('paracou', 'QSMs_trees2', 20, OptInputs, 'qsm_array_2');

[TreeData, OptQSMs, OptQSM] = estimate_precision(QSMs, QSMs2, TreeData, OptModels, 'opt_qsm_2');
