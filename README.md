# LIUM-CVC WMT17 Multimodal Translation Systems

![mmt](./mmt.png?raw=true "mmt")

This repository contains necessary scripts and data files to replicate
the results of LIUM-CVC submissions to Multimodal Translation (MMT)
task of WMT17 for both en->de and en->fr.

**Note** : You need to install [nmtpy](https://github.com/lium-lst/nmtpy.git) in order to follow this tutorial.

## Data

The `data/` folder contains all English, German and French corpora files from
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

## Preparation

The script `scripts/preprocess-bpe-pkl.sh` will first use the following scripts
(which should be **available** in your `$PATH`) from
[Moses](https://github.com/moses-smt/mosesdecoder) repository in order to preprocess the corpora:

 - Normalize punctuations (`normalize-punctuation.perl`)
 - Tokenize (`tokenizer.perl`)
 - Lowercase (`lowercase.perl`)

It will then learn a joint BPE model with 10K merge operations
(for `en->de` and `en->fr` separately)
using the tools provided by the [subword-nmt](https://github.com/rsennrich/subword-nmt) repository. You need
to adapt the script to point to the correct **subword-nmt** folder
by modifying the variables `BPE_APPLY` and `BPE_LEARN`.

Once the BPE-ized files are saved under `data.tok.bpe/bpe.en-de` and `data.tok.bpe/bpe.en-fr`, `nmt-build-dict` from `nmtpy` project will be used to create the vocabulary `.pkl` files in the respective folders.

Since the multimodal architectures have their own data iterators, they need a special `.pkl` corpora file for each Flickr30k and MSCOCO split. These files are created by `scripts/raw2pkl` which is automatically called from `scripts/preprocess-bpe-pkl.sh`.

In the end, the files in `data.tok.bpe/bpe.en-{de,fr}` will be the files
that are used by `nmtpy`. The non-BPE versions of validation and test sets
from `data.tok.bpe` will also be used when scoring the hypotheses with
automatic metrics.

**Note**: The script should be launched directly from the `wmt17-mmt` checkout
folder.

### Image Features

Once the above preprocessing step is completed, you will need to download
and extract the image features under `data/images` as described in the
relevant [README](data/images/) file.

## Training

You should now be ready to train monomodal and multimodal architectures
using the prepared data. If everything went well and you have a recent
enough installation of `nmtpy`, you can use the following commands to
start training your baselines:

```
# Monomodal En->De system
$ nmt-train -c config/monomodal-en-de.conf

# Monomodal En->Fr system
$ nmt-train -c config/monomodal-en-fr.conf

# MNMT (trgmul variant) En->De system
$ nmt-train -c config/mnmt-en-de.conf

# MNMT (trgmul variant) En->Fr system
$ nmt-train -c config/mnmt-en-fr.conf

# MNMT (fusion with conv features) En->De system
$ nmt-train -c config/fusion-en-de.conf

# MNMT (fusion with conv features) En->Fr system
$ nmt-train -c config/fusion-en-fr.conf
```

These configurations will save the best `.npz` checkpoints
under `models/` inside your `wmt17-mmt` checkout.

## Decoding & Scoring

```
# Decode test2017 for monomodal en->de
$ nmt-translate -m models/monomodal-en-de/attention-e128-r256-...-s1234.1.BEST.npz \
                -S data.tok.bpe/bpe.en-de/test2017.norm.tok.lc.bpe10000.en \
                -o nmt.test2017.tok.de

# Decode test2017 for mnmt en->de
$ nmt-translate -m models/mnmt-en-de/mnmt_trgmul-e128-i2048-r256-...-s1234.1.BEST.npz \
                -S data.tok.bpe/bpe.en-de/test2017.bpe10000.pkl \
                   data/images/resnet50-imagenet-pool5/flickr30k_ResNet50_pool5_test2017.npy \
                -o mnmt.test2017.tok.de

# Score both systems (Output stripped to fit here)
$ nmt-coco-metrics -l de -r data.tok.bpe/test2017.norm.tok.lc.de -s *test2017.tok.de

|    Bleu_1     ||    Bleu_2     ||    Bleu_3     ||    Bleu_4     ||    METEOR   |
nmt.test2017.tok.de
|    63.321     ||    48.730     ||    38.804     ||    31.255     ||    51.274   |
mnmt.test2017.tok.de
|    64.342     ||    49.977     ||    39.879     ||    32.112     ||    51.529   |
```

## Results

(Note that the results below belong to single runs while the ones reported
in the paper are averages and ensembles of 5 runs.)

| System          | Val METEOR/BLEU | Test2016 METEOR/BLEU | Test2017 METEOR/BLEU |
|-----------------|-----------------|----------------------|----------------------|
| monomodal-en-de | 56.83/39.17     | 57.40/39.00          | 51.27/31.25          |
| mnmt-en-de      | 56.99/39.15     | 57.05/38.97          | 51.52/32.11          |
| fusion-en-de    |                 |                      |                      |
| monomodal-en-fr | 72.87/57.79     | 74.19/59.02          | 68.87/51.93          |
| mnmt-en-fr      | 73.88/58.93     | 74.75/59.82          | 69.48/52.61          |
| fusion-en-fr    |                 |                      |                      |
