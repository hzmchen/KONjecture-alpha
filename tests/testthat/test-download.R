# download_raw.R — offline tests only: the skip path, manifest round-trip,
# and registry sanity. Actual downloads are deliberate manual acts (no network
# in tests, per the dependency-register discipline).

root <- Sys.getenv("KONJ_ROOT")

test_that("source registry is sane", {
  files <- vapply(DL_SOURCES, `[[`, "", "file")
  urls <- vapply(DL_SOURCES, `[[`, "", "url")
  expect_false(any(duplicated(files)))
  expect_true(all(startsWith(urls, "https://")))
  expect_true(all(nzchar(vapply(DL_SOURCES, `[[`, "", "notes"))))
})

test_that("cached files are skipped and the manifest round-trips unchanged", {
  tmp <- file.path(tempfile("dlroot"), "")
  raw <- file.path(tmp, "data", "raw")
  dir.create(raw, recursive = TRUE)
  # presence is all the skip path checks: placeholder files + the real manifest
  for (s in DL_SOURCES) file.create(file.path(raw, s$file))
  file.copy(file.path(root, "data", "raw", "manifest.json"), file.path(raw, "manifest.json"))

  status <- download_main(character(), root = tmp)
  expect_identical(status, 0L)
  before <- jsonlite::read_json(file.path(root, "data", "raw", "manifest.json"))
  after <- jsonlite::read_json(file.path(raw, "manifest.json"))
  expect_identical(after, before)
})

test_that("--only with an unknown id is a no-op that still writes a valid manifest", {
  tmp <- tempfile("dlroot2")
  status <- download_main(c("--only", "does_not_exist"), root = tmp)
  expect_identical(status, 0L)
  m <- jsonlite::read_json(file.path(tmp, "data", "raw", "manifest.json"))
  expect_length(m, 0)
})

test_that("root resolution honors KONJ_ROOT", {
  expect_identical(dl_get_root(), normalizePath(root))
  expect_identical(archive_get_root(), normalizePath(root))
})

test_that("download failure is reported per source and sets exit status 1", {
  old_sources <- DL_SOURCES
  on.exit(DL_SOURCES <<- old_sources)
  DL_SOURCES <<- list(broken = list(url = "https://127.0.0.1:1/nope",
                                    file = "nope.bin", notes = "unreachable, offline test"))
  tmp <- tempfile("dlfail")
  expect_message(status <- download_main(character(), root = tmp), "\\[FAIL\\] broken")
  expect_identical(status, 1L)
  expect_false(file.exists(file.path(tmp, "data", "raw", "nope.bin")))
})

test_that("a successful download writes the file and a full manifest entry", {
  payload <- tempfile(fileext = ".bin")
  writeLines("payload", payload)
  old_sources <- DL_SOURCES
  on.exit(DL_SOURCES <<- old_sources)
  DL_SOURCES <<- list(local = list(url = paste0("file://", payload),
                                   file = "local.bin", notes = "file:// url, offline test"))
  tmp <- tempfile("dlok")
  status <- download_main(character(), root = tmp)
  expect_identical(status, 0L)
  dest <- file.path(tmp, "data", "raw", "local.bin")
  expect_true(file.exists(dest))
  m <- jsonlite::read_json(file.path(tmp, "data", "raw", "manifest.json"))
  expect_identical(m$local.bin$sha256, digest::digest(file = dest, algo = "sha256"))
  expect_identical(m$local.bin$source_id, "local")
})

test_that("alt_urls are tried in order after the primary url fails", {
  payload <- tempfile(fileext = ".bin")
  writeLines("fallback payload", payload)
  old_sources <- DL_SOURCES
  on.exit(DL_SOURCES <<- old_sources)
  DL_SOURCES <<- list(moved = list(
    url = "file:///nonexistent/primary.bin",
    alt_urls = c("file:///nonexistent/second.bin", paste0("file://", payload)),
    file = "moved.bin", notes = "url fallback, offline test"))
  tmp <- tempfile("dlalt")
  status <- download_main(character(), root = tmp)
  expect_identical(status, 0L)
  dest <- file.path(tmp, "data", "raw", "moved.bin")
  expect_identical(readLines(dest), "fallback payload")
  # the manifest records the url that actually served the file
  m <- jsonlite::read_json(file.path(tmp, "data", "raw", "manifest.json"))
  expect_identical(m$moved.bin$url, paste0("file://", payload))
})

