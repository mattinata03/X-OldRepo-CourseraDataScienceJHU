---
title: "Creating a Tidy Data Set from Human Activity Recognition (HAR) Smartphone Data"
author: "Lisa Murray"
date: "7/4/2019"
output: html_document
---

This project is the final project for the Johns Hopkins University course "Getting and Cleaning Data", as part of its Specialization in Data Science.

The purpose of this project is to analyze data to produce a tidy dataset.

## Project background

The data used as part of this project was collected as part of a study done with 30 volunteers aged 19-48 who performed six activities while wearing a smartphone on their waists. [1]  The data was captured using the accelerometer and gyroscope in a Samsung Galaxy S II. Data that was collected included a
the accelerometer and gyroscope 3-axial raw time domain signals tAcc-XYZ and tGyro-XYZ (prefixed with a **t**). The acceleration signal was separated into body and gravity acceleration signals. Jerk signals were also derived and the magnitude of these signals were calculated. Applying a Fourier transformation, frequency domain signals were also produced (prefixed with an **f**).

The following types of data were collected:


| Data                     | Description                                     |
| ------------------------ | ------------------------------------------------|
| by time domain:          |                                                 |
| tBodyAcc-XYZ             | accelerometer body measurement 3 axial data     |
| tGravityAcc-XYZ          | accelerometer gravity measurement 3 axial data  |
| tBodyAccJerk-XYZ         | accelerometer body jerk measurement 3 axial data|
| tBodyGyro-XYZ            | gyroscope body measurement 3 axial data         |
| tBodyGyroJerk-XYZ        | gyroscope body jerk measurement 3 axial data    |
| tBodyAccMag              | accelerometer body magnitude measurement        |
| tGravityAccMag           | accelerometer body magnitude measurement        |
| tBodyAccJerkMag          | accelerometer body jerk magnitude measurement   |
| tBodyGyroMag             | gyroscope body magnitude measurement            |
| tBodyGyroJerkMag         | gyroscope body jerk magnitude measurement       |
| by frequency domain:     |                                                 |
| fBodyAcc-XYZ             | accelerometer body measurement 3 axial data     |
| fBodyAccJerk-XYZ         | accelerometer body jerk measurement 3 axial data|
| fBodyGyro-XYZ            | gyroscope body measurement 3 axial data         |
| fBodyAccMag              | accelerometer body magnitude measurement        |
| fBodyAccJerkMag          | accelerometer body jerk magnitude measurement   |
| fBodyGyroMag             | gyroscope body magnitude measurement            |
| fBodyGyroJerkMag         | gyroscope body jerk magnitude measurement       |


Several statistical calculations were done on the data and each data element has a suffix to indicate what calculation was made.

For the purpose of this project only data with the suffixes of **-mean()** and **-std()** were analyzed.

## Project goals

This purpose of this final project is to demonstrate the ability to convert raw data into a clean data set. The requirements of the assignment are:

1. Merge the training and the test sets to create one data set.
2. Extract only the measurements on the mean and standard deviation for each measurement.
3. Use descriptive activity names to name the activities in the data set
4. Appropriately label the data set with descriptive variable names.
5. From the data set in step 4, create a second, independent tidy data set with the average of each variable for each activity and each subject.

## Data Source, CodeBook, and Analysis script

The data analysis script **run_analysis.R** can be found in the **mattinata03/CourseraDataScienceJHU/DataCleaning/FinalProject** github repository, along with the codebook **CodeBook.md**. The raw data files can be downloaded from:

https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip

The **run_analysis.R** script runs with the following assumptions:
* the data has been downloaded
* the data has been unzipped and resides in the working directory

### Data Analysis / Outline of run_analysis.R

To ensure all needed R packages are installed in the system library, the following packages are loaded at the beginning of the R script:

* dplyr
* tidyr
* readr
* sqldf
* reshape2

The raw data is read into the following data frames:

* ytrain: the activity monitored for each test/observation  (data source: y_train.txt)
* ytrain: the measurements/features collected and calculated for each observation (data source: X_train.txt)
* subtrain: the subject id for each test/observation (data source: subject_train.txt)
* ytest: the activity monitored for each test/observation  (data source: y_test.txt)
* xtest: the measurements/features collected and calculated for each observation (data source: X_test.txt)
* subtest: the subject id for each test/observation (data source: subject_test.txt)
* headerFile: a description of each measurement(i.e. column) in the X_train.txt and X_test.txt files (data soure: features.txt)
* activity: a description of each of the six (6) activities monitored in the study (data source: activity_labels.txt)

Column names are assigned when reading in all data files except for xtest and xtrain.

### Pre Processing Data

#### Checking for errors in data

While the data appeared to be complete based on the provided documentation and initial browsing of the data, some automated checks are executed at the beginning of the scrip to confirm that this is the case. The following data checks are done:

##### Completeness of Test and Training Data
The complete raw test and training data are in three separate files each. None of the files have header rows. Thus the only way to check that the data is complete is to compare the number of rows of each input file (xtest, ytest, subtest and xtrain, ytrain, subtrain). A simple check was done using the nrow() command and a warning message is displayed if there is an error.

```
if(nrow(xtrain) != nrow(ytrain) |
   nrow(xtrain)!= nrow(subtrain){
        message("Warning: A training file is missing one or more rows
                   of data. \nSummary results will not be as expected")
}

if(nrow(xtest) != nrow(ytest) |
   nrow(xtest) != nrow(subtest)){
        message("Warning: A test file is missing one or more rows of data.
                   \nSummary results will not be as expected")
}
```

