"""
Synthetic Data Generator for GeoDisha BigQuery Tables
Generates realistic data for 15 Telangana constituencies across 6 modules
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta, date, time
import random
import uuid
import json
from pathlib import Path

# Telangana Parliamentary Constituencies (2019 Lok Sabha Election Data)
CONSTITUENCIES = [
    {"id": "PC01", "name": "Adilabad", "pc_no": 1, "electors": 1489790, "voters": 1062895, "male_voters": 523054, "female_voters": 539832, "turnout": 71.42},
    {"id": "PC02", "name": "Peddapalle", "pc_no": 2, "electors": 1479091, "voters": 969198, "male_voters": 484439, "female_voters": 484738, "turnout": 65.59},
    {"id": "PC03", "name": "Karimnagar", "pc_no": 3, "electors": 1651543, "voters": 1146915, "male_voters": 558800, "female_voters": 588108, "turnout": 69.52},
    {"id": "PC04", "name": "Nizamabad", "pc_no": 4, "electors": 1553385, "voters": 1061622, "male_voters": 474024, "female_voters": 587594, "turnout": 68.44},
    {"id": "PC05", "name": "Zahirabad", "pc_no": 5, "electors": 1498666, "voters": 1043843, "male_voters": 514518, "female_voters": 529323, "turnout": 69.70},
    {"id": "PC06", "name": "Medak", "pc_no": 6, "electors": 1603318, "voters": 1149490, "male_voters": 581947, "female_voters": 567533, "turnout": 71.75},
    {"id": "PC07", "name": "Malkajgiri", "pc_no": 7, "electors": 3150313, "voters": 1561400, "male_voters": 823072, "female_voters": 738294, "turnout": 49.63},
    {"id": "PC08", "name": "Secunderabad", "pc_no": 8, "electors": 1968276, "voters": 914154, "male_voters": 488024, "female_voters": 426124, "turnout": 46.50},
    {"id": "PC09", "name": "Hyderabad", "pc_no": 9, "electors": 1957931, "voters": 877267, "male_voters": 479564, "female_voters": 397698, "turnout": 44.84},
    {"id": "PC10", "name": "Chevella", "pc_no": 10, "electors": 2443112, "voters": 1298953, "male_voters": 678645, "female_voters": 620290, "turnout": 53.25},
    {"id": "PC11", "name": "Mahbubnagar", "pc_no": 11, "electors": 1506102, "voters": 983891, "male_voters": 494155, "female_voters": 489732, "turnout": 65.39},
    {"id": "PC12", "name": "Nagarkurnool", "pc_no": 12, "electors": 1588111, "voters": 989048, "male_voters": 502620, "female_voters": 486427, "turnout": 62.33},
    {"id": "PC13", "name": "Nalgonda", "pc_no": 13, "electors": 1585980, "voters": 1174750, "male_voters": 585803, "female_voters": 588944, "turnout": 74.15},
    {"id": "PC14", "name": "Bhongir", "pc_no": 14, "electors": 1628033, "voters": 1211256, "male_voters": 616922, "female_voters": 594332, "turnout": 74.49},
    {"id": "PC15", "name": "Warangal", "pc_no": 15, "electors": 1666770, "voters": 1060412, "male_voters": 530268, "female_voters": 530078, "turnout": 63.70},
    {"id": "PC16", "name": "Mahabubabad", "pc_no": 16, "electors": 1424385, "voters": 982734, "male_voters": 485104, "female_voters": 497622, "turnout": 69.06},
    {"id": "PC17", "name": "Khammam", "pc_no": 17, "electors": 1513809, "voters": 1138425, "male_voters": 559568, "female_voters": 578825, "turnout": 75.30}
]

# Assembly Constituencies (ACs) per Parliamentary Constituency with 2023 Election Data
# Each PC has 7 Assembly Constituencies
ASSEMBLY_CONSTITUENCIES = {
    "PC01": [
        {"name": "Boath", "ac_no": 8, "electors": 208599, "voters": 174078, "male_voters": 85031, "female_voters": 87347, "turnout": 83.45},
        {"name": "Nirmal", "ac_no": 9, "electors": 253551, "voters": 198524, "male_voters": 89197, "female_voters": 106647, "turnout": 78.30},
        {"name": "Khanapur", "ac_no": 6, "electors": 220942, "voters": 174325, "male_voters": 82023, "female_voters": 90385, "turnout": 78.90},
        {"name": "Adilabad", "ac_no": 7, "electors": 240559, "voters": 188956, "male_voters": 92577, "female_voters": 93305, "turnout": 78.55},
        {"name": "Asifabad", "ac_no": 5, "electors": 226778, "voters": 184723, "male_voters": 92584, "female_voters": 90932, "turnout": 81.46},
        {"name": "Mancherial", "ac_no": 4, "electors": 275141, "voters": 192618, "male_voters": 93982, "female_voters": 96071, "turnout": 70.01},
        {"name": "Chennur", "ac_no": 2, "electors": 188417, "voters": 152246, "male_voters": 75588, "female_voters": 75196, "turnout": 80.80}
    ],
    "PC02": [
        {"name": "Husnabad", "ac_no": 32, "electors": 242397, "voters": 206871, "male_voters": 101937, "female_voters": 103079, "turnout": 85.34},
        {"name": "Huzurabad", "ac_no": 31, "electors": 249738, "voters": 209636, "male_voters": 102204, "female_voters": 105413, "turnout": 83.94},
        {"name": "Karimnagar", "ac_no": 26, "electors": 355156, "voters": 229902, "male_voters": 111988, "female_voters": 112458, "turnout": 64.73},
        {"name": "Choppadandi", "ac_no": 27, "electors": 233183, "voters": 182384, "male_voters": 85549, "female_voters": 95655, "turnout": 78.21},
        {"name": "Vemulawada", "ac_no": 28, "electors": 222304, "voters": 175628, "male_voters": 78248, "female_voters": 96062, "turnout": 79.00},
        {"name": "Sircilla", "ac_no": 29, "electors": 244532, "voters": 189752, "male_voters": 90110, "female_voters": 98088, "turnout": 77.60},
        {"name": "Peddapalle", "ac_no": 25, "electors": 254530, "voters": 209217, "male_voters": 103531, "female_voters": 103864, "turnout": 82.20}
    ],
    "PC03": [
        {"name": "Karimnagar", "ac_no": 26, "electors": 355156, "voters": 229902, "male_voters": 111988, "female_voters": 112458, "turnout": 64.73},
        {"name": "Choppadandi", "ac_no": 27, "electors": 233183, "voters": 182384, "male_voters": 85549, "female_voters": 95655, "turnout": 78.21},
        {"name": "Vemulawada", "ac_no": 28, "electors": 222304, "voters": 175628, "male_voters": 78248, "female_voters": 96062, "turnout": 79.00},
        {"name": "Sircilla", "ac_no": 29, "electors": 244532, "voters": 189752, "male_voters": 90110, "female_voters": 98088, "turnout": 77.60},
        {"name": "Manakondur", "ac_no": 30, "electors": 221741, "voters": 185891, "male_voters": 91497, "female_voters": 92915, "turnout": 83.83},
        {"name": "Huzurnagar", "ac_no": 89, "electors": 247708, "voters": 216220, "male_voters": 104729, "female_voters": 109315, "turnout": 87.29},
        {"name": "Korutla", "ac_no": 20, "electors": 240901, "voters": 183776, "male_voters": 80353, "female_voters": 101785, "turnout": 76.29}
    ],
    "PC04": [
        {"name": "Armoor", "ac_no": 11, "electors": 210341, "voters": 161991, "male_voters": 69450, "female_voters": 90295, "turnout": 77.01},
        {"name": "Bodhan", "ac_no": 12, "electors": 220238, "voters": 172648, "male_voters": 81153, "female_voters": 90092, "turnout": 78.39},
        {"name": "Jukkal", "ac_no": 13, "electors": 200100, "voters": 164738, "male_voters": 81642, "female_voters": 82081, "turnout": 82.33},
        {"name": "Banswada", "ac_no": 14, "electors": 195384, "voters": 160146, "male_voters": 76007, "female_voters": 82651, "turnout": 81.96},
        {"name": "Yellareddy", "ac_no": 15, "electors": 220789, "voters": 184818, "male_voters": 87212, "female_voters": 96202, "turnout": 83.71},
        {"name": "Kamareddy", "ac_no": 16, "electors": 252620, "voters": 192913, "male_voters": 89936, "female_voters": 100866, "turnout": 76.36},
        {"name": "Nizamabad Urban", "ac_no": 17, "electors": 294902, "voters": 184680, "male_voters": 88928, "female_voters": 92872, "turnout": 62.62}
    ],
    "PC05": [
        {"name": "Narayankhed", "ac_no": 35, "electors": 231255, "voters": 194143, "male_voters": 98856, "female_voters": 93619, "turnout": 83.95},
        {"name": "Andole", "ac_no": 36, "electors": 249301, "voters": 212799, "male_voters": 105712, "female_voters": 105632, "turnout": 85.36},
        {"name": "Zahirabad", "ac_no": 38, "electors": 270889, "voters": 209108, "male_voters": 106452, "female_voters": 101310, "turnout": 77.19},
        {"name": "Sangareddy", "ac_no": 39, "electors": 245329, "voters": 187719, "male_voters": 92892, "female_voters": 92070, "turnout": 76.52},
        {"name": "Patancheru", "ac_no": 40, "electors": 397307, "voters": 277618, "male_voters": 142332, "female_voters": 134247, "turnout": 69.87},
        {"name": "Dubbak", "ac_no": 41, "electors": 198158, "voters": 174834, "male_voters": 85551, "female_voters": 87819, "turnout": 88.23},
        {"name": "Gajwel", "ac_no": 42, "electors": 274726, "voters": 232456, "male_voters": 115845, "female_voters": 115122, "turnout": 84.61}
    ],
    "PC06": [
        {"name": "Medak", "ac_no": 34, "electors": 216835, "voters": 186949, "male_voters": 89685, "female_voters": 95234, "turnout": 86.22},
        {"name": "Narsapur", "ac_no": 37, "electors": 223632, "voters": 198079, "male_voters": 97698, "female_voters": 99293, "turnout": 88.57},
        {"name": "Siddipet", "ac_no": 33, "electors": 233840, "voters": 181811, "male_voters": 88632, "female_voters": 89662, "turnout": 77.75},
        {"name": "Husnabad", "ac_no": 32, "electors": 242397, "voters": 206871, "male_voters": 101937, "female_voters": 103079, "turnout": 85.34},
        {"name": "Koratla", "ac_no": 20, "electors": 240901, "voters": 183776, "male_voters": 80353, "female_voters": 101785, "turnout": 76.29},
        {"name": "Jagtial", "ac_no": 21, "electors": 231513, "voters": 176478, "male_voters": 78820, "female_voters": 95651, "turnout": 76.23},
        {"name": "Dharmapuri", "ac_no": 22, "electors": 227013, "voters": 181789, "male_voters": 84111, "female_voters": 96338, "turnout": 80.08}
    ],
    "PC07": [
        {"name": "Malkajgiri", "ac_no": 44, "electors": 489299, "voters": 265616, "male_voters": 134333, "female_voters": 129692, "turnout": 54.29},
        {"name": "Quthbullapur", "ac_no": 45, "electors": 699239, "voters": 401745, "male_voters": 206924, "female_voters": 192808, "turnout": 57.45},
        {"name": "Kukatpally", "ac_no": 46, "electors": 463917, "voters": 250853, "male_voters": 129815, "female_voters": 120073, "turnout": 54.07},
        {"name": "Uppal", "ac_no": 47, "electors": 529574, "voters": 275085, "male_voters": 139730, "female_voters": 133489, "turnout": 51.94},
        {"name": "Lal Bahadur Nagar", "ac_no": 49, "electors": 593762, "voters": 295255, "male_voters": 149962, "female_voters": 141593, "turnout": 49.73},
        {"name": "Medchal", "ac_no": 43, "electors": 637995, "voters": 400602, "male_voters": 201870, "female_voters": 195203, "turnout": 62.79},
        {"name": "Mudhole", "ac_no": 10, "electors": 249826, "voters": 202345, "male_voters": 98036, "female_voters": 102936, "turnout": 80.99}
    ],
    "PC08": [
        {"name": "Secunderabad", "ac_no": 70, "electors": 262539, "voters": 142074, "male_voters": 70838, "female_voters": 70268, "turnout": 54.12},
        {"name": "Secunderabad Cantonment", "ac_no": 71, "electors": 250788, "voters": 124551, "male_voters": 62310, "female_voters": 61751, "turnout": 49.66},
        {"name": "Amberpet", "ac_no": 59, "electors": 277125, "voters": 146499, "male_voters": 73539, "female_voters": 71938, "turnout": 52.86},
        {"name": "Khairatabad", "ac_no": 60, "electors": 296036, "voters": 154945, "male_voters": 79557, "female_voters": 74674, "turnout": 52.34},
        {"name": "Jubilee Hills", "ac_no": 61, "electors": 385287, "voters": 183337, "male_voters": 95002, "female_voters": 87562, "turnout": 47.58},
        {"name": "Sanathnagar", "ac_no": 62, "electors": 249032, "voters": 129826, "male_voters": 66784, "female_voters": 62584, "turnout": 52.13},
        {"name": "Nampally", "ac_no": 63, "electors": 332791, "voters": 152425, "male_voters": 79859, "female_voters": 71956, "turnout": 45.80}
    ],
    "PC09": [
        {"name": "Karwan", "ac_no": 64, "electors": 359485, "voters": 175865, "male_voters": 92371, "female_voters": 82709, "turnout": 48.92},
        {"name": "Goshamahal", "ac_no": 65, "electors": 270633, "voters": 150275, "male_voters": 80405, "female_voters": 69443, "turnout": 55.53},
        {"name": "Charminar", "ac_no": 66, "electors": 226126, "voters": 98106, "male_voters": 53165, "female_voters": 44646, "turnout": 43.39},
        {"name": "Chandrayangutta", "ac_no": 67, "electors": 337912, "voters": 153791, "male_voters": 78684, "female_voters": 74532, "turnout": 45.51},
        {"name": "Yakutpura", "ac_no": 68, "electors": 353141, "voters": 140438, "male_voters": 73792, "female_voters": 66085, "turnout": 39.77},
        {"name": "Bahadurpura", "ac_no": 69, "electors": 316675, "voters": 144404, "male_voters": 77805, "female_voters": 66234, "turnout": 45.60},
        {"name": "Malakpet", "ac_no": 58, "electors": 317875, "voters": 132099, "male_voters": 67486, "female_voters": 63876, "turnout": 41.56}
    ],
    "PC10": [
        {"name": "Chevella", "ac_no": 53, "electors": 262079, "voters": 196917, "male_voters": 99962, "female_voters": 94872, "turnout": 75.14},
        {"name": "Pargi", "ac_no": 54, "electors": 259674, "voters": 201478, "male_voters": 100255, "female_voters": 98290, "turnout": 77.59},
        {"name": "Vicarabad", "ac_no": 55, "electors": 228330, "voters": 174299, "male_voters": 87026, "female_voters": 85454, "turnout": 76.34},
        {"name": "Tandur", "ac_no": 56, "electors": 236125, "voters": 175253, "male_voters": 85919, "female_voters": 87831, "turnout": 74.22},
        {"name": "Kalwakurthy", "ac_no": 83, "electors": 241897, "voters": 202794, "male_voters": 102700, "female_voters": 98526, "turnout": 83.83},
        {"name": "Shadnagar", "ac_no": 84, "electors": 236392, "voters": 195622, "male_voters": 98592, "female_voters": 95434, "turnout": 82.75},
        {"name": "Maheshwaram", "ac_no": 50, "electors": 546654, "voters": 306374, "male_voters": 154896, "female_voters": 148206, "turnout": 56.05}
    ],
    "PC11": [
        {"name": "Kollapur", "ac_no": 85, "electors": 234348, "voters": 192324, "male_voters": 98060, "female_voters": 92503, "turnout": 82.07},
        {"name": "Nagarkurnool", "ac_no": 81, "electors": 233014, "voters": 184667, "male_voters": 93271, "female_voters": 89876, "turnout": 79.25},
        {"name": "Achampet", "ac_no": 82, "electors": 242302, "voters": 196346, "male_voters": 98207, "female_voters": 96077, "turnout": 81.03},
        {"name": "Kalwakurthy", "ac_no": 83, "electors": 241897, "voters": 202794, "male_voters": 102700, "female_voters": 98526, "turnout": 83.83},
        {"name": "Wanaparthy", "ac_no": 78, "electors": 271371, "voters": 213312, "male_voters": 106606, "female_voters": 104132, "turnout": 78.61},
        {"name": "Jadcherla", "ac_no": 75, "electors": 220503, "voters": 180877, "male_voters": 91299, "female_voters": 88332, "turnout": 82.03},
        {"name": "Mahbubnagar", "ac_no": 74, "electors": 252678, "voters": 182004, "male_voters": 89384, "female_voters": 88680, "turnout": 72.03}
    ],
    "PC12": [
        {"name": "Nagarkurnool", "ac_no": 81, "electors": 233014, "voters": 184667, "male_voters": 93271, "female_voters": 89876, "turnout": 79.25},
        {"name": "Achampet", "ac_no": 82, "electors": 242302, "voters": 196346, "male_voters": 98207, "female_voters": 96077, "turnout": 81.03},
        {"name": "Kalwakurthy", "ac_no": 83, "electors": 241897, "voters": 202794, "male_voters": 102700, "female_voters": 98526, "turnout": 83.83},
        {"name": "Shadnagar", "ac_no": 84, "electors": 236392, "voters": 195622, "male_voters": 98592, "female_voters": 95434, "turnout": 82.75},
        {"name": "Devarkadra", "ac_no": 76, "electors": 235352, "voters": 195540, "male_voters": 98409, "female_voters": 96133, "turnout": 83.08},
        {"name": "Makthal", "ac_no": 77, "electors": 242316, "voters": 187861, "male_voters": 94115, "female_voters": 92744, "turnout": 77.53},
        {"name": "Narayanpet", "ac_no": 73, "electors": 232062, "voters": 182972, "male_voters": 90593, "female_voters": 91115, "turnout": 78.85}
    ],
    "PC13": [
        {"name": "Nalgonda", "ac_no": 92, "electors": 244545, "voters": 204137, "male_voters": 97528, "female_voters": 101914, "turnout": 83.48},
        {"name": "Munugode", "ac_no": 93, "electors": 252699, "voters": 233665, "male_voters": 116562, "female_voters": 115595, "turnout": 92.47},
        {"name": "Devarakonda", "ac_no": 86, "electors": 251710, "voters": 214038, "male_voters": 108586, "female_voters": 104006, "turnout": 85.03},
        {"name": "Nakrekal", "ac_no": 95, "electors": 250653, "voters": 219065, "male_voters": 109584, "female_voters": 107561, "turnout": 87.40},
        {"name": "Miryalaguda", "ac_no": 88, "electors": 231502, "voters": 195767, "male_voters": 95702, "female_voters": 97466, "turnout": 84.56},
        {"name": "Huzurnagar", "ac_no": 89, "electors": 247708, "voters": 216220, "male_voters": 104729, "female_voters": 109315, "turnout": 87.29},
        {"name": "Kodad", "ac_no": 90, "electors": 241669, "voters": 209321, "male_voters": 101003, "female_voters": 105668, "turnout": 86.61}
    ],
    "PC14": [
        {"name": "Bhongir", "ac_no": 94, "electors": 216995, "voters": 196099, "male_voters": 97572, "female_voters": 97488, "turnout": 90.37},
        {"name": "Nakrekal", "ac_no": 95, "electors": 250653, "voters": 219065, "male_voters": 109584, "female_voters": 107561, "turnout": 87.40},
        {"name": "Thungathurthi", "ac_no": 96, "electors": 255163, "voters": 225237, "male_voters": 113312, "female_voters": 110181, "turnout": 88.27},
        {"name": "Alair", "ac_no": 97, "electors": 233366, "voters": 212777, "male_voters": 107279, "female_voters": 104447, "turnout": 91.18},
        {"name": "Jangaon", "ac_no": 98, "electors": 237242, "voters": 204965, "male_voters": 101490, "female_voters": 101593, "turnout": 86.39},
        {"name": "Ghanpur", "ac_no": 99, "electors": 249321, "voters": 216524, "male_voters": 108523, "female_voters": 106706, "turnout": 86.85},
        {"name": "Husnabad", "ac_no": 32, "electors": 242397, "voters": 206871, "male_voters": 101937, "female_voters": 103079, "turnout": 85.34}
    ],
    "PC15": [
        {"name": "Warangal East", "ac_no": 106, "electors": 254726, "voters": 171860, "male_voters": 83558, "female_voters": 86335, "turnout": 67.47},
        {"name": "Warangal West", "ac_no": 105, "electors": 286757, "voters": 167155, "male_voters": 79922, "female_voters": 82472, "turnout": 58.29},
        {"name": "Bhupalpally", "ac_no": 108, "electors": 273803, "voters": 225785, "male_voters": 111738, "female_voters": 112690, "turnout": 82.46},
        {"name": "Mulugu", "ac_no": 109, "electors": 226574, "voters": 187597, "male_voters": 91138, "female_voters": 94683, "turnout": 82.80},
        {"name": "Parkal", "ac_no": 104, "electors": 221590, "voters": 188898, "male_voters": 91917, "female_voters": 95445, "turnout": 85.25},
        {"name": "Dornakal", "ac_no": 101, "electors": 219426, "voters": 193643, "male_voters": 95642, "female_voters": 96723, "turnout": 88.25},
        {"name": "Mahabubabad", "ac_no": 102, "electors": 253524, "voters": 210362, "male_voters": 103801, "female_voters": 104784, "turnout": 82.98}
    ],
    "PC16": [
        {"name": "Mahabubabad", "ac_no": 102, "electors": 253524, "voters": 210362, "male_voters": 103801, "female_voters": 104784, "turnout": 82.98},
        {"name": "Dornakal", "ac_no": 101, "electors": 219426, "voters": 193643, "male_voters": 95642, "female_voters": 96723, "turnout": 88.25},
        {"name": "Pinapaka", "ac_no": 110, "electors": 198604, "voters": 159968, "male_voters": 78530, "female_voters": 80446, "turnout": 80.55},
        {"name": "Yellandu", "ac_no": 111, "electors": 219836, "voters": 178384, "male_voters": 87162, "female_voters": 89114, "turnout": 81.14},
        {"name": "Khammam", "ac_no": 112, "electors": 323072, "voters": 236304, "male_voters": 110138, "female_voters": 120560, "turnout": 73.14},
        {"name": "Palair", "ac_no": 113, "electors": 236451, "voters": 217008, "male_voters": 104450, "female_voters": 110412, "turnout": 91.78},
        {"name": "Sathupalle", "ac_no": 116, "electors": 243220, "voters": 215387, "male_voters": 103994, "female_voters": 108605, "turnout": 88.56}
    ],
    "PC17": [
        {"name": "Khammam", "ac_no": 112, "electors": 323072, "voters": 236304, "male_voters": 110138, "female_voters": 120560, "turnout": 73.14},
        {"name": "Palair", "ac_no": 113, "electors": 236451, "voters": 217008, "male_voters": 104450, "female_voters": 110412, "turnout": 91.78},
        {"name": "Madhira", "ac_no": 114, "electors": 221473, "voters": 196419, "male_voters": 95351, "female_voters": 99260, "turnout": 88.69},
        {"name": "Wyra", "ac_no": 115, "electors": 193264, "voters": 169457, "male_voters": 81991, "female_voters": 85352, "turnout": 87.68},
        {"name": "Sathupalle", "ac_no": 116, "electors": 243220, "voters": 215387, "male_voters": 103994, "female_voters": 108605, "turnout": 88.56},
        {"name": "Kothagudem", "ac_no": 117, "electors": 244006, "voters": 188053, "male_voters": 91305, "female_voters": 95023, "turnout": 77.07},
        {"name": "Aswaraopeta", "ac_no": 118, "electors": 156012, "voters": 136249, "male_voters": 66560, "female_voters": 68937, "turnout": 87.33}
    ]
}

# Date range: Jan 2025 - Dec 2025
START_DATE = date(2025, 1, 1)
END_DATE = date(2025, 12, 31)

def random_date(start, end):
    """Generate random date between start and end"""
    delta = end - start
    random_days = random.randint(0, delta.days)
    return start + timedelta(days=random_days)

def random_timestamp(start, end):
    """Generate random timestamp"""
    dt = random_date(start, end)
    return datetime.combine(dt, time(random.randint(0, 23), random.randint(0, 59)))

# =====================================================
# MODULE 1: COMMAND CENTER
# =====================================================

def generate_constituency_overview():
    """Generate constituency_overview data using real PC data"""
    data = []
    
    for const in CONSTITUENCIES:
        # Calculate population estimate (electors * 1.2 to account for non-voters)
        population = int(const['electors'] * 1.2)
        health_score = random.randint(65, 92)
        active_issues = random.randint(45, 180)
        
        data.append({
            'constituency_id': const['id'],
            'constituency_name': const['name'],
            'health_score': health_score,
            'risk_level': 'low' if health_score > 80 else ('medium' if health_score > 70 else 'high'),
            'total_population': population,
            'total_voters': const['electors'],
            'active_issues': active_issues,
            'resolved_issues_30d': random.randint(80, 220),
            'pending_issues': active_issues,
            'critical_alerts': random.randint(2, 12),
            'satisfaction_score': random.randint(65, 88),
            'last_visit_date': random_date(date(2025, 11, 1), date(2025, 12, 15)),
            'visit_frequency_30d': random.randint(8, 25),
            'grievances_30d': random.randint(120, 350),
            'promises_total': random.randint(25, 45),
            'promises_completed': random.randint(15, 30),
            'promises_in_progress': random.randint(8, 15),
            'last_updated': datetime(2025, 12, 15, random.randint(8, 18), 0)
        })
    
    return pd.DataFrame(data)

def generate_constituency_kpis():
    """Generate daily KPI data for 365 days"""
    data = []
    
    for const in CONSTITUENCIES:
        current_date = START_DATE
        while current_date <= END_DATE:
            data.append({
                'kpi_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'report_date': current_date,
                'visits_conducted': random.randint(0, 5),
                'people_contacted': random.randint(50, 800),
                'grievances_received': random.randint(5, 35),
                'grievances_resolved': random.randint(3, 30),
                'events_conducted': random.randint(0, 3),
                'resources_distributed': random.randint(0, 150),
                'promises_on_track': random.randint(15, 30),
                'promises_delayed': random.randint(2, 8),
                'alert_count': random.randint(1, 8),
                'critical_alerts': random.randint(0, 3),
                'sentiment_score': round(random.uniform(0.4, 0.85), 2),
                'media_mentions': random.randint(0, 12),
                'social_engagement': random.randint(500, 5000),
                'created_at': datetime.combine(current_date, time(23, 55))
            })
            current_date += timedelta(days=1)
    
    return pd.DataFrame(data)

def generate_constituency_trends():
    """Generate trend analysis data"""
    data = []
    metrics = ['health_score', 'satisfaction', 'visit_coverage', 'grievance_resolution', 'promise_delivery']
    
    for const in CONSTITUENCIES:
        for i in range(12):  # Monthly data
            analysis_date = date(2025, i+1, 1)
            
            for metric in metrics:
                current = random.randint(60, 90)
                previous = current + random.randint(-10, 10)
                change = round(((current - previous) / previous) * 100, 2)
                
                data.append({
                    'trend_id': str(uuid.uuid4()),
                    'constituency_id': const['id'],
                    'metric_name': metric,
                    'current_value': current,
                    'previous_value': previous,
                    'change_value': current - previous,
                    'change_percentage': change,
                    'trend_direction': 'up' if change > 0 else ('down' if change < 0 else 'stable'),
                    'analysis_period': 'monthly',
                    'analysis_date': analysis_date,
                    'benchmark_value': random.randint(70, 85),
                    'created_at': datetime.combine(analysis_date, time(23, 0))
                })
    
    return pd.DataFrame(data)

def generate_executive_summary():
    """Generate executive summary reports"""
    data = []
    
    for const in CONSTITUENCIES:
        for month in range(1, 13):
            report_date = date(2025, month, 1)
            
            data.append({
                'summary_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'report_date': report_date,
                'report_period': 'monthly',
                'overall_health_score': random.randint(70, 90),
                'key_achievements': json.dumps([
                    f"Completed {random.randint(3, 8)} infrastructure projects",
                    f"Resolved {random.randint(100, 300)} grievances",
                    f"Conducted {random.randint(15, 30)} public meetings"
                ]),
                'critical_issues': json.dumps([
                    "Water supply disruption in Ward " + random.choice(['1', '2', '3']),
                    "Road repair pending for " + str(random.randint(30, 90)) + " days"
                ]),
                'top_opportunities': json.dumps([
                    "High youth engagement opportunity",
                    "Strong community support for education initiative"
                ]),
                'immediate_actions': json.dumps([
                    "Schedule visit to high-risk ward",
                    "Address water supply issue urgently"
                ]),
                'risk_alerts': json.dumps([
                    "Opposition activity increasing in Ward " + random.choice(['2', '4', '5'])
                ]),
                'constituency_mood': random.choice(['positive', 'neutral', 'cautiously_positive']),
                'political_temperature': random.randint(60, 85),
                'generated_by': 'ai_system',
                'reviewed_by': 'admin',
                'created_at': datetime.combine(report_date, time(9, 0)),
                'updated_at': datetime.combine(report_date, time(18, 0))
            })
    
    return pd.DataFrame(data)

# =====================================================
# MODULE 2: AI INTELLIGENCE HUB
# =====================================================

def generate_ai_recommendations():
    """Generate AI recommendations"""
    data = []
    rec_types = ['policy', 'outreach', 'crisis_response', 'resource_allocation']
    priorities = ['critical', 'high', 'medium', 'low']
    statuses = ['pending', 'accepted', 'in_progress', 'completed', 'rejected']
    
    for const in CONSTITUENCIES:
        for _ in range(random.randint(15, 30)):
            created = random_timestamp(START_DATE, END_DATE)
            status = random.choice(statuses)
            
            data.append({
                'recommendation_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'recommendation_type': random.choice(rec_types),
                'title': f"Improve {random.choice(['healthcare', 'education', 'infrastructure'])} in Ward {random.randint(1, 6)}",
                'description': f"Recommendation based on AI analysis of ground data",
                'priority': random.choice(priorities),
                'confidence_score': round(random.uniform(0.7, 0.95), 2),
                'impact_score': round(random.uniform(60, 95), 1),
                'effort_level': random.choice(['low', 'medium', 'high']),
                'target_audience': random.choice(['youth', 'women', 'farmers', 'all']),
                'estimated_cost': round(random.uniform(50000, 500000), 2),
                'estimated_timeline_days': random.randint(7, 90),
                'status': status,
                'assigned_to': f"officer_{random.randint(1, 10)}" if status != 'pending' else None,
                'ai_reasoning': "Based on sentiment analysis and historical data patterns",
                'data_sources': json.dumps(['visit_records', 'grievances', 'social_media', 'field_reports'][:random.randint(2, 4)]),
                'expected_outcomes': json.dumps([
                    f"Improve {random.choice(['satisfaction', 'service delivery', 'infrastructure quality'])} by {random.randint(15, 40)}%",
                    f"Benefit {random.randint(500, 5000)} people directly"
                ]),
                'risks': json.dumps([
                    random.choice(['Budget constraints', 'Timeline delays', 'Resource availability', 'Weather conditions', 'Stakeholder resistance'])
                ] if random.random() > 0.3 else []),
                'created_at': created,
                'updated_at': created + timedelta(days=random.randint(1, 30)),
                'completed_at': created + timedelta(days=random.randint(30, 90)) if status == 'completed' else None,
                'feedback_rating': random.randint(3, 5) if status == 'completed' else None,
                'feedback_notes': f"Good implementation, achieved {random.randint(70, 95)}% of objectives" if status == 'completed' and random.random() > 0.5 else None
            })
    
    return pd.DataFrame(data)

def generate_media_talking_points():
    """Generate media talking points"""
    data = []
    topics = ['healthcare', 'education', 'infrastructure', 'employment', 'agriculture', 'welfare']
    media_types = ['tv', 'print', 'social', 'press_conference']
    tones = ['positive', 'defensive', 'neutral']
    urgencies = ['immediate', 'this_week', 'this_month']
    
    for const in CONSTITUENCIES:
        for _ in range(random.randint(10, 20)):
            created = random_timestamp(START_DATE, END_DATE)
            topic = random.choice(topics)
            
            data.append({
                'talking_point_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'topic': topic,
                'headline': f"{topic.title()} Initiative Success in {const['name']}",
                'key_message': f"Major progress in {topic} sector with tangible results for constituents",
                'supporting_facts': json.dumps([
                    f"{random.randint(50, 200)} {topic} facilities upgraded",
                    f"{random.randint(5000, 50000)} beneficiaries reached",
                    f"{random.randint(10, 50)}% improvement in service delivery"
                ]),
                'statistics': json.dumps([
                    {'label': 'Budget Allocated', 'value': f"₹{random.randint(5, 50)} Cr"},
                    {'label': 'Projects Completed', 'value': str(random.randint(10, 100))},
                    {'label': 'Beneficiaries', 'value': f"{random.randint(5, 50)}K"}
                ]),
                'target_media': random.choice(media_types),
                'tone': random.choice(tones),
                'urgency': random.choice(urgencies),
                'related_events': json.dumps([f"Event_{random.randint(1, 10)}" for _ in range(random.randint(1, 3))]),
                'dos': json.dumps([
                    "Emphasize tangible results",
                    "Highlight beneficiary testimonials",
                    "Show before-after comparisons"
                ]),
                'donts': json.dumps([
                    "Avoid overpromising",
                    "Don't get into political debates",
                    "Avoid criticism of opposition"
                ]),
                'sample_quotes': json.dumps([
                    f"We have successfully transformed {topic} delivery in {const['name']}",
                    "Our focus is on inclusive development for all sections"
                ]),
                'counter_narratives': json.dumps([
                    "Address any criticism with facts and figures",
                    "Focus on progress rather than defending past"
                ]),
                'generated_by': random.choice(['ai', 'manual', 'hybrid']),
                'ai_confidence': round(random.uniform(0.7, 0.95), 2),
                'reviewed_by': f"media_team_{random.randint(1, 5)}",
                'approved_status': random.choice(['draft', 'approved', 'published']),
                'created_at': created,
                'updated_at': created + timedelta(days=random.randint(1, 7)),
                'used_at': created + timedelta(days=random.randint(1, 14)) if random.random() > 0.5 else None,
                'effectiveness_rating': random.randint(3, 5) if random.random() > 0.6 else None
            })
    
    return pd.DataFrame(data)

def generate_influencer_mapping():
    """Generate influencer mapping data"""
    data = []
    categories = ['religious', 'business', 'community', 'youth', 'women', 'media']
    leanings = ['favorable', 'neutral', 'opposition', 'unknown']
    
    for const in CONSTITUENCIES:
        acs = ASSEMBLY_CONSTITUENCIES[const['id']]
        
        # 30-60 influencers per constituency
        for i in range(random.randint(30, 60)):
            created = random_timestamp(START_DATE, END_DATE)
            category = random.choice(categories)
            
            data.append({
                'influencer_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'name': f"Influencer_{i+1}_{const['id']}",
                'category': category,
                'sub_category': f"{category}_local" if random.random() > 0.5 else None,
                'influence_level': random.choice(['high', 'medium', 'low']),
                'influence_score': random.randint(40, 100),
                'reach_estimate': random.randint(500, 50000),
                'location_ward': random.choice(acs)['name'],
                'location_mandal': random.choice(acs)['name'],
                'contact_phone': f"+91{random.randint(7000000000, 9999999999)}",
                'contact_email': f"influencer{i+1}@example.com",
                'political_leaning': random.choice(leanings),
                'engagement_history': json.dumps([
                    {
                        'date': (created - timedelta(days=random.randint(30, 180))).date().isoformat(),
                        'event': random.choice(['Meeting', 'Event', 'Phone call', 'Community gathering']),
                        'outcome': random.choice(['Positive', 'Neutral', 'Needs follow-up'])
                    }
                    for _ in range(random.randint(1, 4))
                ]),
                'key_issues': json.dumps([random.choice(['Infrastructure', 'Education', 'Healthcare', 'Employment']) for _ in range(random.randint(2, 4))]),
                'relationship_strength': random.choice(['strong', 'moderate', 'weak', 'none']),
                'last_interaction_date': (created - timedelta(days=random.randint(1, 90))).date(),
                'next_followup_date': (created + timedelta(days=random.randint(7, 60))).date() if random.random() > 0.3 else None,
                'notes': f"Key influencer in {category} sector" if random.random() > 0.5 else None,
                'added_by': f"coordinator_{random.randint(1, 5)}",
                'verified': random.choice([True, False]),
                'created_at': created,
                'updated_at': created + timedelta(days=random.randint(1, 30))
            })
    
    return pd.DataFrame(data)

def generate_visit_planning():
    """Generate visit planning data"""
    data = []
    plan_types = ['routine', 'campaign', 'crisis_response', 'festival']
    statuses = ['draft', 'scheduled', 'in_progress', 'completed', 'cancelled']
    
    for const in CONSTITUENCIES:
        acs = ASSEMBLY_CONSTITUENCIES[const['id']]
        
        # 15-25 plans per constituency
        for _ in range(random.randint(15, 25)):
            plan_date = random_date(START_DATE, END_DATE)
            status = random.choice(statuses)
            
            # Generate 2-4 locations for the plan
            locations = []
            for _ in range(random.randint(2, 4)):
                ac = random.choice(acs)
                visit_start = datetime.combine(plan_date, time(random.randint(9, 16), 0))
                locations.append({
                    'ward': ac['name'],
                    'village': f"Village_{random.randint(1, 10)}",
                    'visit_type': random.choice(['public_meeting', 'inspection', 'community_event']),
                    'start_time': visit_start.isoformat(),
                    'end_time': (visit_start + timedelta(hours=random.randint(1, 3))).isoformat(),
                    'expected_attendance': random.randint(100, 2000),
                    'key_people': [f"Person_{random.randint(1, 20)}" for _ in range(random.randint(2, 5))]
                })
            
            data.append({
                'plan_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'plan_name': f"Visit Plan - {plan_date.strftime('%B %Y')}",
                'plan_date': plan_date,
                'plan_type': random.choice(plan_types),
                'status': status,
                'priority': random.choice(['critical', 'high', 'medium', 'low']),
                'locations': json.dumps(locations),
                'route_optimization': json.dumps({
                    'total_distance_km': round(random.uniform(50, 200), 2),
                    'estimated_travel_time_mins': random.randint(180, 480),
                    'optimized_sequence': [loc['ward'] for loc in locations],
                    'fuel_cost_estimate': round(random.uniform(2000, 8000), 2)
                }),
                'objectives': json.dumps([
                    "Meet key stakeholders",
                    "Address public grievances",
                    "Inspect ongoing projects"
                ]),
                'target_demographics': json.dumps(['youth', 'women', 'farmers'][:random.randint(1, 3)]),
                'key_messages': json.dumps([
                    "Development progress update",
                    "New schemes announcement",
                    "Community welfare focus"
                ]),
                'resource_requirements': json.dumps({
                    'vehicles': random.randint(2, 5),
                    'security_personnel': random.randint(5, 15),
                    'volunteers': random.randint(10, 50),
                    'budget': round(random.uniform(50000, 200000), 2)
                }),
                'risk_assessment': json.dumps({
                    'weather_risk': random.choice(['low', 'medium', 'high']),
                    'security_risk': random.choice(['low', 'medium']),
                    'crowd_management_risk': random.choice(['low', 'medium', 'high']),
                    'mitigation_steps': ["Backup plan ready", "Security briefed", "Weather monitoring"]
                }),
                'ai_suggestions': json.dumps([
                    "Optimal time: Morning hours for better attendance",
                    "Route optimized for minimal travel time",
                    "Key influencers invited"
                ]),
                'created_by': f"planner_{random.randint(1, 5)}",
                'approved_by': f"admin_{random.randint(1, 3)}" if status in ['scheduled', 'in_progress', 'completed'] else None,
                'created_at': datetime.combine(plan_date - timedelta(days=random.randint(7, 30)), time(10, 0)),
                'updated_at': datetime.combine(plan_date - timedelta(days=random.randint(1, 7)), time(15, 0)),
                'actual_completion_notes': f"Successfully completed with {random.randint(80, 100)}% attendance" if status == 'completed' else None
            })
    
    return pd.DataFrame(data)

# =====================================================
# MODULE 3: GROUND REALITY
# =====================================================

def generate_visit_records_enhanced():
    """Generate enhanced visit records using AC-level data"""
    data = []
    visit_types = ['public_meeting', 'house_visit', 'office_hours', 'event', 'inspection']
    sentiments = ['very_positive', 'positive', 'neutral', 'negative', 'very_negative']
    
    for const in CONSTITUENCIES:
        acs = ASSEMBLY_CONSTITUENCIES[const['id']]
        # Generate 200-400 visits per PC over the year
        num_visits = random.randint(200, 400)
        
        for _ in range(num_visits):
            visit_date = random_date(START_DATE, END_DATE)
            attendance = random.randint(50, 2000)
            
            data.append({
                'visit_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'visit_date': visit_date,
                'visit_time': time(random.randint(8, 18), random.choice([0, 15, 30, 45])),
                'location_ward': random.choice(acs)['name'],
                'visit_type': random.choice(visit_types),
                'visit_category': random.choice(['scheduled', 'impromptu', 'emergency']),
                'leader_name': 'MP ' + const['name'],
                'leader_role': random.choice(['MP', 'MLA', 'Minister']),
                'total_attendance': attendance,
                'grievances_count': random.randint(5, 50),
                'grievances_resolved_on_spot': random.randint(2, 20),
                'public_sentiment': random.choice(sentiments),
                'sentiment_score': round(random.uniform(-0.3, 0.9), 2),
                'photos_count': random.randint(5, 50),
                'videos_count': random.randint(0, 5),
                'media_coverage': random.choice(['yes', 'no']),
                'recorded_by': f"volunteer_{random.randint(1, 20)}",
                'verification_status': random.choice(['verified', 'pending', 'verified']),
                'created_at': datetime.combine(visit_date, time(20, 0)),
                'updated_at': datetime.combine(visit_date, time(22, 0))
            })
    
    return pd.DataFrame(data)

def generate_issue_heatmap():
    """Generate heatmap data for issue concentration"""
    data = []
    
    for const in CONSTITUENCIES:
        acs = ASSEMBLY_CONSTITUENCIES[const['id']]
        
        # Generate weekly heatmap data for each AC
        current_date = START_DATE
        while current_date <= END_DATE:
            for ac in acs:
                total_issues = random.randint(10, 100)
                resolved = random.randint(5, int(total_issues * 0.7))
                
                data.append({
                    'heatmap_id': str(uuid.uuid4()),
                    'constituency_id': const['id'],
                    'location_ward': ac['name'],
                    'data_date': current_date,
                    'total_issues_reported': total_issues,
                    'critical_issues': random.randint(2, 15),
                    'resolved_issues': resolved,
                    'pending_issues': total_issues - resolved,
                    'resolution_rate': round((resolved / total_issues) * 100, 2),
                    'intensity_score': round(random.uniform(20, 95), 2),
                    'severity_index': round(random.uniform(30, 90), 2),
                    'urgency_index': round(random.uniform(25, 85), 2),
                    'population_estimate': int(ac['electors']),
                    'issues_per_capita': round(total_issues / ac['electors'] * 1000, 2),
                    'last_visit_date': random_date(current_date - timedelta(days=30), current_date),
                    'days_since_last_visit': random.randint(1, 30),
                    'visit_frequency_30d': random.randint(2, 8),
                    'created_at': datetime.combine(current_date, time(23, 0)),
                    'updated_at': datetime.combine(current_date, time(23, 30))
                })
            
            current_date += timedelta(days=7)  # Weekly data
    
    return pd.DataFrame(data)

def generate_ward_intelligence():
    """Generate ward-level intelligence reports"""
    data = []
    
    for const in CONSTITUENCIES:
        acs = ASSEMBLY_CONSTITUENCIES[const['id']]
        
        # Monthly reports for each AC
        for month in range(1, 13):
            report_date = date(2025, month, 1)
            
            for ac in acs:
                voters_in_ac = int(ac['voters'])
                health_score = random.randint(60, 95)
                
                data.append({
                    'ward_id': str(uuid.uuid4()),
                    'constituency_id': const['id'],
                    'ward_name': ac['name'],
                    'report_date': report_date,
                    'total_population': int(ac['electors'] * 1.2),
                    'total_voters': voters_in_ac,
                    'total_households': int(voters_in_ac / 4),
                    'infrastructure_score': random.randint(55, 90),
                    'public_service_score': random.randint(60, 92),
                    'safety_score': random.randint(65, 95),
                    'development_score': random.randint(58, 88),
                    'satisfaction_score': random.randint(62, 90),
                    'overall_health_score': health_score,
                    'last_leader_visit_date': random_date(date(2025, month, 1), date(2025, month, 28)),
                    'visit_frequency_30d': random.randint(2, 10),
                    'visit_frequency_90d': random.randint(8, 30),
                    'leader_visibility_score': random.randint(55, 90),
                    'active_volunteers': random.randint(10, 50),
                    'community_events_30d': random.randint(3, 15),
                    'opposition_activity_level': random.choice(['high', 'medium', 'low']),
                    'opposition_events_30d': random.randint(0, 8),
                    'competitive_threat_score': random.randint(20, 75),
                    'risk_level': 'low' if health_score > 80 else ('medium' if health_score > 70 else 'high'),
                    'attention_required': health_score < 70,
                    'created_at': datetime.combine(report_date, time(9, 0)),
                    'updated_at': datetime.combine(report_date, time(18, 0))
                })
    
    return pd.DataFrame(data)

def generate_visit_statistics():
    """Generate aggregated visit statistics per constituency"""
    data = []
    
    for const in CONSTITUENCIES:
        # Monthly statistics for each constituency
        for month in range(1, 13):
            report_date = date(2025, month, 1)
            
            # Calculate random but realistic visit stats
            total_visits = random.randint(15, 40)
            public_meetings = random.randint(5, 15)
            house_visits = random.randint(8, 20)
            total_attendance = random.randint(2000, 10000)
            grievances = random.randint(50, 300)
            resolved = random.randint(int(grievances * 0.6), int(grievances * 0.9))
            
            data.append({
                'stat_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'report_date': report_date,
                'period_type': 'monthly',
                'total_visits': total_visits,
                'visits_by_type': json.dumps({
                    'public_meeting': public_meetings,
                    'house_visit': house_visits,
                    'office_hours': random.randint(3, 8),
                    'event': random.randint(2, 6),
                    'inspection': random.randint(1, 4)
                }),
                'total_attendance': total_attendance,
                'average_attendance_per_visit': round(total_attendance / total_visits, 2),
                'total_grievances_collected': grievances,
                'grievances_resolved': resolved,
                'resolution_rate': round((resolved / grievances) * 100, 2),
                'average_sentiment_score': round(random.uniform(0.3, 0.8), 2),
                'positive_sentiment_pct': round(random.uniform(60, 85), 2),
                'neutral_sentiment_pct': round(random.uniform(10, 25), 2),
                'negative_sentiment_pct': round(random.uniform(5, 15), 2),
                'media_coverage_count': random.randint(5, 20),
                'photos_collected': random.randint(100, 500),
                'videos_collected': random.randint(10, 50),
                'wards_covered': random.randint(5, 7),
                'coverage_pct': round(random.uniform(70, 100), 2),
                'high_priority_issues': random.randint(10, 30),
                'created_at': datetime.combine(report_date, time(23, 59)),
                'updated_at': datetime.combine(report_date, time(23, 59))
            })
    
    return pd.DataFrame(data)

# =====================================================
# MODULE 4: Election War Room
# =====================================================

def generate_booth_analysis():
    """Generate booth-level analysis"""
    data = []
    
    for const in CONSTITUENCIES:
        acs = ASSEMBLY_CONSTITUENCIES[const['id']]
        voters_per_ac = int(const['voters'] / len(acs))
        
        # Each AC has 150-250 booths
        total_booths = random.randint(150, 250)
        voters_per_booth = int(voters_per_ac / total_booths * len(acs))
        
        for i in range(total_booths):
            booth_voters = voters_per_booth + random.randint(-100, 100)
            booth_score = random.randint(45, 95)
            
            data.append({
                'booth_id': f"{const['id']}_B{i+1:03d}",
                'constituency_id': const['id'],
                'booth_number': f"B{i+1:03d}",
                'booth_name': f"Polling Station {i+1}",
                'location_ward': random.choice(acs)['name'],
                'analysis_date': date(2025, 11, 1),
                'total_voters': booth_voters,
                'male_voters': int(booth_voters * 0.52),
                'female_voters': int(booth_voters * 0.48),
                'first_time_voters': int(booth_voters * 0.08),
                'senior_voters': int(booth_voters * 0.12),
                'booth_score': booth_score,
                'risk_level': 'secure' if booth_score > 75 else ('moderate' if booth_score > 60 else 'vulnerable'),
                'competitive_threat_score': random.randint(20, 80),
                'booth_agents': random.randint(2, 5),
                'active_volunteers': random.randint(5, 20),
                'booth_committee_strength': random.choice(['strong', 'moderate', 'weak']),
                'last_meeting_date': random_date(date(2025, 10, 1), date(2025, 11, 30)),
                'surveyed_by': f"surveyor_{random.randint(1, 10)}",
                'verification_date': date(2025, 11, 15),
                'created_at': datetime(2025, 11, 1, 10, 0),
                'updated_at': datetime(2025, 11, 30, 18, 0)
            })
    
    return pd.DataFrame(data)

def generate_booth_score_trends():
    """Generate booth score trends over time"""
    data = []
    
    # Sample 20% of booths for trend tracking
    for const in CONSTITUENCIES:
        num_booths = random.randint(150, 250)
        sampled_booths = int(num_booths * 0.2)
        
        for booth_num in range(sampled_booths):
            booth_id = f"{const['id']}_B{booth_num+1:03d}"
            
            # Monthly tracking
            for month in range(1, 13):
                measurement_date = date(2025, month, 1)
                booth_score = random.randint(50, 90)
                
                data.append({
                    'trend_id': str(uuid.uuid4()),
                    'booth_id': booth_id,
                    'constituency_id': const['id'],
                    'measurement_date': measurement_date,
                    'booth_score': booth_score,
                    'favorable_pct': round(random.uniform(35, 70), 2),
                    'opposition_pct': round(random.uniform(20, 45), 2),
                    'undecided_pct': round(random.uniform(10, 25), 2),
                    'vs_previous_week': random.randint(-5, 8),
                    'vs_previous_month': random.randint(-10, 12),
                    'vs_baseline': random.randint(-15, 20),
                    'trend_direction': random.choice(['improving', 'stable', 'declining']),
                    'momentum_score': random.randint(-30, 40),
                    'velocity': round(random.uniform(-2.5, 3.5), 2),
                    'visits_count_7d': random.randint(0, 3),
                    'visits_count_30d': random.randint(2, 10),
                    'events_count_7d': random.randint(0, 2),
                    'events_count_30d': random.randint(1, 8),
                    'volunteer_activity_score': random.randint(40, 90),
                    'door_to_door_coverage_pct': round(random.uniform(20, 85), 2),
                    'voter_contact_count_30d': random.randint(50, 500),
                    'grievances_resolved_30d': random.randint(5, 40),
                    'rank_in_constituency': random.randint(1, sampled_booths),
                    'percentile': random.randint(20, 95),
                    'positive_events': json.dumps([
                        random.choice(['Successful rally', 'Community meeting', 'Development work completed', 'Festival celebration'])
                        for _ in range(random.randint(0, 3))
                    ]),
                    'negative_events': json.dumps([
                        random.choice(['Infrastructure issue', 'Opposition rally', 'Negative media', 'Service complaint'])
                        for _ in range(random.randint(0, 2))
                    ]),
                    'created_at': datetime.combine(measurement_date, time(23, 0))
                })
    
    return pd.DataFrame(data)

def generate_voter_segments():
    """Generate voter segmentation analysis"""
    data = []
    
    segment_types = ['demographic', 'issue_based', 'geographic', 'loyalty']
    demographics_profiles = [
        {'age_group': 'youth_18_35', 'gender': 'all', 'occupation_category': 'students_professionals', 'income_level': 'lower_middle', 'education_level': 'graduate', 'religion': 'all', 'caste_category': 'general'},
        {'age_group': 'middle_age_36_55', 'gender': 'all', 'occupation_category': 'business_trade', 'income_level': 'middle', 'education_level': 'undergraduate', 'religion': 'all', 'caste_category': 'obc'},
        {'age_group': 'senior_55plus', 'gender': 'all', 'occupation_category': 'retired', 'income_level': 'lower', 'education_level': 'secondary', 'religion': 'all', 'caste_category': 'sc_st'},
        {'age_group': 'all', 'gender': 'female', 'occupation_category': 'homemaker_worker', 'income_level': 'lower_middle', 'education_level': 'secondary', 'religion': 'all', 'caste_category': 'all'},
        {'age_group': 'all', 'gender': 'male', 'occupation_category': 'agriculture', 'income_level': 'lower', 'education_level': 'primary', 'religion': 'all', 'caste_category': 'all'}
    ]
    
    for const in CONSTITUENCIES:
        acs = ASSEMBLY_CONSTITUENCIES[const['id']]
        total_voters = const['voters']
        
        # Generate 8-12 segments per constituency
        num_segments = random.randint(8, 12)
        
        for i in range(num_segments):
            segment_type = random.choice(segment_types)
            segment_voters = random.randint(int(total_voters * 0.05), int(total_voters * 0.20))
            
            # Pick a demographic profile
            demo_profile = random.choice(demographics_profiles)
            
            # Create support distribution
            strong_fav = random.randint(int(segment_voters * 0.2), int(segment_voters * 0.4))
            leaning_fav = random.randint(int(segment_voters * 0.15), int(segment_voters * 0.25))
            neutral = random.randint(int(segment_voters * 0.1), int(segment_voters * 0.2))
            opposition = random.randint(int(segment_voters * 0.1), int(segment_voters * 0.25))
            undecided = segment_voters - (strong_fav + leaning_fav + neutral + opposition)
            
            data.append({
                'segment_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'segment_name': f"{segment_type}_{i+1}_{const['name'].lower().replace(' ', '_')}",
                'segment_type': segment_type,
                'analysis_date': date(2025, random.randint(1, 12), 1),
                'total_voters': segment_voters,
                'percentage_of_total': round((segment_voters / total_voters) * 100, 2),
                'demographics': json.dumps(demo_profile),
                'geographic_concentration': json.dumps([
                    {'ward': ac['name'], 'voter_count': random.randint(1000, 5000), 'concentration_pct': round(random.uniform(10, 30), 2)}
                    for ac in random.sample(acs, min(3, len(acs)))
                ]),
                'support_level': json.dumps({
                    'strong_favorable': strong_fav,
                    'leaning_favorable': leaning_fav,
                    'neutral': neutral,
                    'opposition': opposition,
                    'undecided': undecided
                }),
                'top_issues': json.dumps([
                    {'issue': random.choice(['employment', 'infrastructure', 'education', 'healthcare', 'water_supply']),
                     'priority_level': random.choice(['high', 'medium', 'low']),
                     'satisfaction_score': random.randint(40, 85)}
                    for _ in range(3)
                ]),
                'engagement_score': random.randint(40, 90),
                'contact_coverage_pct': round(random.uniform(30, 85), 2),
                'last_contact_date': random_date(START_DATE, END_DATE),
                'preferred_channels': json.dumps(random.sample(['door_to_door', 'phone', 'whatsapp', 'social_media', 'events'], k=random.randint(2, 4))),
                'key_messengers': json.dumps([f"Leader_{random.randint(1, 10)}" for _ in range(random.randint(2, 4))]),
                'priority_level': random.choice(['high', 'medium', 'low']),
                'target_message': json.dumps([f"Message theme {random.randint(1, 5)}" for _ in range(random.randint(2, 4))]),
                'recommended_actions': json.dumps([
                    random.choice(['Door-to-door campaign', 'Social media outreach', 'Community events', 'Phone banking'])
                    for _ in range(random.randint(2, 4))
                ]),
                'estimated_conversion_rate': round(random.uniform(0.15, 0.45), 2),
                'turnout_tendency': random.choice(['high', 'medium', 'low']),
                'loyalty_score': random.randint(40, 95),
                'swing_potential': random.choice(['high', 'medium', 'low']),
                'budget_allocated': round(random.uniform(50000, 500000), 2),
                'volunteers_assigned': random.randint(10, 50),
                'events_planned': random.randint(3, 15),
                'created_at': datetime.now(),
                'updated_at': datetime.now()
            })
    
    return pd.DataFrame(data)

def generate_opposition_intelligence():
    """Generate opposition party intelligence reports"""
    data = []
    
    opposition_parties = ['BRS', 'BJP', 'AIMIM', 'CPI', 'Independent']
    
    for const in CONSTITUENCIES:
        acs = ASSEMBLY_CONSTITUENCIES[const['id']]
        
        # 2-3 major opposition parties per constituency
        major_parties = random.sample(opposition_parties, k=random.randint(2, 3))
        
        for party in major_parties:
            # Generate 4-6 intelligence reports per party per constituency
            for _ in range(random.randint(4, 6)):
                report_date = random_date(START_DATE, END_DATE)
                strength = random.randint(35, 75)
                
                data.append({
                    'intel_id': str(uuid.uuid4()),
                    'constituency_id': const['id'],
                    'opposition_party': party,
                    'report_date': report_date,
                    'overall_strength_score': strength,
                    'estimated_vote_share': round(random.uniform(0.15, 0.35), 2),
                    'trend': random.choice(['growing', 'stable', 'declining']),
                    'candidate_profile': json.dumps({
                        'name': f"{party} Candidate {const['name']}",
                        'age': random.randint(35, 65),
                        'background': random.choice(['Political veteran', 'Businessman', 'Social activist', 'Ex-bureaucrat']),
                        'strength_areas': random.sample(['Ground connect', 'Resource mobilization', 'Media presence', 'Youth appeal'], k=2),
                        'weakness_areas': random.sample(['Limited experience', 'Controversial past', 'Weak organization', 'Poor communication'], k=2),
                        'popularity_score': random.randint(40, 80)
                    }),
                    'campaign_intensity': random.choice(['very_high', 'high', 'medium', 'low']),
                    'activity_metrics': json.dumps({
                        'public_meetings_30d': random.randint(5, 25),
                        'door_to_door_coverage_pct': round(random.uniform(20, 70), 2),
                        'social_media_reach': random.randint(10000, 100000),
                        'volunteer_count': random.randint(50, 500),
                        'estimated_budget': round(random.uniform(5000000, 50000000), 2)
                    }),
                    'key_messages': json.dumps([
                        f"{party} message theme {i+1}" for i in range(random.randint(3, 5))
                    ]),
                    'attack_lines': json.dumps([
                        f"Attack point {i+1}" for i in range(random.randint(2, 4))
                    ]),
                    'target_segments': json.dumps(random.sample(['youth', 'women', 'farmers', 'minorities', 'urban_poor'], k=random.randint(2, 4))),
                    'strong_areas': json.dumps([
                        {'ward': ac['name'], 'strength_level': random.choice(['very_strong', 'strong']), 'estimated_vote_share': round(random.uniform(0.25, 0.45), 2)}
                        for ac in random.sample(acs, min(2, len(acs)))
                    ]),
                    'weak_areas': json.dumps([
                        {'ward': ac['name'], 'strength_level': random.choice(['weak', 'very_weak']), 'estimated_vote_share': round(random.uniform(0.05, 0.20), 2)}
                        for ac in random.sample(acs, min(2, len(acs)))
                    ]),
                    'alliance_partners': json.dumps([random.choice(opposition_parties)] if random.random() > 0.5 else []),
                    'support_from_influencers': json.dumps([f"Influencer_{random.randint(1, 20)}" for _ in range(random.randint(2, 5))]),
                    'issues_being_raised': json.dumps([
                        {'issue': random.choice(['unemployment', 'corruption', 'poor_infrastructure', 'unfulfilled_promises']),
                         'narrative': f"Narrative about issue {random.randint(1, 5)}",
                         'impact_level': random.choice(['high', 'medium', 'low'])}
                        for _ in range(random.randint(2, 4))
                    ]),
                    'vulnerabilities': json.dumps([
                        {'vulnerability': random.choice(['Weak local leadership', 'Limited resources', 'Internal conflicts', 'Poor ground organization']),
                         'severity': random.choice(['high', 'medium', 'low']),
                         'exploitation_strategy': f"Strategy {random.randint(1, 5)}"}
                        for _ in range(random.randint(2, 3))
                    ]),
                    'recommended_counter_actions': json.dumps([
                        f"Counter action {i+1}" for i in range(random.randint(3, 5))
                    ]),
                    'defensive_messaging': json.dumps([
                        f"Defensive message {i+1}" for i in range(random.randint(2, 4))
                    ]),
                    'source_quality': random.choice(['high', 'medium', 'low']),
                    'verification_status': random.choice(['verified', 'probable', 'rumor']),
                    'notes': f"Intelligence report for {party} in {const['name']}",
                    'reported_by': f"field_analyst_{random.randint(1, 10)}",
                    'created_at': datetime.combine(report_date, time(random.randint(16, 22), 0)),
                    'updated_at': datetime.combine(report_date, time(random.randint(16, 22), 30))
                })
    
    return pd.DataFrame(data)

# =====================================================
# MODULE 5: Promises
# =====================================================

def generate_promises():
    """Generate promise catalog with all schema fields"""
    data = []
    categories = ['infrastructure', 'healthcare', 'education', 'employment', 'agriculture', 'welfare']
    statuses = ['announced', 'planning', 'in_progress', 'completed', 'delayed', 'cancelled']
    
    for const in CONSTITUENCIES:
        acs = ASSEMBLY_CONSTITUENCIES[const['id']]
        # 25-45 promises per constituency
        num_promises = random.randint(25, 45)
        
        for i in range(num_promises):
            announced = random_date(date(2025, 1, 1), date(2025, 3, 31))
            category = random.choice(categories)
            status = random.choice(statuses)
            completion = random.randint(0, 100) if status not in ['announced', 'cancelled'] else 0
            
            # Generate milestones
            num_milestones = random.randint(3, 6)
            milestones = []
            for m in range(num_milestones):
                milestone_date = announced + timedelta(days=random.randint(30, 180) * (m + 1))
                milestones.append({
                    'milestone_name': f"Phase {m+1}: {random.choice(['Planning', 'Execution', 'Monitoring', 'Completion'])}",
                    'target_date': milestone_date.isoformat(),
                    'actual_date': (milestone_date + timedelta(days=random.randint(-10, 10))).isoformat() if m < completion / 20 else None,
                    'status': random.choice(['completed', 'in_progress', 'pending']) if m < num_milestones / 2 else 'pending',
                    'description': f"Milestone description for phase {m+1}"
                })
            
            data.append({
                'promise_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'promise_title': f"{category.title()} Development in {const['name']}",
                'promise_description': f"Comprehensive {category} improvement initiative covering multiple aspects",
                'promise_category': category,
                'promise_type': random.choice(['election_manifesto', 'public_meeting', 'media_statement', 'budget_announcement']),
                'announced_date': announced,
                'announced_by': f"MP {const['name']}",
                'announced_at': f"{random.choice(acs)['name']} Public Meeting",
                'target_beneficiaries': random.choice(['all', 'youth', 'women', 'farmers', 'sc_st', 'minorities']),
                'estimated_beneficiaries_count': random.randint(5000, 100000),
                'scope': random.choice(['constituency_wide', 'ward_specific', 'village_specific']),
                'specific_locations': json.dumps([random.choice(acs)['name'] for _ in range(random.randint(2, 5))]),
                'impact_level': random.choice(['transformative', 'high', 'medium', 'low']),
                'estimated_cost': round(random.uniform(5000000, 50000000), 2),
                'budget_allocated': round(random.uniform(4000000, 45000000), 2),
                'budget_utilized': round(random.uniform(1000000, 40000000), 2) if completion > 0 else 0,
                'funding_source': random.choice(['state_govt', 'central_govt', 'local_body', 'mixed']),
                'target_completion_date': announced + timedelta(days=random.randint(180, 720)),
                'actual_start_date': announced + timedelta(days=random.randint(30, 90)) if status not in ['announced', 'cancelled'] else None,
                'actual_completion_date': announced + timedelta(days=random.randint(200, 800)) if status == 'completed' else None,
                'duration_months': random.randint(6, 24),
                'status': status,
                'completion_percentage': completion,
                'milestones': json.dumps(milestones),
                'implementing_agency': random.choice(['PWD', 'Municipal Corporation', 'State Department', 'Contractor']),
                'project_manager': f"Manager_{random.randint(1, 20)}",
                'contact_person': f"Contact_{random.randint(1, 30)}",
                'contact_phone': f"+91{random.randint(7000000000, 9999999999)}",
                'current_challenges': json.dumps([
                    random.choice(['Land acquisition delay', 'Budget constraints', 'Weather issues', 'Contractor issues'])
                    for _ in range(random.randint(1, 3))
                ] if status in ['in_progress', 'delayed'] else []),
                'risk_factors': json.dumps([
                    random.choice(['Timeline risk', 'Budget overrun', 'Quality concerns', 'Political opposition'])
                    for _ in range(random.randint(1, 2))
                ]),
                'mitigation_measures': json.dumps([
                    'Regular monitoring',
                    'Stakeholder engagement',
                    'Contingency planning'
                ]),
                'public_awareness_level': random.choice(['high', 'medium', 'low']),
                'satisfaction_score': random.randint(60, 95) if completion > 50 else random.randint(40, 70),
                'feedback_count': random.randint(50, 500),
                'media_coverage_count': random.randint(5, 30),
                'last_public_update_date': announced + timedelta(days=random.randint(30, 200)) if completion > 10 else None,
                'visibility_score': random.randint(40, 90),
                'document_urls': json.dumps([f"https://docs.example.com/promise_{uuid.uuid4().hex[:8]}.pdf" for _ in range(random.randint(1, 3))]),
                'photo_urls': json.dumps([f"https://photos.example.com/img_{uuid.uuid4().hex[:8]}.jpg" for _ in range(random.randint(2, 8))]),
                'notes': f"Additional notes for {category} promise" if random.random() > 0.5 else None,
                'created_by': 'admin',
                'created_at': datetime.combine(announced, time(10, 0)),
                'updated_at': datetime.combine(announced + timedelta(days=random.randint(30, 300)), time(15, 0))
            })
    
    return pd.DataFrame(data)

def generate_promise_milestones():
    """Generate promise milestone tracking data"""
    # This generates milestones that would be linked to promises
    # For synthetic data, we'll create standalone milestone records
    data = []
    
    milestone_types = ['planning_completed', 'budget_approved', 'work_started', 'phase_1_completed', 'phase_2_completed', 'final_completion', 'inauguration']
    
    for const in CONSTITUENCIES:
        # Generate 15-25 promise milestones per constituency
        num_milestones = random.randint(15, 25)
        
        for _ in range(num_milestones):
            target_date = random_date(START_DATE, END_DATE)
            status = random.choice(['completed', 'in_progress', 'pending', 'delayed'])
            actual_date = random_date(START_DATE, END_DATE) if status == 'completed' else None
            
            data.append({
                'milestone_id': str(uuid.uuid4()),
                'promise_id': str(uuid.uuid4()),  # Would link to actual promise
                'constituency_id': const['id'],
                'milestone_name': random.choice(milestone_types),
                'milestone_description': f"Milestone for promise in {const['name']}",
                'milestone_order': random.randint(1, 7),
                'target_date': target_date,
                'actual_date': actual_date,
                'status': status,
                'completion_percentage': random.randint(0, 100) if status != 'pending' else 0,
                'deliverables': json.dumps([f"Deliverable {i+1}" for i in range(random.randint(2, 5))]),
                'responsible_team': f"Team {random.randint(1, 5)}",
                'budget_allocated': round(random.uniform(100000, 5000000), 2),
                'budget_spent': round(random.uniform(50000, 3000000), 2) if status in ['completed', 'in_progress'] else 0,
                'challenges': json.dumps([f"Challenge {i+1}" for i in range(random.randint(0, 3))]) if random.random() > 0.5 else json.dumps([]),
                'verification_status': random.choice(['verified', 'pending', 'not_required']),
                'verified_by': f"verifier_{random.randint(1, 5)}" if status == 'completed' else None,
                'verification_date': actual_date if status == 'completed' and actual_date else None,
                'photos': json.dumps([f"photo_{uuid.uuid4()}.jpg" for _ in range(random.randint(0, 8))]),
                'documents': json.dumps([f"doc_{uuid.uuid4()}.pdf" for _ in range(random.randint(0, 4))]),
                'notes': f"Milestone tracking notes for {const['name']}",
                'created_at': datetime.now(),
                'updated_at': datetime.now()
            })
    
    return pd.DataFrame(data)

def generate_promise_updates():
    """Generate promise progress updates (see schema promise_updates table)"""
    data = []
    
    update_types = ['milestone_achieved', 'progress_report', 'delay_notification', 'budget_update', 'completion']
    
    for const in CONSTITUENCIES:
        # 30-50 updates per constituency
        num_updates = random.randint(30, 50)
        
        for _ in range(num_updates):
            update_date = random_date(START_DATE, END_DATE)
            update_type = random.choice(update_types)
            
            data.append({
                'update_id': str(uuid.uuid4()),
                'promise_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'update_date': update_date,
                'update_time': datetime.combine(update_date, time(random.randint(9, 18), random.choice([0, 15, 30, 45]))),
                'completion_percentage': random.randint(0, 100),
                'status': random.choice(['announced', 'planning', 'in_progress', 'completed', 'delayed']),
                'update_type': update_type,
                'update_title': f"{update_type.replace('_', ' ').title()} for {const['name']}",
                'update_description': f"Detailed update about {update_type} in {const['name']} constituency",
                'achievements': json.dumps([f"Achievement {i+1}" for i in range(random.randint(1, 4))]) if update_type in ['milestone_achieved', 'completion'] else json.dumps([]),
                'deliverables_completed': json.dumps([f"Deliverable {i+1}" for i in range(random.randint(0, 3))]),
                'beneficiaries_reached': random.randint(100, 10000) if update_type in ['completion', 'progress_report'] else None,
                'amount_spent': round(random.uniform(50000, 2000000), 2) if update_type == 'budget_update' else None,
                'new_challenges': json.dumps([f"Challenge {i+1}" for i in range(random.randint(0, 3))]) if update_type == 'delay_notification' else json.dumps([]),
                'delays_reason': random.choice(['Budget constraints', 'Administrative delays', 'Weather conditions', 'Resource shortage']) if update_type == 'delay_notification' else None,
                'revised_timeline': random_date(update_date, END_DATE) if update_type == 'delay_notification' else None,
                'media_release': random.choice([True, False]),
                'public_event': random.choice([True, False]) if update_type in ['milestone_achieved', 'completion'] else False,
                'photos_count': random.randint(0, 15),
                'videos_count': random.randint(0, 5),
                'verified': random.choice([True, False]),
                'verified_by': f"verifier_{random.randint(1, 5)}" if random.random() > 0.3 else None,
                'verification_notes': f"Verification notes for update" if random.random() > 0.5 else None,
                'testimonials': json.dumps([
                    {'person_name': f"Beneficiary {i+1}", 'person_role': random.choice(['Resident', 'Local Leader', 'Shopkeeper']),
                     'quote': f"Testimonial quote {i+1}", 'photo_url': f"photo_{uuid.uuid4()}.jpg"}
                    for i in range(random.randint(0, 3))
                ]),
                'updated_by': f"coordinator_{random.randint(1, 10)}",
                'created_at': datetime.combine(update_date, time(random.randint(10, 20), 0))
            })
    
    return pd.DataFrame(data)

def generate_promise_beneficiaries():
    """Generate promise beneficiary tracking data (derived from promise_impact schema)"""
    data = []
    
    for const in CONSTITUENCIES:
        # 10-20 beneficiary records per constituency
        num_records = random.randint(10, 20)
        
        for _ in range(num_records):
            assessment_date = random_date(START_DATE, END_DATE)
            
            data.append({
                'beneficiary_id': str(uuid.uuid4()),
                'promise_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'assessment_date': assessment_date,
                'beneficiary_type': random.choice(['individual', 'household', 'community', 'institution']),
                'beneficiary_category': random.choice(['all_citizens', 'youth', 'women', 'farmers', 'sc_st', 'minorities', 'bpl_families']),
                'total_beneficiaries': random.randint(100, 50000),
                'direct_beneficiaries': random.randint(50, 30000),
                'indirect_beneficiaries': random.randint(50, 20000),
                'registered_beneficiaries': random.randint(80, 40000),
                'verified_beneficiaries': random.randint(70, 35000),
                'satisfaction_score': random.randint(60, 95),
                'feedback_collected': random.randint(20, 500),
                'positive_feedback_pct': round(random.uniform(60, 90), 2),
                'impact_rating': round(random.uniform(3.5, 5.0), 1),
                'lives_improved': random.randint(50, 10000),
                'economic_benefit_per_beneficiary': round(random.uniform(5000, 100000), 2),
                'total_economic_impact': round(random.uniform(500000, 50000000), 2),
                'testimonials_count': random.randint(5, 50),
                'case_studies_count': random.randint(1, 10),
                'media_stories_count': random.randint(2, 20),
                'before_after_analysis': json.dumps({
                    'before_condition': random.choice(['poor', 'inadequate', 'lacking']),
                    'after_condition': random.choice(['improved', 'good', 'excellent']),
                    'improvement_pct': round(random.uniform(40, 90), 2)
                }),
                'geographic_distribution': json.dumps({
                    'urban': random.randint(30, 70),
                    'rural': random.randint(30, 70)
                }),
                'created_at': datetime.combine(assessment_date, time(23, 0)),
                'updated_at': datetime.combine(assessment_date, time(23, 30))
            })
    
    return pd.DataFrame(data)

# =====================================================
# MODULE 6: Alerts & Crisis
# =====================================================

def generate_alerts():
    """Generate alerts system data"""
    data = []
    alert_types = ['crisis', 'opportunity', 'threat', 'anomaly', 'milestone']
    categories = ['political', 'social', 'infrastructure', 'health', 'law_order']
    severities = ['critical', 'high', 'medium', 'low']
    statuses = ['new', 'acknowledged', 'investigating', 'action_taken', 'resolved', 'false_alarm', 'monitoring']
    
    for const in CONSTITUENCIES:
        acs = ASSEMBLY_CONSTITUENCIES[const['id']]
        
        # 100-200 alerts per constituency over the year
        num_alerts = random.randint(100, 200)
        
        for _ in range(num_alerts):
            reported = random_timestamp(START_DATE, END_DATE)
            severity = random.choice(severities)
            status = random.choice(statuses)
            has_resolution = status in ['resolved', 'false_alarm']
            
            data.append({
                'alert_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'alert_type': random.choice(alert_types),
                'alert_category': random.choice(categories),
                'title': f"Alert in {random.choice(acs)['name']}",
                'description': f"Detailed alert description for {const['name']}",
                'severity': severity,
                'urgency': 'immediate' if severity == 'critical' else random.choice(['within_24h', 'within_week', 'routine']),
                'location_type': random.choice(['ward', 'constituency_wide']),
                'location_ward': random.choice(acs)['name'],
                'location_village': random.choice(['Village A', 'Village B', 'Village C', None]),
                'location_coordinates': json.dumps({'lat': round(random.uniform(17.0, 18.5), 6), 'lng': round(random.uniform(78.0, 79.5), 6)}) if random.random() > 0.3 else None,
                'affected_area_radius_km': round(random.uniform(0.5, 15), 2) if random.random() > 0.4 else None,
                'potential_impact': random.choice(['high', 'medium', 'low']),
                'estimated_people_affected': random.randint(100, 10000),
                'estimated_voters_affected': random.randint(50, 5000),
                'political_risk_score': random.randint(20, 95),
                'source_type': random.choice(['field_report', 'social_media', 'volunteer', 'news', 'ai_detection', 'public_complaint']),
                'source_name': random.choice(['Local News', 'Twitter Monitor', 'Field Agent', 'Community Leader', None]),
                'source_credibility': random.choice(['high', 'medium', 'high']),
                'reported_by': f"volunteer_{random.randint(1, 30)}",
                'incident_time': reported - timedelta(hours=random.randint(0, 12)),
                'detected_at': reported,
                'reported_at': reported,
                'status': status,
                'priority': f"p{['0', '1', '2', '3'][severities.index(severity)]}_" + severity,
                'assigned_to': f"coordinator_{random.randint(1, 5)}",
                'assigned_at': reported + timedelta(minutes=random.randint(5, 120)) if status != 'new' else None,
                'escalated_to': f"senior_officer_{random.randint(1, 3)}" if severity in ['critical', 'high'] and random.random() > 0.5 else None,
                'escalation_level': random.randint(0, 3),
                'actions_taken': json.dumps([
                    {'action': random.choice(['Site visit', 'Team deployed', 'Resources allocated', 'Meeting arranged']),
                     'taken_by': f"officer_{random.randint(1, 5)}",
                     'taken_at': (reported + timedelta(hours=random.randint(1, 24))).isoformat(),
                     'outcome': random.choice(['Successful', 'Partial', 'In Progress'])}
                    for _ in range(random.randint(1, 3))
                ] if status not in ['new', 'acknowledged'] else []),
                'resolution_notes': f"Issue resolved through {random.choice(['immediate action', 'coordination with authorities', 'resource deployment', 'community engagement'])}" if has_resolution else None,
                'resolved_by': f"coordinator_{random.randint(1, 5)}" if has_resolution else None,
                'resolved_at': reported + timedelta(hours=random.randint(2, 168)) if has_resolution else None,
                'resolution_time_mins': random.randint(30, 2880) if has_resolution else None,
                'requires_followup': random.choice([True, False]) if has_resolution else None,
                'followup_date': (reported + timedelta(days=random.randint(7, 30))).date() if has_resolution and random.random() > 0.5 else None,
                'followup_notes': f"Monitor situation for {random.randint(7, 30)} days" if has_resolution and random.random() > 0.6 else None,
                'photos': json.dumps([f"photo_{uuid.uuid4()}.jpg" for _ in range(random.randint(0, 5))]),
                'videos': json.dumps([f"video_{uuid.uuid4()}.mp4" for _ in range(random.randint(0, 2))]),
                'documents': json.dumps([f"doc_{uuid.uuid4()}.pdf" for _ in range(random.randint(0, 3))]),
                'media_coverage': random.choice([True, False]),
                'related_alerts': json.dumps([str(uuid.uuid4()) for _ in range(random.randint(0, 2))]),
                'related_promises': json.dumps([str(uuid.uuid4()) for _ in range(random.randint(0, 2))]),
                'related_visits': json.dumps([str(uuid.uuid4()) for _ in range(random.randint(0, 3))]),
                'ai_sentiment_score': round(random.uniform(-0.8, 0.8), 2) if random.random() > 0.3 else None,
                'ai_risk_prediction': random.choice(['high_risk', 'medium_risk', 'low_risk', None]),
                'ai_recommended_actions': json.dumps([
                    random.choice(['Immediate site visit', 'Deploy resources', 'Coordinate with authorities', 'Public communication', 'Monitor situation'])
                    for _ in range(random.randint(2, 4))
                ]) if random.random() > 0.4 else json.dumps([]),
                'created_at': reported,
                'updated_at': reported + timedelta(hours=random.randint(1, 48))
            })
    
    return pd.DataFrame(data)

def generate_crisis_events():
    """Generate major crisis event tracking"""
    data = []
    
    crisis_types = ['natural_disaster', 'civil_unrest', 'health_emergency', 'infrastructure_failure', 'political_crisis', 'law_order']
    
    for const in CONSTITUENCIES:
        acs = ASSEMBLY_CONSTITUENCIES[const['id']]
        
        # 3-8 crisis events per constituency over the year
        num_crises = random.randint(3, 8)
        
        for _ in range(num_crises):
            start_time = datetime.combine(random_date(START_DATE, END_DATE), time(random.randint(0, 23), random.randint(0, 59)))
            crisis_type = random.choice(crisis_types)
            severity = random.choice(['catastrophic', 'severe', 'moderate', 'minor'])
            status = random.choice(['active', 'contained', 'resolved', 'monitoring'])
            
            # Calculate duration
            if status == 'resolved':
                duration_hours = round(random.uniform(2, 168), 2)  # 2 hours to 7 days
                end_time = start_time + timedelta(hours=duration_hours)
            elif status in ['contained', 'monitoring']:
                duration_hours = round(random.uniform(12, 96), 2)
                end_time = start_time + timedelta(hours=duration_hours)
            else:
                duration_hours = None
                end_time = None
            
            data.append({
                'crisis_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'crisis_type': crisis_type,
                'crisis_name': f"{crisis_type.replace('_', ' ').title()} in {const['name']}",
                'description': f"Major {crisis_type} event affecting {const['name']} constituency",
                'severity_level': severity,
                'start_time': start_time,
                'end_time': end_time,
                'duration_hours': duration_hours,
                'status': status,
                'affected_locations': json.dumps([
                    {'ward': ac['name'], 'village': f"Village_{random.randint(1, 10)}", 'severity': random.choice(['high', 'medium', 'low'])}
                    for ac in random.sample(acs, min(random.randint(2, 5), len(acs)))
                ]),
                'impact_metrics': json.dumps({
                    'people_affected': random.randint(500, 50000),
                    'households_affected': random.randint(100, 10000),
                    'voters_affected': random.randint(400, 40000),
                    'casualties': random.randint(0, 20) if severity in ['catastrophic', 'severe'] else 0,
                    'injuries': random.randint(0, 100) if severity in ['catastrophic', 'severe'] else random.randint(0, 30),
                    'property_damage_estimate': round(random.uniform(1000000, 100000000), 2),
                    'infrastructure_damaged': [f"Infrastructure_{i+1}" for i in range(random.randint(1, 5))]
                }),
                'political_sensitivity': random.choice(['very_high', 'high', 'medium', 'low']),
                'media_attention_level': random.choice(['viral', 'high', 'medium', 'low', 'none']),
                'opposition_exploitation_risk': random.choice(['high', 'medium', 'low']),
                'voter_sentiment_impact': round(random.uniform(-0.8, 0.2), 2),
                'response_team': json.dumps([
                    {'member_name': f"Officer_{random.randint(1, 20)}", 'role': random.choice(['Coordinator', 'Field Officer', 'Medical', 'Logistics']),
                     'contact': f"+91-{random.randint(7000000000, 9999999999)}"}
                    for _ in range(random.randint(3, 8))
                ]),
                'command_center_location': random.choice(acs)['name'],
                'response_coordinator': f"Senior_Officer_{random.randint(1, 5)}",
                'relief_measures': json.dumps([
                    {'measure': random.choice(['Food distribution', 'Medical aid', 'Shelter', 'Cash assistance', 'Infrastructure repair']),
                     'beneficiaries': random.randint(100, 10000),
                     'amount_spent': round(random.uniform(100000, 5000000), 2),
                     'deployed_at': (start_time + timedelta(hours=random.randint(2, 48))).isoformat(),
                     'effectiveness': random.choice(['Highly effective', 'Effective', 'Partially effective'])}
                    for _ in range(random.randint(2, 5))
                ]),
                'resources_deployed': json.dumps({
                    'personnel': random.randint(20, 200),
                    'vehicles': random.randint(5, 50),
                    'equipment': [f"Equipment_{i+1}" for i in range(random.randint(3, 10))],
                    'budget_allocated': round(random.uniform(500000, 20000000), 2),
                    'budget_spent': round(random.uniform(300000, 15000000), 2)
                }),
                'public_statements': json.dumps([
                    {'statement_time': (start_time + timedelta(hours=random.randint(1, 72))).isoformat(),
                     'statement_by': random.choice([f"MP {const['name']}", f"Minister_{random.randint(1, 5)}", f"Officer_{random.randint(1, 10)}"]),
                     'channel': random.choice(['Press Conference', 'Social Media', 'TV Interview', 'Radio']),
                     'content': f"Statement about crisis response"}
                    for _ in range(random.randint(2, 6))
                ]),
                'media_briefings_count': random.randint(2, 10),
                'social_media_updates_count': random.randint(10, 50),
                'agencies_involved': json.dumps(random.sample(['Police', 'Fire Dept', 'Medical Services', 'Revenue Dept', 'Municipal Corp', 'NGOs'], k=random.randint(3, 5))),
                'external_support': json.dumps([f"Agency_{i+1}" for i in range(random.randint(0, 4))]),
                'challenges_faced': json.dumps([f"Challenge {i+1}" for i in range(random.randint(2, 5))]),
                'what_worked_well': json.dumps([f"Success factor {i+1}" for i in range(random.randint(2, 4))]),
                'areas_for_improvement': json.dumps([f"Improvement area {i+1}" for i in range(random.randint(2, 4))]),
                'recommendations': json.dumps([f"Recommendation {i+1}" for i in range(random.randint(2, 5))]),
                'incident_report_url': f"https://reports.geodisha.com/crisis_{uuid.uuid4()}.pdf",
                'photos': json.dumps([f"photo_{uuid.uuid4()}.jpg" for _ in range(random.randint(5, 20))]),
                'videos': json.dumps([f"video_{uuid.uuid4()}.mp4" for _ in range(random.randint(2, 8))]),
                'news_coverage': json.dumps([f"https://news.com/article_{uuid.uuid4()}" for _ in range(random.randint(3, 15))]),
                'created_by': f"crisis_manager_{random.randint(1, 5)}",
                'created_at': start_time,
                'updated_at': end_time if end_time else start_time + timedelta(hours=24)
            })
    
    return pd.DataFrame(data)

def generate_issue_escalations():
    """Generate issue escalation tracking"""
    data = []
    
    issue_types = ['grievance', 'complaint', 'service_request', 'emergency', 'feedback']
    issue_categories = ['infrastructure', 'healthcare', 'education', 'water_supply', 'electricity', 'roads', 'sanitation', 'law_order']
    
    for const in CONSTITUENCIES:
        # 40-80 escalations per constituency
        num_escalations = random.randint(40, 80)
        
        for _ in range(num_escalations):
            original_report = datetime.combine(random_date(START_DATE, END_DATE - timedelta(days=30)), time(random.randint(8, 20), random.randint(0, 59)))
            escalated_at = original_report + timedelta(days=random.randint(1, 15), hours=random.randint(0, 23))
            status = random.choice(['escalated', 'under_review', 'action_initiated', 'resolved', 'closed'])
            
            days_since = (escalated_at.date() - original_report.date()).days
            sla_deadline = original_report + timedelta(days=random.randint(7, 30))
            sla_breached = escalated_at > sla_deadline
            
            # Resolution time
            if status in ['resolved', 'closed']:
                resolved_at = escalated_at + timedelta(hours=random.randint(4, 240))
                resolution_hours = (resolved_at - escalated_at).total_seconds() / 3600
            else:
                resolved_at = None
                resolution_hours = None
            
            data.append({
                'escalation_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'original_issue_id': str(uuid.uuid4()),
                'issue_type': random.choice(issue_types),
                'issue_category': random.choice(issue_categories),
                'issue_description': f"Issue in {const['name']} requiring escalation",
                'escalation_level': random.randint(1, 4),
                'escalation_reason': random.choice(['No action taken', 'Requires senior attention', 'Complex issue', 'SLA breach', 'VIP complaint']),
                'escalated_from': f"officer_level_{random.randint(1, 3)}",
                'escalated_to': f"officer_level_{random.randint(2, 4)}",
                'escalated_at': escalated_at,
                'original_report_date': original_report,
                'days_since_reported': days_since,
                'sla_breached': sla_breached,
                'sla_deadline': sla_deadline,
                'status': status,
                'priority': random.choice(['p0_critical', 'p1_high', 'p2_medium', 'p3_low']),
                'complainant_name': f"Complainant_{random.randint(1, 1000)}",
                'complainant_contact': f"+91-{random.randint(7000000000, 9999999999)}",
                'complainant_location': random.choice(ASSEMBLY_CONSTITUENCIES[const['id']])['name'],
                'assigned_to': f"resolver_{random.randint(1, 15)}",
                'assigned_at': escalated_at + timedelta(hours=random.randint(1, 24)),
                'actions_taken': json.dumps([
                    {'action': random.choice(['Site inspection', 'Team deployed', 'Coordination meeting', 'Resource allocation']),
                     'action_by': f"officer_{random.randint(1, 10)}",
                     'action_at': (escalated_at + timedelta(hours=random.randint(2, 100))).isoformat(),
                     'notes': f"Action notes {random.randint(1, 100)}"}
                    for _ in range(random.randint(1, 4))
                ]),
                'resolution_time_hours': resolution_hours,
                'resolution_notes': f"Issue resolved through {random.choice(['immediate intervention', 'coordination', 'resource deployment'])}" if status in ['resolved', 'closed'] else None,
                'resolved_by': f"resolver_{random.randint(1, 15)}" if status in ['resolved', 'closed'] else None,
                'resolved_at': resolved_at,
                'complainant_satisfied': random.choice([True, False]) if status in ['resolved', 'closed'] else None,
                'satisfaction_score': random.randint(1, 5) if status in ['resolved', 'closed'] else None,
                'feedback': f"Feedback from complainant" if status in ['resolved', 'closed'] and random.random() > 0.5 else None,
                'root_cause': random.choice(['Resource shortage', 'Administrative delay', 'Coordination gap', 'Technical issue']) if status in ['resolved', 'closed'] else None,
                'preventive_measures': json.dumps([f"Measure {i+1}" for i in range(random.randint(1, 3))]) if status in ['resolved', 'closed'] else json.dumps([]),
                'created_at': escalated_at,
                'updated_at': resolved_at if resolved_at else escalated_at + timedelta(hours=random.randint(1, 48))
            })
    
    return pd.DataFrame(data)

def generate_monitoring_metrics():
    """Generate real-time monitoring dashboard metrics"""
    data = []
    
    for const in CONSTITUENCIES:
        acs = ASSEMBLY_CONSTITUENCIES[const['id']]
        
        # Generate daily metrics for each constituency
        current_date = START_DATE
        while current_date <= END_DATE:
            measurement_time = datetime.combine(current_date, time(23, 59, 59))
            
            # Alert metrics
            total_active = random.randint(10, 80)
            critical = random.randint(2, 15)
            high = random.randint(5, 20)
            medium = random.randint(10, 30)
            low = total_active - (critical + high + medium)
            
            data.append({
                'metric_id': str(uuid.uuid4()),
                'constituency_id': const['id'],
                'measurement_time': measurement_time,
                'measurement_date': current_date,
                'alert_counts': json.dumps({
                    'total_active': total_active,
                    'critical': critical,
                    'high': high,
                    'medium': medium,
                    'low': low,
                    'new_24h': random.randint(5, 25),
                    'resolved_24h': random.randint(3, 20)
                }),
                'crisis_counts': json.dumps({
                    'active_crises': random.randint(0, 5),
                    'new_crises_7d': random.randint(0, 3),
                    'resolved_crises_7d': random.randint(1, 4),
                    'average_resolution_time_hours': round(random.uniform(12, 120), 2)
                }),
                'response_performance': json.dumps({
                    'avg_response_time_mins': round(random.uniform(15, 180), 2),
                    'avg_resolution_time_hours': round(random.uniform(4, 72), 2),
                    'on_time_resolution_rate': round(random.uniform(0.65, 0.95), 2),
                    'escalation_rate': round(random.uniform(0.05, 0.25), 2)
                }),
                'health_scores': json.dumps({
                    'overall_health': random.randint(60, 95),
                    'crisis_readiness': random.randint(65, 95),
                    'response_capability': random.randint(70, 95),
                    'resource_adequacy': random.randint(60, 90)
                }),
                'trends': json.dumps({
                    'alert_trend_7d': random.choice(['increasing', 'stable', 'decreasing']),
                    'severity_trend': random.choice(['worsening', 'stable', 'improving']),
                    'resolution_trend': random.choice(['faster', 'stable', 'slower'])
                }),
                'hotspot_wards': json.dumps([
                    {'ward': ac['name'], 'active_alerts': random.randint(2, 15), 'severity_score': random.randint(40, 90),
                     'attention_needed': random.choice([True, False])}
                    for ac in random.sample(acs, min(random.randint(2, 4), len(acs)))
                ]),
                'alerts_by_category': json.dumps([
                    {'category': cat, 'count': random.randint(2, 20), 'critical_count': random.randint(0, 5)}
                    for cat in random.sample(['political', 'social', 'infrastructure', 'health', 'law_order'], k=random.randint(3, 5))
                ]),
                'risk_indicators': json.dumps({
                    'high_risk_areas': random.randint(1, 5),
                    'unresolved_critical_alerts': critical,
                    'pending_escalations': random.randint(2, 15),
                    'sla_breaches_24h': random.randint(0, 8)
                }),
                'capacity_status': json.dumps({
                    'active_responders': random.randint(20, 100),
                    'available_resources': random.randint(50, 200),
                    'utilization_rate': round(random.uniform(0.4, 0.9), 2),
                    'overload_risk': random.choice([True, False])
                }),
                'created_at': measurement_time
            })
            
            current_date += timedelta(days=1)
    
    return pd.DataFrame(data)

# =====================================================
# Save Functions
# =====================================================

def save_to_csv(df, filename):
    """Save dataframe to CSV"""
    output_dir = Path('sql/seed')
    output_dir.mkdir(parents=True, exist_ok=True)
    
    filepath = output_dir / filename
    df.to_csv(filepath, index=False)
    print(f"✓ Generated {filename}: {len(df)} rows")

def main():
    """Generate all synthetic data for 24 tables across 6 modules"""
    print("🚀 Starting synthetic data generation for 24 tables...\n")
    
    print("MODULE 1: Command Center (4 tables)")
    save_to_csv(generate_constituency_overview(), '01_constituency_overview.csv')
    save_to_csv(generate_constituency_kpis(), '02_constituency_kpis.csv')
    save_to_csv(generate_constituency_trends(), '03_constituency_trends.csv')
    save_to_csv(generate_executive_summary(), '04_executive_summary.csv')
    
    print("\nMODULE 2: AI Intelligence Hub (4 tables)")
    save_to_csv(generate_ai_recommendations(), '05_ai_recommendations.csv')
    save_to_csv(generate_media_talking_points(), '06_media_talking_points.csv')
    save_to_csv(generate_influencer_mapping(), '07_influencer_mapping.csv')
    save_to_csv(generate_visit_planning(), '08_visit_planning.csv')
    
    print("\nMODULE 3: Ground Reality (4 tables)")
    save_to_csv(generate_visit_records_enhanced(), '09_visit_records_enhanced.csv')
    save_to_csv(generate_issue_heatmap(), '10_issue_heatmap.csv')
    save_to_csv(generate_ward_intelligence(), '11_ward_intelligence.csv')
    save_to_csv(generate_visit_statistics(), '12_visit_statistics.csv')
    
    print("\nMODULE 4: Election War Room (4 tables)")
    save_to_csv(generate_booth_analysis(), '13_booth_analysis.csv')
    save_to_csv(generate_booth_score_trends(), '14_booth_score_trends.csv')
    save_to_csv(generate_voter_segments(), '15_voter_segments.csv')
    save_to_csv(generate_opposition_intelligence(), '16_opposition_intelligence.csv')
    
    print("\nMODULE 5: Promises (4 tables)")
    save_to_csv(generate_promises(), '17_promises.csv')
    save_to_csv(generate_promise_updates(), '18_promise_updates.csv')
    save_to_csv(generate_promise_milestones(), '19_promise_milestones.csv')
    save_to_csv(generate_promise_beneficiaries(), '20_promise_beneficiaries.csv')
    
    print("\nMODULE 6: Alerts & Crisis (4 tables)")
    save_to_csv(generate_alerts(), '21_alerts.csv')
    save_to_csv(generate_crisis_events(), '22_crisis_events.csv')
    save_to_csv(generate_issue_escalations(), '23_issue_escalations.csv')
    save_to_csv(generate_monitoring_metrics(), '24_monitoring_metrics.csv')
    
    print("\n✅ Data generation complete!")
    print(f"📁 24 CSV files saved to: sql/seed/")
    print(f"📊 Total tables generated: 24 (4 per module × 6 modules)")

if __name__ == "__main__":
    main()
