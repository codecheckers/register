## check_register.R
library("yaml")
library("knitr")

# put a token GITHUB_PAT in .Renviron to fix reate limits,
# see https://github.com/settings/tokens
library("gh")
# see https://github.com/r-lib/gh#readme for usage

## For each entry in the registry we can do some basic checks, e.g. like
## - checking the certificate numbers match
## - checking the yaml exists?
## - linting the yaml?
get_codecheck_yml_uncached <- function(repo) {
    repo_files <- gh::gh("GET /repos/codecheckers/:repo/contents/",
            repo = repo,
            .accept = "application/vnd.github.VERSION.raw")
        repo_file_names <- sapply(repo_files, "[[", "name")

    if ("codecheck.yml" %in% repo_file_names) {
        config_file_response <- gh::gh(
            "GET /repos/codecheckers/:repo/contents/:file",
            repo = repo,
            file = "codecheck.yml",
            .accept = "application/vnd.github.VERSION.raw")
        config_file <- yaml::read_yaml(text = config_file_response$message)
        return(config_file)
    } else {
        return(NULL)
    }
}

library("R.cache")
library("assertthat")
get_codecheck_yml <- addMemoization(get_codecheck_yml_uncached)

# MUST-contents only, see https://codecheck.org.uk/spec/config/latest/
validate_codecheck_yml <- function(configuration) {
    codecheck_yml <- NULL
    if (is.character(configuration) && file.exists(configuration)) {
        # TODO: validate that file encoding is UTF-8, if a file is given
        # TODO: check the 
        stop("File checking not yet implemented.")
        # read file to YAML, continue
    }

    codecheck_yml <- configuration

    # MUST have manifest
    assertthat::assert_that(assertthat::has_name(codecheck_yml, "manifest"))

    # manifest must not be named
    assertthat::assert_that(assertthat::has_name(codecheck_yml$manifest, NULL))

    # each element of the manifest MUST have a file
    sapply(X = hopfield$manifest, FUN = function(manifest_item) {
        assertthat::assert_that(assertthat::has_name(manifest_item, "file"))
        }
    )
}

check_register <- function(register) {
    for (i in seq_len(nrow(register))) {
        cat("Checking", toString(register[i, ]), "\n")
        entry <- register[i, ]

        # check certificate IDs if there is a codecheck.yml
        codecheck_yaml <- get_codecheck_yml(entry$Repo)
        if (!is.null(codecheck_yaml)) {
            if (entry$Certificate != codecheck_yaml$certificate) {
                stop("Certificate mismatch, register: ", entry$Certificate,
                     " vs. repo ", codecheck_yaml$certificate)
            }

            if (is.null(codecheck_yaml$report)) {
                warning("Report mis missing for ", entry$Certificate)
            }
        } else {
            warning(entry$Certificate, " does not have a codecheck.yml file")
        }

        # check issue status
        if (!is.na(entry$Issue)) {
            # get the status and labels from an issue
            issue <- gh::gh("GET /repos/codecheckers/:repo/issues/:issue",
                repo = "register",
                issue = entry$Issue)
            issue$state
            issue$labels
            if (issue$state != "closed") {
                warning(entry$Certificate, " issue is still open: ",
                    "<https://github.com/codecheckers/register/issues/",
                    entry$Issue, ">")
            }
        }
    }
}

the_register <- read.csv("register.csv", as.is = TRUE)

check_register(the_register)

# Futher test ideas:
# - Does the repo have a LICENSE?

register_table <- the_register

# add report links if available
reports <- c()
for (i in seq_len(nrow(the_register))) {
    config_yml <- get_codecheck_yml(the_register[i, ]$Repo)

    report <- NA
    if (!is.null(config_yml)) {
        report <- config_yml$report
    }

    reports <- c(reports, report)
}
register_table$Report <- reports

# turn IDs into links for table rendering
register_table$Issue <- sapply(X = register_table$Issue,
                               FUN = function(issue_id) {
    if (!is.na(issue_id)) {
        paste0("[",
               issue_id,
               "](https://github.com/codecheckers/register/issues/",
               issue_id, ")")
    } else {
        issue_id
    }
})

capture.output(
    cat("---\ntitle: CODECHECK Register\n---\n"),
    kable(register_table, format = "markdown"),
    file = "register.md"
)

# render register to HTML
library("rmarkdown")
rmarkdown::render("register.md",
                  output_yaml = "docs/html_document.yml",
                  output_file = "docs/index.html")
