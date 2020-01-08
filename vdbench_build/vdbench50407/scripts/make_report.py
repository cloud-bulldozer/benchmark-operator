#!/usr/bin/env python3

"""
    This script is used for create a clean test results report.
    
    Author : Avi Liani <alayani@redhat.com>
    Created : Aug-29-2019
"""

import sys
import os
import time
import xlsxwriter

"""
    verify that the script is running with python3 and above only
"""
if sys.version_info.major < 3:
    print ("This script need to run with python version 3 only !")
    exit(1)

""" 
    verify that input filename passed to the script 
"""
if len(sys.argv) > 1:
    file_name = sys.argv[1]
else:
    print ("Error: No input file !!!")
    sys.exit(1)

"""
    verify that the input file is exist.
"""
if os.path.isfile(file_name) is not True:
    print ("Error: Input file dose not exist !")
    sys.exit(1)

"""
    Setting up the output file to be at the same location as the input file
"""
logdir = os.path.dirname(os.path.realpath(file_name))

"""
    splitting the file name to create the output filename
    with different extension, for the excel report.
"""
rep_file = "{}.xlsx".format(os.path.splitext(file_name)[0])


summery_row = 0  # the row to print in the excel file - summery tab
rd = ""  # The name of the test run definition
tit = ""  # The title of the test - especially for the curve points.

# The excel workbook object
workbook = xlsxwriter.Workbook(rep_file)

"""
    creating worksheets for the data and summery
"""
worksheet = workbook.add_worksheet("RawData")
worksheet.set_column('A:A',15)

summery = workbook.add_worksheet("Summery")
summery.set_column('A:A',25)

"""
    Creating the cells formatting
"""
# Header format for each section
Head_format = workbook.add_format()
Head_format.set_border(2)
Head_format.set_bg_color('yellow')
Head_format.set_align('center')
Head_format.set_bold()

format_summery_title = []  # the summery section test name format

"""
    setting up the formats fot the titles in the summery tab
"""
for i in range(4):
    j_format = workbook.add_format()
    j_format.set_bg_color('white')
    j_format.set_bold()
    j_format.set_align('center')
    j_format.set_top(2)
    j_format.set_bottom(2)
    j_format.set_right(2)
    j_format.set_left(2)
    format_summery_title.append(j_format)
format_summery_title[0].set_top(1)
format_summery_title[0].set_bottom(1)
format_summery_title[1].set_bg_color('#B6B6B6')
format_summery_title[2].set_bg_color('#82B5DE')
format_summery_title[3].set_bg_color('#8BC572')

"""
    debugging information - print the names of the files.
"""
print ("logdir = {}".format(logdir))
print ("Base Filename : {}".format(os.path.splitext(file_name)[0]))
print ("Input file name is {}".format(file_name))
print ("Report file name is {}".format(rep_file))

class line_format(object):

    def __init__(self):

        self.cols = []
        for i in range(13):
            lf = workbook.add_format()

            # set general configuration for this format
            lf.set_bold()
            lf.set_align('center')
            lf.set_top(2)
            lf.set_bottom(2)
            lf.set_right(1)
            lf.set_left(1)

            self.cols.append(lf)
            self.set_borders()

    def set_borders(self):
        for i in range(len(self.cols)):
            if i in [0, 1, 2, 4, 5, 7, 8]:
                self.cols[i].set_left(2)

            if i in [0, 1, 4, 7, 9, 10, 12]:
                self.cols[i].set_right(2)

class data_format(line_format):

    def __init__(self):
        super(data_format, self).__init__()
        self.set_borders()
        self.set_formats()

    def set_borders(self):
        super(data_format, self).set_borders()
        for i in range(len(self.cols)):
            self.cols[i].set_top(1)
            self.cols[i].set_bottom(1)
            self.cols[i].set_bold(False)

    def set_formats(self):
        for i in range(len(self.cols)):
            if i > 0:
                self.cols[i].set_num_format('#,##0')
                if i in range(5,11):
                    self.cols[i].set_num_format('#,##0.00')
                if i in [4, 7, 10]:
                    self.cols[i].set_bold()
            else:
                self.cols[i].set_num_format('HH:MM:SS')

class avg_format(data_format):
    def __init__(self):
        super(avg_format, self).__init__()

    def set_borders(self):
        super(avg_format, self).set_borders()
        for i in range(len(self.cols)):
            self.cols[i].set_top(2)
            self.cols[i].set_bottom(2)
            self.cols[i].set_bold()
            self.cols[i].set_bg_color('#b6b6b6')

    def set_formats(self):
        super(avg_format, self).set_formats()
        self.cols[0].set_num_format('HH:MM:SS')

