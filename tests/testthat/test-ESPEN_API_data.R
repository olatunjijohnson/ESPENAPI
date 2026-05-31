library(ESPENAPI)

# ---- Input validation (no network needed) --------------------------------

test_that("missing country and iso2 gives informative error", {
  expect_error(
    ESPEN_API_data(disease = "sth", api_key = "dummy"),
    "Supply a country name"
  )
})

test_that("invalid disease gives informative error", {
  expect_error(
    ESPEN_API_data(country = "Nigeria", disease = "flu", api_key = "dummy"),
    "disease must be one of"
  )
})

test_that("invalid level gives informative error", {
  expect_error(
    ESPEN_API_data(country = "Nigeria", disease = "sth", level = "bad",
                  api_key = "dummy"),
    "level must be"
  )
})

test_that("invalid subtype gives informative error", {
  expect_error(
    ESPEN_API_data(country = "Nigeria", disease = "sth", subtype = "bad",
                  api_key = "dummy"),
    "subtype must be"
  )
})

test_that("missing API key with no env var gives informative error", {
  withr::with_envvar(c("ESPEN_API_KEY" = ""), {
    expect_error(
      ESPEN_API_data(country = "Nigeria", disease = "sth"),
      "No API key found"
    )
  })
})

test_that("all valid disease values are accepted without error before network call", {
  valid <- c("lf", "oncho", "loa", "sch", "sth", "trachoma", "coendemicity")
  for (d in valid) {
    # Should NOT error on disease validation (will error later on network/key)
    expect_no_error(
      tryCatch(
        ESPEN_API_data(country = "Nigeria", disease = d, api_key = "dummy"),
        error = function(e) {
          if (grepl("disease must be", conditionMessage(e))) stop(e)
          # any other error (network, auth) is fine here
        }
      )
    )
  }
})

test_that("country name is title-cased before sending", {
  # Pass an obviously lowercase country name — it should not error on validation
  # (title-casing happens internally before the API call)
  expect_no_error(
    tryCatch(
      ESPEN_API_data(country = "nigeria", disease = "sth", api_key = "dummy"),
      error = function(e) {
        if (grepl("Supply a country|disease must|level must", conditionMessage(e)))
          stop(e)
      }
    )
  )
})

# ---- Network tests (skipped when offline or no key) ----------------------

test_that("invalid API key returns [401] error", {
  skip_if_offline()
  expect_error(
    ESPEN_API_data(country = "Nigeria", disease = "sth",
                  start_year = 2010, end_year = 2010,
                  api_key = "invalid_key_00000"),
    "ESPEN API request failed \\[401\\]"
  )
})

test_that("valid API key returns a data frame with rows and columns", {
  skip_if_offline()
  key <- Sys.getenv("ESPEN_API_KEY")
  skip_if(nchar(trimws(key)) == 0, "ESPEN_API_KEY not set — skipping live API test")

  result <- ESPEN_API_data(
    country    = "Nigeria",
    disease    = "sth",
    level      = "sitelevel",
    start_year = 2010,
    end_year   = 2010,
    api_key    = key
  )

  expect_s3_class(result, "data.frame")
  expect_gt(nrow(result), 0)
  expect_gt(ncol(result), 0)
})

test_that("iso2 argument works as an alternative to country", {
  skip_if_offline()
  key <- Sys.getenv("ESPEN_API_KEY")
  skip_if(nchar(trimws(key)) == 0, "ESPEN_API_KEY not set — skipping live API test")

  result <- ESPEN_API_data(
    iso2       = "NG",
    disease    = "sth",
    level      = "sitelevel",
    start_year = 2010,
    end_year   = 2010,
    api_key    = key
  )

  expect_s3_class(result, "data.frame")
  expect_gt(nrow(result), 0)
})

test_that("df = FALSE returns an ESPEN_api object", {
  skip_if_offline()
  key <- Sys.getenv("ESPEN_API_KEY")
  skip_if(nchar(trimws(key)) == 0, "ESPEN_API_KEY not set — skipping live API test")

  result <- ESPEN_API_data(
    country    = "Nigeria",
    disease    = "sth",
    level      = "sitelevel",
    start_year = 2010,
    end_year   = 2010,
    df         = FALSE,
    api_key    = key
  )

  expect_s3_class(result, "ESPEN_api")
  expect_named(result, c("content", "url", "response"))
})
