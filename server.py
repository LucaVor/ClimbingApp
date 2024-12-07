from flask import Flask, send_file, jsonify, request, abort
from flask_cors import CORS, cross_origin
from werkzeug.utils import secure_filename
import colorsys
import shutil
import base64
import pickle
import model
import cv2
import io
import numpy as np
import os
import time

app = Flask(__name__)
cors = CORS(app) 
app.config['CORS_HEADERS'] = 'Content-Type'

def read_pickle (pickle_path: str):
    file_pickle = None
    
    with open (pickle_path, "rb") as f:
        file_pickle = pickle.loads (f.read ())
        f.close ()
        
    return file_pickle

def write_pickle (obj: object, pickle_path: str):
    with open (pickle_path, "wb") as f:
        f.write (pickle.dumps (obj))
        f.close ()

def create_wall (wall_path: str, wall_name: str):
    image = cv2.imread(os.path.join (wall_path, "img.jpg"))
    
    holds = model.get_holds_from_image (image, 0, 0, image.shape[1], image.shape[0])
    
    wall_information = {
        "name": wall_name,
        "holds": holds,
        "routes": [],
    }
    
    write_pickle (wall_information, os.path.join (wall_path, "wall.pkl"))
        
@app.route ("/getWalls", methods=["POST"])
@cross_origin ()
def getWalls ():    
    walls = os.listdir ("./walls")
    
    return walls

@app.route ("/removeHold", methods=["POST"])
@cross_origin ()
def removeHold ():    
    wall_path = "./walls/{}".format (request.json["name"])
    pickle_path = os.path.join (wall_path, "wall.pkl")
    wall_data = read_pickle (pickle_path)
    
    holds_to_remove = []
    
    for hold in wall_data["holds"]:
        if hold["id"] == request.json["id"]:
            holds_to_remove.append (hold)
                
    for hold_to_remove in holds_to_remove:
        wall_data["holds"].remove (hold_to_remove)
            
    write_pickle (wall_data, pickle_path)
    
    return "Success"
    

@app.route ("/addHold", methods=["POST"])
@cross_origin ()
def addHold ():    
    wall_path = "./walls/{}".format (request.json["name"])
    pickle_path = os.path.join (wall_path, "wall.pkl")
    wall_data = read_pickle (pickle_path)
    
    ID = round(time.time() * 1000)
    
    wall_image = cv2.imread(os.path.join (wall_path, "img.jpg"))
    
    center_x = (request.json["xmin"] + request.json["xmax"]) / 2
    center_y = (request.json["ymin"] + request.json["ymax"]) / 2
    radius_x = (request.json["xmax"] - request.json["xmin"]) / 2
    radius_y = (request.json["ymax"] - request.json["ymin"]) / 2
    
    def on_radius (position: float, radius: float, perc: float):
        return int(position + radius * perc)
    
    wall_image = wall_image[on_radius (center_y, -radius_y, 0.33):on_radius (center_y, radius_y, 0.33),
                            on_radius (center_x, -radius_x, 0.33):on_radius (center_x, radius_x, 0.33)]
    
    b = np.median (wall_image[:, :, 0]) / 255
    g = np.median (wall_image[:, :, 1]) / 255
    r = np.median (wall_image[:, :, 2]) / 255
    
    h, s, v = colorsys.rgb_to_hsv (r, g, b)
    
    hold_color_name = model.get_color_name (h, s, v)
    
    wall_data["holds"].append ({
        "xmin": request.json["xmin"],
        "xmax": request.json["xmax"],
        "ymin": request.json["ymin"],
        "ymax": request.json["ymax"],
        "id": ID,
        "hold_color_name": hold_color_name
    })
    
    write_pickle (wall_data, pickle_path)
    
    return {
        "id": ID,
        "hold_color_name": hold_color_name
    }
    
@app.route ("/addRoute", methods=["POST"])
@cross_origin ()
def addRoute ():    
    wall_path = "./walls/{}".format (request.json["name"])
    pickle_path = os.path.join (wall_path, "wall.pkl")
    wall_data = read_pickle (pickle_path)
    
    ID = round(time.time() * 1000)
    
    wall_data["routes"].append ({
        "start_hold_a": request.json["start_hold_a"],
        "start_hold_b": request.json["start_hold_b"],
        "finish_hold": request.json["finish_hold"],
        "activated_holds": request.json["activated_holds"],
        "route_name": request.json["route_name"],
        "id": ID,
        "rating": request.json["rating"],
    })
    
    write_pickle (wall_data, pickle_path)
    
    return {
        "id": ID
    }
    