##### Check that the headerFile has no duplicates
**headerFile** contains the column header names xtext and xtrain files. Due to some issues earlier in how I was processing the data, I kept getting duplicate column headers when I was trying to concatenate files, so I wrote some code for error handling for duplicates.

Since the data required for the output is only mean() or std() data, unnecessary column headings are filtered out prior to checking for duplicates.

```
headerFile <- as.tbl(read.table("./UCI HAR Dataset/features.txt",
                         col.names = c("key", "name")))

keepCols <- grep("mean|std", headerFile$name)
dupeTest <- duplicated(headerFile$name)
dupes <- grep("TRUE", dupeTest)

numDupes <- intersect(keepCols, dupes)

if (length(numDupes) != 0){print("Warning: there are duplicate values in
                                 headerFile. Data needs to be scrubbed.") }
```

##### Error in subject data
The 30 subjects which participated in the study were assigned to either the  testing or the training groups (30%/70%). Thus should not be a subject id that resides in both the subtest and subtrain data sets. Although visual analysis ensured that the data was accurate, the script also contains a quick check to make sure that no subjectID is duplicated across both the test and training files.

```
checkUniqueSubjectID <- intersect(unique(subtest[,1]),
                                  unique(subtrain[,1]))
if(dim(checkUniqueSubjectID)[1] != 0) {
        message("Warning: One or more SubjectID is in both the training
                and test data: ", checkUniqueSubjectID, "\nSummary results
                will not be as expected")
}
```

##### Other miscellaneous pre processing cleanup, etc
Because all of the other data is mostly lower case, I changed the activity codes, which are stored as all caps, to  lower case so the output data looked as uniform as possible.

```
activity <- as.tbl(read.table("./UCI HAR Dataset/activity_labels.txt",
                       col.names = c("activityCode", "activity")))
activity[[2]] <- tolower(activity[[2]])
```

Using the **headerFile** and **keepCols** files the column names are added to the xtest and xtrain files and a subset data set (xtestKeep and xtrainKeep) is created for each which contain only the mean() and std() data.

```
colnames(xtest) <- (headerFile$name)
colnames(xtrain) <- (headerFile$name)

xtestKeep <- xtest[, c(keepCols)]
xtrainKeep <- xtrain[, c(keepCols)]
```

Additionally, while the script runs, status messages are printed to the console.

### Processing the data

#### Combine the test and training data

After reading in the raw data and doing initial error processing, the test data and the training data are combined into one file for each. Because the data isn't keyed, the three test and the three training files are concatenated together using the bind_cols() command. The two resulting files are then joined together using the bind_rows() command. NOTE The naming convention HAR is used for the complete "Human Activity Recognition" data.
```
testHAR <- as.tbl(bind_cols(subtest, ytest, xtestKeep))
trainHAR <- as.tbl(bind_cols(subtrain, ytrain, xtrainKeep))
dataHAR <- as.tbl(bind_rows(testHAR, trainHAR))
```
Once the raw data is combined, I use the melt() function to combine the data as such:

```
meltHAR<-melt(dataHAR, id=c("subjectID","activityCode"))
```

Then the data is casted in a wide form and the **mean** of each data value is calculated. An interim tidy file data file, **tidyHARprep** which will be cleaned up in the final steps.

```tidyHARprep<- dcast(meltHAR, subjectID+activityCode
                ~ variable,fun.aggregate=mean)
```

### Final file processing

While browsing through the data, I noticed that one set of the variables had "BodyBody" as part of the column name. I run a quick clean up at the end of the script to correct that as well as to add the verbiage *Average* in the column headings for the data.


```
headerName <- names(tidyHARprep)
headerName <- gsub("\\(\\)", "", headerName)
headerName <- gsub("BodyBody", "Body", headerName)
headerName <- gsub('^f', "Averagef", headerName)
headerName <- gsub('^t', "Averaget", headerName)
names(tidyHARprep) <- headerName
```

The last file manipulation is done by merging the activity file (from the rawdata activity_labels.txt) with the tidy data set using the activityCode as the index to relate the files.

```
tidyHARprep <- as.tbl(merge(tidyHARprep, activity, by = "activityCode"))
```

The last step is to order/sort the final data and write it to disk. Any remaining interim files are deleted. *(Files are deleted throughout the process once they are no longer needed.)*


```
tidyHARprep <- as.tbl(merge(tidyHARprep, activity, by = "activityCode"))
tidyHARprep <- select(tidyHARprep, subjectID, activityCode, activity,
                  everything())
tidyHAR <- tidyHARprep[order(tidyHARprep$subjectID,
                               tidyHARprep$activityCode),]
write.table(tidyHAR, file = "tidyHAR.txt",
            row.names = FALSE,  quote = FALSE)
```
## Project Summary and Comments

Having a background in SQL and data processing, most of the upfront data design was pretty straight forward. The relationships between the different data were easily mapped out. The challenging part was to (1) determine the most efficient way to slice the data to create the most user friendly layout, and (2) figure out how to code the script in R (a new language for me). I *tried* to code similar processes with the same function to be consitent.  

## Acknowledgments

* Coursera forum -- especially thoughtfulbloke AKA David Hood
* User PurpleBooth on github -- for a having a good README markdown template on her repository -- this is new for me.
* Those that conducted the initial study from which we obtained the data (see acknowledgement above)
* [1] Davide Anguita, Alessandro Ghio, Luca Oneto, Xavier Parra and Jorge L. Reyes-Ortiz. Human Activity Recognition on Smartphones using a Multiclass Hardware-Friendly Support Vector Machine. International Workshop of Ambient Assisted Living (IWAAL 2012). Vitoria-Gasteiz, Spain. Dec 2012
