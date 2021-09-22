[![Build Status](https://travis-ci.org/voteview/articles.svg?branch=master)](https://travis-ci.org/voteview/articles)

# voteview.com article repository

This repository contains the source documents for the articles, help messages, and blog posts used on voteview.com. We welcome user contributions!

## How to contribute

To contribute, follow these simple steps:

1. Fork our repository or clone the "example" branch.
2. Rename the `docs/blank` folder to a short stub name suitable for your contribution.
3. Inside, rename `blank.Rmd` to match the folder name, and use it as a template for your article.
4. Open `article.Rproj` and run `compiler.R` to verify your article compiles correctly.
5. Open a pull request merging your local branch into `voteview/articles/master`
6. Wait for automatic integration testing to verify your pull request, and for us to approve it. 

## Compiler flags

When running `compiler.R` from the command line, there are certain flags that can be used to induce specified behaviour:

- `-d`, `--dryrun`: When run with this flag, the compiler will not update any articles, it will simply notify you which articles would be updated.
- `-f filename`, `--force filename`: When run with this flag, the compiler will update the article whose Rmd is located at `filename`. This will ignore the default update/cache settings.

## Article Frontmatter

Each article supports a variety of front matter to customize the display of the article and the operation of the compiler.

- `tag: blog, help, data`. Tags determine which category the article fits into. The `blog` tag will be entered into the listing found on the Data page of the website. Other tags are currently not used directly; thus, articles missing the `blog` tag will not be linked by default.
- `title`. Contains the article's title
- `author`. Contains the article's author name
- `description`. Contains a short description of the article's content, used for both the article listing and page metadata
- `original_date: YYYY-MM-DD`. The date the article was originally written, which will be used in header of the resulting article.
- `date: YYYY-MM-DD`. Typically this is used to inject a dynamic date into the article reflecting the most recent update.
- `update_delta: n`. How often the article should be updated, where `n` is a number of days. Use `9999` or similar for static articles. If no `update_delta` is provided, the default is 7 days. 

## Managing R dependencies in articles

Each article should contain a section near the top describing external dependencies. The template for this section is:

```r
# We use pacman to load and install dependencies.
library(pacman)

# Please list your article's dependencies here, comma separated:
p_load(tidyverse, ggplot2)
```

**pacman** is used to manage dependencies because it is broadly compatible with our CI system and server; if a dependency is not installed, the `p_load` command will install it as necessary.

## File and directory structure

The structure of this repository is as follows:

- `compiler.R`: Script that handles RMarkdown compilation and output for articles, as well as JSON metadata generation
- `docs/`: Folder containing subfolders for each article.
- `docs/<article>/`: All files required to compile an article should go in this folder; working directory reflects this.
- `docs/<article>/<article>.Rmd`: Main Rmd file to compile an article.
- `output_template/template_stub.html`: Template HTML stub, which is used with RMarkdown to generate our HTML output.
- `articles.Rproj`: R Project file for this repository.
- `.travis.yml`: Configuration info for Travis CI.
- `.gitignore`: Github file ignore information
- `README.md`: This file

## Contribution guidelines

We welcome user contributions which meet the following requirements:

1. Articles must be written in English
2. Articles must use Voteview data or NOMINATE estimation to produce either a new, derived dataset or examine a problem of political, journalistic, or social interest.
3. Code must be non-destructive, must not modify files outside the article's folder, and must contain clearly documented and easily understood functionality.
4. Articles must be submitted as a GitHub pull request to this repository.
5. Articles must be submitted by their authors.

We reserve the right to reject submissions for any reason, with or without feedback. 

## License

The content of this repository is available under the MIT license. By submitting a contribution to this repository, you are granting Voteview / UCLA certain irrevocable non-exclusive rights to display your contribution on voteview.com or related sites, or to promote or advertise your contribution in connection with the site. We will preserve and display author metadata that you submit along with your article.