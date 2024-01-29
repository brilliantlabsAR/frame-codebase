from PIL import Image
import numpy as np
import argparse


def bayer_image(file):
    image = Image.open(file)

    if image.mode == "P":
        image = image.convert("RGB")

    bayered_image = np.zeros((image.height * 2, image.width * 2, 3), np.uint8)

    for h in range(image.height):
        for w in range(image.width):
            bayered_image[2 * h, 2 * w, 2] = np.array(image)[h, w, 2]
            bayered_image[2 * h + 1, 2 * w, 1] = np.array(image)[h, w, 1]
            bayered_image[2 * h, 2 * w + 1, 1] = np.array(image)[h, w, 1]
            bayered_image[2 * h + 1, 2 * w + 1, 0] = np.array(image)[h, w, 0]

    array_index = 0

    for h in range(image.height * 2):
        for w in range(image.width * 2):
            if (h % 2 == 0):
                if (w % 2 == 0):
                    # blue channel
                    print(f"mem[{str(array_index)}] = 'd{str(bayered_image[h, w, 2] * 4)};")
                else:
                    # blue channel
                    print(f"mem[{str(array_index)}] = 'd{str(bayered_image[h, w, 1] * 4)};")

            else:
                if (w % 2 == 0):
                    # green channel
                    print(f"mem[{str(array_index)}] = 'd{str(bayered_image[h, w, 1] * 4)};")
                else:
                    # red channel
                    print(f"mem[{str(array_index)}] = 'd{str(bayered_image[h, w, 0] * 4)};")
            array_index += 1

    bayered_image = Image.fromarray(bayered_image)
    bayered_image.save(f"{file[:-4]}_bayered.png")


def debayer_image(file, width, height):
    rgb_array = np.zeros((height, width, 3), dtype=np.uint8)

    data = np.loadtxt(file, dtype=np.uint32)

    for y in range(height):
        for x in range(width):
            pixel = data[y * width + x]

            red = ((pixel & 0x3FF00000) >> 22) & 0xFF
            green = ((pixel & 0xFFC00) >> 12) & 0xFF
            blue = ((pixel & 0x3FF) >> 2) & 0xFF

            rgb_array[y, x] = [red, green, blue]

    image = Image.fromarray(rgb_array)
    image.save(f"{file[:-4]}.png")


def main():
    parser = argparse.ArgumentParser(
        prog="debayer_utils",
        description="Bayer or debayer an image for use with the debayer testbench",
    )

    subparser = parser.add_subparsers(dest="operation")

    bayer_subcommand = subparser.add_parser("bayer", help="bayer an image")
    bayer_subcommand.add_argument(
        "file",
        type=str,
        help="image file to bayer",
    )

    debayer_subcommand = subparser.add_parser("debayer", help="debayer an array")
    debayer_subcommand.add_argument(
        "file",
        type=str,
        help="array to debayer",
    )
    debayer_subcommand.add_argument(
        "width",
        type=int,
        help="expected width",
    )
    debayer_subcommand.add_argument(
        "height",
        type=int,
        help="expected height",
    )

    # Parse
    args = parser.parse_args()

    if args.operation == "bayer":
        bayer_image(args.file)

    elif args.operation == "debayer":
        debayer_image(args.file, args.width, args.height)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
