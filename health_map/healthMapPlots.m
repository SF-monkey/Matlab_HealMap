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
        
        % CNR count per build
        varNamesCycle = string(zeros(14,1))';
        varNamesCycle(:) = 'double';
        varNamesHost = string(zeros(length(unique(hm.Host)),1))';
        varNamesHost(:) = 'double';
        totalCNR = 0;
        
        % create CNR counter table by cycle
        cnrCntCycle = table('Size', [1 14],...
            'VariableTypes',varNamesCycle,...
            'VariableNames', hm.Properties.VariableNames(22:35));
        
        % create CNR counter table by host
        cnrCntHost = table('Size', [1 length(unique(hm.Host))],...
            'VariableTypes',varNamesHost,...
            'VariableNames', unique(hm.Host));
        
        % create zero array with the same height as the Build table
        cnrFilter = zeros(height(bT),1);
        
        for n = bT.Properties.VariableNames(22:35)
            x = contains(bT.(char(n)), 'CNR');
            cnrCntCycle.(char(n)) = sum(x);
            totalCNR = totalCNR + sum(x);
            % add the count to the according cycle
            buildCNRsCnt(buildList(m) - min(buildList) + 1,1) =...
                buildCNRsCnt(buildList(m) - min(buildList) + 1,1) + sum(x);
            cnrFilter = cnrFilter | x;
        end
        
        barCNRCycle = bar(cycles, table2array(cnrCntCycle(1,:)));
        % add labels to bar graph
        xtipsCNRCycle = barCNRCycle(1).XEndPoints;
        ytipsCNRCycle = barCNRCycle(1).YEndPoints;
        labelsCNRCycle = string(barCNRCycle(1).YData);
        text(xtipsCNRCycle,ytipsCNRCycle,labelsCNRCycle,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Total CNRs');
        ylim([0 max(table2array(cnrCntCycle(1,:)))*1.2+0.1]);
        title(strcat(string(totalCNR), ' Total CNRs Break Down by Cycles in Build ', string(buildList(m))));
        saveas(barCNRCycle, strcat(pwd,'\Plots\', 'Total CNRs Break Down by Cycles in Build ', string(buildList(m)), '.png'));
        close(gcf);
       
        cnrBT = bT(cnrFilter, :);
        
        for n = 1:height(cnrBT)
            % find how many times CNR occurs within a row
            x = sum(contains(table2cell(cnrBT(n, 22:35)), 'CNR'));
            % add the count to the according Host 
            cnrCntHost.(char(table2cell(cnrBT(n,10)))) =...
                cnrCntHost.(char(table2cell(cnrBT(n,10)))) + x;
        end
        
        barCNRHost = bar(categorical(unique(hm.Host)), table2array(cnrCntHost(1,:)));
        % add labels to bar graph
        xtipsCNRHost = barCNRHost(1).XEndPoints;
        ytipsCNRHost = barCNRHost(1).YEndPoints;
        labelsCNRHost = string(barCNRHost(1).YData);
        text(xtipsCNRHost,ytipsCNRHost,labelsCNRHost,...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
        ylabel('Total CNRs');
        ylim([0 max(table2array(cnrCntHost(1,:)))*1.2+0.1]);
        title(strcat(string(totalCNR), ' Total CNRs Break Down by Host in Build ', string(buildList(m))));
        saveas(barCNRHost, strcat(pwd,'\Plots\', 'Total CNRs Break Down by Host in Build ', string(buildList(m)), '.png'));
        close(gcf);
        
        % Cypress count per build
        for n = bT.Properties.VariableNames(22:35)
            x = contains(bT.(char(n)), 'Cypress');
            buildCypressCnt(buildList(m) - min(buildList) + 1,1) =...
                buildCypressCnt(buildList(m) - min(buildList) + 1,1) + sum(x);
        end
        
        % Cypress count per build
        for n = bT.Properties.VariableNames(22:35)
            x = contains(bT.(char(n)), 'Direct');
            buildDirectCnt(buildList(m) - min(buildList) + 1,1) =...
                buildDirectCnt(buildList(m) - min(buildList) + 1,1) + sum(x);
        end
        
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
        ylim([0 max(summaryData)*1.2]);
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
    ylim([0 max(buildSummary, [], 'all')*1.2]);
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
    ylim([0 max(buildFailCnt)*1.2]);
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
    ylim([0 max(buildCNRsCnt)*1.2]);
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
    ylim([0 max(buildCypressCnt)*1.2]);
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
    ylim([0 max(buildDirectCnt)*1.2]);
    title('Direct Issue Count per Build');
    saveas(gcf, strcat(pwd,'\Plots\','Direct Issue Count per Build.png'));
    close(gcf);
    %% =============================== %
    
    hostFilter = contains(hm.Host, 'Host 1');
    resultFilter = contains(hm.Result, 'Real');
    dut1Filter = contains(hm.DUT1, 'Go');
    basicOpFilter = contains(hm.BasicOp, 'Direct');
    
    
    
end