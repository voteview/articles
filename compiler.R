#!/usr/bin/env Rscript

# Load our dependencies
result_pacman = require(pacman)
if(!result_pacman) {
  # Hardcoded a repo in order to force proceeding.
  install.packages("pacman", repos = "https://cloud.r-project.org")
  library(pacman)
}
p_load(rmarkdown, knitr, rjson, argparse)

# This is a quick hack for pandoc not working in the MacOS command line.
if(!rmarkdown::pandoc_available("1.12.3")) {
  Sys.setenv(
    RSTUDIO_PANDOC = "/Applications/RStudio.app/Contents/MacOS/pandoc"
  )
  if(!rmarkdown::pandoc_available("1.12.3")) {
    stop("Error: Pandoc not detected in R installation.")
  }
}

# 
process_file_name = function(file_name, force = FALSE, dryrun = FALSE) {
  # String split to get the name of the folder, the name of the file,
  # and the pre-extension name of the file ("base_name")
  folder_chunks = strsplit(file_name, "/")
  stripped_file_name = folder_chunks[[1]][length(folder_chunks[[1]])]
  base_name = substr(stripped_file_name,
                     1, (nchar(stripped_file_name)-4))
  folder_name = paste0(
    paste(folder_chunks[[1]][1:(length(folder_chunks[[1]])-1)],
          collapse = "/"),
    "/")

  # Check if we have a current HTML version
  html_version = paste0(folder_name, base_name, ".html")
  json_metadata = paste0(folder_name, base_name, ".json")
  extra_outputs = paste0(folder_name, base_name, "_files")

  # If each of the files exists, then a compiled version is considered to
  # exist.
  compiled_exists = file.exists(html_version) &&
    file.exists(json_metadata) && file.exists(extra_outputs)
  
  # If we have JSON metadata, then we can check recompile data in the JSON
  # metadata
  if(file.exists(json_metadata)) {
    needs_recompile = read_expiry_date(json_metadata)
  } else {
    needs_recompile = TRUE
  }

  # Dummied: Get file's most recent modify date.  
  recent_modify = file.mtime(file_name) > file.mtime(html_version)

  # Updates:
  # - Compiled files do not exist
  # - Compiled files do exist, but the JSON tells us it's time to recompile
  # - Force recompile
  need_update = !compiled_exists || needs_recompile || force

  # Do the update if necessary
  if(need_update) {
    if(dryrun) {
      cat("\tWould have compiled, but dryrun is set... \n")
    } else {
      cat("\tRendering Rmd to HTML... \n")
      render_file(file_name, folder_name)
      cat("\tWriting JSON metadata... \n")
      parse_front_matter(file_name, folder_name, base_name)
      clean_superfluous_libraries(folder_name, base_name)
    }
  } else {
    cat("\tFile not modified, keeping cached version.\n")
    cat(paste0("\tFiles exist? ", compiled_exists, "\n"))
    cat(paste0("\tRmd modified? ", recent_modify, "\n"))
    cat(paste0("\tNeeds recompile (timer)? ", needs_recompile, "\n"))
    cat(paste0("\tForce recompile? ", force, "\n"))
  }

}

render_file = function(file_name, folder) {
  # Override default output options to use our template
  rmarkdown::render(input = file_name,
                    output_format = "html_document",
                    output_options = list(
                      template = "../../output_template/template_stub.html",
                      self_contained = FALSE
                    ),
                    output_dir = folder,
                    clean = TRUE,
                    quiet = TRUE)

}

clean_superfluous_libraries = function(folder_name, base_name) {
  # RMarkdown generates JS files for its dependencies, we don't need
  # them really.
  file_chunk = paste0(folder_name, base_name, "_files/")
  unlink(paste0(file_chunk, "bootstrap-*"), recursive = TRUE)
  unlink(paste0(file_chunk, "jquery-*"), recursive = TRUE)
  unlink(paste0(file_chunk, "navigation-*"), recursive = TRUE)
}

