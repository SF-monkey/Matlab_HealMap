close all;
clear;
clc;

%% edit parameters here
sheetname = 'Health Map';
rows = 5000; % number of rows to scan
startColIdx = 'L'; % starting column index needed for scanning (from excel)
endColIdx = 'S'; % the last colomn index needed for scanning (from excel)
bgColor = 'FF C7 CE'; % need to put spaces in between RGB value

%% main
[fn, fp, index] = uigetfile('*.xlsx');
if index == 0
    disp('No file selected!');
else
    filename = strcat(fp,fn);
    excel = actxserver('Excel.Application');  %start excel
    excel.Visible = true;    %optional, make excel visible
    wb = excel.Workbooks.Open(filename);   %open excel file
    ws = wb.Worksheets.Item(sheetname);  %get worksheet reference
    
    % convert the hex RGB to hex BGR, then convert hex to decimal
    bgColor = hex2dec(strjoin(fliplr(split(bgColor,' ')'),''));
    % create cell array, letters subtraction is ASCII code subtraction
    colorsMap = cell(rows, (endColIdx - startColIdx +1));
    for m = startColIdx:endColIdx
        for n = 1:rows
            curCell = strcat(m, num2str(n, '%0d'));
            color = ws.Range(curCell).Interior.Color;
            if color == bgColor
                colorsMap{n, (m - startColIdx + 1)} = ws.Range(curCell).value;
            else
                colorsMap{n, (m - startColIdx + 1)} = 0;
            end
        end
    end

    wb.Close;
    excel.Quit;
end

