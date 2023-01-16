close all

%% edit parameters here
rows = 5000; % number of rows to scan
startColIdx = 'L'; % starting column index needed for scanning (from excel)
endColIdx = 'S'; % the last colomn index needed for scanning (from excel)
bgColor = 'FF C7 CE'; % need to put spaces in between RGB value

%% main
[fn, fp, index] = uigetfile('*.xlsx');
if index == 0
    disp('No file selected!');
else
    filename = 'C:\Users\sfang\OneDrive - Analog Devices, Inc\Documents\MATLAB\Safer_Matlab\health_map\Health Map.xlsx';
    sheetname = 'Health Map';
    excel = actxserver('Excel.Application');  %start excel
    excel.Visible = true;    %optional, make excel visible
    workbook = excel.Workbooks.Open(filename);   %open excel file
    worksheet = workbook.Worksheets.Item(sheetname);  %get worksheet reference
    
    % convert the hex RGB to hex BGR, then convert hex to decimal
    bgColor = hex2dec(strjoin(fliplr(split(bgColor,' ')'),''));
    colorsMap = cell(rows, char(endColIdx) - char(startColIdx) +1);
    for m = startColIdx:endColIdx
        for n = 1:rows
            curCell = strcat(m, num2str(n, '%0d'));
            color = worksheet.Range(curCell).Interior.Color;
            if color == bgColor
                colorsMap{n, (char(m) - char(startColIdx) + 1)} = worksheet.Range(curCell).value;
            else
                colorsMap{n, (char(m) - char(startColIdx) + 1)} = 0;
            end
        end
    end

    workbook.Close;
    excel.Quit;
end

