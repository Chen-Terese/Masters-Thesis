#!/bin/bash
# preprocess_adni.sh
RAW_DIR=/mnt/f/User/Downloads/ADNI1_Split
PROCESSED_DIR=/mnt/f/User/Downloads/ADNI_processed

# Ensure FSL is sourced
source ~/fsl/etc/fslconf/fsl.sh

# Track progress
TOTAL=$(find $RAW_DIR -type f \( -name "*.nii" -o -name "*.nii.gz" \) | wc -l)
COUNT=0
mkdir -p "$PROCESSED_DIR"
> "$PROCESSED_DIR/failed.txt"

for SPLIT in train val test; do
    for LABEL in CN MCI AD; do
        INPUT_DIR="$RAW_DIR/$SPLIT/$LABEL"
        OUTPUT_DIR="$PROCESSED_DIR/$SPLIT/$LABEL"
        mkdir -p "$OUTPUT_DIR"

        for FILE in "$INPUT_DIR"/*; do

            # Skip non-NIfTI files
            if [[ "$FILE" != *.nii && "$FILE" != *.nii.gz ]]; then
                continue
            fi

            COUNT=$((COUNT + 1))
            BASENAME=$(basename "$FILE")
            BASENAME_NOEXT="${BASENAME%%.*}"

            echo "[$COUNT/$TOTAL] Processing: $BASENAME ..."

            # Skip if already done
            if [ -f "$OUTPUT_DIR/${BASENAME_NOEXT}_brain_norm.nii.gz" ]; then
                echo "  -> Already processed, skipping"
                continue
            fi

            # Step 1: Skull stripping
            bet "$FILE" "$OUTPUT_DIR/${BASENAME_NOEXT}_brain.nii.gz" -B -f 0.4

            if [ ! -f "$OUTPUT_DIR/${BASENAME_NOEXT}_brain.nii.gz" ]; then
                echo "  FAILED at BET: $FILE" >> "$PROCESSED_DIR/failed.txt"
                continue
            fi

            # Step 2: Registration to MNI template
            flirt -in "$OUTPUT_DIR/${BASENAME_NOEXT}_brain.nii.gz" \
                  -ref $FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz \
                  -out "$OUTPUT_DIR/${BASENAME_NOEXT}_brain_reg.nii.gz"

            if [ ! -f "$OUTPUT_DIR/${BASENAME_NOEXT}_brain_reg.nii.gz" ]; then
                echo "  FAILED at FLIRT: $FILE" >> "$PROCESSED_DIR/failed.txt"
                rm -f "$OUTPUT_DIR/${BASENAME_NOEXT}_brain.nii.gz"
                continue
            fi

            # Step 3: Intensity normalization (z-score)
            mean=$(fslstats "$OUTPUT_DIR/${BASENAME_NOEXT}_brain_reg.nii.gz" -M)
            std=$(fslstats "$OUTPUT_DIR/${BASENAME_NOEXT}_brain_reg.nii.gz" -S)

            fslmaths "$OUTPUT_DIR/${BASENAME_NOEXT}_brain_reg.nii.gz" \
                     -sub $mean -div $std \
                     "$OUTPUT_DIR/${BASENAME_NOEXT}_brain_norm.nii.gz"

            # Delete intermediate files — keep only final _brain_norm.nii.gz
            rm -f "$OUTPUT_DIR/${BASENAME_NOEXT}_brain.nii.gz"
            rm -f "$OUTPUT_DIR/${BASENAME_NOEXT}_brain_reg.nii.gz"

            echo " Done: ${BASENAME_NOEXT}_brain_norm.nii.gz"
        done
    done
done

echo ""
echo "All done! $COUNT images processed."
echo "Check failed cases: $PROCESSED_DIR/failed.txt"
