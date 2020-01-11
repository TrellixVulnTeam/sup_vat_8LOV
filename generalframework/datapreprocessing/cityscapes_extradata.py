import shutil
import errno
import numpy as np
import argparse
from pathlib import Path
from collections import Iterable
from functools import partial
from multiprocessing import Pool
from PIL import Image
from generalframework.utils.utils import recursive_glob


def copy_(src, dest, move=False):
    """
    This function will copy both files and directories. First, we put our
    copytree function in a try block to catch any nasty exceptions.
    If our exception was caused because the source directory/folder was
    actually a file, then we copy the file instead.
    """

    try:
        shutil.copytree(src, dest)
    except OSError as e:
        # If the error was caused because the source wasn't a directory
        if e.errno == errno.ENOTDIR:
            if move:
                shutil.move(src, dest)
            else:
                shutil.copy(src, dest)
        else:
            print('Directory not copied. Error: %s' % e)


def preprocessing(filepaths: list, destiny_path: Path, resize: bool, size: Iterable):
    for img_path in filepaths:
        parts = img_path.parts
        dst_dir_img = destiny_path.joinpath(*parts[-4:-1])
        if not dst_dir_img.exists():
            dst_dir_img.mkdir(parents=True, exist_ok=True)

        gt_path = Path(
            img_path.as_posix().replace('/leftImg8bit', '/gtCoarse').replace('_leftImg8bit', '_gtCoarse_labelIds'))
        parts = gt_path.parts
        dst_dir_gt = destiny_path.joinpath(*parts[-4:-1])
        if not dst_dir_gt.exists():
            dst_dir_gt.mkdir(parents=True, exist_ok=True)

        if resize:
            assert img_path.exists()
            assert gt_path.exists()
            img: Image.Image = Image.open(img_path)
            gt: Image.Image = Image.open(gt_path)

            new_img = img.resize(size, resample=Image.BICUBIC)
            new_gt = gt.resize(size, resample=Image.NEAREST)
            new_img.save(dst_dir_img.joinpath(img_path.name))
            new_gt.save(dst_dir_gt.joinpath(gt_path.name))
        else:
            print(img_path, dst_dir_img.joinpath(img_path.name))
            print(gt_path, dst_dir_gt.joinpath(gt_path.name))
            copy_(img_path, dst_dir_img.joinpath(img_path.name))
            copy_(gt_path, dst_dir_gt.joinpath(gt_path.name))


def main(args: argparse.Namespace) -> None:
    # path to the unzipped leftImg8bit_trainextra folder
    images_path = Path(args.images_path)  # Path('../../dataset/Cityscapes/leftImg8bit/train')
    # images_path = Path('../../dataset/Cityscapes/leftImg8bit/train')
    assert images_path.exists()
    # root path of Cityscapes dataset
    destiny_path = Path('../../dataset/Cityscapes_extra')
    n_selected_imgs = args.n_images
    img_path_list = recursive_glob(rootdir=images_path.joinpath('leftImg8bit'), suffix=".png")
    print('{} images found'.format(img_path_list.__len__()))

    np.random.seed(1)
    filepaths = [
        Path(folder) for folder in np.random.choice(img_path_list, size=n_selected_imgs, replace=False)
    ]
    print('{} images randomly selected'.format(filepaths.__len__()))
    # resize and save in destiny_path
    preprocessing(filepaths, destiny_path, resize=args.preprocess, size=args.size)

    # resize_ = partial(preprocessing, destiny_path, resize=args.preprocess, size=args.size)
    # Pool().map(resize_, filepaths)


def get_args() -> argparse.Namespace:
    choices = argparse.ArgumentParser(description='input folder and files to report the training')
    choices.add_argument('--images_path', type=str,
                         help='path to the unzipped leftImg8bit_trainextra folder of Cityscapes dataset', required=True)
    choices.add_argument('--preprocess', type=bool, help='if the images must be preprocessed', default=True)
    choices.add_argument('--n_images', type=int, help='number of images to be selected as extra training data',
                         default=2000)
    choices.add_argument('--size', type=int, nargs='*', help='size of the preprocessed images', default=[1024, 512])
    args = choices.parse_args()
    print(args)
    return args


if __name__ == '__main__':
    main(get_args())
