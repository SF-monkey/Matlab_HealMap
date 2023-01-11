filename = 'C:\Users\sfang\OneDrive - Analog Devices, Inc\Documents\MATLAB\Health Map.xlsx';
sheetname = 'Health Map';
cell = 'M3675';

excel = actxserver('Excel.Application');  %start excel
excel.Visible = true;    %optional, make excel visible
workbook = excel.Workbooks.Open(filename);   %open excel file
worksheet = workbook.Worksheets.Item(sheetname);  %get worksheet reference
rgb = worksheet.Range(cell).Interior.Color;
red = mod(rgb, 256);
green = floor(mod(rgb / 256, 256));
blue = floor(rgb / 65536);
workbook.Close;
excel.Quit;