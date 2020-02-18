## check_register.R
require(yaml)
require(knitr)
a = read.csv("register.csv",as.is=TRUE)

## For each row of the CSV we can do some basic checks, e.g. like
## - checking the certificate numbers match
## - checking the yaml exists?
## - linting the yaml?

o = read_yaml("https://raw.githubusercontent.com/codecheckers/Piccolo-2020/master/codecheck.yml")
a$doi = o$codecheck$doi


capture.output(kable(a, format="markdown"), file="register.md")
