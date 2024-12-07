import os
import cv2
import tqdm
import colorsys
import torch
import numpy as np
import matplotlib.pyplot as plt
from detectron2.config import get_cfg
from detectron2.engine import DefaultPredictor
from detectron2.structures import Boxes
from detectron2.utils.visualizer import Visualizer
from detectron2.data import MetadataCatalog
from scipy.ndimage import distance_transform_edt
import pickle

def make_global (path: str) -> str:
    return os.path.join (os.getcwd(), path)

# Load configuration and model weights
config_pickle = open (make_global ("smear_model/hold-detector_cfg.pickle"), "rb")
config = pickle.load (config_pickle)
config_pickle.close ()

config.MODEL.WEIGHTS = make_global ("smear_model/smear_beta.pth")
config.MODEL.ROI_HEADS.SCORE_THRESH_TEST = 0.5  # Threshold for detections
config.MODEL.ROI_HEADS.NMS_THRESH_TEST = 0.5   # Non-Maximum Suppression threshold
config.MODEL.DEVICE = "cpu"

predictor = DefaultPredictor(config)

# Prediction function
def predict(image: np.ndarray):
    prediction = predictor(image)
    return prediction

def get_color_name (hue: float, saturation: float, value: float):
    hue *= 360
    
    if saturation < 0.05:
        return "White"
    if value <= 0.2:
        return "Black"
    
    if 0 <= hue < 30:
        return "Red"
    elif 30 <= hue < 70:
        return "Yellow"
    elif 70 <= hue < 160:
        return "Green"
    elif 160 <= hue < 240:
        return "Blue"
    elif 240 <= hue < 290:
        return "Purple"
    elif 290 <= hue < 340:
        return "Pink"
    elif 340 <= hue <= 360:
        return "Red"
    
    raise Exception ("This point in the code should not be reached. Hue and Saturation were {} and {}".format (hue, saturation))

def get_holds_from_image (image: np.ndarray, lower_x: int, lower_y: int, upper_x: int, upper_y: int):
    image_slice = image[lower_y: upper_y, lower_x: upper_x]
    print (image_slice)
    prediction = predict (image_slice)

    holds = []

    boxes = prediction["instances"].pred_boxes.tensor.cpu().numpy()
    classes = prediction["instances"].pred_classes.cpu().numpy()
    scores = prediction["instances"].scores.cpu().numpy()
    masks = prediction["instances"].pred_masks.cpu().numpy()
    
    for hold_idx in tqdm.tqdm(range (len (prediction["instances"])), desc="Parsing Holds"):
        local_mask = masks[hold_idx].astype (np.float32)
        bbox = boxes[hold_idx].astype (np.int32)
        
        b, g, r = np.median (image_slice[local_mask == 1], axis=0) / 255
        h, s, v = colorsys.rgb_to_hsv (r, g, b)
        r, g, b = colorsys.hsv_to_rgb (h, s, v)
        
        hold_color_name = get_color_name (h, s, v)
        
        global_mask = np.zeros (shape=image.shape[:2])
        global_mask[lower_y: upper_y, lower_x: upper_x] = local_mask
        
        holds.append  ({"ymin": int(bbox[1] + lower_y),
                        "ymax": int(bbox[3] + lower_y),
                        "xmin": int(bbox[0] + lower_x),
                        "xmax": int(bbox[2] + lower_x),
                        "hold_color_name": hold_color_name,
                        "id": hold_idx})
        
    return holds

# image = cv2.imread ("./test_images/project24.jpg")
# holds = get_holds_from_image (image, 0, 0, image.shape[1], image.shape[0])
# np.random.shuffle (holds)

# for hold in holds:
#     print (hold)
#     plt.imshow (image[hold["ymin"]:hold["ymax"],hold["xmin"]:hold["xmax"]])
#     plt.show ()