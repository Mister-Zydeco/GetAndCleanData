---
title: "README"
author: "David Nadler"
date: "January 31, 2016"
output: html_document
---

Our R script [run_aanalysis.R](run_analysis.R) is desgined to be run in conjunction with the [UCI HAR Dataset](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones). 

To run it, first obtain the [zip file for this dataset](https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip) and unzip it. This will create a top-level directory called `UCI HAR Dataset`. Move a copy `run_analysis.R` into this top-level directory. With `UCI HAR Dataset` as your working directory, run the script with no arguments. This will produce an space-delimited output file called `averages_all_vars_by_subject_actvity.txt`.

This script was run with R version 3.2.2 ("Fire Safety"). Any version of R later than that should also work.

## Processing
All filen and directory ames below are paths relative to the top-level directory `UCI HAR Dataset`.

We make a data frame from the files in the `test` subdirectory by cbinding the  human subject ids from `test/subject_test.txt`, the activity names obtained from using the activity ids in `test/y_test.txt` as indices into an array containing our activity names, and a third set of columns.

This third set of 66 columns contains the data for features of interest from `test/X_test.txt`. Those are the columns corresponding to feature names in `features.txt` that match our regular expression `([ft])(.*?)-(mean|std)\\(\\)-?(.*)?"`. One  detail is that a few of the functions in `functions.txt` have the word `Body` repeated in their names. We view this as a typo and substitute a single occurence of `Body` whenver we see `BodyBody`; this happens before matching.

From the vectorized application of str_match to the function names in `functions.txt` with this pattern, we obtain NA for those functions do not match. for those functions which match, we obtain a row of strings with the full match along with 3 or 4 captured groups.

We call R's `which` function with the appropriate flags on the match array to get the indices where we have matches and then call our function `make\_clean\_var\_name` on the matching function names. This approach allows us to link our column names to the appopriate columns in `test\X_test.txt`.

We now describe in excruciating detail our function `make\_clean\_var\_name`. It transforms the authors' feature names into our feature names. It operates on the data returned by the rows of strings returned by the above call to str_match.  The first group is either an f or t, which we map to `TimeDomain` or `Frequency Domain`; the second group might be called the "vector force name with abbreviations": we map this to a name without abbreviations. The third group is either `mean` or `std`, which we map to `Mean` or `StandardDeviation`. The fourth group will be present only if  function is the X, Y, or Z coordinate of some force vector: these are mapped to `X.Direction`, `Y.Direction`, or `Z.Direction` as the case may be. When our function is not a vector coordinate but rather a vector magnitude, there will be no fourth captured group, and in this case the unmapped vector force name will end with `Mag`. We map `Mag` to `VectorMagnitude`. Finally, our assembly order is different from that of the authors of the dataset: thus, their `tBodyAccJerk-std()-X` becomes our `StandardDeviation.TimeDomain.BodyAccelerationJerk.X.Direction` and their `tBodyAccJerkMag-std()` becomes our `StandardDeviation.TimeDomain.BodyAccelerationJerk.VectorMagnitude`. 

We now have our column names for the feature data and we can extract the feature data itself because we know the corresponding column indices in `test/X_test.X`.

We perform the same processing on the data in the `train` subdirectory (where the filenames have `train` instead of `test`). We thus have data frames for two dijoint sets of observations which we may rbind into a merged data set.

We form our data set by finding the unique pairs of subject ids and activity names in our merged data set. For each unique pair, we use R's boolean row selector device to find the indices of matching rows and perform an lapply of the `mean` function for all data columns (index 3 and greater) in our merged data set. This is the desired data frame, which we write out as a space-delimited file called `averages_all_vars_by_subject_actvity.txt`.

