close all;
clear;
clc;

[fn, fp, index] = uigetfile('*.xlsx');
if index == 0
    disp('No file selected!');
else
    
    mkdir Plots
    mkdir Plots\Real
    mkdir Plots\CNR
    mkdir Plots\Direct
    mkdir Plots\Cypress
    mkdir Plots\Usage
    
    % load the table
    % load the fail device table
    healthMap = readtable(strcat(fp,fn), 'Sheet', "Health Map");
    failDev = readtable(strcat(fp,'failDevices.xlsx'), 'Format', 'auto');
    hm = [healthMap, failDev(1:height(healthMap), :)];
    % TotalBugs is inaccurate and should not be used!
    hm.TotalBugs(:) = 0;
    
    
    % define oepration cycle category, same as the health map
    cycles = categorical({'BasicOp','DPAudio','LEXUSB','LEXPwr',...
        'Link', 'REXPwr', 'REXDevice', 'LEXDP',...
        'REXDP', 'Standby', 'Restart', 'Shutdown',...
        'SideChannelCycle', 'RS232Cycle'});
    cycles = reordercats(cycles,...
        {'BasicOp','DPAudio','LEXUSB','LEXPwr',...
        'Link', 'REXPwr', 'REXDevice', 'LEXDP',...
        'REXDP', 'Standby', 'Restart', 'Shutdown',...
        'SideChannelCycle', 'RS232Cycle'});
    
    buildList = unique(hm.Build);
    buildTotalTestList = zeros(18,1);
    
    %% Real fail/CNRs/Cypress/Direct count per build
    
    % create lists for different category
    [buildFailCnt, buildCNRsCnt, buildCypressCnt, ...
     buildDirectCnt, buildTotalCnt, buildPassCnt] = ...
        deal(zeros(length(buildList),1));

    summaryLabel = categorical({'Real', 'CNR', 'Cypress','Direct'});
    summaryLabel = reordercats(summaryLabel, {'Real', 'CNR', 'Cypress','Direct'});

    % create lists for variable types
    varTypesCycle = string(zeros(14,1))';
    varTypesCycle(:) = 'double';
    varTypesHost = string(zeros(length(unique(hm.Host)),1))';
    varTypesHost(:) = 'double';
    
    % Fail count table for each cycle per build
    masterRealCntByCycle = table('Size', [length(buildList) 15],...
        'VariableTypes',['double', varTypesCycle],...
        'VariableNames', ['Build', hm.Properties.VariableNames(22:35)]);
    
    % loop through every builds
    for m = 1:length(buildList)
        buildFilter = hm.Build == buildList(m);
        bT = hm(buildFilter, :); % sub table by build
        bT.TotalBugs(:) = 0;
        
        % total test count per build
        buildTotalCnt(m,1) = sum(bT.TotalTests);
    
         %%%% Real count per build %%%%
        buildTotalReal = 0;
        
        
        % create Real counter table by cycle
        RealCntByCycle = table('Size', [1 14],...
            'VariableTypes',varTypesCycle,...
            'VariableNames', hm.Properties.VariableNames(22:35));
        
        % create Real counter table by host
        RealCntByHost = table('Size', [1 length(unique(hm.Host))],...
            'VariableTypes',varTypesHost,...
            'VariableNames', unique(hm.Host));
        
        % create zero array with the same height as the Build table
        RealFilter = zeros(height(bT),1);
        
        %%%%% Total Reals Break Down by Cycles in each Build %%%%%
        
        for n = bT.Properties.VariableNames(22:35)
            % x is a logical array with same height as build table
