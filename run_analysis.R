library(stringr)
library(plyr)

#
# Lists and a vector to help map original feature names to
# more readable versions.
#
feature_base_to_var_base <- list(
  BodyAcc="BodyAcceleration",          GravityAcc="GravityAcceleration",
  BodyAccJerk="BodyAccelerationJerk",  BodyGyro="GyroscopicBody",
  BodyGyroJerk="GyroscopicBodyJerk",   BodyAccMag="BodyAcceleration",
  GravityAccMag="GravityAcceleration", BodyAccJerkMag="BodyAccelerationJerk",
  BodyGyroMag="BodyGyroscope",         BodyGyroJerkMag="BodyGyroscopeJerk")


freq_or_time <- list(f="FrequencyDomain", t="TimeDomain")

mean_or_std <- list(mean="Mean", std="StandardDeviation")

cleaned_activities <-c(
  "Walking",
  "Walking up stairs",
  "Walking down stairs",
  "Sitting", "Standing",
  "Lying down")

# decompose_feature_name 
# This function will select only those features (columns) which
# measure a mean or standard deviation. It will match the raw feature
# name against a regex and extract the pieces from that name bearing
# the following information:
#   (1) frequency domain or time domain?
#   (2) name of the force vector being measured
#   (3) statistic being measured (mean or standard deviation)
#   (4) geometric attribute of the force vector being measured 
#       (X-direction, Y-direction, Z-direction, or vector magnitude)
# For example, the raw column name "tBodyGyro-std()-X" decomposes into the
# pieces "t", "BodyGyro, "std", and "X".
decompose_feature_name <- function(feature_name) {
  pattern <- "([ft])(.*?)-(mean|std)\\(\\)-?(.*)?"
  #corrected_feature_name <- gsub("BodyBody", "Body", feature_name)
  matches <- str_match(feature_name, pattern)
  return(matches)
}

# get_feature_matches takes the raw feature names and performs a 
# vectorized call to decompose_feature_names. But the raw data "features.txt"
# contains a slight disconnect from its description in the original README.txt.
# Some of the feature names have an unintentional double occurence of the word
# "Body", e.g."fBodyBodyAccJerkMag-mean()". We therefore make a corrected version
# of "features.txt" called "features.txt.corrected" which finds all occurrences
# of "BodyBody" and replaces them with "Body". We use this corrected file as the
# list of feature names to decompose.
get_feature_matches <- function() {
  features_m <- read.delim("features.txt", header=FALSE, sep=" ")
  features <- features_m[,2]
  features_corrected <- gsub("BodyBody", "Body", features)
  matches <- decompose_feature_name(features_corrected)
  return(matches)
}
#
# make_clean_var_name(match_row)
# match_row: a match vector produced by decompose_feature_name
# for one of the feature names we are interested in (one with
# mean() or (std() in its name).
#
# This function maps the pieces of its match vector parameter to
# full-word strings and reassembles these strings to form the
# corresponding column name of our tidy data set.
# For example, the raw column name "tBodyGyro-std()-X" yieds a match
# vector containing the pieces "t", "BodyGyro, "std", and "X". These
# are mapped respectively to "TimeDomain", "GyroscopicBody",
# "StandardDeviation", and "X". Finally, the mapped pieces are
# reassembled to form the very long but human-readable variable name
# "StandardDeviation.TimeDomain.GyroscopicBody.X.Direction".
# 
make_clean_var_name <- function(match_row) {
  base_end_match_with_mag <- str_match(match_row[3], ".*Mag$")
  ends_with_mag <- !is.na(base_end_match_with_mag)
  direction <- ifelse(ends_with_mag, "", match_row[5])
  varname_end <- ifelse(ends_with_mag, "VectorMagnitude",
                       sprintf("%s.Direction", direction))
  varname <- sprintf("%s.%s.%s.%s", mean_or_std[match_row[4]],
    freq_or_time[match_row[2]], feature_base_to_var_base[match_row[3]],
    varname_end)
  return(varname)
}

