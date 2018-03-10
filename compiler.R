# Load our dependencies
library(pacman)
p_load(rmarkdown, knitr, rjson)

process_file_name = function(file_name) {
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
  compiled_exists = file.exists(html_version)

  # If we do, check if we need to write another one, or if we're fine with
  # the cache
  need_update = ifelse(compiled_exists,
                       file.mtime(file_name) > file.mtime(html_version),
                       TRUE)
  
  # Do the update if necessary
  if(need_update) {
    cat("\tRendering Rmd to HTML... \n")
    render_file(file_name, folder_name)
    cat("\tWriting JSON metadata... \n")
    parse_front_matter(file_name, folder_name, base_name)
    clean_superfluous_libraries(folder_name, base_name)
  } else {
    cat("\tFile not modified, keeping cached version.\n")
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
  
  # 
  if(is.null(yaml_metadata_list$tag)) {
    cat("\tWARNING: No tags included in article metadata.\n")
  }
  if(is.null(yaml_metadata_list$title)) {
    cat("\tWARNING: No title included in article metadata,",
        "defaulting to \"", base_name, "\"\n")
    yaml_metadata_list$title = base_name
  }
  if(is.null(yaml_metadata_list$author)) {
    cat("\tWARNING: No author included in article metadata,",
        "defaulting to \"Voteview Team\"\n")
    yaml_metadata_list$author = "Voteview Team"
  }
  if(is.null(yaml_metadata_list$original_data)) {
    cat("\tWARNING: No original date in article metadata,",
        "defaulting to", format(Sys.Date(), "%Y-%m-%d"), "\n")
    yaml_metadata_list$original_date = format(Sys.Date(), "%Y-%m-%d")
  }
  
  json_output_list = list(
    title = yaml_metadata_list$title,
    author = yaml_metadata_list$author,
    description = yaml_metadata_list$description,
    original_date = yaml_metadata_list$original_date,
    date_modified = as.numeric(Sys.time()),
    tags = yaml_metadata_list$tags
  )
  
  write(rjson::toJSON(json_output_list), 
        paste0(folder_name, base_name, ".json"))
}

core_loop = function() {
  # Process these
  rmd_process_list = list.files(".", ".Rmd$", recursive = TRUE)
  
  # Loop through the files we wish to process
  i = 1
  for(file_name in rmd_process_list) {
    cat(paste0("Processing file ", i, "/", 
               length(rmd_process_list), ": ", 
               file_name, "\n"))
    process_file_name(file_name)
    i = i + 1
  } 
  cat("Job complete.\n")
}

core_loop()