#!/usr/bin/python3

import math, os
import numpy as np
from PIL import Image

COMPONENT_DIR = 'Components'  # The folder for the flower components
OUTPUT_DIR = 'images'         # The folder for image output
FILE_TYPE = '.png'            # The image extension for the flower components

# Image size
IMG_W = 500
IMG_H = 500

# Filename prefixes for the petal, center, and sepal components
PETAL_PREFIX = 'petal'
CENTER_PREFIX = 'middle'
SEPAL_PREFIX = 'sepal'

# Features of the flowers
PETAL_STYLES = ['pointed', 'concave', 'round']
PETAL_COUNTS = [2, 4, 6, 8]
PETAL_COLORS = {'blue':(60, 0, 180),     # encoded in RGB
                'pink':(190, 0, 125),
                'yellow':(185, 160, 75),
                'green':(0, 200, 75)}
CENTER_SHAPES = ['circle', 'triangle', 'square', 'star']
CENTER_COLORS = {'purple':(205, 0, 255),   # encoded in RGB
                 'orange':(255, 40, 15),
                 'brightgreen':(0, 255, 60),
                 'lightblue':(55, 175, 255)}
SEPAL_COUNTS = [0, 1, 2, 3]

SEPAL_RGB = (0, 0, 0)
PETAL_RADIUS = 150

def remove_white(img):
    """Turns all white pixels into transparent pixels"""
    arr = np.array(np.asarray(img))
    r,g,b,a = np.rollaxis(arr, axis=-1)
    mask = ((r==255)&(g==255)&(b==255))
    arr[mask,3] = 0
    return Image.fromarray(arr, mode='RGBA')

def component(name, prefix='', folder_name=COMPONENT_DIR, file_type=FILE_TYPE):
    """Get the image for the component of a given name.
    prefix- the name of the component's feature (leg, segment, wing)
    name- the feature's value
    folder_name- the enclosing folder for component images
    file_type- the format of component images"""
    path = os.path.dirname(__file__) + '/' + folder_name + '/'
    if prefix and str(name):
        return remove_white(Image.open(path + prefix + '_' + str(name) + file_type))
    elif prefix:
        return remove_white(Image.open(path + prefix + file_type))
    elif name:
        return remove_white(Image.open(path + name + file_type))

def rgb_image(rgb, w=IMG_W, h=IMG_H):
    """Get a blank image of the color rgb"""
    return Image.new('RGBA', (w, h), rgb)

def hsv_image(hsl, w=IMG_W, h=IMG_H):
    """Get a blank image of the color hsv"""
    return rgb_image(ImageColor.getrgb('hsv(' + str(hsl[0]) + ', '
                                       + str(hsl[1]) + '%, '
                                       + str(hsl[2]) + '%)'), w=w, h=h)

def draw_centered(background, img, color, dx=0, dy=0):
    """Draw an img on a background centered around the 
    background's center + (dx, dy)"""
    background.paste(rgb_image(color, w=img.width, h=img.height),
                     box=(int(dx + background.width/2.0 - img.width/2.0),
                          int(dy + background.height/2.0 - img.height/2.0)),
                     mask=img)


def draw_rotated(background, img, color, angle, radius=PETAL_RADIUS, dx=0, dy=0):
    """Draw img on background rotated about (dx, dy)"""
    draw_centered(background, img.rotate(angle, expand=True), color,
                  dx=dx+radius*math.cos(math.radians(angle)),
                  dy=dy+radius*math.sin(math.radians(angle)))

def draw_flower(petal_style, petal_color, petal_rgb, petal_num,
                center_color, center_rgb, center_shape, sepal_num):
    # Make a blank image
    flower = rgb_image((255, 255, 255))
    
    # Draw the center
    center = component(center_shape, prefix=CENTER_PREFIX)
    draw_centered(flower, center, center_rgb)
    
    # Draw the petals and sepals
    petal = component(petal_style, PETAL_PREFIX)
    for angle in range(0, 360, int(360/petal_num)):
        draw_rotated(flower, petal, petal_rgb, angle)
    
    sepal = component(sepal_num, prefix=SEPAL_PREFIX)
    for angle in range(0, 360, int(360/petal_num)):
        draw_rotated(flower, sepal, SEPAL_RGB, int(angle + 180/petal_num),
                     radius=-PETAL_RADIUS)
    return flower

for petal_style in PETAL_STYLES:
    for petal_color, petal_rgb in PETAL_COLORS.items():
        for petal_num in PETAL_COUNTS:
            for center_color, center_rgb in CENTER_COLORS.items():
                for center_shape in CENTER_SHAPES:
                    for sepal_num in SEPAL_COUNTS:                    
                        flower = draw_flower(petal_style, petal_color, petal_rgb, petal_num,
                                             center_color, center_rgb, center_shape,
                                             sepal_num)
                        # save the image
                        flower.save(os.path.dirname(__file__) + '/' + OUTPUT_DIR + '/stim_'
                                    + petal_style + '_' + str(petal_num)
                                    + '_' + petal_color + '_' + center_shape
                                    + '_' + center_color + '_' + str(sepal_num) + FILE_TYPE)
