---
title: "CodeBook"
author: "David Nadler"
date: "January 29, 2016"
output: html_document
---

## The UCI HAR Dataset

Some wearable devices contain digital gyroscopes and accelerometers and so are able to record measurements of the motion of their wearers. It seems reasonable to believe that applications written for such devices should be able to deduce what the user is doing physically (e.g. walking, running, sitting). Such recognition will be achieved by analyzing gyroscope and accelerometer readings in the wearers device. Datasets of such readings with different wearers performing different activities will be useful to those designing activity recognition algorithms.

Authors Reyes-Ortiz, Anguita, Ghio, Oneto, and Parra provide such a [Human Activity Recognition (HAR) database](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones). They observed thirty human subjects performing six everyday physical activities. The subjects were wearing waist-mounted Samsung Galaxy S cell phones. Each raw observation in the database is a 2.56 second window of device readings from a given subject performing a given activity. The sampling frequency was 50Hz, and so each raw observation consists of 128 accelerometer readings and 128 gyroscope readings. 

These findings were published in the Machine Learning Repository managed by the Center for Machine Learning and Intellgent Systems at the Universtity of California at Irvine (UCI). That completes our acronym demystification.

The data set may be obtained by unzipping [this zip file](https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip). This unzipping will create a top-level directory called `UCI HAR Dataset`. In the discussion following, all file names are relative to this top-level directory.

### Processing of the raw data
The raw data are presumably difficult to use directly in activity recongition algorithms, and so from each raw observation, the authors calculate a corresponding *feature vector* as described in the file `features_info.txt`. To summarize, they calculate various acceleration vectors and angular velocities from the raw accerlerometer and gyroscope readings. They calculate the X,Y, and Z coordinates of these vectors (where the axes are presumably those of some moving frame determined by the orientation of the cellphone). For some types of vectors, the magnitude (Euclidean) length of the vector is also provided.  The angular veocities are with respect to these axes. The units of measurement of the acceleration is the standard g-force (9.8 meters per second squared), and the unit of measurement of angular velocity is radians per second. But the authors state that features are normalized and bounded to have values in [-1,1]: this effectively means that different observations have different units.

Each of these quantities is calculated from one of the 128 samples in the 2.56 second observation window -- such a quantity is said to be in the time domain. The authors also provide Fast Fourier transforms for some of the 128-element time-domain vectors: such a Fast Fourier transform is also a 128-element vector of pure-frequency components. The Fast Fourier transforms are said to be in the frequency domain.

We now have several vectors of length 128: each is a time-domain or frequency-domain series of a coordinate or magnitude of some force vector. Most of the elementd if the *feature vector* are formed by calcuating functions of these 128-entry vectors: among these functions are mean, standard deviation, entropy, and energy. The complete list of them is provide in `features_info.txt`. We are interested only in those features where the vector function applied is mean or standard deviation.

Some other features are provided that are not relevant to our task, but for completeness we mention them. The features that we have described so far are functions of one coordintate or magnitude of a time- or frequency-domain force vector. For ccertain time-domain vectors, the correlation of the X- and Y-coordinate time series is provided, as well as those for the X- and Z- coordinates, and Y- and Z-coordinates. For a certain set of important time-domain vector types, angles between the vector means of pairs of those types are provided as part of the feature vector. Finally, for certain types of frequency-domain vectors, something called a `mean frequency` is provided. This is the mean of each each frequency in the Fourier transform weighted by its Fourier coefficient.

#### Form of the data set

The dataset contains several observations for each subject performing each activity. The thirty human subjects (and so the observations) are arbitrarily divided into what the authors call a training set (70% of the subjects) and a test set (30% of the subjects).  For this reason, there are two subdirectories containing called `test` and `train` containing the observations for the test and training subjects. More on that in a moment. There are a couple of top-level files that have information common to the test and training datasets. One of these is `features.txt`, which lists the names of the 561 features provided for each observation. Another top-level file called `activitiy_labels.txt` provides an activity index between 1 and 6 for each of the physical activities studied here.

The `test` directory contains data for 2947 observations. Each of the 561 columns of the file `test/X_test.txt` contains the observation data for a feature named in the corresponding line  in `features.txt`. Each line in `test/X_test.txt` is the feature vector for some observation. Each line of the file `test/y_test.txt` contains an index identifying the activity being performed: the name of that activity is contained in the line in `activity_labels.txt` with that activity index. Finnaly, the identifier of the human subject is contained in `test/subject_test.txt`.

