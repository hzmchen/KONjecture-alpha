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

test_that("manifest_entry records url, sha256 and size of the file on disk", {
  f <- tempfile()
  writeLines("hello", f)
  e <- manifest_entry("x", list(url = "https://example.org/x", notes = "n"), f)
  expect_identical(e$url, "https://example.org/x")
  expect_identical(e$sha256, digest::digest(file = f, algo = "sha256"))
  expect_identical(as.integer(e$bytes), 6L)
  expect_match(e$retrieved_at, "^\\d{4}-\\d{2}-\\d{2}T")
})