parse_front_matter = function(file_name, folder_name, base_name) {
  # Write a JSON
  yaml_metadata_list = rmarkdown::yaml_front_matter(file_name)

  # Tags: this will affect where something shows up
  if(is.null(yaml_metadata_list$tag)) {
    cat("\tWARNING: No tags included in article metadata.\n")
  }
  
  # Article title
  if(is.null(yaml_metadata_list$title)) {
    cat("\tWARNING: No title included in article metadata,",
        "defaulting to \"", base_name, "\"\n")
    yaml_metadata_list$title = base_name
  }
  
  # Who wrote it
  if(is.null(yaml_metadata_list$author)) {
    cat("\tWARNING: No author included in article metadata,",
        "defaulting to \"Voteview Team\"\n")
    yaml_metadata_list$author = "Voteview Team"
  }
  
  # What do we write the date as?
  if(is.null(yaml_metadata_list$original_date)) {
    cat("\tWARNING: No original date in article metadata,",
        "defaulting to", format(Sys.Date(), "%Y-%m-%d"), "\n")
    yaml_metadata_list$original_date = format(Sys.Date(), "%Y-%m-%d")
  }
  
  # How often does the article need to be updated?
  if(is.null(yaml_metadata_list$update_delta)) {
    yaml_metadata_list$update_delta = 7
  }
  update_date = format(Sys.Date() + yaml_metadata_list$update_delta, "%Y-%m-%d")

  # Output data
  json_output_list = list(
    title = yaml_metadata_list$title,
    author = yaml_metadata_list$author,
    description = yaml_metadata_list$description,
    original_date = yaml_metadata_list$original_date,
    date_modified = as.numeric(Sys.time()),
    # Note one stupid hack: the JSON field is recompile_date, but the yaml
    # field is update_delta, which here becomes update_date when parsed.
    recompile_date = update_date,
    tags = yaml_metadata_list$tags
  )

  write(rjson::toJSON(json_output_list),
        paste0(folder_name, base_name, ".json"))
}

read_expiry_date = function(filename) {
  json_matter = fromJSON(file = filename)
  if(!"recompile_date" %in% names(json_matter)) { return(TRUE) }

  Sys.Date() > json_matter[["recompile_date"]]
}

core_loop = function() {
  # Process these
  rmd_process_list = list.files(".", ".Rmd$", recursive = TRUE)

  # Loop through the files we wish to process -- why is this not an imap?
  # Because we don't include tidyverse as a dependency by default in the
  # compiler. We could include it since many articles do, but we don't
  # by default.
  i = 1
  for(file_name in rmd_process_list) {
    cat(paste0("Processing file ", i, "/",
               length(rmd_process_list), ": ",
               file_name, "\n"))
    tryCatch({
      process_file_name(file_name)
    }, error = function(e) {
      print(e)
      cat("Error working on this file.\n")
    })
    i = i + 1
  }
  cat("Job complete.\n")
}

parse_arguments_dispatch = function() {
  # Parse command line options (if called from Rscript)
  parser <- argparse::ArgumentParser()
  
  # Force a single file to update
  parser$add_argument(
    "-f", "--filename", default="", type="character",
    help="Name of article Rmarkdown file to process (default processes all articles).")
  parser$add_argument(
    "-d", "--dryrun", action="store_true",
    help="Don't recompile any articles, just say what you would have done."
  )
  args <- parser$parse_args()
  
  if (args$filename != "") {
    if (file.exists(args$filename)) {
      # Process this file and force it to be rewritten.
      cat(sprintf("Processing %s:\n", args$filename))
      process_file_name(args$filename, force=TRUE, dryrun=args$dryrun)
    } else {
      stop(sprintf("Rmarkdown file '%s' not found.\n", args$filename))
    }
  } else {
    cat("Processing all articles:\n")
    core_loop(dryrun=args$dryrun)
  }  
}

# Parse arguments or process all files.
parse_arguments_dispatch()