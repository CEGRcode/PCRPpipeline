#! /usr/bin/python

import os, sys, getopt
from io import BytesIO
import base64
from PIL import Image, ImageOps, ImageDraw, ImageFont

usage = """
Usage:
This script will annotate heatmaps given input parameters
-i Input PNG File
-o Output PNG File
-b true/false add border and tick marks
-v "-500,0,500" must be string containing 3 comma-delimited variables
-x "X-label"
-y "Y-label"
-t "Title"

Example: python label_Heatmap.py -i USF1_merge.png -o USF1_label.png -b true -v "-250,0,250" -x "Distance from Motif midpoint (bp)" -y "N=1,800" -t "USF1 1B8 K562 ChIP-exo"
***
"""

def add_ImageBorder(image):
     THICK = 2
     THIN = 1
     # Add borders to img
     borderimg = ImageOps.expand(image, border=(2,2,2,2), fill=(0,0,0))
     origwidth, origheight = borderimg.size
     # Add empty bottom to img
     borderimg = ImageOps.expand(borderimg, border=(0,0,0,5), fill=(255, 255, 255, 0))
     # Get new axis dimensions
     width, height = borderimg.size
     draw = ImageDraw.Draw(borderimg) 
     draw.line((0,origheight, 0,height), fill=(0,0,0), width=THICK)
     draw.line((width-THICK,origheight, width-THICK,height), fill=(0,0,0), width=THICK)
     draw.line((width/2,origheight, width/2,height), fill=(0,0,0), width=THICK)
     draw.line((width/4,origheight, width/4,height), fill=(0,0,0), width=THIN)
     draw.line(((width/4)*3,origheight, (width/4)*3,height), fill=(0,0,0), width=THIN)
     return borderimg

def add_Xvalue(image, left, middle, right):
    ORIGwidth, ORIGheight = image.size
    # Add y-axis labels
    font = ImageFont.truetype(os.path.join(sys.path[0],"arial.ttf"), 12)
    Lwidth, Lheight = font.getsize(left)
    Mwidth, Mheight = font.getsize(middle)
    Rwidth, Rheight = font.getsize(right)
    #Rotate all images 315 degrees
    Limage = Image.new('RGBA', (Lwidth, Lheight), (255, 255, 255, 0))
    Ldraw = ImageDraw.Draw(Limage)
    Ldraw.text((0, 0), text=left, font=font, fill=(0, 0, 0))
    Limage = Limage.rotate(315, expand=1)
    Mimage = Image.new('RGBA', (Mwidth, Mheight), (255, 255, 255, 0))
    Mdraw = ImageDraw.Draw(Mimage)
    Mdraw.text((0, 0), text=middle, font=font, fill=(0, 0, 0))
    Rimage = Image.new('RGBA', (Rwidth, Rheight), (255, 255, 255, 0))
    Rdraw = ImageDraw.Draw(Rimage)
    Rdraw.text((0, 0), text=right, font=font, fill=(0, 0, 0))
    Rimage = Rimage.rotate(315, expand=1)

    Lwidth, Lheight = Limage.size
    Mwidth, Mheight = Mimage.size
    Rwidth, Rheight = Rimage.size
    newHeight = max(Lheight, Mheight, Rheight)
    xaxisimg = ImageOps.expand(image, border=((Lwidth / 2),0,(Rwidth / 2),newHeight), fill=(255,255,255,0))
    width, height = xaxisimg.size
    xaxisimg.paste(Limage, (0, (height - Lheight)), Limage)
    xaxisimg.paste(Mimage, ((width / 2) - (Mwidth / 2), ORIGheight), Mimage)
    xaxisimg.paste(Rimage, (width - Rwidth, (height - Rheight)), Rimage)
    return xaxisimg

