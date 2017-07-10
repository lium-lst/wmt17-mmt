# LIUMCVC WMT17 Systems

This repository contains necessary scripts and data files to replicate
the results of LIUM-CVC submissions to Multimodal Translation (MMT)
task of WMT17 for both en->de and en->fr. You need to install
[nmtpy](https://github.com/lium-lst/nmtpy.git) in order to follow this tutorial.

## Data

The `data/` folder contains all English, German and French
[Multi30k](https://arxiv.org/abs/1605.00459) dataset
necessary to train and evaluate the systems. A secondary ambiguous MSCOCO test set
is also provided along with the main Flickr30k sets. All the files
under `data/` are verbatim copies of files downloaded from the
[official campaign website](http://www.statmt.org/wmt17/multimodal-task.html).

- `train.*` : 29K sentences
- `val.*` : 1014 sentences
- `test2016.*` : 1000 sentences
- `test2017.*` : 1000 sentences
- `testcoco.*` : 461 sentences

The `*_images.txt` files are text files containing the list of image names
for each split as they are ordered in the image features files.
