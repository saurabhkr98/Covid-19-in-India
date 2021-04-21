#Preprocess
library(pracma)
library(ggplot2)

#File Location
file_name <- "./state_wise_daily.csv"


data <- read.csv(file_name)
delhi_data = data[, c("Status", "Date", "DL")]


for (i in 1:nrow(delhi_data)) {
  date <- delhi_data$Date[i]
  lst <- unlist(strsplit(date , '-'))
  if (lst[2] == "Sept")
    delhi_data[i, 2] <-
    strcat(strcat(lst[1], "Sep", '-'), lst[3], '-')
}

colnames(delhi_data) <- c("Status", "Date", "Count")



output <-
  sisd_cummulative(18710922, 1 / 14.0, 305, 30 , 30, 40, delhi_data, 0)


print(output[1]) #Graph
print(output[2]) #Predictions
