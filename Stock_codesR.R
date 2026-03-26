# We import our data in R.
data= read.csv("C:/Users/mickey/Desktop/su work/1.2/timeseries/stock.csv")
# view our data.
head(data, 10)
# Check number of missing values per column
colSums(is.na(data))
#Select the columns that we need in our analysis
data1 <- data[, c("Date", "Adj..Close")]
head(data1,10)
colnames(data1)<- c("Date", "Price")
head(data1,10)
# 
str(data1)
# correct the Date to be a date time object
data1$Date <- as.Date(data1$Date, format = "%b %d, %Y")
# arrange the data in a chronological order
data2 <- data1[order(data1$Date), ]
head(data2, 10)
# Time plot of adjusted closing prices
plot(
  data2$Date, 
  data2$Price, 
  type = "l",
  col = "blue",
  lwd = 2,
  xlab = "Date",
  ylab = "Adjusted Closing Price",
  main = "Time Plot of Stock Prices (NSE)"
)

# Compute log returns and remove NA in one step
data2$log_return <- diff(log(data2$Price))

# Remove the first row to align prices and returns
data2 <- data2[-1, ]
head(data2,10)

# Plot log returns
#png("log_returns_plot.png", width = 800, height = 500)
#plot(
#  data2$Date,
#  data2$log_return,
 # type = "l",
  #col = "darkgreen",
#  lwd = 2,
 # xlab = "Date",
 # ylab = "Log Returns",
 # main = "Time Plot of Stock Log Returns"
#)
#dev.off()


#........................................................................

# STEP ONE: Import data into R

# Load necessary libraries
library(tidyverse)  # for data manipulation

# Import CSV
data <- read.csv("C:/Users/mickey/Desktop/su work/1.2/timeseries/stock.csv")

# View first few rows
head(data, 10)

# Check structure
str(data)

# Check for missing values
colSums(is.na(data))

# Convert Date column to Date class
data$Date <- mdy(trimws(data$Date))

# Check for missing values
colSums(is.na(data))




# STEP 2: Select only relevant columns

# Select only Date and Adjusted Close
data1 <- data[, c("Date", "Adj..Close")]

# Rename columns
colnames(data1) <- c("Date", "Price")

# Check the first rows
head(data1, 10)



head(data1, 10)


#STEP 3: Arrange data chronologically

# Order by Date
data2 <- data1[order(data1$Date), ]

# Verify order
head(data2, 10)
tail(data2, 10)
dim(data2)
colSums(is.na(data2))
str(data2)

#STEP 4: plot the data
plot(data2$Date, data2$Price, type = "l", col = "blue",
     main = "Stock Price Over Time",
     xlab = "Date", ylab = "Adjusted Close Price")
grid()


#STEP 5: Compute Log Returns

data2$log_return <- c(NA, diff(log(data2$Price)))
data2 <- data2[-1, ]  # remove first row, no need for na.omit
# Quick look
head(data2, 10)

# plot the log_returns
# Basic line plot
plot(data2$Date, data2$log_return, type = "l", 
     col = "green", lwd = 2,
     main = "Log Returns Over Time",
     xlab = "Date", ylab = "Log Return")
abline(h = 0, col = "red", lty = 2)  # adds a horizontal line at 0


#STEP 6: Compute Volatility
# check the assumptions.

#1). stationarity
library(tseries)
adf.test(data2$log_return)

#2). Autocorrelation.
acf(data2$log_return)
pacf(data2$log_return)

Box.test(data2$log_return, lag = 20, type = "Ljung-Box")

#3). Heteroscedasticity Check
install.packages("FinTS")

ArchTest(data2$log_return)

#STEP 6: Compute Volatility

# Overall volatility
volatility <- sd(data2$log_return)
volatility

# rolling 20-day volatility
library(zoo)
data2$vol_20 <- rollapply(data2$log_return, width = 20, FUN = sd, fill = NA, align = "right")

# Plot rolling volatility
plot(data2$Date, data2$vol_20, type = "l", col = "red",
     main = "20-Day Rolling Volatility",
     xlab = "Date", ylab = "Volatility")
grid()


tail(data2,10)

#STEP 7: Risk-Return Model Using OLS

data2$vol_5 <- rollapply(data2$log_return, width = 5, FUN = sd, fill = NA, align = "right")

# Plot rolling volatility
plot(data2$Date, data2$vol_5, type = "l", col = "red",
     main = "5-Day Rolling Volatility",
     xlab = "Date", ylab = "Volatility")
grid()


head(data2,10)

# Fit OLS: log_return ~ rolling volatility for the 5 days window
ols_model <- lm(log_return ~ vol_5, data = data2)

# Summary of OLS model
summary(ols_model)


# Fit OLS: log_return ~ rolling volatility for the 20 days window
ols_model2 <- lm(log_return ~ vol_20, data = data2)

# Summary of OLS model
summary(ols_model2)



# Step 8: Checking for the OLS assumptions (6) 
# 1. The mean of the ressiduals is zero
mean(residuals(ols_model))


#2. The ressiduals have a constant variance
plot(ols_model$fitted.values, residuals(ols_model))
abline(h = 0, col = "red")

# Breusch-Pagan test:
library(lmtest)
bptest(ols_model)


# 3. The ressiduals are normaly distributed
qqnorm(residuals(ols_model))
qqline(residuals(ols_model), col="red")

# Shapiro test
shapiro.test(residuals(ols_model))

# 4. No multicollinearity
library(lmtest)
dwtest(ols_model)


#5. No autocorrelation for the ressiduals 



# 6. No endogenity.


# step 9: THE MLE estimation method.

data_mle <- na.omit(data2[, c("log_return", "vol_5")])


library(stats4)   # For MLE estimation

#Define the log-likelihood function
loglik <- function(alpha, beta, sigma) {
  mu <- alpha + beta * data_mle$vol_5   # mean equation
  -sum(dnorm(data_mle$log_return, mean = mu, sd = sigma, log = TRUE))
}


#Fit the MLE model
mle_model <- mle(loglik,
                 start = list(alpha = 0, beta = 0.1, sigma = 0.02),
                 method = "BFGS")
summary(mle_model)


#
