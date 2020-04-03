## check_register.R
library("yaml")
library("knitr")

# put a token GITHUB_PAT in .Renviron to fix reate limits,
# see https://github.com/settings/tokens
library("gh")
# see https://github.com/r-lib/gh#readme for usage

the_register <- read.csv("register.csv", as.is = TRUE)

## For each row of the CSV we can do some basic checks, e.g. like
## - checking the certificate numbers match
## - checking the yaml exists?
## - linting the yaml?

get_codecheck_yml <- function(repo) {
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

check_register <- function(register) {
    for (i in seq_len(nrow(register))) {
        cat("Checking", toString(register[i, ]), "\n")
        entry <- register[i, ]

        # check certificate IDs if there is a codecheck.yml
        codecheck_yaml <- get_codecheck_yml(entry$Repo)
        if (!is.null(codecheck_yaml)) {
            if (entry$Certificate != codecheck_yaml$codecheck$certificate) {
                stop("Certificate mismatch, register: ", entry$Certificate,
                     " vs. repo ", configFile$codecheck$certificate)
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
                    "<https://github.com/codecheckers/register/issue/",
                    entry$Issue, ">")
            }
        }
    }
}

check_register(the_register)

# Futher test ideas:
# - Does the repo have a LICENSE?

# add DOIs if available
dois <- c()
for (i in seq_len(nrow(the_register))) {
    config_yml <- get_codecheck_yml(the_register[i, ]$Repo)

    the_doi <- NA
    if (is.null(config_yml)) {
    } else {
        if (is.character(config_yml$codecheck$doi))
            the_doi <- config_yml$codecheck$doi
    }

    dois <- c(dois, the_doi)
}

the_register$DOI <- dois

capture.output(kable(the_register, format = "markdown"), file = "register.md")
