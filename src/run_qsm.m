%% Load all point clouds and save in a single .mat file
data_dir = "../../../data/clouds/2023-03-30_full_plot/11_12/leafoff/las";
files = dir(fullfile(data_dir, "*.las"));
% Ps = cell(size(files, 1),1)
clear Ps

for i=1:size(files,1)
    las = lasFileReader(fullfile(data_dir, files(i).name));
    pcd = readPointCloud(las);
    P = pcd.Location;
    P = P - mean(P); % Apply global shift
    % Ps(i) = {P};
    tree_name = strsplit(files(i).name, ".");
    tree_name = tree_name(1);
    Ps.("ti_" + tree_name) = P;
end

save("trees", "-struct", "Ps")

%% Define the input parameters
create_input();
inputs = define_input('trees', 2, 3, 2)

%% Use |make_models| to produce QSMs
QSMs = make_models_parallel('trees', 'QSMs_trees', 2, inputs);

%% Select optimal QSMs
[TreeData, OptModels, OptInputs, OptQSM] = select_optimum(QSMs);

%% Estimate uncertainty more reliably
QSMs2 = make_models_parallel('trees', 'QSMs_trees2', 20, OptInputs);

[TreeData, OptQSMs, OptQSM] = estimate_precision(QSMs, QSMs2, TreeData, OptModels);