def add_Xlabel(label, image):
    # Add x-axis labels
    font = ImageFont.truetype(os.path.join(sys.path[0],"arial.ttf"), 12)
    xwidth, xheight = font.getsize(label)
    xaxisimg=ImageOps.expand(image, border=(0,0,0,xheight + 1), fill=(255,255,255,0))
    width, height = image.size
    # Adjust width of image if label size larger than native image
    if xwidth > width:
        xaxisimg = ImageOps.expand(xaxisimg, border=((xwidth - width) / 2,0,(xwidth - width) / 2,0), fill=(255,255,255,0))
    drawTitle = ImageDraw.Draw(xaxisimg)
    drawTitle.text(((xaxisimg.size[0] / 2) - (xwidth / 2), height), text=label, font=font, fill=(0, 0, 0))
    return xaxisimg

def add_Ylabel(label, image):
    width, height = image.size
    # Add y-axis labels
    font = ImageFont.truetype(os.path.join(sys.path[0],"arial.ttf"), 12)
    ywidth, yheight = font.getsize(label)
    yaxisimg=ImageOps.expand(image, border=(yheight + 1,0,0,0), fill=(255,255,255,0))
    yimage = Image.new('RGBA', (ywidth, yheight), (255, 255, 255, 0))
    ydraw = ImageDraw.Draw(yimage)
    ydraw.text((0, 0), text=label, font=font, fill=(0, 0, 0))
    yimage = yimage.rotate(90, expand=1)
    # Centers y-label against image
    sx, sy = yimage.size
    px, py = 0, (height / 2)
    yaxisimg.paste(yimage, (px, (py - (sy / 2))), yimage)
    return yaxisimg

def add_Title(title, image):
   # Add Title
    font = ImageFont.truetype(os.path.join(sys.path[0],"arial.ttf"), 12)
    Twidth, Theight = font.getsize(title)
    imgTitle=ImageOps.expand(image, border=(0,(Theight + 1),0,0), fill=(255,255,255,0))
    width, height = image.size
    if Twidth > width:
        imgTitle=ImageOps.expand(imgTitle, border=((Twidth - width) / 2,0,(Twidth - width) / 2,0), fill=(255,255,255,0))
    drawTitle = ImageDraw.Draw(imgTitle)
    drawTitle.text(((imgTitle.size[0] / 2) - (Twidth / 2), 0), text=title, font=font, fill=(0, 0, 0))
    return imgTitle

if __name__ == '__main__':
    if len(sys.argv) < 2 or not sys.argv[1].startswith("-"): sys.exit(usage)
    
    # Set defaults
    border = "true"
    value = ""
    XLABEL = ""
    YLABEL = ""
    TITLE = ""
    
    # Get arguments
    optlist, alist = getopt.getopt(sys.argv[1:], 'hi:o:b:v:x:y:t:')
    for opt in optlist:
        if opt[0] == "-h": sys.exit(usage)
        elif opt[0] == "-i": inPNG = opt[1]
        elif opt[0] == "-o": outPNG  = opt[1]
        elif opt[0] == "-b": border = opt[1]
        elif opt[0] == "-v": value = opt[1]
        elif opt[0] == "-x": XLABEL  = opt[1]
        elif opt[0] == "-y": YLABEL = opt[1]
        elif opt[0] == "-t": TITLE  = opt[1]

    # Open original image
    img = Image.open(open(inPNG))
    
    # Add Border and x-axis ticks
    if border == 'true':
        img = add_ImageBorder(img)

    # X-axis labeling
    if value != "":
        xNum = value.split(",")
        if(len(xNum) == 3):
            img = add_Xvalue(img, xNum[0], xNum[1], xNum[2])
        else:
            sys.stderr.write("Improper x-axes values entered!!!")

    # Add X-label
    YEXIST = 0
    if XLABEL != "":
	# If X-axis is larger than image at this point, process y-axis first so it does blow out
        # otherwise process first
        font = ImageFont.truetype(os.path.join(sys.path[0],"arial.ttf"), 12)
        Xwidth = font.getsize(XLABEL)[0]
	if Xwidth > img.size[0] and YLABEL != "":
	    img = add_Ylabel(YLABEL, img)
	    YEXIST = 1
        img = add_Xlabel(XLABEL, img)

    # Add Y-label
    if YLABEL != "" and YEXIST != 1:
        img = add_Ylabel(YLABEL, img)

    # Add Title
    if TITLE != "":
        img = add_Title(TITLE, img)

    # Output new PNG
    img.save(outPNG)
