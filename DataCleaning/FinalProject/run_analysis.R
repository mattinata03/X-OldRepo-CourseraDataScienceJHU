####################################################################
# Creating a Tidy Data Set from Human Activity Recognition (HAR)
# Smartphone Data
# created: by Lisa Murray for Course course: Getting and Cleaning
# Data (JHU)
####################################################################

# Ensure libraries are installed

library(dplyr)
library(tidyr)
library(readr)
library(sqldf)
library(reshape2)

# Read the raw data files -- column names are created for all files
# except the xtest and xtrain files

print("Loading files into environment.")

# Read features.txt file and perform integrity check

headerFile <- as.tbl(read.table("./UCI HAR Dataset/features.txt",
                         col.names = c("key", "name")))
# parse column numbers for the std() and mean()

keepCols <- grep("mean|std", headerFile$name)

# check for duplicate data
dupeTest <- duplicated(headerFile$name)
dupes <- grep("TRUE", dupeTest)

numDupes <- intersect(keepCols, dupes)

if (length(numDupes) != 0){print("Warning: there are duplicate values in
                                 headerFile. Data needs to be scrubbed.") }

print("no duplicates found...files being processed")

# Read test and training files

xtrain <- as.tbl(read.table("./UCI HAR Dataset/train/X_train.txt"))
ytrain <- as.tbl(read.table("./UCI HAR Dataset/train/y_train.txt",
                     col.names = c("activityCode")))
subtrain <-as.tbl(read.table("./UCI HAR Dataset/train/subject_train.txt",
                      col.names = c("subjectID")))

xtest <- as.tbl(read.table("./UCI HAR Dataset/test/X_test.txt"))
ytest<- as.tbl(read.table("./UCI HAR Dataset/test/y_test.txt",
                     col.names = c("activityCode")))
subtest <- as.tbl(read.table("./UCI HAR Dataset/test/subject_test.txt",
                      col.names = c("subjectID")))

# Check for duplicate subject ids

checkUniqueSubjectID <- intersect(unique(subtest[,1]),
                                  unique(subtrain[,1]))
if(dim(checkUniqueSubjectID)[1] != 0) {
        message("Warning: One or more SubjectID is in both the training
                and test data: ", checkUniqueSubjectID, "\nSummary results
                will not be as expected")
}

# read activity_labels.txt fils
# change the activity names to lower case

activity <- as.tbl(read.table("./UCI HAR Dataset/activity_labels.txt",
                       col.names = c("activityCode", "activity")))
activity[[2]] <- tolower(activity[[2]])

print("Data is loaded. Cleaning up...")

rm("dupes", "dupeTest", "numDupes", "checkUniqueSubjectID")

# label and extract the std() and mean() data from the xtest and xtrain files

print("Labeling and extracting the std() and mean() raw data")

colnames(xtest) <- (headerFile$name)
colnames(xtrain) <- (headerFile$name)

xtestKeep <- xtest[, c(keepCols)]
xtrainKeep <- xtrain[, c(keepCols)]

# combine the test and training files

print("Combining test and training files and cleaning up")
testHAR <- as.tbl(bind_cols(subtest, ytest, xtestKeep))
trainHAR <- as.tbl(bind_cols(subtrain, ytrain, xtrainKeep))
dataHAR <- as.tbl(bind_rows(testHAR, trainHAR))

rm("subtest","subtrain", "xtest", "ytest", "xtrain", "ytrain", "xtestKeep", "xtrainKeep")

# melt the combined data on subjectID and activityCode
# and recast the data and calculate the mean

meltHAR<-melt(dataHAR, id=c("subjectID","activityCode"))

tidyHARprep<- dcast(meltHAR, subjectID+activityCode
                ~ variable,fun.aggregate=mean)

print("Data combined. Cleaning up files and creating
      user friedly column headings....")


# clean up data column names

headerName <- names(tidyHARprep)
headerName <- gsub("\\(\\)", "", headerName)
headerName <- gsub("BodyBody", "Body", headerName)
headerName <- gsub('^f', "Averagef", headerName)
headerName <- gsub('^t', "Averaget", headerName)
names(tidyHARprep) <- headerName

# sort the data to create the final tidy data file

tidyHARprep <- as.tbl(merge(tidyHARprep, activity, by = "activityCode"))
tidyHARprep <- select(tidyHARprep, subjectID, activityCode, activity,
                  everything())
tidyHAR <- tidyHARprep[order(tidyHARprep$subjectID,
                               tidyHARprep$activityCode),]
write.table(tidyHAR, file = "tidyHAR.txt",
            row.names = FALSE,  quote = FALSE)
#clean up remaining files

rm("testHAR", "trainHAR",
   "headerFile", "dataHAR",
   "tidyHARprep", "headerName", "keepCols",
   "meltHAR","activity")

print("Unneeded files deleted.")

# END
