# voteview.com article repository

This repository contains the source documents for the articles, help messages, and blog posts used on voteview.com. The structure of this repository is as follows:

- `compiler.R`: Script that handles RMarkdown compilation and output for articles, as well as JSON metadata generation
- `docs/`: Folder containing subfolders for each article.
- `docs/<article>/`: All files required to compile an article should go in this folder; working directory reflects this.
- `docs/<article>/<article>.Rmd`: Main Rmd file to compile an article.
- `output_template/template_stub.html`: Template HTML stub, which is used with RMarkdown to generate our HTML output.
- `articles.Rproj`: R Project file for this repository.
- `.travis.yml`: Configuration info for Travis CI.
- `.gitignore`: Github file ignore information
- `README.md`: This file

## Contributing to voteview.com

We welcome user contributions that meet the following requirements:

1. English language text
2. Use NOMINATE or Voteview data to produce a derived dataset or examine a problem of political, journalistic, or social interest.
3. Contain code that is non-destructive, does not modify files outside the article's subfolder, has functionality that is clearly documented and able to be understood
4. Are submitted through a GitHub pull request to this repository.

We reserve the right to reject submissions for any reason.

< info about how to make a pull request >

## Licensing

The content of this repository is available under the MIT license. By submitting a contribution to this repository, you are granting Voteview / UCLA certain irrevocable non-exclusive rights to display your contribution on voteview.com or related sites, or to promote or advertise your contribution in connection with the site. We will preserve and display author metadata that you submit along with your article.
