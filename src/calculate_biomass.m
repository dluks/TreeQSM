qsm_dir = "location/of/qsms";
qsms = dir(fullfile(qsm_dir, "qsms/optimal", "OptimalQSMs*.mat"));

for i=1:size(qsms)

    if isempty(strfind(qsms(i).name, '0-1'))
        opt_qsms_all = load(fullfile(qsms(i).folder, qsms(i).name));

        diam = qsms(i).name(13:15);
        % Update this to the correct filename pattern
        shifts = load(fullfile(qsm_dir, "clouds", strcat("prefix_", diam, "_shifts.mat")));

        opt_qsms = opt_qsms_all.OptQSM;
        qsms_data = NaN(size(opt_qsms, 2), 5);
        for j=1:size(opt_qsms, 2)
            opt_qsm = opt_qsms(j);
            name = string(opt_qsms_all.TreeData(j).name);
            treedata = opt_qsm.treedata;

            shift = [shifts.(name)];
            location = treedata.location + shift;

            % Get volume from branches > 0.03 m
            branches = opt_qsm.branch;
            total_vol = 0;
            branch_vol = 0;
            for k=1:size(branches.diameter, 1)
                if branches.order(k) > 0 && branches.diameter(k) >= 0.03
                    branch_vol = branch_vol + branches.volume(k);
                end
            end
            
            total_vol = branch_vol + opt_qsm.treedata.TrunkVolume;
            biomass = total_vol * 0.626;

            tree.id = name;
            tree.easting = location(1);
            tree.northing = location(2);
            tree.elevation = location(3);
            tree.volume = total_vol;
            tree.biomass = biomass;

            if ~exist("trees")
                trees = tree;
            else
                trees = [trees, tree];
            end
        end
    end
end

T = struct2table(trees);
% Update the below output path according to your needs
writetable(T, "path/to/biomass.csv");
