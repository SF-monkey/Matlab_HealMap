close all

%% edit parameters here
rows = 5000;
startColIdx = 'L';
endColIdx = 'S';

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

    colorsMap = cell(rows, char(endColIdx) - char(startColIdx) +1);
    for m = startColIdx:endColIdx
        for n = 1:rows
            curCell = strcat(m, num2str(n, '%0d'));
            color = worksheet.Range(curCell).Interior.Color;
            if color == 13551615
                colorsMap{n, (char(m) - char(startColIdx) + 1)} = worksheet.Range(curCell).value;
            else
                colorsMap{n, (char(m) - char(startColIdx) + 1)} = 0;
            end
        end
    end

    workbook.Close;
    excel.Quit;
end

