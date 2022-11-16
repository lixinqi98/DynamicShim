#!/Users/mona/GitClone/nnUNet/unet/bin/python3

"""
Execute a graph cut on a region image based on some foreground and background markers.

Copyright (C) 2013 Oskar Maier

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

# build-in modules
from argparse import RawTextHelpFormatter
import argparse
import logging
import os

# third-party modules

# path changes

# own modules
from medpy.core import Logger
from medpy.io import load, save
from medpy.graphcut.wrapper import split_marker, graphcut_split,\
    graphcut_stawiaski



# information
__author__ = "Oskar Maier"
__version__ = "r0.3.4, 2012-03-16"
__email__ = "oskar.maier@googlemail.com"
__status__ = "Release"
__description__ = """
                  !Modified version of original GC label, as splits the volumes into
                  more handy sizes before processing them. Also uses multiple subprocesses.
                  
                  Perform a binary graph cut using Boykov's max-flow/min-cut algorithm.
                  
                  This implementation does only compute a boundary term and does not use
                  any regional term. The desired boundary term can be selected via the
                  --boundary argument. Depending on the selected term, an additional
                  image has to be supplied as badditional.
                  
                  In the case of the stawiaski boundary term, this is the gradient image.
                  In the case of the difference of means, it is the original image.
                  
                  Furthermore the algorithm requires the region map of the original
                  image, a binary image with foreground markers and a binary
                  image with background markers.
                  
                  Additionally a filename for the created binary mask marking foreground
                  and background has to be supplied.
                  
                  Note that the input images must be of the same dimensionality,
                  otherwise an exception is thrown.
                  Note to take into account the input images orientation.
                  Note that the quality of the resulting segmentations depends also on
                  the quality of the supplied markers.
                  
                  Copyright (C) 2013 Oskar Maier
                  This program comes with ABSOLUTELY NO WARRANTY; This is free software,
                  and you are welcome to redistribute it under certain conditions; see
                  the LICENSE file or <http://www.gnu.org/licenses/> for details.   
                  """

# code
def main():
    # parse cmd arguments
    parser = getParser()
    parser.parse_args()
    args = getArguments(parser)
    
    # prepare logger
    logger = Logger.getInstance()
    if args.debug: logger.setLevel(logging.DEBUG)
    elif args.verbose: logger.setLevel(logging.INFO)
        
    # check if output image exists
    if not args.force:
        if os.path.exists(args.output):
            logger.warning('The output image {} already exists. Exiting.'.format(args.output))
            exit(-1)
            
    # constants
    # the minimal edge length of a subvolume-cube ! has to be of type int!
    minimal_edge_length = 200
    overlap = 20
    
    # load input images
    region_image_data, reference_header = load(args.region)
    markers_image_data, _ = load(args.markers)
    gradient_image_data, _ = load(args.gradient)
    
    # split marker image into fg and bg images
    fgmarkers_image_data, bgmarkers_image_data = split_marker(markers_image_data)
       
    # execute distributed graph cut
    output_volume = graphcut_split(graphcut_stawiaski,
                                   region_image_data,
                                   gradient_image_data,
                                   fgmarkers_image_data,
                                   bgmarkers_image_data,
                                   minimal_edge_length,
                                   overlap)
    
    # save resulting mask
    save(output_volume, args.output, reference_header, args.force)

    logger.info('Successfully terminated.')

def getArguments(parser):
    "Provides additional validation of the arguments collected by argparse."
    return parser.parse_args()

def getParser():
    "Creates and returns the argparse parser object."
    parser = argparse.ArgumentParser(description=__description__, formatter_class=RawTextHelpFormatter)
    parser.add_argument('gradient', help='The gradient magnitude image of the image to segment.')
    parser.add_argument('region', help='The region image of the image to segment.')
    parser.add_argument('markers', help='Binary image containing the foreground (=1) and background (=2) markers.')
    parser.add_argument('output', help='The output image containing the segmentation.')
    parser.add_argument('-f', dest='force', action='store_true', help='Set this flag to silently override files that exist.')
    parser.add_argument('-v', dest='verbose', action='store_true', help='Display more information.')
    parser.add_argument('-d', dest='debug', action='store_true', help='Display debug information.')
    
    return parser    

if __name__ == "__main__":
    main()