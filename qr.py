import cv2
import numpy as np
from ultralytics import YOLO 
import matplotlib.pyplot as plt  


def detect_qr_codes_and_draw_boundary(image_path):
    # Load image
    image = cv2.imread(image_path)
    if image is None:
        print("Error: Could not load image.")
        return

    # Initialize QR code detector
    qr_detector = cv2.QRCodeDetector()

    # Convert to grayscale
    #gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Detect QR codes
    retval, points = qr_detector.detectMulti(image)



    top_left = points[0,0]  # Top-left corner (x1, y1)
    bottom_left = points[0,3]  # Bottom-left corner (x2, y2)

    # Calculate height using Euclidean distance
    height = int(np.sqrt((bottom_left[0] - top_left[0]) ** 2 + (bottom_left[1] - top_left[1]) ** 2))

    top_left = tuple(map(int, top_left))
    bottom_right = (top_left[0] - height, top_left[1] + height)

    cv2.rectangle(image, top_left, bottom_right, color=(0, 255, 0), thickness=2)

    grid_size = 5
    line_color=(255, 0, 0)
    grid_thickness=2
    step_size = height // grid_size  # How far apart the lines will be

    # Draw vertical grid lines
    for i in range(1, grid_size):
        x = (top_left[0] - height) + i * step_size
        cv2.line(image, (x, top_left[1]), (x, bottom_right[1]), line_color, grid_thickness)

    # Draw horizontal grid lines
    for i in range(1, grid_size):
        y = top_left[1] + i * step_size
        cv2.line(image, (top_left[0], y), (bottom_right[0], y), line_color, grid_thickness)
    
    return image, top_left, bottom_right, height


def create_binary_mask(image):
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    
    # Define lower and upper bounds for skin tones in HSV
    lower_skin = np.array([0, 20, 70], dtype=np.uint8)
    upper_skin = np.array([20, 255, 255], dtype=np.uint8)
    
    # Create a mask for skin tones
    mask = cv2.inRange(hsv, lower_skin, upper_skin)
    return mask



def calculate_occlusion_percentage(binary_mask, top_left, bottom_right, height, grid_size=5, threshold=0.5):
    """
    Calculate the percentage of grid cells occluded by the finger.

    Args:
        binary_mask (numpy.ndarray): Binary mask of the image.
        top_left (tuple): Coordinates of the top-left corner of the bounding square.
        bottom_right (tuple): Coordinates of the bottom-right corner of the bounding square.
        height (int): Height of the bounding square.
        grid_size (int): Number of grid cells per row/column.
        threshold (float): Fraction of cell area to consider it as occluded (0 to 1).

    Returns:
        float: Percentage of the screen occluded by the finger.
    """
    step_size = height // grid_size
    occluded_cells = 0

    # Loop over each grid cell
    for i in range(grid_size):
        for j in range(grid_size):
            # Calculate cell boundaries
            x1 = (top_left[0] - height) + i * step_size
            x2 = x1 + step_size
            y1 = top_left[1] + j * step_size
            y2 = y1 + step_size

            # Extract cell region from the binary mask
            cell = binary_mask[y1:y2, x1:x2]

            # Calculate occluded fraction
            occluded_fraction = np.count_nonzero(cell) / (step_size * step_size)

            # Mark cell as occluded if fraction exceeds the threshold
            if occluded_fraction >= threshold:
                occluded_cells += 1

    # Calculate occlusion percentage
    total_cells = grid_size * grid_size
    occlusion_percentage = (occluded_cells / total_cells) * 100
    return occlusion_percentage


def main(image_path):
    # Detect QR code and get bounding square
    result = detect_qr_codes_and_draw_boundary(image_path)
    if result is None:
        return

    # Unpack the result
    processed_image, top_left, bottom_right, height = result

    # Create binary mask for occlusion detection
    binary_mask = create_binary_mask(processed_image)

    # Calculate occlusion percentage
    occlusion_percentage = calculate_occlusion_percentage(
        binary_mask, top_left, bottom_right, height, grid_size=5, threshold=0.5
    )

    # Display the result
    print(f"Occlusion Percentage: {occlusion_percentage:.2f}%")
    cv2.imshow("Occlusion Visualization", processed_image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()


# Provide the path to your image, image works better in "jpg" format
image_path = "images/IMG_961FDD04C53A-1.jpg"
main(image_path)

