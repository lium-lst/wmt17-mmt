#!/bin/bash

export LC_ALL=en_US.UTF_8

# Make sure that the following scripts are in your $PATH
#   lowercase.perl
#   tokenizer.perl
#   normalize-punctuation.perl

# Make sure that nmtpy is installed and/or the nmt-build-dict
# script is in your $PATH

# Raw files path
RAWDATA=data

RAW2PKL=scripts/raw2pkl

# Output files
OUT=data.tok.bpe

SUFFIX="norm.tok.lc"

# BPE related variables
BPE_APPLY=~/git/subword-nmt/apply_bpe.py
BPE_LEARN=~/git/subword-nmt/learn_bpe.py
BPE_MOPS=10000

mkdir -p $OUT &> /dev/null

##################
# Preprocess files
##################
for TYPE in "train" "val" "test2016" "test2017" "testcoco"; do
  for LLANG in en de fr; do
    INP="${RAWDATA}/${TYPE}.${LLANG}.gz"
    OUTP="${OUT}/${TYPE}.${SUFFIX}.${LLANG}"
    if [ -f $INP ]; then
      if [ ! -f $OUTP ]; then
        # Normalize, tokenize and lowercase and save under $OUT
        zcat $INP | normalize-punctuation.perl -l $LLANG | \
            tokenizer.perl -l $LLANG -threads 2 | \
            lowercase.perl > $OUTP &
      fi
    fi
  done
done
wait

################
# BPE processing
################
if [ ! -f "${OUT}/en-de.bpe${BPE_MOPS}" ]; then
  echo "Learning BPE with $BPE_MOPS ops on en->de"
  cat "${OUT}/train.${SUFFIX}".{en,de} | $BPE_LEARN -s $BPE_MOPS > "${OUT}/en-de.bpe${BPE_MOPS}"
fi

if [ ! -f "${OUT}/en-fr.bpe${BPE_MOPS}" ]; then
  echo "Learning BPE with $BPE_MOPS ops on en->fr"
  cat "${OUT}/train.${SUFFIX}".{en,fr} | $BPE_LEARN -s $BPE_MOPS > "${OUT}/en-fr.bpe${BPE_MOPS}"
fi

###########
# BPE apply
###########

# Apply for en->de and en->fr separately
for TLANG in "de" "fr"; do
  LPAIR="en-${TLANG}"
  OUTDIR="${OUT}/bpe.${LPAIR}"
  BPEFILE="${OUT}/${LPAIR}.bpe${BPE_MOPS}"

  for TYPE in "train" "val" "test2016" "test2017" "testcoco"; do
    # Source language for the current pair
    if [ ! -f "${OUTDIR}/${TYPE}.${SUFFIX}.bpe${BPE_MOPS}.en" ]; then
      if [ -f "${OUT}/${TYPE}.${SUFFIX}.en" ]; then
        echo "Applying BPE to ${TYPE}.${SUFFIX}.en"
        $BPE_APPLY -c $BPEFILE -i "${OUT}/${TYPE}.${SUFFIX}.en" \
          -o "${OUTDIR}/${TYPE}.${SUFFIX}.bpe${BPE_MOPS}.en"
      fi
    fi

    # Target language for the current pair
    if [ ! -f "${OUTDIR}/${TYPE}.${SUFFIX}.bpe${BPE_MOPS}.${TLANG}" ]; then
      if [ -f "${OUT}/${TYPE}.${SUFFIX}.${TLANG}" ]; then
        echo "Applying BPE to ${TYPE}.${SUFFIX}.${TLANG}"
        $BPE_APPLY -c $BPEFILE -i "${OUT}/${TYPE}.${SUFFIX}.${TLANG}" \
          -o "${OUTDIR}/${TYPE}.${SUFFIX}.bpe${BPE_MOPS}.${TLANG}"
      fi
    fi

    if [ ! -f "${OUTDIR}/${TYPE}.bpe${BPE_MOPS}.pkl" ]; then
      # Create PKL files for nmtpy iterator(s)
      $RAW2PKL -i "${RAWDATA}/${TYPE}_images.txt" \
               -s "${OUTDIR}/${TYPE}.${SUFFIX}.bpe${BPE_MOPS}.en" \
               -t "${OUTDIR}/${TYPE}.${SUFFIX}.bpe${BPE_MOPS}.${TLANG}" \
               -o "${OUTDIR}/${TYPE}.bpe${BPE_MOPS}.pkl"
    fi
  done
done

#####################
# Create vocabularies
#####################
if [ ! -f "${OUT}/bpe.en-de/train.${SUFFIX}.bpe${BPE_MOPS}.en.vocab.pkl" ]; then
  nmt-build-dict "${OUT}/bpe.en-de/train.${SUFFIX}.bpe${BPE_MOPS}".{en,de} -o "${OUT}/bpe.en-de"
fi
if [ ! -f "${OUT}/bpe.en-fr/train.${SUFFIX}.bpe${BPE_MOPS}.en.vocab.pkl" ]; then
  nmt-build-dict "${OUT}/bpe.en-fr/train.${SUFFIX}.bpe${BPE_MOPS}".{en,fr} -o "${OUT}/bpe.en-fr"
fi
