import os

PORT = 8001

os.chdir (".\\climbingapp\\build\\web")
os.system ("python -m http.server {}".format (PORT))