The hidden primary key for these observations is "line number in the data files". For example, let's pick line number 100. The 100th line of subject_test.txt contains the number 2, so what we might call "test observation 100" is an observation about human subject number 2. Line 100 in y_test.txt contains the activity index 1: from the file activity_labels.txt in the top-level directory, we see that this corresponds to the activity "WALKING". The first three columns of line 100 in the file X_test.txt are the numbers 2.6663115e-001, -4.3309471e-002, and -1.4096216e-001. We see from the top-level file features_info.txt that the first three columns are the time-domain means of the X-, Y-, and Z-coordinates BodyAcc force vector. So for "test observation 100", Human subject number 2 was walking and had an averge body acceleration of 2.66e-1 in the X-direction. Similarly, the inertial signals for test observation 100 are found in line 100 in each of the data files in the Inertial Signals subdirectory these lines has 128 columns, one value for each sample take over the 2.56 second sampling window.

The `train`  directory works in the same way, except the data file names there are `train/subject\train.txt`, `train/y_train.txt`, and `train/X_train.txt`. It contains data for 7352 oservations.

The `test` and `train` subdirectories also each contain a subdirectory called `Inertial Signals`. These data are not of interest in our task. They are the result of the first stage of processing of the accelerometer and gyroscope readings. They contain the gravitational acceleration, body acceleration, and angular veocity time series for each observation. As mentioned before, the observation window is 2.56 seconds long and the sampling frequency is 50Hz, and so each line in these files has 128 columns.

## Our Summary of the Dataset

Our task is to provide a tidy data set containing the average of all mean and standard deviation features for each subject and each activity in the merged test and training datasets.  That means we are not interested in the inertial force data and we are not interested in the angles between vector means, nor are we interested in those features which are statistics other than mean or standard deviation. Finally, we are not interested in the `mean frequency` features mentioned above.

Our script [run_analysis.R](run_analysis.R) will create such a summary dataset. Instructions on how to run this script and how it works are contained in [README.md](README.md).

#### Selection of the data of interest

For convnience, we discuss below the processing done on the training set. The identical processing is done on the test set -- only the directory and file names are different.

For the training data set, we make an R data frame by selecting the following columns from files:
1. subject id column from the file train/subject_train.txt
2. activity id column from train/y_train.txt and using it as the index into our modified list of activity names, which we describe below
3. the 66 columns from train/X_train.txt with column names that contain either the pattern `mean()` or the pattern `std()`. Recall that the 561 columns of train/X_train.txt are named by the 561 lines in the file features.txt. 

#### Activity mapping

We provide the following references as authority for our modifications to the authors' activity names:

[https://www.englishforums.com/English/UpTheStairsUpstairs/zmgdq/post.htm](https://www.englishforums.com/English/UpTheStairsUpstairs/zmgdq/post.htm)
[http://public.wsu.edu/~brians/errors/lay.html](http://public.wsu.edu/~brians/errors/lay.html)

|Activity Index | Authors' Activity Name | Our Activity Name   |
| ------------- | ---------------------- | ------------------- |
| 1             | WALKING                | Walking             |
| 2             | WALKING_UPSTAIRS       | Walking up stairs   |
| 3             | WALKING_DOWNSTAIRS     | Walking down stairs |
| 4             | SITTING                | Sitting             |
| 5             | STANDING               | Standing            |
| 6             | LAYING                 | Lying down          |

#### Column naming

It seems as though there is a typogprahical error in the authors' file `features.txt` which holds the authors' feature names. For some feature names, the word `Body` is repeated, e.g. `fBodyBodyGyroJerkMag-std()`. We assume that all occurences of `BodyBody` are typos and substitute `Body` for them in our processing.

We name the first of our selected columns `Subject.ID` and the second `Activity`.
The rules of tidy datasets say that we must have one row for each observation and one column for each variable. The authors' organization of the data actualy obeys this. The only objections to their feature names are that they contain punctuation that the R language doesn't like and that they contain abbreviations.

We will make variable names that don't have abbreviations and that have the period as their only punctuation character, which is legal in R.

We decompose the feature name given by the authors into functional pieces using R regular expressions with capturing groups, and we map the abbreviations to full words. It's perhaps best to illustrate this with an example. We'll use the feature called tBodyAccJerk-std()-X in the nomenclature of the authors. 

| Functional piece of authors' name | Functional piece of our name |
|  -------------------------------- | ---------------------------- |
| t                                 | TimeDomain                   |
| BodyAccJerk                       | BodyAccelerationJerk         |
| std()                             | StandardDeviation            |
| X                                 | X.Direction                   |

We assemble the pieces of our column names differently from the authors: after assembly, our variable name for this feature is StandardDeviation.TimeDomain.BodyAccelerationJerk.X.Direction.

#### Merging and summarizing
We perform the above processing to create R data frames for both the training and test sets of observations. The set of human subjects in the test set is disjoint from that in the training set and so it makes perfect sense to combine our training and test data frames with a simple call to rbind. We finally group observations by subject id and activity name and take the group averages of all those features we selected. The result is one feature vector for each of the 30 human subjects performing each of the 6 activities, thus 180 rows in all. Our `run_analysis.R` script produces a space-delimted file called `averages_all_vars_by_subject_actvity.txt`.
