import getopt, sys
import cv2
#import numpy as np

############################################################################
### python resize_png.py -i input.png -o output.png -r 200 -c 600
############################################################################
usage = """
Usage:
This script will compress a PNG file using INTER_AREA interpolation

python resize_png.py -i <input image> -o <output image> -r <row num after compress> -c <col num after compress>'

Example:
python resize_png.py -i 17385_memeCluster1_10.png -o test.png -r 400 -c 400
"""

#       res = cv2.resize(img, dsize=(col_num, row_num), interpolation=cv2.INTER_NEAREST)
#       res = cv2.resize(img, dsize=(col_num, row_num), interpolation=cv2.INTER_LINEAR)
#       res = cv2.resize(img, dsize=(col_num, row_num), interpolation=cv2.INTER_AREA)
#       res = cv2.resize(img, dsize=(col_num, row_num), interpolation=cv2.INTER_CUBIC)
#       res = cv2.resize(img, dsize=(col_num, row_num), interpolation=cv2.INTER_LANCZOS4)

if __name__ == '__main__':

	#check for command line arguments
	if len(sys.argv) < 2 or not sys.argv[1].startswith("-"): sys.exit(usage)
        # get arguments
        try:
		optlist, alist = getopt.getopt(sys.argv[1:], 'hi:o:r:c:')
	except getopt.GetoptError:
                sys.exit(usage)

	#default figure width/height is defined by matrix size
	#if user-defined size is smaller than matrix, activate rebin function
	row_num = 600
	col_num = 200

        for opt in optlist:
                if opt[0] == "-h":
                        sys.exit(usage)
                elif opt[0] == "-i":
                        input_file = opt[1]
                elif opt[0] == "-o":
                        out_file = opt[1]
                elif opt[0] == "-r":
                        row_num = int(opt[1])
                elif opt[0] == "-c":
                        col_num = int(opt[1])

	if row_num < 1:
		print "Invalid Row Number!!! Must be positive"
		sys.exit(usage)
	if col_num < 1:
		print "Invalid Column Number!!! Must be positive"
		sys.exit(usage)

	print "Row number (pixels):",row_num
	print "Col number (pixels):",col_num

	img = cv2.imread(input_file)
        res = cv2.resize(img, dsize=(col_num, row_num), interpolation=cv2.INTER_AREA)
	cv2.imwrite(out_file, res)
