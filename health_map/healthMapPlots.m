close all;
clear;
clc;

[fn, fp, index] = uigetfile('*.xlsx');
if index == 0
    disp('No file selected!');
else
    
    % load the table
    % must run the 'color_test.m' once if health map file is updated.
    healthMap = readtable(strcat(fp,fn), 'Sheet', "Health Map");
    failDev = readtable(strcat(fp,'failDevices.xlsx'), 'Format', 'auto');
    hm = [healthMap, failDev(1:height(healthMap), :)];
    
    % define oepration cycle category
    % NOTE: cycle names must be the same as the excel sheet!
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
    
    %% Real fail/CNRs/Cypress/Direct count per build
    
    buildFailCnt = zeros(length(buildList),1);
    buildCNRsCnt = zeros(length(buildList),1);
    buildCypressCnt = zeros(length(buildList),1);
    buildDirectCnt = zeros(length(buildList),1);
    buildTotalCnt = zeros(length(buildList),1);
    buildPassCnt = zeros(length(buildList),1);
    summaryLabel = categorical({'Real', 'CNR', 'Cypress','Direct'});
    summaryLabel = reordercats(summaryLabel, {'Real', 'CNR', 'Cypress','Direct'});
    
    % loop through different builds
    for m = 1:length(buildList)
        buildFilter = hm.Build == buildList(m);
        bT = hm(buildFilter, :); % sub table by build
        
        % total test count per build
        buildTotalCnt(buildList(m) - min(buildList) + 1,1) = sum(bT.TotalTests);
        
        % real fails count per build
        buildFailCnt(buildList(m) - min(buildList) + 1,1) = sum(bT.TotalBugs);
              
        % create lists for variable types
        varTypesCycle = string(zeros(14,1))';
        varTypesCycle(:) = 'double';
        varTypesHost = string(zeros(length(unique(hm.Host)),1))';
        varTypesHost(:) = 'double';
        
        
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
            buildCNRsCnt(buildList(m) - min(buildList) + 1,1) =...
                buildCNRsCnt(buildList(m) - min(buildList) + 1,1) + sum(x);
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
        saveas(barCNRCycle, strcat(pwd,'\Plots\', 'Total CNRs Break Down by Cycles in Build ', string(buildList(m)), '.png'));
        close(gcf);
       
        
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
        saveas(barCNRHost, strcat(pwd,'\Plots\', 'Total CNRs Break Down by Host in Build ', string(buildList(m)), '.png'));
        close(gcf);
        
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
            buildCypressCnt(buildList(m) - min(buildList) + 1,1) =...
                buildCypressCnt(buildList(m) - min(buildList) + 1,1) + sum(x);
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
        saveas(barCypressCycle, strcat(pwd,'\Plots\', 'Total Cypress Issues Break Down by Cycles in Build ', string(buildList(m)), '.png'));
        close(gcf);
       
        
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
        saveas(barCypressHost, strcat(pwd,'\Plots\', 'Total Cypress Issues Break Down by Host in Build ', string(buildList(m)), '.png'));
        close(gcf);
        
        %%%% Direct count per build %%%%
        buildTotalDirect = 0;
        
        % create Direct counter table by cycle
        drCntByCycle = table('Size', [1 14],...
            'VariableTypes',varTypesCycle,...
            'VariableNames', hm.Properties.VariableNames(22:35));
        
        % create Direct counter table by host
        drCntByHost = table('Size', [1 length(unique(hm.Host))],...
            'VariableTypes',varTypesHost,...
            'VariableNames', unique(hm.Host));
        
        % create zero array with the same height as the Build table
        drFilter = zeros(height(bT),1);
        
        %%%%% Total Direct Break Down by Cycles in each Build %%%%%
        
        for n = bT.Properties.VariableNames(22:35)
            % x is a logical array with same height as build table
            x = contains(bT.(char(n)), 'Direct');
            drCntByCycle.(char(n)) = sum(x);
            buildTotalDirect = buildTotalDirect + sum(x);
            % add the count to the according cycle
            buildDirectCnt(buildList(m) - min(buildList) + 1,1) =...
                buildDirectCnt(buildList(m) - min(buildList) + 1,1) + sum(x);
            drFilter = drFilter | x;
        end
        
        barDirectCycle = bar(cycles, table2array(drCntByCycle(1,:)));
        % add labels to bar graph
        xtipsDirectCycle = barDirectCycle(1).XEndPoints;
        ytipsDirectCycle = barDirectCycle(1).YEndPoints;
        labelsDirectCycle = string(barDirectCycle(1).YData);
        text(xtipsDirectCycle,ytipsDirectCycle,labelsDirectCycle,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Total Direct');
        ylim([0 max(table2array(drCntByCycle(1,:)))*1.2+0.1]);
        title(strcat(string(buildTotalDirect), ' Total Direct Issues Break Down by Cycles in Build ', string(buildList(m))));
        saveas(barDirectCycle, strcat(pwd,'\Plots\', 'Total Direct Issues Break Down by Cycles in Build ', string(buildList(m)), '.png'));
        close(gcf);
       
        
        %%%%% Total Directs Break Down by Hosts in each Build %%%%%
        drBT = bT(drFilter, :);
        
        for n = 1:height(drBT)
            % find how many times Direct occurs within a row
            x = sum(contains(table2cell(drBT(n, 22:35)), 'Direct'));
            % add the count to the according Host 
            drCntByHost.(char(table2cell(drBT(n,10)))) =...
                drCntByHost.(char(table2cell(drBT(n,10)))) + x;
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
        saveas(barDirectHost, strcat(pwd,'\Plots\', 'Total Direct Issues Break Down by Host in Build ', string(buildList(m)), '.png'));
        close(gcf);
        
        buildPassCnt(buildList(m) - min(buildList) + 1,1) =...
            buildTotalCnt(buildList(m) - min(buildList) + 1,1) -...
            buildDirectCnt(buildList(m) - min(buildList) + 1,1) -...
            buildCypressCnt(buildList(m) - min(buildList) + 1,1) -...
            buildCNRsCnt(buildList(m) - min(buildList) + 1,1) -...
            buildFailCnt(buildList(m) - min(buildList) + 1,1);
        %% =============================== %
        
        % Test failure summary plot per build
        summaryData = [buildFailCnt(buildList(m) - min(buildList) + 1,1) ...
            buildCNRsCnt(buildList(m) - min(buildList) + 1,1) ...
            buildCypressCnt(buildList(m) - min(buildList) + 1,1) ...
            buildDirectCnt(buildList(m) - min(buildList) + 1,1)];
        
        summaryBar = bar(summaryLabel, summaryData);
        % add labels to bar graph
        xtipsSummary = summaryBar(1).XEndPoints;
        ytipsSummary = summaryBar(1).YEndPoints;
        labelsSummary = string(summaryBar(1).YData);
        text(xtipsSummary,ytipsSummary,labelsSummary,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        xlabel('Failure Type');
        ylabel('Count');
        ylim([0 max(summaryData)*1.2+0.1]);
        title(strcat('Build', string(buildList(m)), ' Test Summary'));
        saveas(gcf, strcat(pwd,'\Plots\', 'Build', string(buildList(m)), ' Test Failure Summary.png'));
        close(gcf);
        %% =============================== %
        
        
        
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
    ylabel('Total Bugs');
    ylim([0 max(buildSummary, [], 'all')*1.2+0.1]);
    title('Test Failure Summary per Build');
    % set position and resolution
    set(sumfig,'position',[0,0,1920,1080]);
    saveas(sumfig, strcat(pwd,'\Plots\','Test Failure Summary per Build.png'));
    close(sumfig);
    %% =============================== %
    
    % plot real fails count per build
    realCntBar = bar(categorical(buildList), buildFailCnt);
    % add labels to bar graph
    xtipsRealCnt = realCntBar(1).XEndPoints;
    ytipsRealCnt = realCntBar(1).YEndPoints;
    labelsRealCnt = string(realCntBar(1).YData);
    text(xtipsRealCnt,ytipsRealCnt,labelsRealCnt,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    xlabel('Build');
    ylabel('Total Bugs');
    ylim([0 max(buildFailCnt)*1.2+0.1]);
    title('Real Fail Count per Build');
    saveas(gcf, strcat(pwd,'\Plots\','Real Fail Count per Build.png'));
    close(gcf);
    %% =============================== %
    
    % plot CNR count per build
    cnrCntBar = bar(categorical(buildList), buildCNRsCnt);
    % add labels to bar graph
    xtipsCNRCnt = cnrCntBar(1).XEndPoints;
    ytipsCNRCnt = cnrCntBar(1).YEndPoints;
    labelsCNRCnt = string(cnrCntBar(1).YData);
    text(xtipsCNRCnt,ytipsCNRCnt,labelsCNRCnt,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    xlabel('Build');
    ylabel('Total CNR Count');
    ylim([0 max(buildCNRsCnt)*1.2+0.1]);
    title('CNR Count per Build');
    saveas(gcf, strcat(pwd,'\Plots\','CNR Count per Build.png'));
    close(gcf);
    %% =============================== %
    
    % plot Cypress count per build
    cypressCntBar = bar(categorical(buildList), buildCypressCnt);
    % add labels to bar graph
    xtipsCypressCnt = cypressCntBar(1).XEndPoints;
    ytipsCypressCnt = cypressCntBar(1).YEndPoints;
    labelsCypressCnt = string(cypressCntBar(1).YData);
    text(xtipsCypressCnt,ytipsCypressCnt,labelsCypressCnt,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    xlabel('Build');
    ylabel('Total Cypress Issue');
    ylim([0 max(buildCypressCnt)*1.2+0.1]);
    title('Cypress Issue Count per Build');
    saveas(gcf, strcat(pwd,'\Plots\','Cypress Issue Count per Build.png'));
    close(gcf);
    %% =============================== %
    
    % plot Direct count per build
    directCntBar = bar(categorical(buildList), buildDirectCnt);
    % add labels to bar graph
    xtipsDirectCnt = directCntBar(1).XEndPoints;
    ytipsDirectCnt = directCntBar(1).YEndPoints;
    labelsDirectCnt = string(directCntBar(1).YData);
    text(xtipsDirectCnt,ytipsDirectCnt,labelsDirectCnt,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    xlabel('Build');
    ylabel('Total Direct Issue');
    ylim([0 max(buildDirectCnt)*1.2+0.1]);
    title('Direct Issue Count per Build');
    saveas(gcf, strcat(pwd,'\Plots\','Direct Issue Count per Build.png'));
    close(gcf);
    %% =============================== %
    
    hostFilter = contains(hm.Host, 'Host 1');
    resultFilter = contains(hm.Result, 'Real');
    dut1Filter = contains(hm.DUT1, 'Go');
    basicOpFilter = contains(hm.BasicOp, 'Direct');
    
    
    
end