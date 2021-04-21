#' Prediction of Cumulative number of cases using data driven modified SIS model
#' @return graph showing the training phase and prediction of cumulative number of cases
#' @export

sisd_cummulative <-
  function(population,
           gamma,
           cur_day,
           last_n_day,
           last_limit,
           next_n_days,
           data,
           mu) {
    library(pracma)
    library(ggplot2)


    min_mu = 0.001
    max_mu = 0.1
    mu_step = 0.001


    if (!missing(mu)) {
      min_mu = mu
      max_mu = mu
    }


    dt <- vector()
    c <- vector()
    r <- vector()
    d <- vector()

    for (i in 1:nrow(data)) {
      row <- data[i,]
      status <- row$Status
      date <- row$Date
      num <- row$Count
      if (date %in% dt == FALSE)
        dt <- append(dt, date)
      if (strcmp(status, "Confirmed"))
        c <- append(c, num)
      else if (strcmp(status, "Recovered"))
        r <- append(r, num)
      else if (strcmp(status, "Deceased"))
        d <- append(d, num)
    }

    #Calculating the Cumulative cases using the data
    get_data <- function(dt, c, r, d, N) {
      sus <- vector()
      cum_inf <- vector()
      inf_active <- vector()
      deceased <- vector()
      date <- vector()
      day <- vector()
      sus <- append(sus, N - c[1])
      cum_inf <- append(cum_inf, c[1])
      inf_active <- append(inf_active, c[1] - r[1])
      deceased <- append(deceased, d[1])
      day <- append(day, 0)
      date <- append(date, dt[1])
      for (i in 2:length(c)) {
        cum_inf <- append(cum_inf, c[i] + tail(cum_inf, n = 1))
        inf_active <-
          append(inf_active, c[i] - r[i] - d[i] + tail(inf_active, n = 1))
        sus <- append(sus, N - tail(inf_active, n = 1))
        date <- append(date, dt[i])
        day <- append(day, i)
        deceased <- append(deceased, d[i] + tail(deceased, n = 1))
      }
      ret <-
        list(
          "S" = sus,
          "I" = inf_active,
          "C" = cum_inf,
          "D" = deceased,
          "date" = date,
          "day" = day
        )
      return(ret)
    }


    odata <- get_data(dt, c, r, d, population)

    #Used for estimating beta and mu
    sisd <-
      function(N,
               beta,
               gamma,
               mu,
               cur_day,
               last_n,
               So,
               Io,
               Co,
               Do) {
        start <- cur_day - last_n + 1
        S_P <- So[start]
        I_P <- Io[start]
        C_P <- Co[start]
        D_P <- Do[start]
        S <- vector()
        I <- vector()
        C <- vector()
        D <- vector()
        S <- append(S, S_P)
        I <- append(I, I_P)
        C <- append(C, C_P)
        D <- append(D, D_P)
        while (start <= cur_day) {
          start <- start + 1
          S_N <- S_P - S_P * I_P * beta / N + gamma * I_P
          I_N <- I_P + S_P * I_P * beta / N - gamma * I_P - mu * I_P
          C_N <- C_P + S_P * I_P * beta / N
          D_N <- D_P + mu * I_P
          S_P <- S_N
          I_P <- I_N
          C_P <- C_N
          D_P <- D_N
          S <- append(S, S_N)
          I <- append(I, I_N)
          C <- append(C, C_N)
          D <- append(D, D_N)
        }
        ret <- list(
          "S" = S,
          "I" = I,
          "C" = C,
          "D" = D
        )
        return(ret)
      }

    #Used for prediction
    sisd_pred <-
      function(N,
               beta,
               gamma,
               mu,
               cur_day,
               next_n,
               So,
               Io,
               Co,
               Do) {
        start <- cur_day
        S_P <- So[start]
        I_P <- Io[start]
        C_P <- Co[start]
        D_P <- Do[start]
        S <- vector()
        I <- vector()
        C <- vector()
        D <- vector()
        start <- start + 1
        while (start <= cur_day + next_n) {
          S_N <- S_P - S_P * I_P * beta / N + gamma * I_P
          I_N <- I_P + S_P * I_P * beta / N - gamma * I_P - mu * I_P
          C_N <- C_P + S_P * I_P * beta / N
          D_N <- D_P + mu * I_P
          S_P <- S_N
          I_P <- I_N
          C_P <- C_N
          D_P <- D_N
          S <- append(S, S_N)
          I <- append(I, I_N)
          C <- append(C, C_N)
          D <- append(D, D_N)
          start <- start + 1
        }
        ret <- list(
          "S" = S,
          "I" = I,
          "C" = C,
          "D" = D
        )
        return(ret)
      }


    best_last_n_days <- last_n_day
    best_beta <- -1
    best_mu <- -1
    avg_error <- Inf
    loss_limit <- last_n_day

    train_days <- vector()
    loss_train <- vector()
    itr <- 1
    while (itr <= last_limit) {
      itr <- itr+ 1
      #print(itr, last_limit)
      mu1 = min_mu
      while (mu1 <= max_mu) {
        beta1 = 0.01
        
        while (beta1 < 0.3) {
          ret <-
            sisd(
              population,
              beta1,
              gamma,
              mu1,
              cur_day,
              last_n_day,
              odata$S,
              odata$I,
              odata$C,
              odata$D
            )
          nerr <- 0
          start <- cur_day - last_n_day + 1
          idx <- 1
          while (idx <= length(ret$I)) {
            if (idx >= (length(ret$I) - loss_limit)) {
              nerr <- nerr + abs(ret$C[idx] - odata$C[start]) ** 2
            }
            idx <- idx + 1
            start <- start + 1
          }
          nerr <- nerr / idx
          nerr <- sqrt(nerr)
          if (avg_error > nerr) {
            avg_error <- nerr
            best_beta <- beta1
            best_mu <- mu1
            best_last_n_days <- last_n_day
          }
          beta1 <- beta1 + 0.01
        }
	mu1 <- mu1 + mu_step
      }
      #train_days <- append(train_days, last_n_day)
      #loss_train <- append(loss_train, err)
      last_n_day <- last_n_day + 1
    }

    print(paste("Optimal mu = ", best_mu))
    print(paste("Optimal beta = ", best_beta))
    print(paste("Optimal training period = ", best_last_n_days))

    train <-
      sisd(
        population,
        best_beta,
        gamma,
        best_mu,
        cur_day,
        best_last_n_days,
        odata$S,
        odata$I,
        odata$C,
        odata$D
      )
    kk <-
      sisd_pred(
        population,
        best_beta,
        gamma,
        best_mu,
        cur_day,
        next_n_days + 1,
        odata$S,
        odata$I,
        odata$C,
        odata$D
      )


    df = data.frame(
      Day = integer(),
      Count = double(),
      Type = character(),
      Date = as.Date(character()),
      stringsAsFactors = FALSE
    )

    idx <- cur_day - best_last_n_days + 1
    while (idx <= cur_day) {
      df[nrow(df) + 1, ] = list(odata$day[idx],
                                odata$C[idx],
                                "Observed",
                                as.Date(odata$date[idx], "%d-%b-%y"))
      idx <- idx + 1
    }

    idx <- cur_day + 1
    idx1 <- 1
    nerr <- 0
    while (idx <= cur_day + next_n_days) {
      df[nrow(df) + 1,] = list(odata$day[idx],
                               formatC(kk$C[idx1], digits = 2, format = "f"),
                               "Predicted",
                               as.Date(odata$date[idx], "%d-%b-%y"))
      idx <- idx + 1
      idx1 <- idx1 + 1
    }

    idx <- cur_day - best_last_n_days + 1
    idx1 <- 1


    while (idx <= cur_day) {
      df[nrow(df) + 1,] = list(odata$day[idx],
                               formatC( train$C[idx1] , digits = 2, format = "f"),
                               "Optimaly Trained",
                               as.Date(odata$date[idx], "%d-%b-%y"))
      idx <- idx + 1
      idx1 <- idx1 + 1
    }

    p <-
      ggplot(df, aes(
        x = Date,
        y = Count,
        shape = Type,
        color = Type
      )) + geom_point(size = 3) + scale_shape_manual(values = c(3, 16, 17)) +
      geom_smooth(size = 1) + scale_color_manual(values = c('#000000', '#008f00', '#ff0000'))
    p <-
      p + scale_x_date(date_breaks = "10 day") + labs(y = "Cumulative Number of Cases", x = "Date") +
      theme(axis.text.x = element_text(angle = 35, hjust = 1))
    return(list(p, df))
  }
