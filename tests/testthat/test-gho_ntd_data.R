library(ESPENAPI)

# ---- gho_ntd_indicators() ------------------------------------------------

test_that("gho_ntd_indicators returns correct structure", {
  ind <- gho_ntd_indicators()
  expect_s3_class(ind, "data.frame")
  expect_named(ind, c("espen_code", "disease_name", "gho_code",
                       "gho_name", "gho_available"))
  expect_true(all(c("oncho", "trachoma") %in%
                    ind$espen_code[ind$gho_available]))
  expect_true(all(c("lf", "sth", "sch", "loa") %in%
                    ind$espen_code[!ind$gho_available]))
})

test_that("gho_ntd_indicators GHO codes are non-NA for available diseases", {
  ind <- gho_ntd_indicators()
  avail <- ind[ind$gho_available, ]
  expect_true(all(!is.na(avail$gho_code)))
  expect_true(all(!is.na(avail$gho_name)))
})

# ---- gho_ntd_data() — input validation -----------------------------------

test_that("missing indicator argument errors clearly", {
  expect_error(gho_ntd_data(), "Provide at least one indicator")
})

# ---- gho_ntd_data() — live tests (no auth needed) ------------------------

test_that("GHO returns a data frame for onchocerciasis treatment", {
  skip_if_offline()
  result <- gho_ntd_data(
    indicator  = "NTD_ONCTREAT",
    start_year = 2018,
    end_year   = 2022
  )
  expect_s3_class(result, "data.frame")
  expect_named(result, c("indicator_code", "indicator_name", "country_iso3",
                          "who_region", "year", "value", "value_text",
                          "low", "high", "comments"))
  expect_gt(nrow(result), 0)
  expect_true(all(result$year >= 2018))
  expect_true(all(result$year <= 2022))
  expect_equal(unique(result$indicator_code), "NTD_ONCTREAT")
})

test_that("GHO country filter works", {
  skip_if_offline()
  result <- gho_ntd_data(
    indicator = "NTD_ONCTREAT",
    country   = c("NGA", "GHA"),
    start_year = 2015,
    end_year   = 2022
  )
  expect_s3_class(result, "data.frame")
  expect_true(all(result$country_iso3 %in% c("NGA", "GHA")))
})

test_that("GHO multiple indicators returns combined data frame", {
  skip_if_offline()
  result <- gho_ntd_data(
    indicator  = c("NTD_ONCTREAT", "NTD_8"),
    start_year = 2018,
    end_year   = 2020
  )
  expect_s3_class(result, "data.frame")
  expect_true(all(c("NTD_ONCTREAT", "NTD_8") %in%
                    unique(result$indicator_code)))
})

test_that("GHO invalid indicator returns an error", {
  skip_if_offline()
  # GHO returns 404 with no content-type for unknown indicators
  expect_error(gho_ntd_data("NOT_A_REAL_INDICATOR"))
})
