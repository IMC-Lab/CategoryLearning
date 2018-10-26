#!/usr/bin/python3

import os, sys
from PIL import Image, ImageColor, ImageDraw

COMPONENT_DIR = 'Components'
OUTPUT_DIR = 'images'
FILE_TYPE = '.png'
IMG_W = 500
IMG_H = 500

LEG_PREFIX = 'legs'
LEG_COLOR = (0,0,0) # encoded in RGB (black)
LEG_OFFSET = (0,48) # move legs lower than the center

SEGMENT_PREFIX = 'segment'
SEGMENT_COUNTS = range(1,4)
SEGMENT_SHAPES = ['circle', 'triangle', 'rectangle']
BODY_SIZE = [100, 250] # height divided among segments
BODY_COLOR = (0,0,0) # encoded in RGB (black)

ANTENNAE_PREFIX = 'antennae'
ANTENNAE_COUNTS = [1, 2, 4]
ANTENNAE_COLORS = {'purple':(205, 0, 255),   # encoded in RGB
                   'orange':(255, 40, 15),
                  # 'brightgreen':(0, 255, 60),
                   'lightblue':(55, 175, 255)}
ANTENNAE_OFFSET = (0, -150)

WING_PREFIX = 'wings'
WING_COUNTS = range(1,4)
WING_ALPHA = 2.0/3.0 # transparency
WING_COLORS = {'blue':(60, 0, 180),     # encoded in RGB
               #'pink':(190, 0, 125),
               'yellow':(185, 160, 75),
               'green':(0, 200, 75)}
WING_OFFSET = (0, 25)

def component(name, prefix='', folder_name=COMPONENT_DIR, file_type=FILE_TYPE):
    """Get the image for the component of a given name.
    prefix- the name of the component's feature (leg, segment, wing)
    name- the feature's value
    folder_name- the enclosing folder for component images
    file_type- the format of component images"""
    path = os.path.dirname(__file__) + '/' + folder_name + '/'
    if prefix and name:
        return Image.open(path + prefix + '_' + str(name) + file_type)
    elif prefix:
        return Image.open(path + prefix + file_type)
    elif name:
        return Image.open(path + name + file_type)

    
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

def set_alpha(img, alpha):
    img.putalpha(Image.eval(img.getchannel('A'), lambda x: x*alpha))
    return img


def draw_insect(segment_count, segment_shape,
             wing_count, wing_color, wing_rgb,
             antennae_count, antennae_color, antennae_rgb):
    insect = rgb_image((255,255,255))

    # draw the antennae
    draw_centered(insect, component(antennae_count, prefix=ANTENNAE_PREFIX),
                  antennae_rgb,
                  dx=ANTENNAE_OFFSET[0], dy=ANTENNAE_OFFSET[1])
    
    # draw the legs
    draw_centered(insect, component('', prefix=LEG_PREFIX),
                  LEG_COLOR, dx=LEG_OFFSET[0], dy=LEG_OFFSET[1])

    # draw the body segments
    segment = component(segment_shape, prefix=SEGMENT_PREFIX).resize((BODY_SIZE[0],
                                                                      int(BODY_SIZE[1] /
                                                                          segment_count)),
                                                                     Image.LANCZOS)
    for i in range(segment_count):
        draw_centered(insect, segment, BODY_COLOR,
                      dy=(i*segment.height -
                          ((segment_count - 1) * BODY_SIZE[1]) / (segment_count*2)))
    
    # draw the wings
    wing = set_alpha(component('', prefix=WING_PREFIX), WING_ALPHA)
    step = BODY_SIZE[1] / (wing_count+1)
    for i in range(wing_count):
        draw_centered(insect, wing, wing_rgb, dx=WING_OFFSET[0],
                      dy=(WING_OFFSET[1] + (i+1)*step - BODY_SIZE[1]/2))
    return insect

            
for segment_count in SEGMENT_COUNTS:
    for segment_shape in SEGMENT_SHAPES:
#        for wing_count in WING_COUNTS:
        wing_count = 1
        for wing_color, wing_rgb in WING_COLORS.items():
            for antennae_count in ANTENNAE_COUNTS:
                for antennae_color, antennae_rgb in ANTENNAE_COLORS.items():
                    insect = draw_insect(segment_count, segment_shape,
                                         wing_count,
                                         wing_color, wing_rgb,
                                         antennae_count, antennae_color, antennae_rgb)
                        
                    # save the image to a file
                    insect.save(os.path.dirname(__file__) + '/' + OUTPUT_DIR
                                + '/insect_' + str(segment_count) + '_' + segment_shape + '_'
                                + str(antennae_count) + '_' + antennae_color + '_'
                                + wing_color + FILE_TYPE)