@app.route ("/removeRoute", methods=["POST"])
@cross_origin ()
def removeRoute ():    
    wall_path = "./walls/{}".format (request.json["name"])
    pickle_path = os.path.join (wall_path, "wall.pkl")
    wall_data = read_pickle (pickle_path)
    
    routes_to_remove = []
    
    for route in wall_data["routes"]:
        if route["id"] == request.json["id"]:
            routes_to_remove.append (route)
        
    for route_to_remove in routes_to_remove:
        wall_data["routes"].remove (route_to_remove)
    
    write_pickle (wall_data, pickle_path)
    
    return "Success"
    
@app.route ("/editRoute", methods=["POST"])
@cross_origin ()
def editRoute ():    
    wall_path = "./walls/{}".format (request.json["name"])
    pickle_path = os.path.join (wall_path, "wall.pkl")
    wall_data = read_pickle (pickle_path)
    
    for i, route in enumerate(wall_data["routes"]):
        if route["id"] == request.json["id"]:
            wall_data["routes"][i]["start_hold_a"] = request.json["start_hold_a"]
            wall_data["routes"][i]["start_hold_b"] = request.json["start_hold_b"]
            wall_data["routes"][i]["finish_hold"] = request.json["finish_hold"]
            wall_data["routes"][i]["activated_holds"] = request.json["activated_holds"]
            wall_data["routes"][i]["route_name"] = request.json["route_name"]
            wall_data["routes"][i]["rating"] = request.json["rating"]
    
    write_pickle (wall_data, pickle_path)
    
    return "Success"
    
@app.route ("/createWall", methods=["POST"])
@cross_origin ()
def createWall ():    
    name = request.json["name"]
    
    if not name:
        abort (500)
    
    wall_path = "./walls/{}".format (name)
    
    if os.path.exists (wall_path):
        shutil.rmtree (wall_path)
    
    os.mkdir (wall_path)
    
    with open (os.path.join (wall_path, "img.jpg"), "wb") as img:
        image_bytes = base64.b64decode (request.json["imageBytes"])
        img.write (image_bytes)
        img.close ()
        
    create_wall (wall_path, name)
        
    return "Success"

@app.route ("/changeHoldColor", methods=["POST"])
@cross_origin ()
def changeHoldColor():
    wall_path = "./walls/{}".format (request.json["name"])
    pickle_path = os.path.join (wall_path, "wall.pkl")
    wall_data = read_pickle (pickle_path)
        
    for idx, hold in enumerate(wall_data["holds"]):
        if hold["id"] == request.json["id"]:
            wall_data["holds"][idx]["hold_color_name"] = request.json["newColor"]
            
    write_pickle (wall_data, pickle_path)
    
    return "Success"
    
@app.route("/getRouteEditingInfo", methods=["POST"])
@cross_origin ()
def getRouteEditingInfo():    
    # Read Image
    wall_path = "./walls/{}".format (request.json["name"])
    image_path = os.path.join(wall_path, "img.jpg")
    image_bytes = None
    
    image = cv2.imread (image_path)
    
    with open(image_path, "rb") as image_file:
        image_bytes = image_file.read()
    
    image_base64 = base64.b64encode(image_bytes).decode("utf-8")
    
    # Read Hold Data
    wall_data = read_pickle (os.path.join (wall_path, "wall.pkl"))

    response_data = {
        "image": image_base64,
        "img_width":image.shape[1],
        "img_height": image.shape[0],
        "image_info": {
            "size": len(image_bytes),
            "format": "jpeg"
        },
        "wall data": wall_data
    }

    return response_data

@app.route("/getWallEditingInfo", methods=["POST"])
@cross_origin ()
def getWallEditingInfo():    
    # Read Image
    wall_path = "./walls/{}".format (request.json["name"])
    image_path = os.path.join(wall_path, "img.jpg")
    image_bytes = None
    
    image = cv2.imread (image_path)
    
    with open(image_path, "rb") as image_file:
        image_bytes = image_file.read()
    
    image_base64 = base64.b64encode(image_bytes).decode("utf-8")
    
    # Read Hold Data
    wall_data = read_pickle (os.path.join (wall_path, "wall.pkl"))

    response_data = {
        "image": image_base64,
        "img_width":image.shape[1],
        "img_height": image.shape[0],
        "image_info": {
            "size": len(image_bytes),
            "format": "jpeg"
        },
        "wall data": wall_data
    }

    return response_data

@app.route("/", methods=["GET"])
@cross_origin ()
def index():
    return "HI"

if __name__ == "__main__":
    app.run(debug=True, port=5222)
