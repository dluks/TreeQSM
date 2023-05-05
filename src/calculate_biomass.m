qsms_dir = './results';
qsms = dir('./results/OptimalQSMs*.mat');

headings = {'biomass [g]', 'total volume [cm3]', 'x', 'y', 'z'};

data = [];

% for i=1:2
for i=1:size(qsms)

    if isempty(strfind(qsms(i).name, '0-1'))
        opt_qsms = load(fullfile(qsms(i).folder, qsms(i).name));
        opt_qsms = opt_qsms.OptQSM;
        qsms_data = NaN(size(opt_qsms, 2), 5);
        for j=1:size(opt_qsms, 2)
            opt_qsm = opt_qsms(j);
            treedata = opt_qsm.treedata;
            
            total_vol = treedata.TotalVolume;
            location = treedata.location;
            biomass = total_vol * 0.626;

            row = [biomass, total_vol, location(1), location(2), location(3)];
            qsms_data(j, :) = row;
        end
        data = [data; qsms_data];
    end
end

T = array2table(data, 'VariableNames', headings);
writetable(T, "../../../2019_FrenchGuiana/TLS_segmentation/tls2trees/qsm/paracou_biomass.csv");