# make_colnos_and_varnames
# This function extracts only those features we're interested in from the raw data
# set and produces a data frame with the following two columns:
#   (1) column index in raw "X" data set
#   (2) correpsonding variable name in tidy data set 
make_colnos_and_varnames <- function() {
  matches <- get_feature_matches()
  desired_l <- !is.na(matches[,1])
  desired <- which(desired_l,arr.ind=TRUE,useNames=FALSE)
  desired_matches <- matches[desired_l,]
  varnames = apply(desired_matches, 1, make_clean_var_name)
  df <- cbind.data.frame(desired, varnames)
  return(df)
}


# make_half_data_fame(test_or_train)
#
#   test_or_train: string with value "test" or "train", indicating 
#                  the subdirectory of the raw data set from which
#                  we will build a tidy data frame
# We read the X data set of measurements, the subject id file, and
# the activity codes. We extract the columns of interest from the
# X data set and give them human-read-able names to form the data frame
# "new_ds". We then cbind the subject ids and mapped activity codes
# 
make_half_data_frame <- function(test_or_train) {
    x_data_filename <- sprintf("%s/X_%s.txt", test_or_train, test_or_train)
    ds <- read.csv(x_data_filename, header=FALSE, sep="",
                     strip.white=TRUE, stringsAsFactors=FALSE)
    subject_id_filename <- sprintf("%s/subject_%s.txt",
                              test_or_train, test_or_train)
    subject_ids <- read.delim(subject_id_filename, header=FALSE,
         stringsAsFactors=FALSE, sep=" ", col.names=c("Subject ID"))
   
    activity_code_filename <- sprintf("%s/y_%s.txt",
                                test_or_train, test_or_train)
    raw_activities <- read.delim(activity_code_filename, header=FALSE,
                                sep=" ")
    Activity <- cleaned_activities[raw_activities[,1]]
    activities_dt <- as.data.frame(Activity, stringsAsFactors=FALSE)
    df <- data.frame(subject_ids,activities_dt)
    colnos_and_varnames <- make_colnos_and_varnames()
    colnos <- colnos_and_varnames[,1]
    varnames <- as.character(colnos_and_varnames[,2])
    colnames(ds)[colnos] <- varnames
    new_ds <- ds[, colnos]
    new_df <- cbind(subject_ids, Activity, new_ds)
    colnames(new_df)[2] <- "Activity"
#     print(sprintf("ncols of %s half df = %d\n", test_or_train, ncol(new_df)))
    return(new_df)
}

# create_dataset
# Creates data frames from the training and test data set
# and merges them row-wise.
create_merged_dataset <- function() {
    test_df <- make_half_data_frame("test")
    train_df <- make_half_data_frame("train")
    tidy_df <- rbind(test_df, train_df)
    return(tidy_df)
}

averages_for_all_vars_by_subject_activity <- function() {
    merged_df <- create_merged_dataset()
    subject_activity_df <- unique(merged_df[c("Subject.ID", "Activity")])
    row.names(subject_activity_df) <- NULL
    nc <- ncol(merged_df)
    observations <- merged_df[, 3:nc]

    averages_for_vars_given_subject_and_activity <- function(subject_id, activity) {
    relevant <- merged_df$Subject.ID == subject_id & merged_df$Activity == activity
    means <- lapply(observations[relevant,], mean)
    row.names(means) <- NULL
    return(means)
  }
  
  obs_colnames <- as.array(colnames(observations))
  means_df <- data.frame(
    matrix(vector(), 0, nc, dimnames=list(c(), colnames(merged_df)) ),
    stringsAsFactors=FALSE)
  nr <- nrow(subject_activity_df)
  for (i in 1:nr) {
    subject_id <- subject_activity_df[i, "Subject.ID"]
    activity <- subject_activity_df[1, "Activity"]
    means_df[i,] <- averages_for_vars_given_subject_and_activity(
                       subject_id, activity)
  }
  full_df <- cbind(subject_activity_df, means_df[,3:nc])
  return(full_df)
}

#MAINLINE
main <- function() {
  averages_all_vars_by_subject_activity_df <-
   averages_for_all_vars_by_subject_activity()
  
  write.table(averages_all_vars_by_subject_activity_df, sep=" ",
    file="averages_all_vars_by_subject_actvity.txt", row.names=FALSE)
}
#test_df <- make_half_data_frame("test")
main()
