library(ESPENAPI)

# ---- resolve_api_key() ---------------------------------------------------

test_that("NULL api_key with no env var gives actionable error", {
  withr::with_envvar(c("ESPEN_API_KEY" = ""), {
    expect_error(
      ESPEN_API_data(country = "Nigeria", disease = "sth"),
      "No API key found"
    )
  })
})

test_that("NULL api_key reads from environment variable", {
  withr::with_envvar(c("ESPEN_API_KEY" = "testkey123"), {
    # Should not error on key resolution (will fail later on network/auth)
    err <- tryCatch(
      ESPEN_API_data(country = "Nigeria", disease = "sth"),
      error = function(e) conditionMessage(e)
    )
    expect_false(grepl("No API key found", err))
  })
})

# ---- validate_inputs() ---------------------------------------------------

test_that("invalid disease gives informative error", {
  expect_error(
    ESPEN_API_data(country = "Nigeria", disease = "flu", api_key = "dummy"),
    "disease must be one of"
  )
})

test_that("all valid disease codes pass validation", {
  valid <- c("lf", "oncho", "loa", "sch", "sth", "trachoma", "coendemicity")
  for (d in valid) {
    expect_no_error(
      tryCatch(
        ESPEN_API_data(country = "Nigeria", disease = d, api_key = "dummy"),
        error = function(e) {
          if (grepl("disease must be", conditionMessage(e))) stop(e)
        }
      )
    )
  }
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

test_that("start_year > end_year gives informative error", {
  expect_error(
    ESPEN_API_data(country = "Nigeria", disease = "sth",
                   start_year = 2020, end_year = 2010, api_key = "dummy"),
    "start_year.*<= end_year"
  )
})

test_that("missing country and iso2 gives informative error", {
  expect_error(
    ESPEN_API_data(disease = "sth", api_key = "dummy"),
    "Supply country"
  )
})

# ---- build_url() ---------------------------------------------------------

test_that("build_url produces a well-formed URL with country", {
  url <- ESPENAPI:::build_url(
    country = "Nigeria", iso2 = NULL,
    disease = "sth", level = "sitelevel",
    type = FALSE, subtype = "mda",
    start_year = 2010, end_year = 2015,
    limit = NULL, offset = NULL, attributes = NULL,
    api_key = "testkey"
  )
  expect_match(url, "^https://espenjapapi\\.afro\\.who\\.int/api/data\\?")
  expect_match(url, "country=Nigeria")
  expect_match(url, "disease=sth")
  expect_match(url, "level=sitelevel")
  expect_match(url, "start_year=2010")
  expect_match(url, "end_year=2015")
  expect_match(url, "api_key=testkey")
})

test_that("build_url uses iso2 when country is NULL", {
  url <- ESPENAPI:::build_url(
    country = NULL, iso2 = "NG",
    disease = "lf", level = "iu",
    type = FALSE, subtype = "mda",
    start_year = NULL, end_year = NULL,
    limit = NULL, offset = NULL, attributes = NULL,
    api_key = "k"
  )
  expect_match(url, "iso2=NG")
  expect_no_match(url, "country=")
})

test_that("build_url title-cases country names", {
  url <- ESPENAPI:::build_url(
    country = "nigeria", iso2 = NULL,
    disease = "sth", level = "sitelevel",
    type = FALSE, subtype = "mda",
    start_year = NULL, end_year = NULL,
    limit = NULL, offset = NULL, attributes = NULL,
    api_key = "k"
  )
  expect_match(url, "country=Nigeria")
})

test_that("build_url includes forecast params when type = TRUE", {
  url <- ESPENAPI:::build_url(
    country = "Nigeria", iso2 = NULL,
    disease = "sth", level = "sitelevel",
    type = TRUE, subtype = "mda",
    start_year = NULL, end_year = NULL,
    limit = NULL, offset = NULL, attributes = NULL,
    api_key = "k"
  )
  expect_match(url, "type=forecast")
  expect_match(url, "subtype=mda")
})

test_that("build_url omits optional params when NULL", {
  url <- ESPENAPI:::build_url(
    country = "Nigeria", iso2 = NULL,
    disease = "sth", level = "sitelevel",
    type = FALSE, subtype = "mda",
    start_year = NULL, end_year = NULL,
    limit = NULL, offset = NULL, attributes = NULL,
    api_key = "k"
  )
  expect_no_match(url, "start_year")
  expect_no_match(url, "end_year")
  expect_no_match(url, "limit")
})

# ---- espen_diseases() and espen_levels() ---------------------------------

test_that("espen_diseases returns a data frame with correct columns", {
  d <- espen_diseases()
  expect_s3_class(d, "data.frame")
  expect_named(d, c("code", "name", "description"))
  expect_equal(nrow(d), 7L)
  expect_true(all(c("sth", "lf", "oncho") %in% d$code))
})

test_that("espen_levels returns a data frame with correct columns", {
  l <- espen_levels()
  expect_s3_class(l, "data.frame")
  expect_named(l, c("code", "name", "description"))
  expect_equal(nrow(l), 2L)
  expect_true(all(c("iu", "sitelevel") %in% l$code))
})

# ---- espen_key_setup() ---------------------------------------------------

test_that("espen_key_setup prints a message and returns NULL invisibly", {
  expect_message(espen_key_setup(), "ESPEN API key setup")
  expect_null(espen_key_setup())
})

# ---- print.ESPEN_api() ---------------------------------------------------

test_that("print.ESPEN_api works without error", {
  obj <- structure(
    list(
      content  = '{"test": 1}',
      url      = "https://example.com/api",
      response = list(status_code = 200)
    ),
    class = "ESPEN_api"
  )
  expect_output(print(obj), "<ESPEN API response>")
  expect_output(print(obj), "Status")
})

# ---- Network tests (skipped when offline or key not set) -----------------

test_that("invalid API key returns [401] with useful error", {
  skip_if_offline()
  expect_error(
    ESPEN_API_data(
      country = "Nigeria", disease = "sth",
      start_year = 2010, end_year = 2010,
      api_key = "invalid_key_00000"
    ),
    "ESPEN API request failed \\[401\\]"
  )
})

test_that("valid key returns a data frame", {
  skip_if_offline()
  key <- Sys.getenv("ESPEN_API_KEY")
  skip_if(nchar(trimws(key)) == 0, "ESPEN_API_KEY not set")

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
})

test_that("iso2 argument returns same data as country name", {
  skip_if_offline()
  key <- Sys.getenv("ESPEN_API_KEY")
  skip_if(nchar(trimws(key)) == 0, "ESPEN_API_KEY not set")

  by_name <- ESPEN_API_data(
    country = "Nigeria", disease = "sth", level = "iu",
    start_year = 2010, end_year = 2010, api_key = key
  )
  by_iso2 <- ESPEN_API_data(
    iso2 = "NG", disease = "sth", level = "iu",
    start_year = 2010, end_year = 2010, api_key = key
  )
  expect_equal(nrow(by_name), nrow(by_iso2))
})

test_that("multi-country download returns combined data frame", {
  skip_if_offline()
  key <- Sys.getenv("ESPEN_API_KEY")
  skip_if(nchar(trimws(key)) == 0, "ESPEN_API_KEY not set")

  result <- ESPEN_API_data(
    country    = c("Nigeria", "Ghana"),
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
  skip_if(nchar(trimws(key)) == 0, "ESPEN_API_KEY not set")

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