class sum_format(data_format):
    def __init__(self):
        super(sum_format, self).__init__()
        self.set_color()

    def set_color(self, color='white'):
        for i in range(len(self.cols)):
            self.cols[i].set_bg_color(color)

    def set_borders(self,typ=1):
        super(sum_format, self).set_borders()
        for i in range(len(self.cols)):
            self.cols[i].set_top(typ)
            self.cols[i].set_bottom(typ)

class CurveChart(object):
    def __init__(self, title,start,pos):
        self.title = title
        self.start_line = start
        self.pos = pos
        self.end_line = 0

    def endline(self, line):
        self.end_line = line

    def write_chart(self):
        chart = workbook.add_chart({'type': 'line', 'subtype': 'smooth'})

        chart.add_series({
            'name': 'Latency',
            'values': '=Summery!$K${}:$K${}'.format(self.start_line, self.end_line),
            'categories': '=Summery!$E${}:$E${}'.format(self.start_line, self.end_line),
        })

        chart.set_title({'name': self.title})
        chart.set_y_axis({'name': 'Latency(ms)'})
        chart.set_x_axis({'name': 'IOPS'})

        chart.set_legend({'position': 'none'})

        summery.insert_chart('O{}'.format(self.start_line), chart,
                             {'width': 20, 'hight': 20})

class data_line(object):

    def __init__(self, data):
        self.data = data.strip().split()
        del self.data[15:]  # delete the trailing data

        # Getting the test time
        self.h, self.m, self.s = self.data[0].split(':')
        self.s = self.s.split('.')[0]
        self.data[0] = (int(self.h) * 3600 + int(self.m) * 60 + int(self.s)) / (60 * 24 * 60)

        if "avg" in data:
            self.data[1] = 0

    def write(self, ws, row):

        write_order = [0, 1, 4, 10, -1, -1, 12, 2, 8, 3, 9, 5, 6, 7, 11]

        formats = data_format()
        if 'AVG' in self.data:
            formats = avg_format()
        elif ws.name == "Summery":
            formats = sum_format()

        for index, res in enumerate(self.data):
            if res == "NaN":
                res = 0

            if write_order[index] >= 0:

                if write_order[index] > 0 and res is not "AVG":
                    res = float(res)

                if write_order[index] == 11:
                    res = float(res / 1024)

                if ws.name == "Summery":
                    if "max" in rd.lower():
                        formats.set_color('#82B5DE')
                        formats.set_borders(2)
                    if "curve" in tit.lower():
                        formats.set_color('#8BC572')
                        formats.set_borders(2)
                    if "format" in rd.lower():
                        formats.set_color('#b6b6b6')
                        formats.set_borders(2)
                    if "%" in rd.lower():
                        formats.set_color('white')
                        formats.set_borders(1)

                ws.write(row, write_order[index], res, formats.cols[write_order[index]])

        return row+1


def print_header(ws, row, test_date):
    '''
        This function print the header lines (2) of the test data

        Arguments :
            ws - the worksheet to print into.
            row - the row in the worksheet to write the header.
            test_date - the date that the test was taken.

        Return parameter :
            int - the next row to write in the worksheet.
    '''

    title_formats = line_format()

    def print_ops(line, col, title):
        '''
            print the Read/Write/Total headers.
            since this need to be written more the once, it written as
            separate function.

            Arguments :
                line - the row to print this header.
                col - start column of this header.
                title - the title of this header
        '''
        ws.merge_range(line-1, col, line-1, col+2, title, title_formats.cols[0])
        ws.write(line, col, 'Read', title_formats.cols[col])
        ws.write(line, col+1, 'Write', title_formats.cols[col+1])
        ws.write(line, col+2, 'Total', title_formats.cols[col+2])

    ws.merge_range('A{}:A{}'.format(row+1, row+2), test_date, title_formats.cols[0])
    ws.merge_range('B{}:B{}'.format(row+1, row+2), 'Interval', title_formats.cols[1])
    print_ops(row+1, 2, 'IOPS')
    print_ops(row+1, 5, 'Bandwidth(MB / Sec)')
    print_ops(row+1, 8, 'Latency(ms)')
    ws.merge_range('L{}:L{}'.format(row+1, row+2), "BS (K)", title_formats.cols[11])
    ws.merge_range('M{}:M{}'.format(row+1, row+2), "% Read", title_formats.cols[12])

    return row+2

def write_chart(start_lin,end_line,col,sec_col,title,yaxis_title,y2axsi_title,pos_line):
    chart = workbook.add_chart({'type': 'line','subtype': 'smooth'})

    # Configure the first series.
    chart.add_series({
        'name':       'IOPS',
        'values':     '=RawData!${}${}:${}${}'.format(col,start_lin,col,end_line),
        'y2_axis': 1,
    })
    chart.add_series({
        'name':       'Latency',
        'values':     '=RawData!${}${}:${}${}'.format(sec_col,start_lin,sec_col,end_line),
    })
    chart.set_title ({'name': title})
    chart.set_x_axis({'name': 'Time Interval (10sec)'})

    chart.set_y_axis({'name': y2axsi_title})
    chart.set_y2_axis({'name': yaxis_title, 'major_gridlines': {'visible': 0}})

    chart.set_legend({'position': 'bottom'})

    worksheet.insert_chart('O{}'.format(pos_line-3), chart, {'width': 20}) #  , {'x_offset': 25, 'y_offset': 10}

