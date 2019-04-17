#!/usr/bin/python3

import os, sys
from PIL import Image, ImageColor, ImageDraw

COMPONENT_DIR = 'Components'
OUTPUT_DIR = 'images'
OUTPUT_FILE_TYPE = '.png'
COMPONENT_FILE_TYPE = '.png'
IMG_W = 500
IMG_H = 500

SHELL_PREFIX = 'shell_short'
SHELL_SHAPES = ['circle', 'box'] #, 'triangle']
SHELL_SIZE = [100, 250]
SHELL_COLOR = (0, 0, 0) # encoded in RGB (black)
SHELL_OFFSET = (0, 12.5)

HEAD_PREFIX = 'head'
HEAD_OFFSET = (0, -190)
HEAD_SHAPES = ['circle', 'triangle']

LEG_PREFIX = 'legs_short'
LEG_OFFSET = (0,15) # move legs lower than the center
LEG_SHAPES = ['fin', 'turtle'] #, 'tortoise']
LEG_COLORS = {#'blue':(60, 0, 180),     # encoded in RGB
              'pink':(190, 0, 125),
              #'yellow':(185, 160, 75),
              'green':(0, 200, 75)}

TAIL_PREFIX = 'tail'
TAIL_OFFSET = (0, 200)
TAIL_TYPES = ['left', 'right']
              
SPOT_PREFIX = 'spots'
SPOT_COUNTS = [1, 3] #range(1, 4)
SPOT_COLORS = {#'purple':(205, 0, 255),   # encoded in RGB
               'orange':(255, 40, 15),
               #'brightgreen':(0, 255, 60),
               'lightblue':(55, 175, 255)}
SPOT_OFFSET = (0, 35)

def component(name, prefix='', folder_name=COMPONENT_DIR, file_type=COMPONENT_FILE_TYPE):
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

def draw_centered(background, img, color, offset=(0, 0)):
    """Draw an img on a background centered around the 
    background's center + (dx, dy)"""
    background.paste(rgb_image(color, w=img.width, h=img.height),
                     box=(int(offset[0] + background.width/2.0 - img.width/2.0),
                          int(offset[1] + background.height/2.0 - img.height/2.0)),
                     mask=img)

def draw_turtle(shell_shape, spot_count, spot_color, spot_rgb,
                head_shape, tail_type,
                leg_shape, leg_color, leg_rgb):
    turtle = rgb_image((255,255,255))

    # draw the shell
    draw_centered(turtle, component(shell_shape, prefix=SHELL_PREFIX),
                  SHELL_COLOR, offset=SHELL_OFFSET)
    
    # draw the head, legs, and tail
    draw_centered(turtle, component(head_shape, prefix=HEAD_PREFIX), leg_rgb, offset=HEAD_OFFSET)
    draw_centered(turtle, component(leg_shape, prefix=LEG_PREFIX), leg_rgb, offset=LEG_OFFSET)
    draw_centered(turtle, component(tail_type, prefix=TAIL_PREFIX), leg_rgb, offset=TAIL_OFFSET)
    
    # draw the spots
    draw_centered(turtle, component(spot_count, prefix=SPOT_PREFIX), spot_rgb, offset=SPOT_OFFSET)
    return turtle

            
for shell_shape in SHELL_SHAPES:
    for spot_count in SPOT_COUNTS:
        for spot_color, spot_rgb in SPOT_COLORS.items():
            for head_shape in HEAD_SHAPES:
                for tail_type in TAIL_TYPES:
                    for leg_shape in LEG_SHAPES:
                        for leg_color, leg_rgb in LEG_COLORS.items():
                            turtle = draw_turtle(shell_shape, spot_count, spot_color, spot_rgb,
                                                 head_shape, tail_type, leg_shape, leg_color, leg_rgb)
                            
                            # save the image to a file
                            turtle.save(os.path.dirname(__file__) + '/' + OUTPUT_DIR
                                        + '/turtle_' + shell_shape + '_' + str(spot_count) + '_'
                                        + spot_color + '_' + head_shape + '_' + tail_type + '_'
                                        + leg_shape + '_' + leg_color + OUTPUT_FILE_TYPE)
                            