test_that("a source's trim hook rewrites the file before the manifest entry", {
  payload <- tempfile(fileext = ".tsv")
  writeLines(c("keep\t1", "drop\t2", "keep\t3"), payload)
  old_sources <- DL_SOURCES
  on.exit(DL_SOURCES <<- old_sources)
  DL_SOURCES <<- list(trimmed = list(
    url = paste0("file://", payload), file = "trimmed.tsv",
    trim = function(dest) writeLines(grep("^keep", readLines(dest), value = TRUE), dest),
    notes = "trim hook, offline test"))
  tmp <- tempfile("dltrim")
  status <- download_main(character(), root = tmp)
  expect_identical(status, 0L)
  dest <- file.path(tmp, "data", "raw", "trimmed.tsv")
  expect_identical(readLines(dest), c("keep\t1", "keep\t3"))
  m <- jsonlite::read_json(file.path(tmp, "data", "raw", "manifest.json"))
  expect_identical(m$trimmed.tsv$sha256, digest::digest(file = dest, algo = "sha256"))
})

test_that("a trim hook rejecting the payload advances to the next url", {
  # CDNs can answer HTTP 200 with an error page; the trim hook is the validator
  bad <- tempfile(fileext = ".tsv"); writeLines("<Error>BlobNotFound</Error>", bad)
  good <- tempfile(fileext = ".tsv"); writeLines(c("keep\t1", "drop\t2"), good)
  old_sources <- DL_SOURCES
  on.exit(DL_SOURCES <<- old_sources)
  strict_trim <- function(dest) {
    lines <- readLines(dest)
    if (!any(grepl("^keep", lines))) stop("not the expected payload")
    writeLines(grep("^keep", lines, value = TRUE), dest)
  }
  DL_SOURCES <<- list(
    guarded = list(url = paste0("file://", bad), alt_urls = paste0("file://", good),
                   file = "guarded.tsv", trim = strict_trim,
                   notes = "200-with-error-body fallback, offline test"),
    hopeless = list(url = paste0("file://", bad),
                    file = "hopeless.tsv", trim = strict_trim,
                    notes = "all urls rejected, offline test"))
  tmp <- tempfile("dlguard")
  expect_message(status <- download_main(character(), root = tmp), "\\[FAIL\\] hopeless")
  expect_identical(status, 1L)
  expect_identical(readLines(file.path(tmp, "data", "raw", "guarded.tsv")), "keep\t1")
  # a rejected-everywhere source leaves no stub behind to shadow future runs
  expect_false(file.exists(file.path(tmp, "data", "raw", "hopeless.tsv")))
  m <- jsonlite::read_json(file.path(tmp, "data", "raw", "manifest.json"))
  expect_identical(m$guarded.tsv$url, paste0("file://", good))
  expect_null(m$hopeless.tsv)
})

test_that("the WEO registry entries are well-formed and the trim hook validates", {
  weo_ids <- grep("^weo_", names(DL_SOURCES), value = TRUE)
  expect_length(weo_ids, 17L)  # Apr+Oct 2018..2025 + Apr 2026
  for (sid in weo_ids) {
    src <- DL_SOURCES[[sid]]
    expect_true(all(startsWith(c(src$url, src$alt_urls), "https://www.imf.org/")))
    expect_match(src$file, "^weo_\\d{4}_(04|10)[.]tsv$")
    expect_identical(src$trim, weo_trim_ngdp_rpch)
  }
  # trim keeps header + NGDP_RPCH rows only
  f <- tempfile(fileext = ".tsv")
  writeLines(c("WEO Country Code\tISO\tWEO Subject Code\t2025",
               "111\tUSA\tNGDP_RPCH\t1.8",
               "111\tUSA\tNGDP_R\t23724.5"), f)
  weo_trim_ngdp_rpch(f)
  expect_identical(length(readLines(f)), 2L)
  # and rejects payloads that are not a WEO bulk table (e.g. CDN error pages)
  writeLines("<Error>BlobNotFound</Error>", f)
  expect_error(weo_trim_ngdp_rpch(f), "not a WEO bulk table")
  writeLines(c("WEO Country Code\tISO\tWEO Subject Code\t2025",
               "111\tUSA\tNGDP_R\t23724.5"), f)
  expect_error(weo_trim_ngdp_rpch(f), "no NGDP_RPCH rows")
})

test_that("manifest_entry records url, sha256 and size of the file on disk", {
  f <- tempfile()
  writeLines("hello", f)
  e <- manifest_entry("x", list(url = "https://example.org/x", notes = "n"), f)
  expect_identical(e$url, "https://example.org/x")
  expect_identical(e$sha256, digest::digest(file = f, algo = "sha256"))
  expect_identical(as.integer(e$bytes), 6L)
  expect_match(e$retrieved_at, "^\\d{4}-\\d{2}-\\d{2}T")
})