"""
    This function create separate line in the worksheet.
"""
def space_line(worksheet, row):
    space_format = workbook.add_format()
    space_format.set_top(2)

    worksheet.merge_range(row, 0, row, 12, '', space_format)
    return row+1

def main():

    global rd
    global tit
    symmery_title_formats = line_format()

    ''' some global parameters '''
    row = 0  # the row to print in the excel file
    start_section = 0  # this will tell the script to print the output

    cchart = CurveChart(None, 0,0)

    with open(file_name, "r") as fh:
        chart_start_line = 0
        line = fh.readline()

        while line:
            line = line.strip('\n')
            if "Estimated totals for all" in line:
                fdata = line.split(':')

                totla_clients = fdata[2].split()[5]

                total_dirs = fdata[4].split(';')[0]
                total_files = fdata[5].split(';')[0]
                total_data = fdata[6]

                summery.merge_range('A2:B2', "Number of Clients is   {}".format(
                    totla_clients), Head_format)
                summery.merge_range('C2:D2', "Total Dirs : {}".format(
                    total_dirs), Head_format)
                summery.merge_range('E2:I2', "Total Files is : {}".format(
                    total_files), Head_format)
                summery.merge_range('J2:M2', "Total Size is : {}".format(
                    total_data), Head_format)
                summery_row = 4

            if "Anchor size:" in line:
                adata = line.split(':')

                summery.merge_range('A1:D1', "Number of Directories is   {}".format(
                    adata[5].split(';')[0].strip()), Head_format)
                summery.merge_range('E1:I1', "Number of Files is   {}".format(
                    adata[6].split(';')[0].strip()), Head_format)
                summery.merge_range('J1:M1', "Total Size is   {}".format(
                    adata[7].strip().split(' ')[0]), Head_format)
                summery_row = 2
                summery_row = print_header(summery, summery_row, '')
                summery.merge_range (summery_row-2,0,summery_row-1,1, "Test Name", symmery_title_formats.cols[0])

            # start the test results section with header
            if "Interval" in line and start_section ==1:
                t_date = line[:12].replace(', ','-').replace(' ','-')

                worksheet.write(row, 0, t_date,symmery_title_formats.cols[0])

                row = print_header(worksheet, row, t_date)
                chart_start_line = row + 2

                line = fh.readline()    # read the second line header.
                start_section = 2

            # Getting test results
            if ":" in line and start_section > 0 and "Reached" not in line and "anchor" not in line:
                dataline = data_line(line)

                if "avg" in line:
                    summery_row = dataline.write(summery, summery_row)
                    sti = 0  # summery title format index
                    if "format" in tit:
                        sti = 1
                    elif "max" in tit:
                        sti = 2
                    elif "curve" in tit:
                        sti = 3
                    summery.merge_range(summery_row-1, 0, summery_row-1, 1, tit, format_summery_title[sti])
                    dataline.data[1] = "AVG"
                    start_section = 0
                    write_chart(chart_start_line,row,'E','K','{} Results'.format(rd),
                                'IOPS','Latency(ms)',chart_start_line-1)

                row = dataline.write(worksheet, row)

                if "avg" in line:
                    row = space_line(worksheet, row)

            # Getting the test name (RD) from the log
            if "Starting RD" in line:
                if cchart.title is not None and "curve" not in line.lower():
                    cchart.endline(summery_row)
                    cchart.write_chart()
                    cchart  = CurveChart(None, 0,0)

                rd = line.split(';')[0].split('=')[-1]
                tit = rd

                if "format" not in line:
                    tit = rd.split('_')[-1]
                    iorate = line.split(';')[2].split()[0].split('=')[-1].capitalize()
                else:
                    iorate = "Max"

                worksheet.merge_range(row,0,row,6,rd, Head_format)
                worksheet.merge_range(row,7,row,12,"IORATE={}".format(iorate), Head_format)
                row = row + 1

                if "curve" in iorate.lower():
                    if cchart.title == None:
                        cchart = CurveChart(rd, summery_row + 2, summery_row)

                start_section = 1

            line = fh.readline()

        if cchart.title is not None:
            cchart.endline(summery_row)
            cchart.write_chart()

    space_line(summery, summery_row)
    """
        make sure the FileHandlers closed.
    """
    fh.close()
    workbook.close()
    return 0

if __name__ == "__main__":
    exit(main())