%             x = contains(bT.(char(n)), 'Real');
            cycleResultList = bT.(char(n));
            cycleRealCnt = 0;
            % loop through each cells in an operation cycle
            for x = 1:height(cycleResultList)
                % split the cell by commas
                curCell = strtrim(split(cycleResultList{x}, ','));
                % loop through the elements in the cell
                for y = 1:length(curCell)
                    % increment Real counter when a 'Real', 'Fail' or a bug number is found
                    if contains(curCell{y}, 'Real') ||...
                            contains(curCell{y}, 'Fail') ||...
                            ~isempty(str2num(curCell{y}))
                        cycleRealCnt = cycleRealCnt + 1;
                        % update Total bugs
                        bT.TotalBugs(x) = bT.TotalBugs(x) + 1;
                        % update logical real filter
                        RealFilter(x) = 1;
                    end
                end
            end
            RealCntByCycle.(char(n)) = cycleRealCnt;
            buildTotalReal = buildTotalReal + cycleRealCnt;
            % add the count to the according cycle
            buildFailCnt(m,1) =...
                buildFailCnt(m,1) + cycleRealCnt;
        end
        
        % add the build number and the final RealCntByCycle result to master table
        masterRealCntByCycle(m,1) = num2cell(buildList(m));
        masterRealCntByCycle(m, 2:end) = RealCntByCycle;
        
        barRealCycle = bar(cycles, table2array(RealCntByCycle(1,:)));
        % add labels to bar graph
        xtipsRealCycle = barRealCycle(1).XEndPoints;
        ytipsRealCycle = barRealCycle(1).YEndPoints;
        labelsRealCycle = string(barRealCycle(1).YData);
        text(xtipsRealCycle,ytipsRealCycle,labelsRealCycle,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Total Real Bugs');
        ylim([0 max(table2array(RealCntByCycle(1,:)))*1.2+0.1]);
        title(strcat(string(buildTotalReal), ' Total Real Bugs Break Down by Cycles in Build ', string(buildList(m))));
        saveas(barRealCycle, strcat(pwd,'\Plots\Real\', 'Total Real Bugs Break Down by Cycles in Build ', string(buildList(m)), '.png'));
        close(gcf);
       %% =============================== %
        
        %%%%% Total Reals Break Down by Hosts in each Build %%%%%
        RealBT = bT(logical(RealFilter), :);
        
        for n = 1:height(RealBT)
            % add the Total Bugs from each row to the according Host 
            RealCntByHost.(char(table2cell(RealBT(n,10)))) =...
                RealCntByHost.(char(table2cell(RealBT(n,10)))) + ...
                table2array(RealBT(n,20));
        end
        
        RealByHost = figure();
        barRealHost =  bar(categorical(unique(hm.Host)), table2array(RealCntByHost(1,:)));
        % add labels to bar graph
        xtipsRealHost = barRealHost(1).XEndPoints;
        ytipsRealHost = barRealHost(1).YEndPoints;
        labelsRealHost = string(barRealHost(1).YData);
        text(xtipsRealHost,ytipsRealHost,labelsRealHost,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Total Real Bugs');
        ylim([0 max(table2array(RealCntByHost(1,:)))*1.2+0.1]);
        title(strcat(string(buildTotalReal), ' Total Real Bugs Break Down by Host in Build ', string(buildList(m))));
        set(RealByHost,'position',[0,0,1920,1080]);
        saveas(barRealHost, strcat(pwd,'\Plots\Real\', 'Total Real Bugs Break Down by Host in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %
        
        %%%% CNR count per build %%%%
        buildTotalCNR = 0;
        
        % create CNR counter table by cycle
        cnrCntByCycle = table('Size', [1 14],...
            'VariableTypes',varTypesCycle,...
            'VariableNames', hm.Properties.VariableNames(22:35));
        
        % create CNR counter table by host
        cnrCntByHost = table('Size', [1 length(unique(hm.Host))],...
            'VariableTypes',varTypesHost,...
            'VariableNames', unique(hm.Host));
        
        % create zero array with the same height as the Build table
        cnrFilter = zeros(height(bT),1);
        
        %%%%% Total CNRs Break Down by Cycles in each Build %%%%%
        
        for n = bT.Properties.VariableNames(22:35)
            % x is a logical array with same height as build table
            x = contains(bT.(char(n)), 'CNR');
            cnrCntByCycle.(char(n)) = sum(x);
            buildTotalCNR = buildTotalCNR + sum(x);
            % add the count to the according cycle
            buildCNRsCnt(m,1) =...
                buildCNRsCnt(m,1) + sum(x);
            cnrFilter = cnrFilter | x;
        end
        
        barCNRCycle = bar(cycles, table2array(cnrCntByCycle(1,:)));
        % add labels to bar graph
        xtipsCNRCycle = barCNRCycle(1).XEndPoints;
        ytipsCNRCycle = barCNRCycle(1).YEndPoints;
        labelsCNRCycle = string(barCNRCycle(1).YData);
        text(xtipsCNRCycle,ytipsCNRCycle,labelsCNRCycle,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Total CNRs');
        ylim([0 max(table2array(cnrCntByCycle(1,:)))*1.2+0.1]);
        title(strcat(string(buildTotalCNR), ' Total CNRs Break Down by Cycles in Build ', string(buildList(m))));
        saveas(barCNRCycle, strcat(pwd,'\Plots\CNR\', 'Total CNRs Break Down by Cycles in Build ', string(buildList(m)), '.png'));
        close(gcf);
       %% =============================== %
        
        %%%%% Total CNRs Break Down by Hosts in each Build %%%%%
        cnrBT = bT(cnrFilter, :);
        
        for n = 1:height(cnrBT)
            % find how many times CNR occurs within a row
            x = sum(contains(table2cell(cnrBT(n, 22:35)), 'CNR'));
            % add the count to the according Host 
            cnrCntByHost.(char(table2cell(cnrBT(n,10)))) =...
                cnrCntByHost.(char(table2cell(cnrBT(n,10)))) + x;
        end
        
        cnrByHost = figure();
        barCNRHost =  bar(categorical(unique(hm.Host)), table2array(cnrCntByHost(1,:)));
        % add labels to bar graph
        xtipsCNRHost = barCNRHost(1).XEndPoints;
        ytipsCNRHost = barCNRHost(1).YEndPoints;
        labelsCNRHost = string(barCNRHost(1).YData);
        text(xtipsCNRHost,ytipsCNRHost,labelsCNRHost,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Total CNRs');
        ylim([0 max(table2array(cnrCntByHost(1,:)))*1.2+0.1]);
        title(strcat(string(buildTotalCNR), ' Total CNRs Break Down by Host in Build ', string(buildList(m))));
        set(cnrByHost,'position',[0,0,1920,1080]);
        saveas(barCNRHost, strcat(pwd,'\Plots\CNR\', 'Total CNRs Break Down by Host in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %
        %%%% Cypress count per build %%%%
        buildTotalCypress = 0;
        
        % create Cypress counter table by cycle
        cyCntByCycle = table('Size', [1 14],...
            'VariableTypes',varTypesCycle,...
            'VariableNames', hm.Properties.VariableNames(22:35));
        
        % create Cypress counter table by host
        cyCntByHost = table('Size', [1 length(unique(hm.Host))],...
            'VariableTypes',varTypesHost,...
            'VariableNames', unique(hm.Host));
        
        % create zero array with the same height as the Build table
        cyFilter = zeros(height(bT),1);
        
        %%%%% Total Cypress Break Down by Cycles in each Build %%%%%
        
        for n = bT.Properties.VariableNames(22:35)
            % x is a logical array with same height as build table
            x = contains(bT.(char(n)), 'Cypress');
            cyCntByCycle.(char(n)) = sum(x);
            buildTotalCypress = buildTotalCypress + sum(x);
            % add the count to the according cycle
            buildCypressCnt(m,1) =...
                buildCypressCnt(m,1) + sum(x);
            cyFilter = cyFilter | x;
        end
        
        barCypressCycle = bar(cycles, table2array(cyCntByCycle(1,:)));
        % add labels to bar graph
        xtipsCypressCycle = barCypressCycle(1).XEndPoints;
        ytipsCypressCycle = barCypressCycle(1).YEndPoints;
        labelsCypressCycle = string(barCypressCycle(1).YData);
        text(xtipsCypressCycle,ytipsCypressCycle,labelsCypressCycle,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Total Cypress');
        ylim([0 max(table2array(cyCntByCycle(1,:)))*1.2+0.1]);
        title(strcat(string(buildTotalCypress), ' Total Cypress Issues Break Down by Cycles in Build ', string(buildList(m))));
        saveas(barCypressCycle, strcat(pwd,'\Plots\Cypress\', 'Total Cypress Issues Break Down by Cycles in Build ', string(buildList(m)), '.png'));
        close(gcf);
       %% =============================== %
        
        %%%%% Total Cypress Break Down by Hosts in each Build %%%%%
        cyBT = bT(cyFilter, :);
        
        for n = 1:height(cyBT)
            % find how many times Cypress occurs within a row
            x = sum(contains(table2cell(cyBT(n, 22:35)), 'Cypress'));
            % add the count to the according Host 
            cyCntByHost.(char(table2cell(cyBT(n,10)))) =...
                cyCntByHost.(char(table2cell(cyBT(n,10)))) + x;
        end
        
        cyByHost = figure();
        barCypressHost =  bar(categorical(unique(hm.Host)), table2array(cyCntByHost(1,:)));
        % add labels to bar graph
        xtipsCypressHost = barCypressHost(1).XEndPoints;
        ytipsCypressHost = barCypressHost(1).YEndPoints;
        labelsCypressHost = string(barCypressHost(1).YData);
        text(xtipsCypressHost,ytipsCypressHost,labelsCypressHost,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Total Cypress');
        ylim([0 max(table2array(cyCntByHost(1,:)))*1.2+0.1]);
        title(strcat(string(buildTotalCypress), ' Total Cypress Issues Break Down by Host in Build ', string(buildList(m))));
        set(cyByHost,'position',[0,0,1920,1080]);
        saveas(barCypressHost, strcat(pwd,'\Plots\Cypress\', 'Total Cypress Issues Break Down by Host in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %
        %%%% Direct count per build %%%%
        buildTotalDirect = 0;
        
        % create Direct counter table by cycle
        dirCntByCycle = table('Size', [1 14],...
            'VariableTypes',varTypesCycle,...
            'VariableNames', hm.Properties.VariableNames(22:35));
        
        % create Direct counter table by host
        drCntByHost = table('Size', [1 length(unique(hm.Host))],...
            'VariableTypes',varTypesHost,...
            'VariableNames', unique(hm.Host));
        
        % create zero array with the same height as the Build table
        dirFilter = zeros(height(bT),1);
        
        %%%%% Total Direct Break Down by Cycles in each Build %%%%%
        
        for n = bT.Properties.VariableNames(22:35)
            % x is a logical array with same height as build table
            x = contains(bT.(char(n)), 'Direct');
            dirCntByCycle.(char(n)) = sum(x);
            buildTotalDirect = buildTotalDirect + sum(x);
            % add the count to the according cycle
            buildDirectCnt(m,1) =...
                buildDirectCnt(m,1) + sum(x);
            dirFilter = dirFilter | x;
        end
        
        barDirectCycle = bar(cycles, table2array(dirCntByCycle(1,:)));
        % add labels to bar graph
        xtipsDirectCycle = barDirectCycle(1).XEndPoints;
        ytipsDirectCycle = barDirectCycle(1).YEndPoints;
        labelsDirectCycle = string(barDirectCycle(1).YData);
        text(xtipsDirectCycle,ytipsDirectCycle,labelsDirectCycle,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Total Direct');
        ylim([0 max(table2array(dirCntByCycle(1,:)))*1.2+0.1]);
        title(strcat(string(buildTotalDirect), ' Total Direct Issues Break Down by Cycles in Build ', string(buildList(m))));
        saveas(barDirectCycle, strcat(pwd,'\Plots\Direct\', 'Total Direct Issues Break Down by Cycles in Build ', string(buildList(m)), '.png'));
        close(gcf);
       %% =============================== %
        
        %%%%% Total Directs Break Down by Hosts in each Build %%%%%
        dirBT = bT(dirFilter, :);
        
        for n = 1:height(dirBT)
            % find how many times Direct occurs within a row
            x = sum(contains(table2cell(dirBT(n, 22:35)), 'Direct'));
            % add the count to the according Host 
            drCntByHost.(char(table2cell(dirBT(n,10)))) =...
                drCntByHost.(char(table2cell(dirBT(n,10)))) + x;
        end
        
        drByHost = figure();
        barDirectHost =  bar(categorical(unique(hm.Host)), table2array(drCntByHost(1,:)));
        % add labels to bar graph
        xtipsDirectHost = barDirectHost(1).XEndPoints;
        ytipsDirectHost = barDirectHost(1).YEndPoints;
        labelsDirectHost = string(barDirectHost(1).YData);
        text(xtipsDirectHost,ytipsDirectHost,labelsDirectHost,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Total Direct');
        ylim([0 max(table2array(drCntByHost(1,:)))*1.2+0.1]);
        title(strcat(string(buildTotalDirect), ' Total Direct Issues Break Down by Host in Build ', string(buildList(m))));
        set(drByHost,'position',[0,0,1920,1080]);
        saveas(barDirectHost, strcat(pwd,'\Plots\Direct\', 'Total Direct Issues Break Down by Host in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %        
        % curBuildTotalTest = buildTotalCnt(buildList(m) - min(buildList) + 1,1);
        curBuildTotalTest = buildTotalCnt(m,1);
        buildTotalTestList(m) = curBuildTotalTest;
        
        buildPassCnt(m,1) = buildTotalCnt(m,1) - buildDirectCnt(m,1) -...
                            buildCypressCnt(m,1) - buildCNRsCnt(m,1) - buildFailCnt(m,1);
        %% =============================== %
        
        % Test failure summary plot per build
        summaryData = [buildFailCnt(m,1) ...
            buildCNRsCnt(m,1) ...
            buildCypressCnt(m,1) ...
            buildDirectCnt(m,1)];
        
        summaryBar = bar(summaryLabel, summaryData, 'facecolor', 'flat');
        
        % set bar color
        summaryBar.CData = [0 114 189;
                            217 83 25;
                            237 177 32;
                            126 47 142] / 255;
        
        % add labels to bar graph
        xtipsSummary = summaryBar(1).XEndPoints;
        ytipsSummary = summaryBar(1).YEndPoints;
        labelsSummary = string(summaryBar(1).YData) +...
                        " (" +...
                        string(round(summaryBar(1).YData/curBuildTotalTest * 100, 2)) +...
                        '%)';
        text(xtipsSummary,ytipsSummary,labelsSummary,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        xlabel('Failure Type');
        ylabel('Count');
        ylim([0 max(summaryData)*1.2+0.1]);
        t_summary = ['Build', string(buildList(m)), ' Test Summary - ',...
             buildTotalCnt(m,1), ' Total Tests'];
        title(join(t_summary,''));
        saveas(gcf, join([pwd,'\Plots\', t_summary, '.png'],''));
        close(gcf);
        % ==================== %
        
        % Test failure summary plot per build on percentage
        summaryDataPercent = round(summaryData/curBuildTotalTest * 100, 2);
        
        summaryPCBar = bar(summaryLabel, summaryDataPercent, 'facecolor', 'flat');
        
        % set bar color
        summaryPCBar.CData = [0 114 189;
                              217 83 25;
                              237 177 32;
                              126 47 142] / 255;
        
        % add labels to bar graph
        xtipsSummaryPC = summaryPCBar(1).XEndPoints;
        ytipsSummaryPC = summaryPCBar(1).YEndPoints;
        labelsSummaryPC = string(summaryPCBar(1).YData + "%");
        text(xtipsSummaryPC,ytipsSummaryPC,labelsSummaryPC,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        xlabel('Failure Type');
        ylabel('Percentage (%)');
        ylim([0 max(summaryDataPercent)*1.2+0.1]);
        t_summaryPC = ['Build', string(buildList(m)), ' Test Summary on Percentage - ',...
             buildTotalCnt(m,1), ' Total Tests'];
        title(join(t_summaryPC,''));
        saveas(gcf, join([pwd,'\Plots\', t_summaryPC, '.png'],''));
        close(gcf);
        
        
        % Test failure summary pie plot per build on percentage
        piesummaryLabel = {'Real', 'CNR', 'Cypress', 'Direct'};
        
        summaryDataPercentR = string(piesummaryLabel) +...
                              ': ' +...
                              string(round(summaryDataPercent, 2)) + '%';

        summaryPCPie = figure();
        pie(summaryDataPercent,[1 0 1 0], summaryDataPercentR);
        legend(piesummaryLabel, 'location', 'southeastoutside');
        
        colormap([0 114 189;
                  217 83 25;
                  237 177 32;
                  126 47 142] / 255);   
        title(join(t_summaryPC,''));
%         set(findobj(summaryPCPie,'type','text'),'fontsize',9);
        set(summaryPCPie,'position',[0,0,1920,1080]);
        saveas(gcf, join([pwd,'\Plots\', t_summaryPC, '_pie','.png'],''));
        close(gcf);
        
        %% =============================== %
        
        % DUTs used in test per Build
        
        tDUTs = table(vertcat(bT.DUT1, bT.DUT2, bT.DUT3, bT.DUT4));
        G_tDUTs = groupsummary(tDUTs, 'Var1');
        % remove the empty DUT denoted by '-'
        if strcmp(table2cell(G_tDUTs(1,1)), '-')
            G_tDUTs(1,:) = [];
        end
        
        DUTsUsed = figure();
        barDUTsUsed =  bar(categorical(G_tDUTs.Var1), G_tDUTs.GroupCount);
        % add labels to bar graph
        xtipsDUTsUsed = barDUTsUsed(1).XEndPoints;
        ytipsDUTsUsed = barDUTsUsed(1).YEndPoints;
        labelsDUTsUsed = string(barDUTsUsed(1).YData);
        text(xtipsDUTsUsed,ytipsDUTsUsed,labelsDUTsUsed,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('DUT Count');
        if isempty(G_tDUTs.GroupCount)
            ylim([0 0.1]);
        else
            ylim([0 max(G_tDUTs.GroupCount)*1.2+0.1]);
        end
        title(strcat('DUTs Used in Build ', string(buildList(m))));
        set(DUTsUsed,'position',[0,0,1920,1080]);
        saveas(gcf, strcat(pwd,'\Plots\Usage\', 'DUTs Used in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %
        
        % DUT1 used in test per Build
        
        G_DUT1 = groupsummary(bT, 'DUT1');
        % remove the empty DUT denoted by '-'
        if strcmp(table2cell(G_DUT1(1,1)), '-')
            G_DUT1(1,:) = [];
        end
        
        DUT1Used = figure();
        barDUT1Used =  bar(categorical(G_DUT1.DUT1), G_DUT1.GroupCount);
        % add labels to bar graph
        xtipsDUT1Used = barDUT1Used(1).XEndPoints;
        ytipsDUT1Used = barDUT1Used(1).YEndPoints;
        labelsDUT1Used = string(barDUT1Used(1).YData);
        text(xtipsDUT1Used,ytipsDUT1Used,labelsDUT1Used,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('DUT Count');
        if isempty(G_DUT1.GroupCount)
            ylim([0 0.1]);
        else
            ylim([0 max(G_DUT1.GroupCount)*1.2+0.1]);
        end
        title(strcat('Port 1 DUT Usage in Build ', string(buildList(m))));
        set(DUT1Used,'position',[0,0,1920,1080]);
        saveas(gcf, strcat(pwd,'\Plots\Usage\', 'Port 1 DUT Usage in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %
        
        % DUT2 used in test per Build
        
        G_DUT2 = groupsummary(bT, 'DUT2');
        % remove the empty DUT denoted by '-'
        if strcmp(table2cell(G_DUT2(1,1)), '-')
            G_DUT2(1,:) = [];
        end
        
        DUT2Used = figure();
        barDUT2Used =  bar(categorical(G_DUT2.DUT2), G_DUT2.GroupCount);
        % add labels to bar graph
        xtipsDUT2Used = barDUT2Used(1).XEndPoints;
        ytipsDUT2Used = barDUT2Used(1).YEndPoints;
        labelsDUT2Used = string(barDUT2Used(1).YData);
        text(xtipsDUT2Used,ytipsDUT2Used,labelsDUT2Used,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('DUT Count');
        if isempty(G_DUT2.GroupCount)
            ylim([0 0.1]);
        else
            ylim([0 max(G_DUT2.GroupCount)*1.2+0.1]);
        end
        title(strcat('Port 2 DUT Usage in Build ', string(buildList(m))));
        set(DUT2Used,'position',[0,0,1920,1080]);
        saveas(gcf, strcat(pwd,'\Plots\Usage\', 'Port 2 DUT Usage in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %
        
        % DUT3 used in test per Build
        
        G_DUT3 = groupsummary(bT, 'DUT3');
        % remove the empty DUT denoted by '-'
        if strcmp(table2cell(G_DUT3(1,1)), '-')
            G_DUT3(1,:) = [];
        end
        
        DUT3Used = figure();
        barDUT3Used =  bar(categorical(G_DUT3.DUT3), G_DUT3.GroupCount);
        % add labels to bar graph
        xtipsDUT3Used = barDUT3Used(1).XEndPoints;
        ytipsDUT3Used = barDUT3Used(1).YEndPoints;
        labelsDUT3Used = string(barDUT3Used(1).YData);
        text(xtipsDUT3Used,ytipsDUT3Used,labelsDUT3Used,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('DUT Count');
        if isempty(G_DUT3.GroupCount)
            ylim([0 0.1]);
        else
            ylim([0 max(G_DUT3.GroupCount)*1.2+0.1]);
        end
        title(strcat('Port 3 DUT Usage in Build ', string(buildList(m))));
        set(DUT3Used,'position',[0,0,1920,1080]);
        saveas(gcf, strcat(pwd,'\Plots\Usage\', 'Port 3 DUT Usage in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %
        
        % DUT4 used in test per Build
        
        G_DUT4 = groupsummary(bT, 'DUT4');
        % remove the empty DUT denoted by '-'
        if strcmp(table2cell(G_DUT4(1,1)), '-')
            G_DUT4(1,:) = [];
        end
        
        DUT4Used = figure();
        barDUT4Used =  bar(categorical(G_DUT4.DUT4), G_DUT4.GroupCount);
        % add labels to bar graph
        xtipsDUT4Used = barDUT4Used(1).XEndPoints;
        ytipsDUT4Used = barDUT4Used(1).YEndPoints;
        labelsDUT4Used = string(barDUT4Used(1).YData);
        text(xtipsDUT4Used,ytipsDUT4Used,labelsDUT4Used,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('DUT Count');
        if isempty(G_DUT4.GroupCount)
            ylim([0 0.1]);
        else
            ylim([0 max(G_DUT4.GroupCount)*1.2+0.1]);
        end
        title(strcat('Port 4 DUT Usage in Build ', string(buildList(m))));
        set(DUT4Used,'position',[0,0,1920,1080]);
        saveas(gcf, strcat(pwd,'\Plots\Usage\', 'Port 4 DUT Usage in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %
        
        % Monitor used in test per Build
        
        G_monitor = groupsummary(bT, 'Monitor');
        % remove the empty DUT denoted by '-'
        if strcmp(table2cell(G_monitor(1,1)), '-')
            G_monitor(1,:) = [];
        end
        
        monitorUsed = figure();
        barMonitorUsed =  bar(categorical(G_monitor.Monitor), G_monitor.GroupCount);
        % add labels to bar graph
        xtipsMonitorUsed = barMonitorUsed(1).XEndPoints;
        ytipsMonitorUsed = barMonitorUsed(1).YEndPoints;
        labelsMonitorUsed = string(barMonitorUsed(1).YData);
        text(xtipsMonitorUsed,ytipsMonitorUsed,labelsMonitorUsed,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Monitor Count');
        if isempty(G_monitor.GroupCount)
            ylim([0 0.1]);
        else
            ylim([0 max(G_monitor.GroupCount)*1.2+0.1]);
        end
        title(strcat('Monitor Usage in Build ', string(buildList(m))));
        set(monitorUsed,'position',[0,0,1920,1080]);
        saveas(gcf, strcat(pwd,'\Plots\Usage\', 'Monitor Usage in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %
        
        % Switch used in test per Build
        
        G_switch = groupsummary(bT, 'Switch');
        % remove the empty DUT denoted by '-'
        if strcmp(table2cell(G_switch(1,1)), '-')
            G_switch(1,:) = [];
        end
        
        switchUsed = figure();
        barSwitchUsed =  bar(categorical(G_switch.Switch), G_switch.GroupCount);
        % add labels to bar graph
        xtipsSwitchUsed = barSwitchUsed(1).XEndPoints;
        ytipsSwitchUsed = barSwitchUsed(1).YEndPoints;
        labelsSwitchUsed = string(barSwitchUsed(1).YData);
        text(xtipsSwitchUsed,ytipsSwitchUsed,labelsSwitchUsed,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Switch Count');
        if isempty(G_switch.GroupCount)
            ylim([0 0.1]);
        else
            ylim([0 max(G_switch.GroupCount)*1.2+0.1]);
        end
        title(strcat('Switch Usage in Build ', string(buildList(m))));
        set(switchUsed,'position',[0,0,1920,1080]);
        saveas(gcf, strcat(pwd,'\Plots\Usage\', 'Switch Usage in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %
        
        % Host used in test per Build
        
        G_Host = groupsummary(bT, 'Host');
        % remove the empty DUT denoted by '-'
        if strcmp(table2cell(G_Host(1,1)), '-')
            G_Host(1,:) = [];
        end
        
        hostUsed = figure();
        barHostUsed =  bar(categorical(G_Host.Host), G_Host.GroupCount);
        % add labels to bar graph
        xtipsHostUsed = barHostUsed(1).XEndPoints;
        ytipsHostUsed = barHostUsed(1).YEndPoints;
        labelsHostUsed = string(barHostUsed(1).YData);
        text(xtipsHostUsed,ytipsHostUsed,labelsHostUsed,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Host Count');
        if isempty(G_Host.GroupCount)
            ylim([0 0.1]);
        else
            ylim([0 max(G_Host.GroupCount)*1.2+0.1]);
        end
        title(strcat('Host Usage in Build ', string(buildList(m))));
        set(hostUsed,'position',[0,0,1920,1080]);
        saveas(gcf, strcat(pwd,'\Plots\Usage\', 'Host Usage in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %
        
        % Fail counts in Port 1,2,3,4 per build
        
        G_fail_DUT1 = groupsummary(bT, 'fail_DUT1');
        G_fail_DUT2 = groupsummary(bT, 'fail_DUT2');
        G_fail_DUT3 = groupsummary(bT, 'fail_DUT3');
        G_fail_DUT4 = groupsummary(bT, 'fail_DUT4');
        % remove the empty DUT denoted by '0'
        if strcmp(table2cell(G_fail_DUT1(1,1)), '0')
            G_fail_DUT1(1,:) = [];
        end
        
        if strcmp(table2cell(G_fail_DUT2(1,1)), '0')
            G_fail_DUT2(1,:) = [];
        end
        
        if strcmp(table2cell(G_fail_DUT3(1,1)), '0')
            G_fail_DUT3(1,:) = [];
        end
        
        if strcmp(table2cell(G_fail_DUT4(1,1)), '0')
            G_fail_DUT4(1,:) = [];
        end
        
        % create a list with the fail count in each port
        failDUTsPortStat = [sum(G_fail_DUT1.GroupCount), sum(G_fail_DUT2.GroupCount),...
            sum(G_fail_DUT3.GroupCount), sum(G_fail_DUT4.GroupCount)];
        
        failDUTsPortStats = figure();
        barfailDUTsPortStats =  bar(categorical({'Port 1';'Port 2';'Port 3';'Port 4'}), failDUTsPortStat);
        % add labels to bar graph
        xtipsfailDUTsPortStats = barfailDUTsPortStats(1).XEndPoints;
        ytipsfailDUTsPortStats = barfailDUTsPortStats(1).YEndPoints;
        labelsfailDUTsPortStats = string(barfailDUTsPortStats(1).YData);
        text(xtipsfailDUTsPortStats,ytipsfailDUTsPortStats,labelsfailDUTsPortStats,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Fail Count');
        if ~any(failDUTsPortStat) % check if the list is not all zeros
            ylim([0 0.1]);
        else
            ylim([0 max(failDUTsPortStat)*1.2]);
        end
        title(strcat('Fail Count in each Port in Build ', string(buildList(m))));
        saveas(gcf, strcat(pwd,'\Plots\Real\', 'Fail Count in each Port in Build ', string(buildList(m)), '.png'));
        close(gcf);
        %% =============================== %
        
        % monitor with fails count per Build
        
        G_fail_monitor = groupsummary(RealBT, 'fail_Monitor');
        % remove the empty Monitor denoted by '0'
        if strcmp(table2cell(G_fail_monitor(1,1)), '0')
            G_fail_monitor(1,:) = [];
        end
        
        if isempty(G_fail_monitor)
            bar(0,0);
            title(strcat('No Monitor Fail in Build ', string(buildList(m))));
            saveas(gcf, strcat(pwd,'\Plots\Real\', 'No Monitor Fail in Build ', string(buildList(m)), '.png'));
            close(gcf);
        else
            failMonitorStat = figure();
            barfailMonitorStat = bar(categorical(G_fail_monitor.fail_Monitor), G_fail_monitor.GroupCount);
            % add labels to bar graph
            xtipsfailMonitorStat = barfailMonitorStat(1).XEndPoints;
            ytipsfailMonitorStat = barfailMonitorStat(1).YEndPoints;
            labelsfailMonitorStat = string(barfailMonitorStat(1).YData);
            text(xtipsfailMonitorStat,ytipsfailMonitorStat,labelsfailMonitorStat,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom')
            ylabel('Fail Count');
            ylim([0 max(G_fail_monitor.GroupCount)*1.2]);
            title(strcat('Fail Monitor in Build ', string(buildList(m))));
            saveas(gcf, strcat(pwd,'\Plots\Real\', 'Fail Monitor in Build ', string(buildList(m)), '.png'));
            close(gcf);
        end
        %% =============================== %
                
        % Ethernet Side Channel with fails count per Build
        
        G_fail_EthernetSideChannel = groupsummary(RealBT, 'fail_EthernetSideChannel');
        % remove the empty Monitor denoted by '0'
        if strcmp(table2cell(G_fail_EthernetSideChannel(1,1)), '0')
            G_fail_EthernetSideChannel(1,:) = [];
        end
        
        if isempty(G_fail_EthernetSideChannel)
            bar(0,0);
            title(strcat('No Side Channel Fail in Build ', string(buildList(m))));
            saveas(gcf, strcat(pwd,'\Plots\Real\', 'No Side Channel Fail in Build ', string(buildList(m)), '.png'));
            close(gcf);
        else
            failSideChannelStat = figure();
            barfailSideChannelStat = bar(categorical(G_fail_EthernetSideChannel.fail_EthernetSideChannel), G_fail_EthernetSideChannel.GroupCount);
            % add labels to bar graph
            xtipsfailSideChannelStat = barfailSideChannelStat(1).XEndPoints;
            ytipsfailSideChannelStat = barfailSideChannelStat(1).YEndPoints;
            labelsfailSideChannelStat = string(barfailSideChannelStat(1).YData);
            text(xtipsfailSideChannelStat,ytipsfailSideChannelStat,labelsfailSideChannelStat,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom')
            ylabel('Fail Count');
            ylim([0 max(G_fail_EthernetSideChannel.GroupCount)*1.2]);
            title(strcat('Fail Ethernet Side Channel in Build ', string(buildList(m))));
            saveas(gcf, strcat(pwd,'\Plots\Real\', 'Fail Ethernet Side Channel in Build ', string(buildList(m)), '.png'));
            close(gcf);
        end
        %% =============================== %
        
        % RS232 with fails count per Build
        
        G_fail_RS232 = groupsummary(RealBT, 'fail_RS232');
        % remove the empty Monitor denoted by '0'
        if G_fail_RS232{1,1} == 0
            G_fail_RS232(1,:) = [];
        end
        
        if isempty(G_fail_RS232)
            bar(0,0);
            title(strcat('No RS232 Fail in Build ', string(buildList(m))));
            saveas(gcf, strcat(pwd,'\Plots\Real\', 'No RS232 Fail in Build ', string(buildList(m)), '.png'));
            close(gcf);
        else
            failRS232Stat = figure();
            barfailRS232Stat = bar(categorical(G_fail_RS232.fail_RS232), G_fail_RS232.GroupCount);
            % add labels to bar graph
            xtipsfailRS232Stat = barfailRS232Stat(1).XEndPoints;
            ytipsfailRS232Stat = barfailRS232Stat(1).YEndPoints;
            labelsfailRS232Stat = string(barfailRS232Stat(1).YData);
            text(xtipsfailRS232Stat,ytipsfailRS232Stat,labelsfailRS232Stat,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom')
            ylabel('Fail Count');
            ylim([0 max(G_fail_RS232.GroupCount)*1.2]);
            title(strcat('Fail RS232 in Build ', string(buildList(m))));
            saveas(gcf, strcat(pwd,'\Plots\Real\', 'Fail RS232 in Build ', string(buildList(m)), '.png'));
            close(gcf);
        end
        %% =============================== %
        
        % DUTs with fails count per Build
        
        % verticlly merge DUT 1,2,3,4 tables
        if isempty(G_fail_DUT1)
            G_fail_DUT1 = table('Size', [0,2], 'VariableNames',{'DUTs','GroupCount'}, 'VariableTypes', {'string', 'double'});
        else
            G_fail_DUT1 = renamevars(G_fail_DUT1, {'fail_DUT1', 'GroupCount'}, {'DUTs', 'GroupCount'});
        end
        if isempty(G_fail_DUT2)
            G_fail_DUT2 = table('Size', [0,2], 'VariableNames',{'DUTs','GroupCount'}, 'VariableTypes', {'string', 'double'});
        else
            G_fail_DUT2 = renamevars(G_fail_DUT2, {'fail_DUT2', 'GroupCount'}, {'DUTs', 'GroupCount'});
        end
        if isempty(G_fail_DUT3)
            G_fail_DUT3 = table('Size', [0,2], 'VariableNames',{'DUTs','GroupCount'}, 'VariableTypes', {'string', 'double'});
        else
            G_fail_DUT3 = renamevars(G_fail_DUT3, {'fail_DUT3', 'GroupCount'}, {'DUTs', 'GroupCount'});
        end
        if isempty(G_fail_DUT4)
            G_fail_DUT4 = table('Size', [0,2], 'VariableNames',{'DUTs','GroupCount'}, 'VariableTypes', {'string', 'double'});
        else
            G_fail_DUT4 = renamevars(G_fail_DUT4, {'fail_DUT4', 'GroupCount'}, {'DUTs', 'GroupCount'});
        end
        G_fail_DUTs = vertcat(G_fail_DUT1, G_fail_DUT2, G_fail_DUT3, G_fail_DUT4);
        
        % group summary again
        G_fail_DUTs = groupsummary(G_fail_DUTs, 'DUTs', 'sum');
        
        if isempty(G_fail_DUTs)
            bar(0,0);
            title(strcat('No DUT Fail in Build ', string(buildList(m))));
            saveas(gcf, strcat(pwd,'\Plots\Real\', 'No DUT Fail in Build ', string(buildList(m)), '.png'));
            close(gcf);
        else
            failDUTsStat = figure();
            barfailDUTsStat = bar(categorical(G_fail_DUTs.DUTs), G_fail_DUTs.sum_GroupCount);
            % add labels to bar graph
            xtipsfailDUTsStat = barfailDUTsStat(1).XEndPoints;
            ytipsfailDUTsStat = barfailDUTsStat(1).YEndPoints;
            labelsfailDUTsStat = string(barfailDUTsStat(1).YData);
            text(xtipsfailDUTsStat,ytipsfailDUTsStat,labelsfailDUTsStat,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom')
            ylabel('Fail Count');
            ylim([0 max(G_fail_DUTs.sum_GroupCount)*1.2]);
            title(strcat('Fail DUTs in Build ', string(buildList(m))));
            set(failDUTsStat,'position',[0,0,1920,1080]);
            saveas(failDUTsStat, strcat(pwd,'\Plots\Real\', 'Fail DUTs in Build ', string(buildList(m)), '.png'));
            close(failDUTsStat);
        end
        
    end
    
    % grouped build failure summary
    buildSummary = [buildFailCnt, buildCNRsCnt, buildCypressCnt, buildDirectCnt];
    
    sumfig = figure();
    summaryBar = bar(categorical(buildList), buildSummary, 'grouped');
    legend(summaryLabel);
    % add labels to bar graph
    xtipsSum1 = summaryBar(1).XEndPoints;
    ytipsSum1 = summaryBar(1).YEndPoints;
    labelsSum1 = string(summaryBar(1).YData);
    text(xtipsSum1,ytipsSum1,labelsSum1,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    
    xtipsSum2 = summaryBar(2).XEndPoints;
    ytipsSum2 = summaryBar(2).YEndPoints;
    labelsSum2 = string(summaryBar(2).YData);
    text(xtipsSum2,ytipsSum2,labelsSum2,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    
    xtipsSum3 = summaryBar(3).XEndPoints;
    ytipsSum3 = summaryBar(3).YEndPoints;
    labelsSum3 = string(summaryBar(3).YData);
    text(xtipsSum3,ytipsSum3,labelsSum3,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    
    xtipsSum4 = summaryBar(4).XEndPoints;
    ytipsSum4 = summaryBar(4).YEndPoints;
    labelsSum4 = string(summaryBar(4).YData);
    text(xtipsSum4,ytipsSum4,labelsSum4,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    
    xlabel('Build');
    ylabel('Fails');
    ylim([0 max(buildSummary, [], 'all')*1.2+0.1]);
    title('Test Failure Summary per Build');
    % set position and resolution
    set(sumfig,'position',[0,0,1920,1080]);
    saveas(sumfig, strcat(pwd,'\Plots\','Test Failure Summary per Build.png'));
    close(sumfig);
    
    % ================== %
    
    % grouped build failure summary on percentage
    buildSummaryPC = [buildFailCnt, buildCNRsCnt, buildCypressCnt, buildDirectCnt] ./ buildTotalTestList * 100;
    buildSummaryPC = round(buildSummaryPC, 1); %round the percentage
    
    sumPCfig = figure();
    summaryPCBar = bar(categorical(buildList), buildSummaryPC, 'grouped');
    legend(summaryLabel);
    % add labels to bar graph
    xtipsSum1PC = summaryPCBar(1).XEndPoints;
    ytipsSum1PC = summaryPCBar(1).YEndPoints;
    labelsSum1PC = string(summaryPCBar(1).YData);
    text(xtipsSum1PC,ytipsSum1PC,labelsSum1PC,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom',...
        'FontSize', 7);
    
    xtipsSum2PC = summaryPCBar(2).XEndPoints;
    ytipsSum2PC = summaryPCBar(2).YEndPoints;
    labelsSum2PC = string(summaryPCBar(2).YData);
    text(xtipsSum2PC,ytipsSum2PC,labelsSum2PC,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom',...
        'FontSize', 7);
    
    xtipsSum3PC = summaryPCBar(3).XEndPoints;
    ytipsSum3PC = summaryPCBar(3).YEndPoints;
    labelsSum3PC = string(summaryPCBar(3).YData);
    text(xtipsSum3PC,ytipsSum3PC,labelsSum3PC,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom',...
        'FontSize', 7);
    
    xtipsSum4PC = summaryPCBar(4).XEndPoints;
    ytipsSum4PC = summaryPCBar(4).YEndPoints;
    labelsSum4PC = string(summaryPCBar(4).YData);
    text(xtipsSum4PC,ytipsSum4PC,labelsSum4PC,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom',...
        'FontSize', 7);
    
    xlabel('Build');
    ylabel('Percentage (%)');
    ylim([0 max(buildSummaryPC, [], 'all')*1.2+0.1]);
    title('Test Failure Summary per Build on Percentage');
    % set position and resolution
    set(sumPCfig,'position',[0,0,1920,1080]);
    saveas(sumPCfig, strcat(pwd,'\Plots\','Test Failure Summary per Build on Percentage.png'));
    %close(sumPCfig);
    
    
    
    %% =============================== %
    
    % plot real fails count per build
    realCntBar = bar(categorical(buildList), buildFailCnt, 'facecolor', 'flat');
    
    % set bar color
    realCntBar.CData = [0 114 189] / 255;
    
    % add labels to bar graph
    xtipsRealCnt = realCntBar(1).XEndPoints;
    ytipsRealCnt = realCntBar(1).YEndPoints;
    labelsRealCnt = string(realCntBar(1).YData);
    text(xtipsRealCnt,ytipsRealCnt,labelsRealCnt,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    xlabel('Build');
    ylabel('Fails');
    ylim([0 max(buildFailCnt)*1.2+0.1]);
    title('Real Issue');
    % set position and resolution
    set(gcf,'position',[0,0,1920,1080]);
    saveas(gcf, strcat(pwd,'\Plots\','Real Issue.png'));
    close(gcf);
    %=====================%
    
    % plot real fails count per build on Percentage
    buildFailCntPC = buildFailCnt ./ buildTotalTestList * 100;
    realCntBarPC = bar(categorical(buildList), buildFailCntPC, 'facecolor', 'flat');
    
    % set bar color
    realCntBarPC.CData = [0 114 189] / 255;
    
    % add labels to bar graph
    xtipsRealCntPC = realCntBarPC(1).XEndPoints;
    ytipsRealCntPC = realCntBarPC(1).YEndPoints;
    labelsRealCntPC = string(realCntBarPC(1).YData);
    text(xtipsRealCntPC,ytipsRealCntPC,labelsRealCntPC,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    xlabel('Build');
    ylabel('Percentage (%)');
    ylim([0 max(buildFailCntPC)*1.2+0.1]);
    title('Real Issue on Percentage');
    % set position and resolution
    set(gcf,'position',[0,0,1920,1080]);
    saveas(gcf, strcat(pwd,'\Plots\','Real Issue on Percentage.png'));
    close(gcf);
    %% =============================== %
    
    % plot CNR count per build
    cnrCntBar = bar(categorical(buildList), buildCNRsCnt, 'facecolor', 'flat');
    
    % set bar color
    cnrCntBar.CData = [217 83 25] / 255;
    
    % add labels to bar graph
    xtipsCNRCnt = cnrCntBar(1).XEndPoints;
    ytipsCNRCnt = cnrCntBar(1).YEndPoints;
    labelsCNRCnt = string(cnrCntBar(1).YData);
    text(xtipsCNRCnt,ytipsCNRCnt,labelsCNRCnt,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    xlabel('Build');
    ylabel('Fails');
    ylim([0 max(buildCNRsCnt)*1.2+0.1]);
    title('CNR Issue');
    % set position and resolution
    set(gcf,'position',[0,0,1920,1080]);
    saveas(gcf, strcat(pwd,'\Plots\','CNR Issue.png'));
    close(gcf);
    %=============================%
    
    % plot CNR count per build on Percentage
    buildCNRsCntPC = buildCNRsCnt ./ buildTotalTestList * 100;
    cnrCntBarPC = bar(categorical(buildList), buildCNRsCntPC, 'facecolor', 'flat');
    
    % set bar color
    cnrCntBarPC.CData = [217 83 25] / 255;
    
    % add labels to bar graph
    xtipsCNRCntPC = cnrCntBarPC(1).XEndPoints;
    ytipsCNRCntPC = cnrCntBarPC(1).YEndPoints;
    labelsCNRCntPC = string(cnrCntBarPC(1).YData);
    text(xtipsCNRCntPC,ytipsCNRCntPC,labelsCNRCntPC,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    xlabel('Build');
    ylabel('Percentage (%)');
    ylim([0 max(buildCNRsCntPC)*1.2+0.1]);
    title('CNR Issue on Percentage');
    % set position and resolution
    set(gcf,'position',[0,0,1920,1080]);
    saveas(gcf, strcat(pwd,'\Plots\','CNR Issue on Percentage.png'));
    close(gcf);
    
    
    %% =============================== %
    
    % plot Cypress count per build
    cypressCntBar = bar(categorical(buildList), buildCypressCnt, 'facecolor', 'flat');
    
    % set bar color
    cypressCntBar.CData = [237 177 32] / 255;
    
    % add labels to bar graph
    xtipsCypressCnt = cypressCntBar(1).XEndPoints;
    ytipsCypressCnt = cypressCntBar(1).YEndPoints;
    labelsCypressCnt = string(cypressCntBar(1).YData);
    text(xtipsCypressCnt,ytipsCypressCnt,labelsCypressCnt,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    xlabel('Build');
    ylabel('Fails');
    ylim([0 max(buildCypressCnt)*1.2+0.1]);
    title('Cypress Issue');
    % set position and resolution
    set(gcf,'position',[0,0,1920,1080]);
    saveas(gcf, strcat(pwd,'\Plots\','Cypress Issue.png'));
    close(gcf);
    %======================%
    
    % plot Cypress count per build on Percentage
    buildCypressCntPC = buildCypressCnt ./ buildTotalTestList * 100;
    cypressCntBarPC = bar(categorical(buildList), buildCypressCntPC, 'facecolor', 'flat');
    
    % set bar color
    cypressCntBarPC.CData = [237 177 32] / 255;
    
    % add labels to bar graph
    xtipsCypressCntPC = cypressCntBarPC(1).XEndPoints;
    ytipsCypressCntPC = cypressCntBarPC(1).YEndPoints;
    labelsCypressCntPC = string(cypressCntBarPC(1).YData);
    text(xtipsCypressCntPC,ytipsCypressCntPC,labelsCypressCntPC,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    xlabel('Build');
    ylabel('Percentage (%)');
    ylim([0 max(buildCypressCntPC)*1.2+0.1]);
    title('Cypress Issue on Percentage');
    % set position and resolution
    set(gcf,'position',[0,0,1920,1080]);
    saveas(gcf, strcat(pwd,'\Plots\','Cypress Issue on Percentage.png'));
    close(gcf);
    
    %% =============================== %
    
    % plot Direct count per build
    directCntBar = bar(categorical(buildList), buildDirectCnt, 'facecolor', 'flat');
    
    % set bar color
    directCntBar.CData = [126 47 142] / 255;
    
    % add labels to bar graph
    xtipsDirectCnt = directCntBar(1).XEndPoints;
    ytipsDirectCnt = directCntBar(1).YEndPoints;
    labelsDirectCnt = string(directCntBar(1).YData);
    text(xtipsDirectCnt,ytipsDirectCnt,labelsDirectCnt,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    xlabel('Build');
    ylabel('Fails');
    ylim([0 max(buildDirectCnt)*1.2+0.1]);
    title('Direct Connect Issue');
    % set position and resolution
    set(gcf,'position',[0,0,1920,1080]);
    saveas(gcf, strcat(pwd,'\Plots\','Direct Connect Issue.png'));
    close(gcf);
    %============================%
    
    % plot Direct count per build
    buildDirectCntPC = buildDirectCnt ./ buildTotalTestList * 100;
    directCntBarPC = bar(categorical(buildList), buildDirectCntPC, 'facecolor', 'flat');
    
    % set bar color
    directCntBarPC.CData = [126 47 142] / 255;
    
    % add labels to bar graph
    xtipsDirectCntPC = directCntBarPC(1).XEndPoints;
    ytipsDirectCntPC = directCntBarPC(1).YEndPoints;
    labelsDirectCntPC = string(directCntBarPC(1).YData);
    text(xtipsDirectCntPC,ytipsDirectCntPC,labelsDirectCntPC,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    xlabel('Build');
    ylabel('Percentage (%)');
    ylim([0 max(buildDirectCntPC)*1.2+0.1]);
    title('Direct Connect Issue on Percentage');
    % set position and resolution
    set(gcf,'position',[0,0,1920,1080]);
    saveas(gcf, strcat(pwd,'\Plots\','Direct Connect Issue on Percentage.png'));
    close(gcf);

    %% =============================== %
    
    % Total bug count for individual cycle, per Builds
    for n = masterRealCntByCycle.Properties.VariableNames(2:15)
        figure();
        barBugCntByCycle = bar(categorical(buildList), masterRealCntByCycle.(char(n)));
        curXTips = barBugCntByCycle(1).XEndPoints;
        curYTips = barBugCntByCycle(1).YEndPoints;
        curlabels = string(barBugCntByCycle(1).YData);
        text(curXTips,curYTips,curlabels,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        xlabel('Build');
        ylabel('Fail Count');
        if ~any(masterRealCntByCycle.(char(n))) % check if the list is not all zeros
            ylim([0 0.1]);
        else
            ylim([0 max(masterRealCntByCycle.(char(n)))*1.2]);
        end
        title(['Fail Count in ', char(n), ' Cycle in each Build']);
        saveas(gcf, [pwd,'\Plots\Real\', 'Fail Count in ', char(n), ' Cycle in each Build', '.png']);
        close(gcf);
    end
    %% =============================== %
    
    
end