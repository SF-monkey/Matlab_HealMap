close all

% load the table
healthMap = readtable('Health Map.xlsx', 'Sheet', "Health Map");

% check the summary of the table, check the variable data type
% summary(healthMap);

% convert the variable type as needed
% healthMap = convertvars(healthMap,[1 3:19 22:35], 'categorical');

% create individual variable filters
% hostFilter = ~cellfun(@isempty, strfind(healthMap.Host, 'Host 1'));
buildFilter = healthMap.Build == 88;
hostFilter = contains(healthMap.Host, 'Host 1');
resultFilter = contains(healthMap.Result, 'Real');
dut1Filter = contains(healthMap.DUT1, 'Go');
basicOpFilter = contains(healthMap.BasicOp, 'Direct');

% combine filters as needed
mixFilter = resultFilter & buildFilter;
mixFilterBB = resultFilter & healthMap.Build == 92;

% apply filter to original table
t1 = healthMap(mixFilter, :);
t1BB = healthMap(mixFilterBB, :);

% subset table by variable as needed
t1Sub = t1(:, ["Units", "Host", "TotalBugs"]);
t1SubBB = t1BB(:, ["Units", "Host", "TotalBugs"]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% create bar plot

% method 1

% generate grouped variable stats
t1SubStat = grpstats(t1Sub,["Units", "Host"]);
t1SubStatBB = grpstats(t1SubBB,["Units", "Host"]);

x = strcat(t1SubStat.Units, '-', t1SubStat.Host);
figure();
b = bar(categorical(x), t1SubStat.GroupCount);

% add labels to bar graph
xtips1 = b(1).XEndPoints;
ytips1 = b(1).YEndPoints;
labels1 = string(b(1).YData);
text(xtips1,ytips1,labels1,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')
ylabel('Total Bugs');
ylim([0 max(t1SubStat.GroupCount)*1.2]);
title('Total Bugs Grouped by Extender and Host in Build 88 Style 1');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% method 2, group bar plot by Extenders (x-axis)

% find the unique Host and Extenders in the group stats table
uHostTable = cell2table(unique(t1SubStat.Host), 'VariableName', {'uHost'});
uT1SubUnitTable = cell2table(unique(t1SubStat.Units), 'VariableName', {'uUnits'});

% replicate the rows; the expanded tables should have the same size of
% the least common multiple of unique(Host) and unique(Unit).
uHostTable_expanded = repmat(uHostTable{:,:}, size(uT1SubUnitTable{:,:}, 1), 1);
uT1SubUnitTable_expanded = sort(repmat(uT1SubUnitTable{:,:}, size(uHostTable{:,:}, 1), 1));

% concatenate the expanded values vertically, then convert to cell table
t1SubExpanded = cell2table(cellstr(horzcat(uT1SubUnitTable_expanded, uHostTable_expanded)),...
                           'VariableName', {'Units', 'Host'});

% join the table                       
t1SubStat2 = outerjoin(t1SubExpanded, t1SubStat(:,1:3),...
                   'LeftKeys', {'Units', 'Host'},...
                   'RightKeys',{'Units', 'Host'},...
                   'MergeKeys', true);

% create a unique cell array of extenders
uUnitList = unique(t1SubStat2.Units)';

% initialize list of y values for bar plot 
yList = [];

% loop through every distinct extenders and get the bugs count by Hosts
% use this loop to get distinct sets of bug count data for grounp bar plot
for m = 1:length(uUnitList)
    % access each element in the extenders cell array
    curUnit = uUnitList{m};
    % create logical filter for current extender
    curUnitFilter = strcmp(t1SubStat2.Units, curUnit);
    % filter the group stat table, get the bugs count only, 
    % convert to number array, then transpose it
    curT1Stat = table2array(t1SubStat2(curUnitFilter, 3))';
    % append to the y value array
    yList = [yList; curT1Stat];
end

figure();
b2 = bar(categorical(unique(t1SubStat2.Host)), yList, 'grouped');
legend(uUnitList);

% add labels to bar graph
xtips21 = b2(1).XEndPoints;
ytips21 = b2(1).YEndPoints;
labels21 = string(b2(1).YData);
text(xtips21,ytips21,labels21,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')

xtips22 = b2(2).XEndPoints;
ytips22 = b2(2).YEndPoints;
labels22 = string(b2(2).YData);
text(xtips22,ytips22,labels22,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')

xtips23 = b2(3).XEndPoints;
ytips23 = b2(3).YEndPoints;
labels23 = string(b2(3).YData);
text(xtips23,ytips23,labels23,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')

ylabel('Total Bugs');
ylim([0 max(t1SubStat2.GroupCount)*1.2]);
title('Total Bugs Grouped by Extender and Host in Build 88 Style 2');               

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% BasicOp Direct Connect table
t2 = healthMap(basicOpFilter, :);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% find top 3 hosts that has most Fails

failHostTable = healthMap(resultFilter, :);
failHostCnt = groupcounts(failHostTable, 'Host');
failHostCnt = sortrows(failHostCnt,'GroupCount', 'descend');
top3FailHost = head(failHostCnt, 3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Total number of Bugs per Extenders grouped by Host in Build 88/92

BugCountVars = ["Units", "Host", "TotalBugs"];
% class(BugCountVars), result is a 1x3 string array.

ravenFilter = strcmp(healthMap.Units, 'Raven');
ravenTable = healthMap(ravenFilter & resultFilter & buildFilter, BugCountVars);
ravenSubStat = grpstats(ravenTable,["Units", "Host"]);

ravenProFilter = contains(healthMap.Units, 'Raven Pro');
ravenProTable = healthMap(ravenProFilter & resultFilter & buildFilter, BugCountVars);
ravenProSubStat = grpstats(ravenProTable,["Units", "Host"]);

maverickFilter = contains(healthMap.Units, 'Maverick');
maverickTable = healthMap(maverickFilter & resultFilter & buildFilter, BugCountVars);
maverickSubStat = grpstats(maverickTable,["Units", "Host"]);

asicFilter = contains(healthMap.Units, 'ASIC');
buildFilter92 = healthMap.Build == 92;
asicTable = healthMap(asicFilter & resultFilter & buildFilter92, BugCountVars);
asicSubStat = grpstats(asicTable,["Units", "Host"]);
           

figure;

subplot(2,2,1);
barRaven = bar(categorical(ravenSubStat.Host), ravenSubStat.GroupCount);

% add labels to bar graph
xtipsbarRaven = barRaven(1).XEndPoints;
ytipsbarRaven = barRaven(1).YEndPoints;
labelsbarRaven = string(barRaven(1).YData);
text(xtipsbarRaven,ytipsbarRaven,labelsbarRaven,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')
ylabel('Total Bugs');
ylim([0 max(ravenSubStat.GroupCount)*1.2]);
title('Total Bugs by Host in Raven in Build 88');

subplot(2,2,2);
barRavenPro = bar(categorical(ravenProSubStat.Host), ravenProSubStat.GroupCount);
% add labels to bar graph
xtipsbarRavenPro = barRavenPro(1).XEndPoints;
ytipsbarRavenPro = barRavenPro(1).YEndPoints;
labelsbarRavenPro = string(barRavenPro(1).YData);
text(xtipsbarRavenPro,ytipsbarRavenPro,labelsbarRavenPro,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')
ylabel('Total Bugs');
ylim([0 max(ravenProSubStat.GroupCount)*1.2]);
title('Total Bugs by Host in RavenPro in Build 88');

subplot(2,2,3);
barMaverick = bar(categorical(maverickSubStat.Host), maverickSubStat.GroupCount);
% add labels to bar graph
xtipsbarMaverick = barMaverick(1).XEndPoints;
ytipsbarMaverick = barMaverick(1).YEndPoints;
labelsbarMaverick = string(barMaverick(1).YData);
text(xtipsbarMaverick,ytipsbarMaverick,labelsbarMaverick,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')
ylabel('Total Bugs');
ylim([0 max(maverickSubStat.GroupCount)*1.2]);
title('Total Bugs by Host in Maverick in Build 88');

subplot(2,2,4);
barASIC = bar(categorical(asicSubStat.Host), asicSubStat.GroupCount);
% add labels to bar graph
xtipsbarASIC = barASIC(1).XEndPoints;
ytipsbarASIC = barASIC(1).YEndPoints;
labelsbarASIC = string(barASIC(1).YData);
text(xtipsbarASIC,ytipsbarASIC,labelsbarASIC,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')
ylabel('Total Bugs');
ylim([0 max(asicSubStat.GroupCount)*1.2]);
title('Total Bugs by Host in ASIC in Build 92');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% style 2, full table with ALL the hosts with fails
% create a table with all the unique hosts
uniqueHostTable = cell2table(unique(t1SubStat.Host), 'VariableName', {'UniqueHost'});
uniqueHostTableBB = cell2table(unique(t1SubStatBB.Host), 'VariableName', {'UniqueHost'});

% join the group stats table with the unique hosts table
ravenSubStatFull = outerjoin(uniqueHostTable, ravenSubStat,...
                   'LeftKeys', {'UniqueHost'},...
                   'RightKeys',{'Host'},...
                   'MergeKeys', true);
               
ravenProSubStatFull = outerjoin(uniqueHostTable, ravenProSubStat,...
                   'LeftKeys', {'UniqueHost'},...
                   'RightKeys',{'Host'},...
                   'MergeKeys', true);
               
maverickSubStatFull = outerjoin(uniqueHostTable, maverickSubStat,...
                   'LeftKeys', {'UniqueHost'},...
                   'RightKeys',{'Host'},...
                   'MergeKeys', true);
               
asicSubStatFull = outerjoin(uniqueHostTableBB, asicSubStat,...
                   'LeftKeys', {'UniqueHost'},...
                   'RightKeys',{'Host'},...
                   'MergeKeys', true);   
               
figure;

subplot(2,2,1);
barRavenFull = bar(categorical(ravenSubStatFull.UniqueHost_Host), ravenSubStatFull.GroupCount);

% add labels to bar graph
xtipsbarRavenFull = barRavenFull(1).XEndPoints;
ytipsbarRavenFull = barRavenFull(1).YEndPoints;
labelsbarRavenFull = string(barRavenFull(1).YData);
text(xtipsbarRavenFull,ytipsbarRavenFull,labelsbarRavenFull,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')
ylabel('Total Bugs');
ylim([0 max(t1SubStat.GroupCount)*1.2]);
title('Total Bugs by Host in Raven in Build 88');

subplot(2,2,2);
barRavenProFull = bar(categorical(ravenProSubStatFull.UniqueHost_Host), ravenProSubStatFull.GroupCount);
% add labels to bar graph
xtipsbarRavenProFull = barRavenProFull(1).XEndPoints;
ytipsbarRavenProFull = barRavenProFull(1).YEndPoints;
labelsbarRavenProFull = string(barRavenProFull(1).YData);
text(xtipsbarRavenProFull,ytipsbarRavenProFull,labelsbarRavenProFull,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')
ylabel('Total Bugs');
ylim([0 max(t1SubStat.GroupCount)*1.2]);
title('Total Bugs by Host in RavenPro in Build 88');

subplot(2,2,3);
barMaverickFull = bar(categorical(maverickSubStatFull.UniqueHost_Host), maverickSubStatFull.GroupCount);
% add labels to bar graph
xtipsbarMaverickFull = barMaverickFull(1).XEndPoints;
ytipsbarMaverickFull = barMaverickFull(1).YEndPoints;
labelsbarMaverickFull = string(barMaverickFull(1).YData);
text(xtipsbarMaverickFull,ytipsbarMaverickFull,labelsbarMaverickFull,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')
ylabel('Total Bugs');
ylim([0 max(t1SubStat.GroupCount)*1.2]);
title('Total Bugs by Host in Maverick in Build 88');

subplot(2,2,4);
barASICFull = bar(categorical(asicSubStatFull.UniqueHost_Host), asicSubStatFull.GroupCount);
% add labels to bar graph
xtipsbarASICFull = barASICFull(1).XEndPoints;
ytipsbarASICFull = barASICFull(1).YEndPoints;
labelsbarASICFull = string(barASICFull(1).YData);
text(xtipsbarASICFull,ytipsbarASICFull,labelsbarASICFull,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')
ylabel('Total Bugs');
ylim([0 max(asicSubStatFull.GroupCount)*1.2]);
title('Total Bugs by Host in ASIC in Build 92');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% find CNRs

% create zero array with the same height as the healthMao table
canNotReproduceFilter = zeros(height(healthMap),1);

for m = healthMap.Properties.VariableNames(22:35)
    x = contains(healthMap.(char(m)), 'CNR');
    canNotReproduceFilter = canNotReproduceFilter | x;
end
t3 = healthMap(canNotReproduceFilter, :);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% get all direct connect issue, break down by host, or cycles

directFilter = zeros(height(healthMap),1);

for m = healthMap.Properties.VariableNames(22:35)
    x = contains(healthMap.(char(m)), 'Direct');
    directFilter = directFilter | x;
end
t4 = healthMap(directFilter, :);
